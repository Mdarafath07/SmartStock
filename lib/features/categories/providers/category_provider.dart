import 'package:flutter/foundation.dart' hide Category;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstock/features/categories/models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('categories')
          .orderBy('name')
          .limit(100)
          .get();
      _categories = snapshot.docs
          .map((doc) => Category.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(String name, {String icon = 'inventory_2_rounded'}) async {
    try {
      await _firestore.collection('categories').add({
        'name': name,
        'icon': icon,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateCategory(String id, String name, {String? icon}) async {
    try {
      final data = <String, dynamic>{'name': name};
      if (icon != null) data['icon'] = icon;
      final batch = _firestore.batch();
      batch.update(_firestore.collection('categories').doc(id), data);
      final products = await _firestore
          .collection('products')
          .where('categoryId', isEqualTo: id)
          .get();
      for (final doc in products.docs) {
        batch.update(doc.reference, {'categoryName': name});
      }
      await batch.commit();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

}
