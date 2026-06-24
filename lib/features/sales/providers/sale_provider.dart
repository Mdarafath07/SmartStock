import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smartstock/features/sales/models/sale_model.dart';
import 'package:smartstock/features/sales/models/serial_number_model.dart';
import 'package:smartstock/features/sales/repositories/sale_repository.dart';

class SaleProvider extends ChangeNotifier {
  final SaleRepository _repository = SaleRepository();
  StreamSubscription<List<Sale>>? _todaysSalesSubscription;
  StreamSubscription<List<Sale>>? _salesHistorySubscription;
  StreamSubscription<List<SerialNumber>>? _serialNumbersSubscription;

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
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final saleIds = await _repository.bulkCreateSales(
        items: items,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
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

  void loadTodaysSales() {
    _todaysSalesSubscription?.cancel();
    _todaysSalesSubscription = _repository.getTodaysSales().listen(
      (sales) {
        _todaysSales = sales;
        notifyListeners();
      },
      onError: (e) => _setError(e.toString()),
    );
    loadDailySalesSummary();
  }

  void loadSalesHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? productId,
    String? categoryId,
    String? customerId,
  }) {
    _salesHistorySubscription?.cancel();
    _salesHistorySubscription = _repository
        .getSalesHistory(
          startDate: startDate,
          endDate: endDate,
          productId: productId,
          categoryId: categoryId,
          customerId: customerId,
        )
        .listen(
          (sales) {
            _salesHistory = sales;
            notifyListeners();
          },
          onError: (e) => _setError(e.toString()),
        );
  }

  void loadAvailableSerialNumbers(String productId) {
    _serialNumbersSubscription?.cancel();
    _serialNumbersSubscription =
        _repository.getAvailableSerialNumbers(productId).listen(
      (serialNumbers) {
        _availableSerialNumbers = serialNumbers;
        notifyListeners();
      },
      onError: (e) => _setError(e.toString()),
    );
  }

  Future<void> loadDailySalesSummary() async {
    try {
      _dailySummary = await _repository.getDailySalesSummary();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
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

  @override
  void dispose() {
    _todaysSalesSubscription?.cancel();
    _salesHistorySubscription?.cancel();
    _serialNumbersSubscription?.cancel();
    super.dispose();
  }
}
