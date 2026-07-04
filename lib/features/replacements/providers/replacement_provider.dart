import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smartstock/features/replacements/models/replacement_model.dart';
import 'package:smartstock/features/replacements/services/replacement_service.dart';

class ReplacementProvider extends ChangeNotifier {
  final ReplacementService _service = ReplacementService();
  StreamSubscription<List<Replacement>>? _subscription;

  List<Replacement> _replacements = [];
  List<Replacement> get replacements => _replacements;

  Replacement? _selectedReplacement;
  Replacement? get selectedReplacement => _selectedReplacement;

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

  void loadReplacements() {
    _setLoading(true);
    _subscription?.cancel();
    _subscription = _service.streamReplacements().listen(
      (replacements) {
        _replacements = replacements;
        _setLoading(false);
      },
      onError: (e) {
        _setError(e.toString());
        _setLoading(false);
      },
    );
  }

  Future<void> createReplacement(Replacement replacement) async {
    _setLoading(true);
    _setError(null);
    try {
      await _service.createReplacement(replacement);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> completeReplacement(
    String id, {
    required String newSerialNumber,
    String? notes,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _service.completeReplacement(
        id,
        newSerialNumber: newSerialNumber,
        notes: notes,
      );
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> rejectReplacement(String id, {String? reason}) async {
    _setLoading(true);
    _setError(null);
    try {
      await _service.rejectReplacement(id, reason: reason);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadReplacementById(String id) async {
    _setLoading(true);
    _setError(null);
    try {
      _selectedReplacement = await _service.getReplacementById(id);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  List<Replacement> get pendingReplacements =>
      _replacements.where((r) => r.status == 'pending').toList();

  List<Replacement> get completedReplacements =>
      _replacements.where((r) => r.status == 'completed').toList();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
