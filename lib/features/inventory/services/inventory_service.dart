import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstock/features/inventory/models/inventory_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<InventoryItem>> getInventory({
    String? categoryId,
    String? brandFilter,
    String? stockStatus,
  }) async {
    final bool filterByCategory =
        categoryId != null && categoryId.isNotEmpty;
    late Query query;

    if (filterByCategory) {
      query = _firestore
          .collection('products')
          .where('categoryId', isEqualTo: categoryId);
    } else {
      query = _firestore
          .collection('products')
          .orderBy('createdAt', descending: true);
    }

    final snapshot = await query.get();
    final items = <InventoryItem>[];

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final availableCount =
          await _countSerialNumbers(doc.id, 'available');
      final soldCount = await _countSerialNumbers(doc.id, 'sold');
      final status = InventoryItem.computeStockStatus(availableCount);

      if (stockStatus != null && stockStatus.isNotEmpty && status != stockStatus) {
        continue;
      }

      final productName = data['productName'] as String? ?? '';
      if (brandFilter != null && brandFilter.isNotEmpty &&
          !productName.toLowerCase().contains(brandFilter.toLowerCase())) {
        continue;
      }

      items.add(InventoryItem(
        productId: doc.id,
        productName: productName,
        categoryName: data['categoryName'] as String? ?? '',
        modelNumber: data['modelNumber'] as String? ?? '',
        imageUrl: data['imageUrl'] as String? ?? '',
        availableStock: availableCount,
        soldStock: soldCount,
        stockStatus: status,
      ));
    }

    return items;
  }

  Future<Map<String, dynamic>> getStockDetails(String productId) async {
    final serialSnapshot = await _firestore
        .collection('serial_numbers')
        .where('productId', isEqualTo: productId)
        .get();

    final serialNumbers = serialSnapshot.docs.map((doc) {
      final data = doc.data();
      return <String, dynamic>{
        'id': doc.id,
        'serialNumber': data['serialNumber'] as String? ?? '',
        'status': data['status'] as String? ?? 'available',
      };
    }).toList();

    final available =
        serialNumbers.where((s) => s['status'] == 'available').length;
    final sold = serialNumbers.where((s) => s['status'] == 'sold').length;
    final defective =
        serialNumbers.where((s) => s['status'] == 'defective').length;

    final productDoc =
        await _firestore.collection('products').doc(productId).get();
    final productData = productDoc.data() ?? {};

    final issuesSnapshot = await _firestore
        .collection('product_issues')
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: 'open')
        .get();
    final openIssuesCount = issuesSnapshot.docs.length;

    return <String, dynamic>{
      'productId': productId,
      'productName': productData['productName'] as String? ?? '',
      'categoryName': productData['categoryName'] as String? ?? '',
      'modelNumber': productData['modelNumber'] as String? ?? '',
      'imageUrl': productData['imageUrl'] as String? ?? '',
      'description': productData['description'] as String? ?? '',
      'purchasePrice': productData['purchasePrice'] as num? ?? 0,
      'sellingPrice': productData['sellingPrice'] as num? ?? 0,
      'available': available,
      'sold': sold,
      'defective': defective,
      'openIssuesCount': openIssuesCount,
      'total': serialNumbers.length,
      'serialNumbers': serialNumbers,
    };
  }

  Future<int> _countSerialNumbers(String productId, String status) async {
    final snapshot = await _firestore
        .collection('serial_numbers')
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: status)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
