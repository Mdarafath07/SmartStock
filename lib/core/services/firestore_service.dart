import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService() : _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getDocuments(String collection) async {
    final snapshot = await _firestore.collection(collection).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return <String, dynamic>{'id': doc.id, ...data};
    }).toList();
  }

  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String docId,
  ) async {
    final doc = await _firestore.collection(collection).doc(docId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return <String, dynamic>{'id': doc.id, ...data};
  }

  Future<String> addDocument(String collection, Map<String, dynamic> data) async {
    final docRef = await _firestore.collection(collection).add(data);
    return docRef.id;
  }

  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(collection).doc(docId).update(data);
  }

  Future<void> deleteDocument(String collection, String docId) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

  Future<List<Map<String, dynamic>>> queryWhere(
    String collection, {
    required String field,
    required dynamic value,
    bool isEqualTo = true,
  }) async {
    Query query = _firestore.collection(collection);
    query = isEqualTo
        ? query.where(field, isEqualTo: value)
        : query.where(field, isNotEqualTo: value);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return <String, dynamic>{'id': doc.id, ...data};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> queryOrderBy(
    String collection, {
    required String field,
    bool descending = false,
    int? limit,
  }) async {
    Query query = _firestore
        .collection(collection)
        .orderBy(field, descending: descending);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return <String, dynamic>{'id': doc.id, ...data};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> queryPaginated(
    String collection, {
    required String orderByField,
    bool descending = false,
    int limit = 20,
    dynamic startAfter,
  }) async {
    Query query = _firestore
        .collection(collection)
        .orderBy(orderByField, descending: descending)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfter([startAfter]);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return <String, dynamic>{'id': doc.id, ...data};
    }).toList();
  }

  Stream<Map<String, dynamic>?> streamDocument(
    String collection,
    String docId,
  ) {
    return _firestore.collection(collection).doc(docId).snapshots().map(
      (snapshot) {
        if (!snapshot.exists) return null;
        final data = snapshot.data() as Map<String, dynamic>;
        return <String, dynamic>{'id': snapshot.id, ...data};
      },
    );
  }

  Stream<List<Map<String, dynamic>>> streamCollection(String collection) {
    return _firestore.collection(collection).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        return <String, dynamic>{'id': doc.id, ...data};
      }).toList(),
    );
  }
}
