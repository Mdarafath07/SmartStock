import 'package:flutter/foundation.dart';
import 'package:smartstock/features/customers/models/customer_model.dart';
import 'package:smartstock/features/customers/repositories/customer_repository.dart';
import 'package:smartstock/features/sales/models/sale_model.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _repository = CustomerRepository();

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

  Future<void> loadCustomers({String? searchQuery}) async {
    try {
      _customers = await _repository.getCustomers(searchQuery: searchQuery);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
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

  Future<void> loadPurchaseHistory(String customerId) async {
    try {
      _purchaseHistory = await _repository.getCustomerPurchaseHistory(customerId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
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

}
