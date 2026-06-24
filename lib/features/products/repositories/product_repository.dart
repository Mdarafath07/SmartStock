import 'package:smartstock/features/products/models/product_model.dart';
import 'package:smartstock/features/products/services/product_service.dart';

class ProductRepository {
  final ProductService _service;

  ProductRepository(this._service);

  Future<List<Product>> getProducts({
    String? categoryId,
    String? searchQuery,
  }) async {
    try {
      return await _service.getProducts(
        categoryId: categoryId,
        searchQuery: searchQuery,
      );
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  Future<Product?> getProductById(String id) async {
    try {
      return await _service.getProductById(id);
    } catch (e) {
      throw Exception('Failed to load product: $e');
    }
  }

  Future<void> addProduct(Product product, List<String> serialNumbers) async {
    try {
      await _service.addProduct(product, serialNumbers);
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _service.updateProduct(product);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _service.deleteProduct(id);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSerialNumbers(String productId) async {
    try {
      return await _service.getSerialNumbers(productId);
    } catch (e) {
      throw Exception('Failed to load serial numbers: $e');
    }
  }

  Future<Map<String, dynamic>> getStockDetails(String productId) async {
    try {
      return await _service.getStockDetails(productId);
    } catch (e) {
      throw Exception('Failed to load stock details: $e');
    }
  }

  Future<void> addSerialNumbers(
      String productId, List<String> serialNumbers) async {
    try {
      await _service.addSerialNumbers(productId, serialNumbers);
    } catch (e) {
      throw Exception('Failed to add serial numbers: $e');
    }
  }
}
