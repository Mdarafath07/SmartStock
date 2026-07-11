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

    final categoriesSnapshot = await _firestore.collection('categories').get();
    final Map<String, String> categoryNameMap = {};
    for (final cat in categoriesSnapshot.docs) {
      final name = cat.data()['name'] as String? ?? 'Unknown';
      categoryNameMap[cat.id] = name;
    }

    final Map<String, _CategoryAggregate> categoryMap = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['saleType'] == 'warranty_claim') continue;
      final catId = data['categoryId'] as String? ?? 'unknown';
      String catName = data['categoryName'] as String? ?? '';
      if (catName.isEmpty) {
        catName = categoryNameMap[catId] ?? 'Unknown';
      }

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
      if (data['saleType'] == 'warranty_claim') continue;
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
    final Map<String, Set<String>> dayBills = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['saleType'] == 'warranty_claim') continue;
      final saleDate = (data['saleDate'] as Timestamp).toDate();
      final dayKey =
          '${saleDate.year}-${saleDate.month.toString().padLeft(2, '0')}-${saleDate.day.toString().padLeft(2, '0')}';

      dailyMap.putIfAbsent(dayKey, () => _DailyAggregate(date: saleDate));
      dayBills.putIfAbsent(dayKey, () => {});
      dailyMap[dayKey]!.totalSales +=
          (data['salePrice'] as num?)?.toDouble() ?? 0.0;
      dailyMap[dayKey]!.totalProfit +=
          (data['profit'] as num?)?.toDouble() ?? 0.0;
      final billKey = (data['batchId'] as String?) ?? doc.id;
      if (dayBills[dayKey]!.add(billKey)) {
        dailyMap[dayKey]!.totalTransactions++;
      }
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

  Future<List<SalesReport>> getYearlySalesReport(int year) async {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year + 1, 1, 1);

    final snapshot = await _firestore
        .collection('sales')
        .where('saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
        .where('saleDate', isLessThan: Timestamp.fromDate(endOfYear))
        .get();

    final Map<String, _DailyAggregate> monthlyMap = {};
    final Map<String, Set<String>> monthBills = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['saleType'] == 'warranty_claim') continue;
      final saleDate = (data['saleDate'] as Timestamp).toDate();
      final monthKey = '${saleDate.year}-${saleDate.month.toString().padLeft(2, '0')}';

      monthlyMap.putIfAbsent(monthKey, () => _DailyAggregate(date: DateTime(saleDate.year, saleDate.month, 1)));
      monthBills.putIfAbsent(monthKey, () => {});
      monthlyMap[monthKey]!.totalSales +=
          (data['salePrice'] as num?)?.toDouble() ?? 0.0;
      monthlyMap[monthKey]!.totalProfit +=
          (data['profit'] as num?)?.toDouble() ?? 0.0;
      final billKey = (data['batchId'] as String?) ?? doc.id;
      if (monthBills[monthKey]!.add(billKey)) {
        monthlyMap[monthKey]!.totalTransactions++;
      }
    }

    return monthlyMap.entries.map((e) {
      return SalesReport(
        date: e.value.date,
        totalSales: e.value.totalSales,
        totalProfit: e.value.totalProfit,
        totalTransactions: e.value.totalTransactions,
        totalProductsSold: e.value.totalTransactions,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<SalesReport> getAllTimeSummary() async {
    final snapshot = await _firestore.collection('sales').get();

    double totalSales = 0;
    double totalProfit = 0;
    int totalTransactions = 0;
    final seenBills = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['saleType'] == 'warranty_claim') continue;
      totalSales += (data['salePrice'] as num?)?.toDouble() ?? 0.0;
      totalProfit += (data['profit'] as num?)?.toDouble() ?? 0.0;
      final billKey = (data['batchId'] as String?) ?? doc.id;
      if (seenBills.add(billKey)) {
        totalTransactions++;
      }
    }

    return SalesReport(
      date: DateTime.now(),
      totalSales: totalSales,
      totalProfit: totalProfit,
      totalTransactions: totalTransactions,
      totalProductsSold: totalTransactions,
    );
  }

  SalesReport _aggregateSales(QuerySnapshot snapshot, DateTime date) {
    double totalSales = 0;
    double totalProfit = 0;
    int totalProducts = 0;
    int totalTransactions = 0;
    final seenBills = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['saleType'] == 'warranty_claim') continue;
      totalSales += (data['salePrice'] as num?)?.toDouble() ?? 0.0;
      totalProfit += (data['profit'] as num?)?.toDouble() ?? 0.0;
      totalProducts += 1;
      final billKey = (data['batchId'] as String?) ?? doc.id;
      if (seenBills.add(billKey)) {
        totalTransactions++;
      }
    }

    return SalesReport(
      date: date,
      totalSales: totalSales,
      totalProfit: totalProfit,
      totalTransactions: totalTransactions,
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
