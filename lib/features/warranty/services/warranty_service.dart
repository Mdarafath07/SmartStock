import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstock/features/warranty/models/warranty_model.dart';

class WarrantyService {
  final FirebaseFirestore _firestore;

  WarrantyService() : _firestore = FirebaseFirestore.instance;

  Future<List<Warranty>> getAllWarranties() async {
    final snapshot = await _firestore
        .collection('sales')
        .orderBy('saleDate', descending: true)
        .get();

    return _mapToWarranties(snapshot);
  }

  Future<List<Warranty>> searchWarranty({
    String? category,
    String? modelNumber,
    String? serialNumber,
  }) async {
    Query query = _firestore.collection('sales');

    bool hasConstraint = false;

    if (modelNumber != null && modelNumber.isNotEmpty) {
      query = query.where('modelNumber', isEqualTo: modelNumber);
      hasConstraint = true;
    }

    if (serialNumber != null && serialNumber.isNotEmpty) {
      query = query.where('serialNumber', isEqualTo: serialNumber);
      hasConstraint = true;
    }

    if (!hasConstraint) {
      query = query.orderBy('saleDate', descending: true);
    }

    final snapshot = await query.get();
    var warranties = _mapToWarranties(snapshot);

    if (category != null && category.isNotEmpty) {
      warranties = warranties
          .where((w) => w.productName
              .toLowerCase()
              .contains(category.toLowerCase()))
          .toList();
    }

    return warranties;
  }

  Future<Warranty?> getWarrantyBySerialNumber(String serial) async {
    final snapshot = await _firestore
        .collection('sales')
        .where('serialNumber', isEqualTo: serial)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return _mapWarranty(snapshot.docs.first);
  }

  Future<List<Warranty>> getExpiredWarranties() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('sales')
        .where('warrantyExpiryDate', isLessThan: Timestamp.fromDate(now))
        .orderBy('warrantyExpiryDate', descending: true)
        .get();

    return _mapToWarranties(snapshot);
  }

  Future<List<Warranty>> getActiveWarranties() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('sales')
        .where('warrantyExpiryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('warrantyExpiryDate', descending: false)
        .get();

    return _mapToWarranties(snapshot);
  }

  Future<Warranty?> getWarrantyBySaleId(String saleId) async {
    final doc = await _firestore.collection('sales').doc(saleId).get();
    if (!doc.exists) return null;
    return _mapWarranty(doc);
  }

  List<Warranty> _mapToWarranties(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) => _mapWarranty(doc)).toList();
  }

  Warranty _mapWarranty(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Warranty.fromJson({...data, 'saleId': doc.id}, doc.id);
  }
}
