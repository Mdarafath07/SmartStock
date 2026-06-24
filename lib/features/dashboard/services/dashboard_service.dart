import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstock/core/constants/app_constants.dart';
import 'package:smartstock/features/dashboard/models/dashboard_stats_model.dart';

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, Map<String, dynamic>>> _fetchProductsByIds(
      Set<String> ids) async {
    if (ids.isEmpty) return {};
    final snapshots = await Future.wait(
      ids.map((id) => _firestore.collection('products').doc(id).get()),
    );
    return {
      for (final doc in snapshots)
        if (doc.exists)
          doc.id: doc.data() as Map<String, dynamic>
    };
  }

  Future<DashboardStats> getDashboardStats() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final results = await Future.wait([
      _firestore.collection('categories').count().get(),
      _firestore.collection('products').count().get(),
      _countAllAvailableSerials(),
      _getTodaySales(todayStart, todayEnd),
      _computeLowStockProducts(),
      _computeOutOfStockProducts(),
      _getTopSellingProducts(),
      _getRecentlyAddedProducts(),
      _getRecentlySoldProducts(),
    ]);

    final totalCategories = (results[0] as AggregateQuerySnapshot).count ?? 0;
    final totalProducts = (results[1] as AggregateQuerySnapshot).count ?? 0;
    final totalAvailableStock = results[2] as int;

    final todaySalesData = results[3] as Map<String, dynamic>;
    final todaySalesAmount =
        (todaySalesData['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final todaySoldProducts =
        (todaySalesData['totalQuantity'] as num?)?.toInt() ?? 0;
    final lowStockProducts = results[4] as int;
    final outOfStockProducts = results[5] as int;
    final topSelling = results[6] as List<TopSellingProduct>;
    final recentlyAdded = results[7] as List<ProductSummary>;
    final recentlySold = results[8] as List<ProductSummary>;

    return DashboardStats(
      totalCategories: totalCategories,
      totalProducts: totalProducts,
      totalAvailableStock: totalAvailableStock,
      todaySalesAmount: todaySalesAmount,
      todaySoldProducts: todaySoldProducts,
      lowStockProducts: lowStockProducts,
      outOfStockProducts: outOfStockProducts,
      topSellingProducts: topSelling,
      mostStockedProducts: recentlyAdded,
      recentlyAddedProducts: recentlyAdded,
      recentlySoldProducts: recentlySold,
    );
  }

  Future<int> _countAllAvailableSerials() async {
    final snapshot = await _firestore
        .collection('serial_numbers')
        .where('status', isEqualTo: 'available')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<Map<String, dynamic>> _getTodaySales(
      DateTime todayStart, DateTime todayEnd) async {
    final snapshot = await _firestore
        .collection('sales')
        .where('saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('saleDate', isLessThan: Timestamp.fromDate(todayEnd))
        .get();

    double totalAmount = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      totalAmount += (data['salePrice'] as num?)?.toDouble() ?? 0.0;
    }
    return {
      'totalAmount': totalAmount,
      'totalQuantity': snapshot.docs.length,
    };
  }

  Future<int> _computeLowStockProducts() async {
    final snapshot = await _firestore
        .collection('products')
        .where('availableQuantity', isGreaterThan: 0)
        .where('availableQuantity',
            isLessThanOrEqualTo: AppConstants.lowStockThreshold)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _computeOutOfStockProducts() async {
    final snapshot = await _firestore
        .collection('products')
        .where('availableQuantity', isEqualTo: 0)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<List<TopSellingProduct>> _getTopSellingProducts() async {
    final snapshot = await _firestore
        .collection('sales')
        .orderBy('saleDate', descending: true)
        .limit(100)
        .get();

    final Map<String, TopSellingProduct> aggregated = {};
    final missingImages = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final productId = data['productId'] as String? ?? '';
      if (productId.isEmpty) continue;
      final existing = aggregated[productId];
      final imageUrl = data['imageUrl'] as String? ?? '';
      if (existing != null) {
        aggregated[productId] = TopSellingProduct(
          productId: productId,
          productName: data['productName'] as String? ?? existing.productName,
          modelNumber: data['modelNumber'] as String? ?? existing.modelNumber,
          imageUrl: imageUrl.isNotEmpty ? imageUrl : existing.imageUrl,
          totalSold: existing.totalSold + 1,
        );
      } else {
        aggregated[productId] = TopSellingProduct(
          productId: productId,
          productName: data['productName'] as String? ?? '',
          modelNumber: data['modelNumber'] as String? ?? '',
          imageUrl: imageUrl,
          totalSold: 1,
        );
        if (imageUrl.isEmpty) missingImages.add(productId);
      }
    }

    if (missingImages.isNotEmpty) {
      final productData = await _fetchProductsByIds(missingImages);
      for (final id in missingImages) {
        final data = productData[id];
        if (data != null) {
          final existing = aggregated[id]!;
          aggregated[id] = TopSellingProduct(
            productId: existing.productId,
            productName: existing.productName.isNotEmpty
                ? existing.productName
                : data['productName'] as String? ?? '',
            modelNumber: existing.modelNumber.isNotEmpty
                ? existing.modelNumber
                : data['modelNumber'] as String? ?? '',
            imageUrl: data['imageUrl'] as String? ?? '',
            totalSold: existing.totalSold,
          );
        }
      }
    }

    final sorted = aggregated.values.toList()
      ..sort((a, b) => b.totalSold.compareTo(a.totalSold));
    return sorted.take(AppConstants.topSellingMaxItems).toList();
  }

  Future<List<ProductSummary>> _getRecentlyAddedProducts() async {
    final snapshot = await _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.recentlyAddedMaxItems)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ProductSummary(
        productId: doc.id,
        productName: data['productName'] as String? ?? '',
        modelNumber: data['modelNumber'] as String? ?? '',
        imageUrl: data['imageUrl'] as String? ?? '',
        categoryName: data['categoryName'] as String? ?? '',
        availableQuantity: (data['availableQuantity'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<List<ProductSummary>> _getRecentlySoldProducts() async {
    final snapshot = await _firestore
        .collection('sales')
        .orderBy('saleDate', descending: true)
        .limit(50)
        .get();

    final salesByProduct = <String, List<Map<String, dynamic>>>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final productId = data['productId'] as String? ?? '';
      if (productId.isEmpty) continue;
      salesByProduct.putIfAbsent(productId, () => []).add(data);
    }

    final sorted = salesByProduct.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final summaries = <ProductSummary>[];
    final productIds = <String>{};
    for (final entry in sorted) {
      if (summaries.length >= 5) break;
      final productId = entry.key;
      final sales = entry.value;
      final latestSale = sales.first;
      productIds.add(productId);
      summaries.add(ProductSummary(
        productId: productId,
        productName: latestSale['productName'] as String? ?? '',
        modelNumber: latestSale['modelNumber'] as String? ?? '',
        imageUrl: latestSale['imageUrl'] as String? ?? '',
        categoryName: latestSale['categoryName'] as String? ?? '',
        availableQuantity: 0,
        soldCount: sales.length,
      ));
    }

    if (productIds.isNotEmpty) {
      final productData = await _fetchProductsByIds(productIds);
      for (int i = 0; i < summaries.length; i++) {
        final data = productData[summaries[i].productId];
        if (data != null) {
          summaries[i] = ProductSummary(
            productId: summaries[i].productId,
            productName: summaries[i].productName.isNotEmpty
                ? summaries[i].productName
                : data['productName'] as String? ?? '',
            modelNumber: summaries[i].modelNumber.isNotEmpty
                ? summaries[i].modelNumber
                : data['modelNumber'] as String? ?? '',
            imageUrl: summaries[i].imageUrl.isNotEmpty
                ? summaries[i].imageUrl
                : data['imageUrl'] as String? ?? '',
            categoryName: summaries[i].categoryName.isNotEmpty
                ? summaries[i].categoryName
                : data['categoryName'] as String? ?? '',
            availableQuantity:
                (data['availableQuantity'] as num?)?.toInt() ?? 0,
            soldCount: summaries[i].soldCount,
          );
        }
      }
    }

    return summaries;
  }
}
