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

  Future<void> addCategory(String name) async {
    try {
      await _firestore.collection('categories').add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateCategory(String id, String name) async {
    try {
      await _firestore.collection('categories').doc(id).update({'name': name});
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _firestore.collection('categories').doc(id).delete();
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
