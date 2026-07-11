import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstock/features/sales/models/sale_model.dart';
import 'package:smartstock/features/sales/models/serial_number_model.dart';

class SaleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _salesCollection => 'sales';
  String get _serialNumbersCollection => 'serial_numbers';
  String get _customersCollection => 'customers';

  Future<String> createSale({
    required String productId,
    required String productName,
    required String modelNumber,
    required String categoryId,
    required String categoryName,
    required String serialNumber,
    required String serialNumberId,
    required String customerId,
    required String customerName,
    required String customerPhone,
    required double salePrice,
    required double purchasePrice,
    required DateTime warrantyExpiryDate,
  }) async {
    final batch = _firestore.batch();

    final saleRef = _firestore.collection(_salesCollection).doc();
    final profit = salePrice - purchasePrice;

    batch.set(saleRef, {
      'productId': productId,
      'productName': productName,
      'modelNumber': modelNumber,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'serialNumber': serialNumber,
      'serialNumberId': serialNumberId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'salePrice': salePrice,
      'purchasePrice': purchasePrice,
      'profit': profit,
      'saleDate': Timestamp.fromDate(DateTime.now()),
      'warrantyExpiryDate': Timestamp.fromDate(warrantyExpiryDate),
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });

    final serialRef = _firestore.collection(_serialNumbersCollection).doc(serialNumberId);
    batch.update(serialRef, {
      'status': 'sold',
      'saleId': saleRef.id,
    });

    await _decrementStock(productId, batch);

    final customerRef = _firestore.collection(_customersCollection).doc(customerId);
    final customerDoc = await customerRef.get();
    if (customerDoc.exists) {
      batch.update(customerRef, {
        'totalOrders': FieldValue.increment(1),
        'lifetimeValue': FieldValue.increment(salePrice),
        'name': customerName,
        'phone': customerPhone,
      });
    } else {
      batch.set(customerRef, {
        'name': customerName,
        'phone': customerPhone,
        'address': '',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'totalOrders': 1,
        'lifetimeValue': salePrice,
      });
    }

    await batch.commit();
    return saleRef.id;
  }

  Future<List<String>> bulkCreateSales({
    required List<Map<String, dynamic>> items,
    required String customerId,
    required String customerName,
    required String customerPhone,
  }) async {
    final batch = _firestore.batch();
    final saleIds = <String>[];
    double totalLifetimeValue = 0;

    final productStockUpdates = <String, int>{};

    for (final item in items) {
      final saleRef = _firestore.collection(_salesCollection).doc();
      final salePrice = item['salePrice'] as double;
      final purchasePrice = item['purchasePrice'] as double;
      final profit = salePrice - purchasePrice;

      batch.set(saleRef, {
        'productId': item['productId'],
        'productName': item['productName'],
        'modelNumber': item['modelNumber'],
        'imageUrl': item['imageUrl'] as String? ?? '',
        'categoryId': item['categoryId'],
        'categoryName': item['categoryName'] as String? ?? '',
        'serialNumber': item['serialNumber'],
        'serialNumberId': item['serialNumberId'],
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'salePrice': salePrice,
        'purchasePrice': purchasePrice,
        'profit': profit,
        'saleDate': Timestamp.fromDate(DateTime.now()),
        'warrantyExpiryDate': Timestamp.fromDate(item['warrantyExpiryDate'] as DateTime),
        'warrantyMonths': item['warrantyMonths'] as int? ?? 0,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
      saleIds.add(saleRef.id);

      final serialRef = _firestore.collection(_serialNumbersCollection).doc(item['serialNumberId'] as String);
      batch.update(serialRef, {
        'status': 'sold',
        'saleId': saleRef.id,
      });

      final pid = item['productId'] as String;
      productStockUpdates[pid] = (productStockUpdates[pid] ?? 0) + 1;
      totalLifetimeValue += salePrice;
    }

    for (final entry in productStockUpdates.entries) {
      final productRef = _firestore.collection('products').doc(entry.key);
      batch.update(productRef, {
        'availableQuantity': FieldValue.increment(-entry.value),
      });
    }

    if (customerId.isNotEmpty) {
      final customerRef = _firestore.collection(_customersCollection).doc(customerId);
      final customerDoc = await customerRef.get();
      if (customerDoc.exists) {
        batch.update(customerRef, {
          'totalOrders': FieldValue.increment(items.length),
          'lifetimeValue': FieldValue.increment(totalLifetimeValue),
          'name': customerName,
          'phone': customerPhone,
        });
      } else {
        batch.set(customerRef, {
          'name': customerName,
          'phone': customerPhone,
          'address': '',
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'totalOrders': items.length,
          'lifetimeValue': totalLifetimeValue,
        });
      }
    }

    await batch.commit();
    return saleIds;
  }

  Future<void> voidSale(String saleId) async {
    final saleDoc = await _firestore.collection(_salesCollection).doc(saleId).get();
    if (!saleDoc.exists) throw Exception('Sale not found');

    final data = saleDoc.data()!;
    final serialNumberId = data['serialNumberId'] as String?;
    final productId = data['productId'] as String?;

    if (serialNumberId == null || productId == null) {
      throw Exception('Sale data incomplete');
    }

    final batch = _firestore.batch();

    batch.update(
      _firestore.collection(_serialNumbersCollection).doc(serialNumberId),
      {'status': 'available', 'saleId': FieldValue.delete()},
    );

    batch.update(
      _firestore.collection('products').doc(productId),
      {'availableQuantity': FieldValue.increment(1)},
    );

    batch.delete(_firestore.collection(_salesCollection).doc(saleId));

    await batch.commit();
  }

  Future<void> _decrementStock(String productId, WriteBatch batch) async {
    batch.update(
      _firestore.collection('products').doc(productId),
      {'availableQuantity': FieldValue.increment(-1)},
    );
  }

  Stream<List<Sale>> getTodaysSales() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection(_salesCollection)
        .where('saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('saleDate', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('saleDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Sale.fromJson(doc.data(), doc.id))
            .where((sale) => sale.saleType != 'warranty_claim')
            .toList());
  }

  Stream<List<Sale>> getSalesHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? productId,
    String? categoryId,
    String? customerId,
  }) {
    Query query = _firestore.collection(_salesCollection);

    bool hasDateFilter = startDate != null && endDate != null;
    bool hasProductFilter = productId != null && productId.isNotEmpty;
    bool hasCategoryFilter = categoryId != null && categoryId.isNotEmpty;
    bool hasCustomerFilter = customerId != null && customerId.isNotEmpty;

    if (hasDateFilter) {
      query = query
          .where('saleDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('saleDate', isLessThan: Timestamp.fromDate(endDate));
    }
    if (hasProductFilter) {
      query = query.where('productId', isEqualTo: productId);
    }
    if (hasCategoryFilter) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    if (hasCustomerFilter) {
      query = query.where('customerId', isEqualTo: customerId);
    }

    return query
        .orderBy('saleDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Sale.fromJson(doc.data() as Map<String, dynamic>, doc.id))
            .where((sale) => sale.saleType != 'warranty_claim')
            .toList());
  }

  Future<List<Sale>> searchSaleBySerialNumber(String serial) async {
    final snapshot = await _firestore
        .collection(_salesCollection)
        .where('serialNumber', isEqualTo: serial)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return [];
    final doc = snapshot.docs.first;
    final data = doc.data();
    final customerId = data['customerId'] as String?;
    final saleDate = data['saleDate'] as Timestamp?;
    if (customerId == null || customerId.isEmpty || saleDate == null) {
      return [Sale.fromJson(data, doc.id)];
    }
    final siblings = await _firestore
        .collection(_salesCollection)
        .where('customerId', isEqualTo: customerId)
        .where('saleDate', isEqualTo: saleDate)
        .get();
    return siblings.docs.map((d) => Sale.fromJson(d.data(), d.id)).toList();
  }

  Future<Sale?> getSaleById(String id) async {
    final doc = await _firestore.collection(_salesCollection).doc(id).get();
    if (!doc.exists) return null;
    return Sale.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<Map<String, dynamic>> getDailySalesSummary() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection(_salesCollection)
        .where('saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('saleDate', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    double totalAmount = 0;
    double totalProfit = 0;
    int totalCount = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['saleType'] == 'warranty_claim') continue;
      totalAmount += (data['salePrice'] as num?)?.toDouble() ?? 0.0;
      totalProfit += (data['profit'] as num?)?.toDouble() ?? 0.0;
      totalCount++;
    }

    return {
      'totalAmount': totalAmount,
      'totalCount': totalCount,
      'totalProfit': totalProfit,
    };
  }

  Stream<List<SerialNumber>> getAvailableSerialNumbers(String productId) {
    return _firestore
        .collection(_serialNumbersCollection)
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SerialNumber.fromJson(doc.data(), doc.id))
            .toList());
  }
}
