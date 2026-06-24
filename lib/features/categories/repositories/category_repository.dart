import 'package:smartstock/features/categories/models/category_model.dart';
import 'package:smartstock/features/categories/services/category_service.dart';

class CategoryRepository {
  final CategoryService _service;

  CategoryRepository(this._service);

  Future<List<Category>> getCategories() async {
    try {
      return await _service.getCategories();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<void> addCategory(Category category) async {
    try {
      await _service.addCategory(category);
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await _service.updateCategory(category);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _service.deleteCategory(id);
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  Future<Category?> getCategoryById(String id) async {
    try {
      return await _service.getCategoryById(id);
    } catch (e) {
      throw Exception('Failed to get category: $e');
    }
  }
}
