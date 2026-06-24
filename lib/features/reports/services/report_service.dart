import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstock/features/reports/models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore;

  ReportService() : _firestore = FirebaseFirestore.instance;

  Future<SalesReport> getDailySalesReport(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('sales')
        .where('saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('saleDate', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    return _aggregateSales(snapshot, startOfDay);
  }

  Future<SalesReport> getMonthlySalesReport(int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final snapshot = await _firestore
        .collection('sales')
        .where('saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('saleDate', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    return _aggregateSales(snapshot, startOfMonth);
  }

  Future<List<CategorySales>> getCategorySalesReport() async {
    final snapshot = await _firestore.collection('sales').get();

    final Map<String, _CategoryAggregate> categoryMap = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final catId = data['categoryId'] as String? ?? 'unknown';
      final catName = data['categoryName'] as String? ?? 'Unknown';
      final salePrice = (data['salePrice'] as num?)?.toDouble() ?? 0.0;

      categoryMap.putIfAbsent(catId, () => _CategoryAggregate(name: catName));
      categoryMap[catId]!.totalSales += salePrice;
      categoryMap[catId]!.totalProducts += 1;
    }

    return categoryMap.entries.map((e) {
      return CategorySales(
        categoryName: e.value.name,
        categoryId: e.key,
        totalSales: e.value.totalSales,
        totalProducts: e.value.totalProducts,
      );
    }).toList()
      ..sort((a, b) => b.totalSales.compareTo(a.totalSales));
  }

  Future<List<TopSellingProductReport>> getTopSellingProducts(int limit) async {
    final snapshot = await _firestore.collection('sales').get();

    final Map<String, _ProductAggregate> productMap = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final productId = data['productId'] as String? ?? '';
      if (productId.isEmpty) continue;

      productMap.putIfAbsent(
        productId,
        () => _ProductAggregate(
          name: data['productName'] as String? ?? '',
          modelNumber: data['modelNumber'] as String? ?? '',
          imageUrl: data['imageUrl'] as String? ?? '',
        ),
      );
      productMap[productId]!.quantitySold += 1;
      productMap[productId]!.totalRevenue +=
          (data['salePrice'] as num?)?.toDouble() ?? 0.0;
    }

    return productMap.entries
        .map((e) => TopSellingProductReport(
              productId: e.key,
              productName: e.value.name,
              modelNumber: e.value.modelNumber,
              imageUrl: e.value.imageUrl,
              quantitySold: e.value.quantitySold,
              totalRevenue: e.value.totalRevenue,
            ))
        .toList()
      ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold))
      ..take(limit);
  }

  Future<List<SalesReport>> getProfitReport({
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await _firestore
        .collection('sales')
        .where('saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('saleDate', isLessThan: Timestamp.fromDate(end))
        .orderBy('saleDate', descending: true)
        .get();

    final Map<String, _DailyAggregate> dailyMap = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final saleDate = (data['saleDate'] as Timestamp).toDate();
      final dayKey =
          '${saleDate.year}-${saleDate.month.toString().padLeft(2, '0')}-${saleDate.day.toString().padLeft(2, '0')}';

      dailyMap.putIfAbsent(dayKey, () => _DailyAggregate(date: saleDate));
      dailyMap[dayKey]!.totalSales +=
          (data['salePrice'] as num?)?.toDouble() ?? 0.0;
      dailyMap[dayKey]!.totalProfit +=
          (data['profit'] as num?)?.toDouble() ?? 0.0;
      dailyMap[dayKey]!.totalTransactions += 1;
    }

    return dailyMap.entries.map((e) {
      return SalesReport(
        date: e.value.date,
        totalSales: e.value.totalSales,
        totalProfit: e.value.totalProfit,
        totalTransactions: e.value.totalTransactions,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  SalesReport _aggregateSales(QuerySnapshot snapshot, DateTime date) {
    double totalSales = 0;
    double totalProfit = 0;
    int totalProducts = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalSales += (data['salePrice'] as num?)?.toDouble() ?? 0.0;
      totalProfit += (data['profit'] as num?)?.toDouble() ?? 0.0;
      totalProducts += 1;
    }

    return SalesReport(
      date: date,
      totalSales: totalSales,
      totalProfit: totalProfit,
      totalTransactions: snapshot.docs.length,
      totalProductsSold: totalProducts,
    );
  }
}

class _CategoryAggregate {
  final String name;
  double totalSales = 0.0;
  int totalProducts = 0;

  _CategoryAggregate({required this.name});
}

class _ProductAggregate {
  final String name;
  final String modelNumber;
  final String imageUrl;
  int quantitySold = 0;
  double totalRevenue = 0.0;

  _ProductAggregate({
    required this.name,
    this.modelNumber = '',
    this.imageUrl = '',
  });
}

class _DailyAggregate {
  final DateTime date;
  double totalSales = 0.0;
  double totalProfit = 0.0;
  int totalTransactions = 0;

  _DailyAggregate({required this.date});
}
