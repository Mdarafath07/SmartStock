import 'package:flutter/foundation.dart';
import 'package:smartstock/features/dashboard/models/dashboard_stats_model.dart';
import 'package:smartstock/features/dashboard/repositories/dashboard_repository.dart';
import 'package:smartstock/features/dashboard/services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _repository =
      DashboardRepository(DashboardService());

  DashboardStats? _stats;
  List<ProductSummary> _dailyAddedProducts = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isDailyLoading = false;
  String? _error;

  DashboardStats? get stats => _stats;
  List<ProductSummary> get dailyAddedProducts => _dailyAddedProducts;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  bool get isDailyLoading => _isDailyLoading;
  String? get error => _error;

  Future<void> loadDashboardStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _repository.getDashboardStats();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDailyAddedProducts({DateTime? date}) async {
    final targetDate = date ?? _selectedDate;
    _selectedDate = targetDate;
    _isDailyLoading = true;
    notifyListeners();

    try {
      _dailyAddedProducts =
          await _repository.getProductsAddedOnDate(targetDate);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isDailyLoading = false;
      notifyListeners();
    }
  }

  Future<void> setDate(DateTime date) async {
    _selectedDate = date;
    await loadDailyAddedProducts(date: date);
  }

  Future<void> refresh() async {
    await Future.wait([
      loadDashboardStats(),
      loadDailyAddedProducts(),
    ]);
  }
}
