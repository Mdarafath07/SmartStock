import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstock/features/product_issues/models/product_issue_model.dart';

class ProductIssueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _collection => 'product_issues';

  Future<String> createIssue(ProductIssue issue) async {
    final batch = _firestore.batch();
    final issueRef = _firestore.collection(_collection).doc();
    final issueData = issue.toJson();
    issueData['createdAt'] = Timestamp.fromDate(issue.createdAt);
    if (issue.resolvedAt != null) {
      issueData['resolvedAt'] = Timestamp.fromDate(issue.resolvedAt!);
    }
    batch.set(issueRef, issueData);

    final serialSnapshot = await _firestore
        .collection('serial_numbers')
        .where('serialNumber', isEqualTo: issue.serialNumber)
        .where('status', isEqualTo: 'available')
        .limit(1)
        .get();

    if (serialSnapshot.docs.isNotEmpty) {
      final serialDoc = serialSnapshot.docs.first;
      final serialData = serialDoc.data();
      final productId = serialData['productId'] as String? ?? '';
      batch.update(serialDoc.reference, {
        'status': 'defective',
      });
      if (productId.isNotEmpty) {
        batch.update(
          _firestore.collection('products').doc(productId),
          {'availableQuantity': FieldValue.increment(-1)},
        );
      }
    }

    await batch.commit();
    return issueRef.id;
  }

  Future<void> updateIssue(String id, Map<String, dynamic> updates) async {
    final updateData = Map<String, dynamic>.from(updates);
    if (updates.containsKey('resolvedAt') && updates['resolvedAt'] is DateTime) {
      updateData['resolvedAt'] = Timestamp.fromDate(updates['resolvedAt'] as DateTime);
    }
    await _firestore.collection(_collection).doc(id).update(updateData);
  }

  Future<void> resolveIssue(String id, String notes) async {
    final issueDoc =
        await _firestore.collection(_collection).doc(id).get();
    if (!issueDoc.exists) return;
    final issueData = issueDoc.data()!;
    final serialNumber = issueData['serialNumber'] as String?;

    final batch = _firestore.batch();
    batch.update(_firestore.collection(_collection).doc(id), {
      'status': 'resolved',
      'resolutionNotes': notes,
      'resolvedAt': Timestamp.fromDate(DateTime.now()),
    });

    if (serialNumber != null) {
      final serialSnapshot = await _firestore
          .collection('serial_numbers')
          .where('serialNumber', isEqualTo: serialNumber)
          .where('status', isEqualTo: 'defective')
          .limit(1)
          .get();
      if (serialSnapshot.docs.isNotEmpty) {
        final serialDoc = serialSnapshot.docs.first;
        final serialData = serialDoc.data();
        final productId = serialData['productId'] as String? ?? '';
        batch.update(serialDoc.reference, {
          'status': 'available',
        });
        if (productId.isNotEmpty) {
          batch.update(
            _firestore.collection('products').doc(productId),
            {'availableQuantity': FieldValue.increment(1)},
          );
        }
      }
    }

    await batch.commit();
  }

  Future<void> deleteIssue(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  Future<List<ProductIssue>> getAllIssues() async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ProductIssue.fromJson(doc.data(), doc.id))
        .toList();
  }

  Stream<List<ProductIssue>> streamIssues() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductIssue.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<List<ProductIssue>> getIssuesByProduct(String productId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('productId', isEqualTo: productId)
        .get();
    return snapshot.docs
        .map((doc) => ProductIssue.fromJson(doc.data(), doc.id))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<ProductIssue>> getIssuesBySerial(String serialNumber) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('serialNumber', isEqualTo: serialNumber)
        .get();
    return snapshot.docs
        .map((doc) => ProductIssue.fromJson(doc.data(), doc.id))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<ProductIssue?> getIssueById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return ProductIssue.fromJson(doc.data()!, doc.id);
  }

  Future<List<Map<String, dynamic>>> searchAvailableSerials(
      String query) async {
    if (query.length < 2) return [];
    final snapshot = await _firestore
        .collection('serial_numbers')
        .where('status', isEqualTo: 'available')
        .orderBy('serialNumber')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(10)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'serialNumber': data['serialNumber'] as String? ?? '',
        'productId': data['productId'] as String? ?? '',
      };
    }).toList();
  }

  Future<Map<String, dynamic>?> getProductBySerial(String serial) async {
    final serialSnapshot = await _firestore
        .collection('serial_numbers')
        .where('serialNumber', isEqualTo: serial)
        .where('status', isEqualTo: 'available')
        .limit(1)
        .get();
    if (serialSnapshot.docs.isEmpty) return null;
    final serialData = serialSnapshot.docs.first.data();
    final productId = serialData['productId'] as String?;
    if (productId == null) return null;
    final productDoc =
        await _firestore.collection('products').doc(productId).get();
    if (!productDoc.exists) return null;
    final pData = productDoc.data()!;
    return {
      'productId': productId,
      'productName': pData['productName'] as String? ?? 'Unknown',
      'modelNumber': pData['modelNumber'] as String? ?? '',
    };
  }
}
