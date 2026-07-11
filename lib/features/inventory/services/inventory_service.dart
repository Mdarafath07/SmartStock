import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstock/features/inventory/models/inventory_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<InventoryItem>> getInventory({
    String? categoryId,
    String? brandFilter,
    Set<String>? stockStatuses,
  }) async {
    final bool filterByCategory =
        categoryId != null && categoryId.isNotEmpty;

    final productsQuery = filterByCategory
        ? _firestore
            .collection('products')
            .where('categoryId', isEqualTo: categoryId)
        : _firestore
            .collection('products')
            .orderBy('createdAt', descending: true);

    final [productsSnap, serialsSnap] = await Future.wait([
      productsQuery.get(),
      _firestore.collection('serial_numbers').get(),
    ]);

    final serialCounts = <String, Map<String, int>>{};
    for (final doc in serialsSnap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      final pid = d['productId'] as String? ?? '';
      if (pid.isEmpty) continue;
      final status = d['status'] as String? ?? 'available';
      serialCounts.putIfAbsent(pid, () => {'available': 0, 'sold': 0});
      if (status == 'available') serialCounts[pid]!['available'] =
          (serialCounts[pid]!['available'] ?? 0) + 1;
      else if (status == 'sold') serialCounts[pid]!['sold'] =
          (serialCounts[pid]!['sold'] ?? 0) + 1;
    }

    final items = <InventoryItem>[];
    for (final doc in productsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final counts = serialCounts[doc.id] ?? {'available': 0, 'sold': 0};
      final availableCount = counts['available']!;
      final soldCount = counts['sold']!;
      final status = InventoryItem.computeStockStatus(availableCount);

      if (stockStatuses != null && stockStatuses.isNotEmpty && !stockStatuses.contains(status)) {
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


}
