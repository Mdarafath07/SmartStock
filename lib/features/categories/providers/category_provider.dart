import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstock/features/categories/models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _subscription;

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void loadCategories() {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _firestore
        .collection('categories')
        .orderBy('name')
        .snapshots()
        .listen(
      (snapshot) {
        _categories = snapshot.docs
            .map((doc) => Category.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
