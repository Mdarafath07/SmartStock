import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstock/features/customers/models/customer_model.dart';
import 'package:smartstock/features/sales/models/sale_model.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _customersCollection => 'customers';
  String get _salesCollection => 'sales';

  Future<List<Customer>> getCustomers({String? searchQuery}) {
    Query query = _firestore.collection(_customersCollection);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query
          .where('searchKeywords', arrayContains: searchQuery.toLowerCase());
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get()
        .then((snapshot) => snapshot.docs
            .map((doc) => Customer.fromJson(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<Customer?> getCustomerById(String id) async {
    final doc = await _firestore.collection(_customersCollection).doc(id).get();
    if (!doc.exists) return null;
    return Customer.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<String> addCustomer(Customer customer) async {
    final ref = _firestore.collection(_customersCollection).doc();
    final data = customer.toJson();
    data['searchKeywords'] = _generateSearchKeywords(customer.name);
    await ref.set(data);
    return ref.id;
  }

  Future<void> updateCustomer(Customer customer) async {
    final data = customer.toJson();
    data['searchKeywords'] = _generateSearchKeywords(customer.name);
    await _firestore
        .collection(_customersCollection)
        .doc(customer.id)
        .update(data);
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final snapshot = await _firestore
        .collection(_customersCollection)
        .get();

    final lowerQuery = query.toLowerCase();
    final results = <Customer>[];
    for (final doc in snapshot.docs) {
      final customer = Customer.fromJson(doc.data(), doc.id);
      if (customer.name.toLowerCase().contains(lowerQuery) ||
          customer.phone.contains(query)) {
        results.add(customer);
      }
    }
    return results;
  }

  Future<List<Sale>> getCustomerPurchaseHistory(String customerId) {
    return FirebaseFirestore.instance
        .collection(_salesCollection)
        .where('customerId', isEqualTo: customerId)
        .orderBy('saleDate', descending: true)
        .limit(50)
        .get()
        .then((snapshot) => snapshot.docs
            .map((doc) => Sale.fromJson(doc.data(), doc.id))
            .where((sale) => sale.saleType != 'warranty_claim')
            .toList());
  }

  List<String> _generateSearchKeywords(String name) {
    final lower = name.toLowerCase();
    final keywords = <String>[lower];
    final parts = lower.split(' ');
    for (final part in parts) {
      if (part.isNotEmpty) {
        keywords.add(part);
        for (int i = 1; i < part.length; i++) {
          keywords.add(part.substring(0, i + 1));
        }
      }
    }
    return keywords.toSet().toList();
  }
}
