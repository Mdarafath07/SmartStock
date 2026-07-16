import 'dart:async';
import 'package:smartstock/features/customers/models/customer_model.dart';
import 'package:smartstock/features/customers/services/customer_service.dart';
import 'package:smartstock/features/sales/models/sale_model.dart';

class CustomerRepository {
  final CustomerService _customerService = CustomerService();

  Future<List<Customer>> getCustomers({String? searchQuery}) =>
      _customerService.getCustomers(searchQuery: searchQuery);

  Future<Customer?> getCustomerById(String id) =>
      _customerService.getCustomerById(id);

  Future<String> addCustomer(Customer customer) =>
      _customerService.addCustomer(customer);

  Future<void> updateCustomer(Customer customer) =>
      _customerService.updateCustomer(customer);

  Future<List<Customer>> searchCustomers(String query) =>
      _customerService.searchCustomers(query);

  Future<List<Sale>> getCustomerPurchaseHistory(String customerId) =>
      _customerService.getCustomerPurchaseHistory(customerId);
}
