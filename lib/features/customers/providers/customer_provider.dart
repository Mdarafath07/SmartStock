import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smartstock/features/customers/models/customer_model.dart';
import 'package:smartstock/features/customers/repositories/customer_repository.dart';
import 'package:smartstock/features/sales/models/sale_model.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _repository = CustomerRepository();
  StreamSubscription<List<Customer>>? _customersSubscription;
  StreamSubscription<List<Sale>>? _purchaseHistorySubscription;

  List<Customer> _customers = [];
  List<Customer> get customers => _customers;

  Customer? _selectedCustomer;
  Customer? get selectedCustomer => _selectedCustomer;

  List<Sale> _purchaseHistory = [];
  List<Sale> get purchaseHistory => _purchaseHistory;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void loadCustomers({String? searchQuery}) {
    _customersSubscription?.cancel();
    _customersSubscription =
        _repository.getCustomers(searchQuery: searchQuery).listen(
      (customers) {
        _customers = customers;
        notifyListeners();
      },
      onError: (e) => _setError(e.toString()),
    );
  }

  Future<void> loadCustomerDetails(String id) async {
    _setLoading(true);
    _setError(null);
    try {
      _selectedCustomer = await _repository.getCustomerById(id);
      notifyListeners();
      if (_selectedCustomer != null) {
        loadPurchaseHistory(id);
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void loadPurchaseHistory(String customerId) {
    _purchaseHistorySubscription?.cancel();
    _purchaseHistorySubscription =
        _repository.getCustomerPurchaseHistory(customerId).listen(
      (sales) {
        _purchaseHistory = sales;
        notifyListeners();
      },
      onError: (e) => _setError(e.toString()),
    );
  }

  Future<List<Customer>> searchCustomer(String query) async {
    return _repository.searchCustomers(query);
  }

  Future<String> addCustomer(Customer customer) async {
    _setLoading(true);
    _setError(null);
    try {
      final id = await _repository.addCustomer(customer);
      return id;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    _setLoading(true);
    _setError(null);
    try {
      await _repository.updateCustomer(customer);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _customersSubscription?.cancel();
    _purchaseHistorySubscription?.cancel();
    super.dispose();
  }
}
