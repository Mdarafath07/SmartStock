import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:smartstock/features/integrations/services/google_sheets_backup_service.dart';

class SyncProvider extends ChangeNotifier {
  final GoogleSheetsBackupService _service = GoogleSheetsBackupService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSyncing = false;
  bool _autoSyncEnabled = false;
  DateTime? _lastSyncTime;
  SyncResult? _lastResult;
  final List<StreamSubscription> _listeners = [];
  String _sheetsServiceAccountJson = '';
  String _sheetsSpreadsheetId = '';
  int _pendingChanges = 0;
  Timer? _debounceTimer;

  bool get isSyncing => _isSyncing;
  bool get autoSyncEnabled => _autoSyncEnabled;
  DateTime? get lastSyncTime => _lastSyncTime;
  SyncResult? get lastResult => _lastResult;
  int get pendingChanges => _pendingChanges;

  void configure(String serviceAccountJson, String spreadsheetId) {
    _sheetsServiceAccountJson = serviceAccountJson;
    _sheetsSpreadsheetId = spreadsheetId;
  }

  Future<void> setAutoSync(bool enabled) async {
    _autoSyncEnabled = enabled;
    notifyListeners();
    if (enabled) {
      _startListening();
      await syncAll();
    } else {
      _stopListening();
    }
  }

  void _startListening() {
    _stopListening();
    final collections = [
      'products', 'categories', 'sales', 'serial_numbers',
      'customers', 'daily_additions', 'product_issues',
      'replacements', 'warranty',
    ];

    for (final collection in collections) {
      final sub = _firestore.collection(collection).snapshots().listen(
        _onDataChange,
        onError: (e) => debugPrint('Sync listener error ($collection): $e'),
      );
      _listeners.add(sub);
    }
  }

  void _stopListening() {
    for (final sub in _listeners) {
      sub.cancel();
    }
    _listeners.clear();
    _debounceTimer?.cancel();
    _pendingChanges = 0;
  }

  void _onDataChange(QuerySnapshot snapshot) {
    if (snapshot.docChanges.isEmpty) return;
    _pendingChanges += snapshot.docChanges.length;
    notifyListeners();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 30), () async {
      if (_autoSyncEnabled && _pendingChanges > 0) {
        await syncAll();
      }
    });
  }

  Future<void> syncAll() async {
    if (_isSyncing) return;
    if (_sheetsServiceAccountJson.isEmpty || _sheetsSpreadsheetId.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    try {
      _lastResult = await _service.syncAll(
        _sheetsServiceAccountJson,
        _sheetsSpreadsheetId,
      );
      _lastSyncTime = DateTime.now();
      _pendingChanges = 0;
    } catch (e) {
      debugPrint('Sync failed: $e');
      _lastResult = SyncResult()
        ..errorCount = 1
        ..errors.add('Sync failed: $e');
    }

    _isSyncing = false;
    notifyListeners();
  }

  void clearPendingChanges() {
    _pendingChanges = 0;
    notifyListeners();
  }

  void reset() {
    _stopListening();
    _autoSyncEnabled = false;
    _lastSyncTime = null;
    _lastResult = null;
    _pendingChanges = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopListening();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
