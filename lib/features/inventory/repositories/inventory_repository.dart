import 'package:smartstock/features/inventory/models/inventory_model.dart';
import 'package:smartstock/features/inventory/services/inventory_service.dart';

class InventoryRepository {
  final InventoryService _service;

  InventoryRepository(this._service);

  Future<List<InventoryItem>> getInventory({
    String? categoryId,
    String? brandFilter,
    String? stockStatus,
  }) async {
    try {
      return await _service.getInventory(
        categoryId: categoryId,
        brandFilter: brandFilter,
        stockStatus: stockStatus,
      );
    } catch (e) {
      throw Exception('Failed to load inventory: $e');
    }
  }

  Future<Map<String, dynamic>> getStockDetails(String productId) async {
    try {
      return await _service.getStockDetails(productId);
    } catch (e) {
      throw Exception('Failed to load stock details: $e');
    }
  }
}
