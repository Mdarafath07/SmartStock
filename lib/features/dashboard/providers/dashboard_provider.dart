import 'package:flutter/foundation.dart';
import 'package:smartstock/features/dashboard/models/dashboard_stats_model.dart';
import 'package:smartstock/features/dashboard/repositories/dashboard_repository.dart';
import 'package:smartstock/features/dashboard/services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _repository =
      DashboardRepository(DashboardService());

  DashboardStats? _stats;
  bool _isLoading = false;
  String? _error;

  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;
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

  Future<void> refresh() async {
    await loadDashboardStats();
  }
}
