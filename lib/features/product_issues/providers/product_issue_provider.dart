import 'package:flutter/foundation.dart';
import 'package:smartstock/features/product_issues/models/product_issue_model.dart';
import 'package:smartstock/features/product_issues/services/product_issue_service.dart';

class ProductIssueProvider extends ChangeNotifier {
  final ProductIssueService _service = ProductIssueService();

  List<ProductIssue> _issues = [];
  List<ProductIssue> get issues => _issues;

  ProductIssue? _selectedIssue;
  ProductIssue? get selectedIssue => _selectedIssue;

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

  Future<void> loadIssues() async {
    _setLoading(true);
    try {
      _issues = await _service.getIssues();
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  Future<void> createIssue(ProductIssue issue) async {
    _setLoading(true);
    _setError(null);
    try {
      await _service.createIssue(issue);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resolveIssue(String id, String notes) async {
    _setLoading(true);
    _setError(null);
    try {
      await _service.resolveIssue(id, notes);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteIssue(String id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _service.deleteIssue(id);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadIssueById(String id) async {
    _setLoading(true);
    _setError(null);
    try {
      _selectedIssue = await _service.getIssueById(id);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  List<ProductIssue> get openIssues =>
      _issues.where((i) => i.status == 'open').toList();

  List<ProductIssue> get inProgressIssues =>
      _issues.where((i) => i.status == 'in_progress').toList();

  List<ProductIssue> get resolvedIssues =>
      _issues.where((i) => i.status == 'resolved').toList();

}
