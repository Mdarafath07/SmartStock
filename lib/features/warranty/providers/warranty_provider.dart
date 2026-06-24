import 'package:flutter/foundation.dart';
import 'package:smartstock/features/warranty/models/warranty_model.dart';
import 'package:smartstock/features/warranty/repositories/warranty_repository.dart';
import 'package:smartstock/features/warranty/services/warranty_service.dart';

class WarrantyProvider extends ChangeNotifier {
  final WarrantyRepository _repository =
      WarrantyRepository(WarrantyService());

  List<Warranty> _warranties = [];
  List<Warranty> _searchResults = [];
  Warranty? _selectedWarranty;
  bool _isLoading = false;
  String? _error;

  List<Warranty> get warranties => _warranties;
  List<Warranty> get searchResults => _searchResults;
  Warranty? get selectedWarranty => _selectedWarranty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _warranties = await _repository.getAllWarranties();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _repository.searchWarranty(
        serialNumber: query,
        modelNumber: query,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBySerial(String serial) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedWarranty =
          await _repository.getWarrantyBySerialNumber(serial);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBySaleId(String saleId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedWarranty = await _repository.getWarrantyBySaleId(saleId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadExpired() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _warranties = await _repository.getExpiredWarranties();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadActive() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _warranties = await _repository.getActiveWarranties();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
