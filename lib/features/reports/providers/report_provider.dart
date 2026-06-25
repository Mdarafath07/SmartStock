import 'package:flutter/foundation.dart';
import 'package:smartstock/features/reports/models/report_model.dart';
import 'package:smartstock/features/reports/repositories/report_repository.dart';
import 'package:smartstock/features/reports/services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportRepository _repository = ReportRepository(ReportService());

  SalesReport? _dailyReport;
  SalesReport? _monthlyReport;
  SalesReport? _allTimeSummary;
  List<CategorySales> _categorySales = [];
  List<TopSellingProductReport> _topSellingProducts = [];
  List<SalesReport> _profitReports = [];
  List<SalesReport> _yearlyReports = [];
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;
  String? _error;

  SalesReport? get dailyReport => _dailyReport;
  SalesReport? get monthlyReport => _monthlyReport;
  SalesReport? get allTimeSummary => _allTimeSummary;
  List<CategorySales> get categorySales => _categorySales;
  List<TopSellingProductReport> get topSellingProducts => _topSellingProducts;
  List<SalesReport> get profitReports => _profitReports;
  List<SalesReport> get yearlyReports => _yearlyReports;
  int get selectedYear => _selectedYear;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setSelectedYear(int year) {
    _selectedYear = year;
    notifyListeners();
  }

  Future<void> loadDailyReport() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dailyReport = await _repository.getDailySalesReport(DateTime.now());
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMonthlyReport() async {
    final now = DateTime.now();
    await loadMonthlyReportFor(now.year, now.month);
  }

  Future<void> loadMonthlyReportFor(int year, int month) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _monthlyReport = await _repository.getMonthlySalesReport(year, month);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategorySales() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categorySales = await _repository.getCategorySalesReport();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTopSellingProducts({int limit = 10}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _topSellingProducts =
          await _repository.getTopSellingProducts(limit);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProfitReport({
    required DateTime start,
    required DateTime end,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profitReports =
          await _repository.getProfitReport(start: start, end: end);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadYearlyReport({int? year}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final y = year ?? _selectedYear;
      _yearlyReports = await _repository.getYearlySalesReport(y);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllTimeSummary() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allTimeSummary = await _repository.getAllTimeSummary();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final results = await Future.wait([
        _repository.getDailySalesReport(now),
        _repository.getMonthlySalesReport(now.year, now.month),
        _repository.getCategorySalesReport(),
        _repository.getTopSellingProducts(10),
        _repository.getAllTimeSummary(),
        _repository.getYearlySalesReport(now.year),
      ]);

      _dailyReport = results[0] as SalesReport;
      _monthlyReport = results[1] as SalesReport;
      _categorySales = results[2] as List<CategorySales>;
      _topSellingProducts = results[3] as List<TopSellingProductReport>;
      _allTimeSummary = results[4] as SalesReport;
      _yearlyReports = results[5] as List<SalesReport>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
