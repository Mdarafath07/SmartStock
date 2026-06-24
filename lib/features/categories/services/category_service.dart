import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstock/features/categories/models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Category>> getCategories() async {
    final snapshot = await _firestore
        .collection('categories')
        .orderBy('name')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Category.fromJson({...data, 'id': doc.id});
    }).toList();
  }

  Future<String> addCategory(Category category) async {
    final docRef = await _firestore.collection('categories').add({
      'name': category.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateCategory(Category category) async {
    await _firestore
        .collection('categories')
        .doc(category.id)
        .update({'name': category.name});
  }

  Future<void> deleteCategory(String id) async {
    await _firestore.collection('categories').doc(id).delete();
  }

  Future<Category?> getCategoryById(String id) async {
    final doc = await _firestore.collection('categories').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return Category.fromJson({...data, 'id': doc.id});
  }
}
