import 'package:flutter/foundation.dart';
import 'package:smartstock/features/inventory/models/inventory_model.dart';
import 'package:smartstock/features/inventory/repositories/inventory_repository.dart';

class InventoryFilter {
  String? categoryId;
  String? brandFilter;
  String? stockStatus;

  InventoryFilter({
    this.categoryId,
    this.brandFilter,
    this.stockStatus,
  });

  InventoryFilter copy() {
    return InventoryFilter(
      categoryId: categoryId,
      brandFilter: brandFilter,
      stockStatus: stockStatus,
    );
  }

  void clear() {
    categoryId = null;
    brandFilter = null;
    stockStatus = null;
  }
}

class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository;

  InventoryProvider(this._repository);

  List<InventoryItem> _items = [];
  bool _isLoading = false;
  String? _error;
  final InventoryFilter _filter = InventoryFilter();
  Map<String, dynamic>? _selectedStockDetails;

  List<InventoryItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  InventoryFilter get filter => _filter;
  Map<String, dynamic>? get selectedStockDetails => _selectedStockDetails;

  int get totalProducts => _items.length;
  int get totalAvailable =>
      _items.fold(0, (sum, item) => sum + item.availableStock);
  int get lowStockCount =>
      _items.where((item) => item.stockStatus == 'low_stock').length;
  int get outOfStockCount =>
      _items.where((item) => item.stockStatus == 'out_of_stock').length;

  Future<void> loadInventory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _repository.getInventory(
        categoryId: _filter.categoryId,
        brandFilter: _filter.brandFilter,
        stockStatus: _filter.stockStatus,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStockDetails(String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedStockDetails =
          await _repository.getStockDetails(productId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategoryFilter(String? categoryId) {
    _filter.categoryId = categoryId;
    loadInventory();
  }

  void setStockStatusFilter(String? stockStatus) {
    _filter.stockStatus = stockStatus;
    loadInventory();
  }

  void setBrandFilter(String? brand) {
    _filter.brandFilter = brand;
    loadInventory();
  }

  void clearFilters() {
    _filter.clear();
    loadInventory();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
