import 'package:flutter/foundation.dart';
import 'package:smartstock/features/sales/models/sale_model.dart';
import 'package:smartstock/features/sales/models/serial_number_model.dart';
import 'package:smartstock/features/sales/repositories/sale_repository.dart';

class SaleProvider extends ChangeNotifier {
  final SaleRepository _repository = SaleRepository();

  List<Sale> _todaysSales = [];
  List<Sale> get todaysSales => _todaysSales;

  List<Sale> _salesHistory = [];
  List<Sale> get salesHistory => _salesHistory;

  List<SerialNumber> _availableSerialNumbers = [];
  List<SerialNumber> get availableSerialNumbers => _availableSerialNumbers;

  Sale? _selectedSale;
  Sale? get selectedSale => _selectedSale;

  Map<String, dynamic> _dailySummary = {};
  Map<String, dynamic> get dailySummary => _dailySummary;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<String> createSale({
    required String productId,
    required String productName,
    required String modelNumber,
    required String categoryId,
    required String categoryName,
    required String serialNumber,
    required String serialNumberId,
    required String customerId,
    required String customerName,
    required String customerPhone,
    required double salePrice,
    required double purchasePrice,
    required DateTime warrantyExpiryDate,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final saleId = await _repository.createSale(
        productId: productId,
        productName: productName,
        modelNumber: modelNumber,
        categoryId: categoryId,
        categoryName: categoryName,
        serialNumber: serialNumber,
        serialNumberId: serialNumberId,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        salePrice: salePrice,
        purchasePrice: purchasePrice,
        warrantyExpiryDate: warrantyExpiryDate,
      );
      await loadDailySalesSummary();
      return saleId;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<String>> bulkCreateSales({
    required List<Map<String, dynamic>> items,
    required String customerId,
    required String customerName,
    required String customerPhone,
    DateTime? saleDate,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final saleIds = await _repository.bulkCreateSales(
        items: items,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        saleDate: saleDate,
      );
      await loadDailySalesSummary();
      return saleIds;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTodaysSales() async {
    try {
      _todaysSales = await _repository.getTodaysSales();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
    loadDailySalesSummary();
  }

  Future<void> loadSalesHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? productId,
    String? categoryId,
    String? customerId,
  }) async {
    try {
      _salesHistory = await _repository.getSalesHistory(
        startDate: startDate,
        endDate: endDate,
        productId: productId,
        categoryId: categoryId,
        customerId: customerId,
      );
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> loadAvailableSerialNumbers(String productId) async {
    try {
      _availableSerialNumbers = await _repository.getAvailableSerialNumbers(productId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> loadDailySalesSummary() async {
    try {
      _dailySummary = await _repository.getDailySalesSummary();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  List<Sale> _searchedSales = [];
  List<Sale> get searchedSales => _searchedSales;
  String _currentSerialSearch = '';
  String get currentSerialSearch => _currentSerialSearch;

  Future<void> searchSaleBySerialNumber(String serial) async {
    if (serial.isEmpty) {
      _searchedSales = [];
      _currentSerialSearch = '';
      notifyListeners();
      return;
    }
    if (serial == _currentSerialSearch) return;
    _currentSerialSearch = serial;
    _setLoading(true);
    _setError(null);
    try {
      _searchedSales = await _repository.searchSaleBySerialNumber(serial);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSaleById(String id) async {
    _setLoading(true);
    _setError(null);
    try {
      _selectedSale = await _repository.getSaleById(id);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> voidSale(String saleId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _repository.voidSale(saleId);
      loadTodaysSales();
      loadDailySalesSummary();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

}
