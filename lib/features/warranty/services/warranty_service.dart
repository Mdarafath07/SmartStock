import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstock/features/warranty/models/warranty_model.dart';

class WarrantyService {
  final FirebaseFirestore _firestore;

  WarrantyService() : _firestore = FirebaseFirestore.instance;

  Future<List<Warranty>> getAllWarranties() async {
    final snapshot = await _firestore
        .collection('sales')
        .orderBy('saleDate', descending: true)
        .get();

    return _mapToWarranties(snapshot);
  }

  Future<List<Warranty>> searchWarranty({
    String? category,
    String? modelNumber,
    String? serialNumber,
  }) async {
    Query query = _firestore.collection('sales');

    bool hasConstraint = false;

    if (modelNumber != null && modelNumber.isNotEmpty) {
      query = query.where('modelNumber', isEqualTo: modelNumber);
      hasConstraint = true;
    }

    if (serialNumber != null && serialNumber.isNotEmpty) {
      query = query.where('serialNumber', isEqualTo: serialNumber);
      hasConstraint = true;
    }

    if (!hasConstraint) {
      query = query.orderBy('saleDate', descending: true);
    }

    final snapshot = await query.get();
    var warranties = _mapToWarranties(snapshot);

    if (category != null && category.isNotEmpty) {
      warranties = warranties
          .where((w) => w.productName
              .toLowerCase()
              .contains(category.toLowerCase()))
          .toList();
    }

    return warranties;
  }

  Future<Warranty?> getWarrantyBySerialNumber(String serial) async {
    final snapshot = await _firestore
        .collection('sales')
        .where('serialNumber', isEqualTo: serial)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return _mapWarranty(snapshot.docs.first);
  }

  Future<List<Warranty>> getExpiredWarranties() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('sales')
        .where('warrantyExpiryDate', isLessThan: Timestamp.fromDate(now))
        .orderBy('warrantyExpiryDate', descending: true)
        .get();

    return _mapToWarranties(snapshot);
  }

  Future<List<Warranty>> getActiveWarranties() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('sales')
        .where('warrantyExpiryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('warrantyExpiryDate', descending: false)
        .get();

    return _mapToWarranties(snapshot);
  }

  Future<Warranty?> getWarrantyBySaleId(String saleId) async {
    final doc = await _firestore.collection('sales').doc(saleId).get();
    if (!doc.exists) return null;
    return _mapWarranty(doc);
  }

  /// Claim warranty for a product:
  /// 1. Check warranty is active and not already claimed
  /// 2. Old serial → status "available", returnType "warranty"
  /// 3. Old product stock +1
  /// 4. New serial → status "sold"
  /// 5. New product stock -1
  /// 6. Create sale record (saleType: 'warranty_claim')
  /// 7. Mark original sale as warrantyClaimed
  Future<void> claimWarranty({
    required String saleId,
    required String serialNumber,
    required String newSerialNumber,
    String? reason,
    String? notes,
  }) async {
    final batch = _firestore.batch();

    // Get original sale
    final saleDoc = await _firestore.collection('sales').doc(saleId).get();
    if (!saleDoc.exists) throw Exception('Sale not found');
    final saleData = saleDoc.data()!;

    // Check if warranty already claimed
    if (saleData['warrantyClaimed'] == true) {
      throw Exception('Warranty has already been claimed for this product');
    }

    // Check warranty is active
    final expiryDate = (saleData['warrantyExpiryDate'] as Timestamp?)?.toDate();
    if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
      throw Exception('Warranty has expired');
    }

    // 1. Find old serial and update
    final oldSerialSnapshot = await _firestore
        .collection('serial_numbers')
        .where('serialNumber', isEqualTo: serialNumber)
        .limit(1)
        .get();

    String oldSerialId = '';
    String productId = saleData['productId'] as String? ?? '';
    if (oldSerialSnapshot.docs.isNotEmpty) {
      oldSerialId = oldSerialSnapshot.docs.first.id;
      batch.update(_firestore.collection('serial_numbers').doc(oldSerialId), {
        'status': 'available',
        'saleId': FieldValue.delete(),
        'returnType': 'warranty',
      });
    }

    // 2. Increment old product stock
    if (productId.isNotEmpty) {
      final productRef = _firestore.collection('products').doc(productId);
      final productDoc = await productRef.get();
      if (productDoc.exists) {
        final currentQty = (productDoc.data()?['availableQuantity'] as num?)?.toInt() ?? 0;
        batch.update(productRef, {
          'availableQuantity': currentQty + 1,
        });
      }
    }

    // 3. Find new serial and update to sold
    String newProductId = '';

    final newSerialSnapshot = await _firestore
        .collection('serial_numbers')
        .where('serialNumber', isEqualTo: newSerialNumber)
        .limit(1)
        .get();

    String newSerialId = '';
    if (newSerialSnapshot.docs.isNotEmpty) {
      newSerialId = newSerialSnapshot.docs.first.id;
      final newSerialData = newSerialSnapshot.docs.first.data();
      newProductId = newSerialData['productId'] as String? ?? '';

      if (newProductId.isNotEmpty) {
        final newProductDoc =
            await _firestore.collection('products').doc(newProductId).get();
        if (newProductDoc.exists) {
          final npData = newProductDoc.data()!;
          final currentQty = (npData['availableQuantity'] as num?)?.toInt() ?? 0;
          batch.update(newProductDoc.reference, {
            'availableQuantity': (currentQty - 1).clamp(0, 999999),
          });
        }
      }
    }

    // 4. Create sale record (warranty claim — product transferred, no profit)
    final now = DateTime.now();
    final oldSaleDate = (saleData['saleDate'] as Timestamp?)?.toDate();
    final saleRef = _firestore.collection('sales').doc();
    batch.set(saleRef, {
      'productId': productId,
      'productName': saleData['productName'] ?? '',
      'modelNumber': saleData['modelNumber'] ?? '',
      'serialNumber': newSerialNumber,
      'serialNumberId': newSerialId,
      'categoryId': saleData['categoryId'] ?? '',
      'categoryName': saleData['categoryName'] ?? '',
      'customerId': saleData['customerId'] ?? '',
      'customerName': saleData['customerName'] ?? '',
      'customerPhone': saleData['customerPhone'] ?? '',
      'salePrice': saleData['salePrice'] ?? 0,
      'purchasePrice': saleData['purchasePrice'] ?? 0,
      'profit': 0,
      'saleDate': Timestamp.fromDate(now),
      'warrantyExpiryDate': Timestamp.fromDate(now),
      'warrantyMonths': 0,
      'createdAt': Timestamp.fromDate(now),
      'imageUrl': saleData['imageUrl'] ?? '',
      'saleType': 'warranty_claim',
      'warrantyClaimed': true,
      'relatedSaleId': saleId,
      'oldSerialNumber': serialNumber,
      'oldPurchaseDate': oldSaleDate != null ? Timestamp.fromDate(oldSaleDate) : null,
      if (reason != null) 'claimReason': reason,
      if (notes != null) 'notes': notes,
    });

    // 5. Update new serial to sold
    if (newSerialId.isNotEmpty) {
      batch.update(
        _firestore.collection('serial_numbers').doc(newSerialId),
        {
          'status': 'sold',
          'saleId': saleRef.id,
        },
      );
    }

    // 6. Mark original sale as warranty claimed
    batch.update(saleDoc.reference, {
      'warrantyClaimed': true,
      'newSerialNumber': newSerialNumber,
      'claimDate': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  Future<List<Map<String, String>>> getAvailableSerials() async {
    final serialSnapshot = await _firestore
        .collection('serial_numbers')
        .where('status', isEqualTo: 'available')
        .get();

    final productIds = <String>{};
    final serialsByProduct = <String, List<String>>{};

    for (final doc in serialSnapshot.docs) {
      final data = doc.data();
      final pid = data['productId'] as String? ?? '';
      final serial = data['serialNumber'] as String? ?? '';
      if (pid.isNotEmpty && serial.isNotEmpty) {
        productIds.add(pid);
        serialsByProduct.putIfAbsent(pid, () => []).add(serial);
      }
    }

    if (productIds.isEmpty) return [];

    final productNames = <String, String>{};
    final chunks = productIds.toList();
    for (int i = 0; i < chunks.length; i += 30) {
      final chunk = chunks.skip(i).take(30).toList();
      final productSnapshot = await _firestore
          .collection('products')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in productSnapshot.docs) {
        productNames[doc.id] = doc.data()['productName'] as String? ?? 'Unknown';
      }
    }

    final result = <Map<String, String>>[];
    for (final entry in serialsByProduct.entries) {
      final name = productNames[entry.key] ?? 'Unknown';
      for (final serial in entry.value) {
        result.add({
          'serialNumber': serial,
          'productName': name,
          'productId': entry.key,
        });
      }
    }
    result.sort((a, b) => a['productName']!.compareTo(b['productName']!));
    return result;
  }

  List<Warranty> _mapToWarranties(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) => _mapWarranty(doc)).toList();
  }

  Warranty _mapWarranty(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Warranty.fromJson({...data, 'saleId': doc.id}, doc.id);
  }
}
