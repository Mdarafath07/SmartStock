import 'package:smartstock/features/dashboard/models/dashboard_stats_model.dart';
import 'package:smartstock/features/dashboard/services/dashboard_service.dart';

class DashboardRepository {
  final DashboardService _service;

  DashboardRepository(this._service);

  Future<DashboardStats> getDashboardStats() async {
    try {
      return await _service.getDashboardStats();
    } catch (e) {
      throw Exception('Failed to load dashboard stats: $e');
    }
  }

  Future<List<ProductSummary>> getProductsAddedOnDate(DateTime date) async {
    try {
      return await _service.getProductsAddedOnDate(date);
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }
}
