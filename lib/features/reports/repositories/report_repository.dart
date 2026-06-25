import 'package:smartstock/features/reports/models/report_model.dart';
import 'package:smartstock/features/reports/services/report_service.dart';

class ReportRepository {
  final ReportService _service;

  ReportRepository(this._service);

  Future<SalesReport> getDailySalesReport(DateTime date) {
    return _service.getDailySalesReport(date);
  }

  Future<SalesReport> getMonthlySalesReport(int year, int month) {
    return _service.getMonthlySalesReport(year, month);
  }

  Future<List<CategorySales>> getCategorySalesReport() {
    return _service.getCategorySalesReport();
  }

  Future<List<TopSellingProductReport>> getTopSellingProducts(int limit) {
    return _service.getTopSellingProducts(limit);
  }

  Future<List<SalesReport>> getProfitReport({
    required DateTime start,
    required DateTime end,
  }) {
    return _service.getProfitReport(start: start, end: end);
  }

  Future<List<SalesReport>> getYearlySalesReport(int year) {
    return _service.getYearlySalesReport(year);
  }

  Future<SalesReport> getAllTimeSummary() {
    return _service.getAllTimeSummary();
  }
}
