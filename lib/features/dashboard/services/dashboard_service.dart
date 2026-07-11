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

    final productsSnap = _firestore.collection('products').get();
    final serialsSnap = _firestore
        .collection('serial_numbers')
        .where('status', isEqualTo: 'available')
        .get();

    final results = await Future.wait([
      _firestore.collection('categories').count().get(),
      _firestore.collection('products').count().get(),
      _countAllAvailableSerials(),
      _getTodaySales(todayStart, todayEnd),
      _getTopSellingProducts(),
      _getRecentlyAddedProducts(),
      _getRecentlySoldProducts(),
      _getDailySales(30),
      _countActiveWarranties(),
      _countOpenProductIssues(),
      productsSnap,
      serialsSnap,
    ]);

    final totalCategories = (results[0] as AggregateQuerySnapshot).count ?? 0;
    final totalProducts = (results[1] as AggregateQuerySnapshot).count ?? 0;
    final totalAvailableStock = results[2] as int;

    final todaySalesData = results[3] as Map<String, dynamic>;
    final todaySalesAmount =
        (todaySalesData['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final todayProfit =
        (todaySalesData['totalProfit'] as num?)?.toDouble() ?? 0.0;
    final todaySoldProducts =
        (todaySalesData['totalQuantity'] as num?)?.toInt() ?? 0;
    final topSelling = results[4] as List<TopSellingProduct>;
    final recentlyAdded = results[5] as List<ProductSummary>;
    final recentlySold = results[6] as List<ProductSummary>;
    final dailyData = results[7] as Map<String, List<double>>;
    final activeWarranties = results[8] as int;
    final openIssueCount = results[9] as int;
    final productsData = results[10] as QuerySnapshot;
    final serialsData = results[11] as QuerySnapshot;

    final serialCount = <String, int>{};
    for (final doc in serialsData.docs) {
      final d = doc.data() as Map<String, dynamic>?;
      if (d == null) continue;
      final pid = d['productId'] as String? ?? '';
      if (pid.isNotEmpty) serialCount[pid] = (serialCount[pid] ?? 0) + 1;
    }

    double totalStockValue = 0;
    double totalStockCost = 0;
    int lowStockProducts = 0;
    int outOfStockProducts = 0;

    for (final doc in productsData.docs) {
      final d = doc.data() as Map<String, dynamic>?;
      if (d == null) continue;
      final qty = serialCount[doc.id] ?? 0;
      final sellingPrice = (d['sellingPrice'] as num?)?.toDouble() ?? 0.0;
      final purchasePrice = (d['purchasePrice'] as num?)?.toDouble() ?? 0.0;

      totalStockValue += sellingPrice * qty;
      totalStockCost += purchasePrice * qty;

      if (qty == 0) {
        outOfStockProducts++;
      } else if (qty <= AppConstants.lowStockThreshold) {
        lowStockProducts++;
      }
    }

    return DashboardStats(
      totalCategories: totalCategories,
      totalProducts: totalProducts,
      totalAvailableStock: totalAvailableStock,
      totalStockValue: totalStockValue,
      totalStockCost: totalStockCost,
      todaySalesAmount: todaySalesAmount,
      todayProfit: todayProfit,
      todaySoldProducts: todaySoldProducts,
      lowStockProducts: lowStockProducts,
      outOfStockProducts: outOfStockProducts,
      topSellingProducts: topSelling,
      mostStockedProducts: recentlyAdded,
      recentlyAddedProducts: recentlyAdded,
      recentlySoldProducts: recentlySold,
      activeWarranties: activeWarranties,
      openIssueCount: openIssueCount,
      dailySales: dailyData['sales'] ?? [],
      dailyProfit: dailyData['profit'] ?? [],
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

  Future<int> _countOpenProductIssues() async {
    final snapshot = await _firestore
        .collection('product_issues')
        .where('status', isEqualTo: 'open')
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
    double totalProfit = 0;
    int totalQuantity = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['saleType'] == 'warranty_claim') continue;
      totalAmount += (data['salePrice'] as num?)?.toDouble() ?? 0.0;
      totalProfit += (data['profit'] as num?)?.toDouble() ?? 0.0;
      totalQuantity++;
    }
    return {
      'totalAmount': totalAmount,
      'totalProfit': totalProfit,
      'totalQuantity': totalQuantity,
    };
  }

  Future<Map<String, List<double>>> _getDailySales(int days) async {
    final now = DateTime.now();
    final sales = <double>[];
    final profits = <double>[];

    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final dayStart = day;
      final dayEnd = dayStart.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('sales')
          .where('saleDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('saleDate', isLessThan: Timestamp.fromDate(dayEnd))
          .get();

      double daySales = 0;
      double dayProfit = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['saleType'] == 'warranty_claim') continue;
        daySales += (data['salePrice'] as num?)?.toDouble() ?? 0.0;
        dayProfit += (data['profit'] as num?)?.toDouble() ?? 0.0;
      }
      sales.add(daySales);
      profits.add(dayProfit);
    }
    return {'sales': sales, 'profit': profits};
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
      if (data['saleType'] == 'warranty_claim') continue;
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
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('products')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('createdAt', isLessThan: Timestamp.fromDate(todayEnd))
        .orderBy('createdAt', descending: true)
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
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  Future<int> _countActiveWarranties() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('sales')
        .where('warrantyExpiryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('warrantyExpiryDate', descending: false)
        .get();

    int count = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['saleType'] == 'warranty_claim') continue;
      if (data['warrantyClaimed'] == true) continue;
      if (((data['warrantyMonths'] as num?)?.toInt() ?? 0) <= 0) continue;
      count++;
    }
    return count;
  }

  Future<List<ProductSummary>> getProductsAddedOnDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('products')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('createdAt', descending: true)
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
        soldCount: (data['soldQuantity'] as num?)?.toInt() ?? 0,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
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
      if (data['saleType'] == 'warranty_claim') continue;
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
