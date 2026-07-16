import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstock/features/replacements/models/replacement_model.dart';

class ReplacementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _collection => 'replacements';
  String get _salesCollection => 'sales';
  String get _serialNumbersCollection => 'serial_numbers';
  String get _productsCollection => 'products';

  Future<String> createReplacement(Replacement replacement) async {
    final docRef = _firestore.collection(_collection).doc();
    final data = replacement.toJson();
    data['createdAt'] = Timestamp.fromDate(replacement.createdAt);
    if (replacement.completedAt != null) {
      data['completedAt'] = Timestamp.fromDate(replacement.completedAt!);
    }
    await docRef.set(data);
    return docRef.id;
  }

  Future<void> updateReplacement(String id, Map<String, dynamic> updates) async {
    final updateData = Map<String, dynamic>.from(updates);
    if (updates.containsKey('completedAt') && updates['completedAt'] is DateTime) {
      updateData['completedAt'] = Timestamp.fromDate(updates['completedAt'] as DateTime);
    }
    await _firestore.collection(_collection).doc(id).update(updateData);
  }

  /// Complete a replacement:
  /// 1. Old serial → available (back in inventory)
  /// 2. Old product stock +1
  /// 3. New serial → sold
  /// 4. New product stock -1
  /// 5. Creates a sale record for the new product (saleType: 'replacement')
  /// 6. Links replacement record to the new sale
  Future<void> completeReplacement(
    String id, {
    required String newSerialNumber,
    String? notes,
  }) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) throw Exception('Replacement request not found');
    final replacement = Replacement.fromJson(doc.data()!, doc.id);

    final batch = _firestore.batch();

    // 1. Find and update old serial
    final oldSerialSnapshot = await _firestore
        .collection(_serialNumbersCollection)
        .where('serialNumber', isEqualTo: replacement.oldSerialNumber)
        .limit(1)
        .get();
    if (oldSerialSnapshot.docs.isNotEmpty) {
      batch.update(oldSerialSnapshot.docs.first.reference, {
        'status': 'available',
        'saleId': FieldValue.delete(),
        'returnType': FieldValue.delete(),
      });
    }

    // 2. Increment old product stock
    if (replacement.productId.isNotEmpty) {
      final oldProductRef = _firestore.collection(_productsCollection).doc(replacement.productId);
      final oldProductDoc = await oldProductRef.get();
      if (oldProductDoc.exists) {
        final currentQty = (oldProductDoc.data()?['availableQuantity'] as num?)?.toInt() ?? 0;
        batch.update(oldProductRef, {
          'availableQuantity': currentQty + 1,
        });
      }
    }

    // 3. Find new serial and update to sold
    String? newProductId;
    String? newProductName;
    String? newModelNumber;
    double? newSellingPrice;
    double? newPurchasePrice;

    final newSerialSnapshot = await _firestore
        .collection(_serialNumbersCollection)
        .where('serialNumber', isEqualTo: newSerialNumber)
        .limit(1)
        .get();

    String newSerialId = '';
    if (newSerialSnapshot.docs.isNotEmpty) {
      final newSerialData = newSerialSnapshot.docs.first.data();
      newSerialId = newSerialSnapshot.docs.first.id;
      newProductId = newSerialData['productId'] as String?;

      // Get new product details
      if (newProductId != null && newProductId.isNotEmpty) {
        final newProductDoc =
            await _firestore.collection(_productsCollection).doc(newProductId).get();
        if (newProductDoc.exists) {
          final npData = newProductDoc.data()!;
          newProductName = npData['productName'] as String? ?? '';
          newModelNumber = npData['modelNumber'] as String? ?? '';
          newSellingPrice = (npData['sellingPrice'] as num?)?.toDouble() ?? 0;
          newPurchasePrice = (npData['purchasePrice'] as num?)?.toDouble() ?? 0;

          // 4. Decrement new product stock
          final currentQty = (npData['availableQuantity'] as num?)?.toInt() ?? 0;
          batch.update(newProductDoc.reference, {
            'availableQuantity': (currentQty - 1).clamp(0, 999999),
          });
        }
      }
    }

    // 5. Create sale record for the new product
    final now = DateTime.now();
    final warrantyMonths = 0;
    final saleRef = _firestore.collection(_salesCollection).doc();
    final profit = (newSellingPrice ?? 0) - (newPurchasePrice ?? 0);
    batch.set(saleRef, {
      'productId': newProductId ?? replacement.productId,
      'productName': newProductName ?? replacement.productName,
      'modelNumber': newModelNumber ?? replacement.modelNumber,
      'serialNumber': newSerialNumber,
      'serialNumberId': newSerialId,
      'categoryId': '',
      'categoryName': '',
      'customerId': '',
      'customerName': replacement.customerName,
      'customerPhone': replacement.customerPhone,
      'salePrice': newSellingPrice ?? 0,
      'purchasePrice': newPurchasePrice ?? 0,
      'profit': profit,
      'saleDate': Timestamp.fromDate(now),
      'warrantyExpiryDate': Timestamp.fromDate(now),
      'warrantyMonths': warrantyMonths,
      'createdAt': Timestamp.fromDate(now),
      'imageUrl': '',
      'saleType': 'replacement',
      'relatedSaleId': replacement.saleId.isNotEmpty ? replacement.saleId : null,
      'oldSerialNumber': replacement.oldSerialNumber,
    });

    // Update new serial to sold
    if (newSerialId.isNotEmpty) {
      batch.update(
        _firestore.collection(_serialNumbersCollection).doc(newSerialId),
        {
          'status': 'sold',
          'saleId': saleRef.id,
        },
      );
    }

    // 6. Update replacement record
    batch.update(doc.reference, {
      'status': 'completed',
      'newSerialNumber': newSerialNumber,
      'notes': notes,
      'saleId': saleRef.id,
      'completedAt': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  Future<void> rejectReplacement(String id, {String? reason}) async {
    await _firestore.collection(_collection).doc(id).update({
      'status': 'rejected',
      'notes': reason,
      'completedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteReplacement(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  Future<List<Replacement>> getReplacements() async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snapshot.docs
        .map((doc) => Replacement.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<List<Replacement>> getReplacementsByCustomer(String customerId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Replacement.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<List<Replacement>> getReplacementsBySerial(String serialNumber) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('oldSerialNumber', isEqualTo: serialNumber)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Replacement.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<Replacement?> getReplacementById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return Replacement.fromJson(doc.data()!, doc.id);
  }
}
