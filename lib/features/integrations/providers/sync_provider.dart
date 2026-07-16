import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smartstock/features/integrations/services/google_sheets_backup_service.dart';

class SyncProvider extends ChangeNotifier {
  final GoogleSheetsBackupService _service = GoogleSheetsBackupService();

  bool _isSyncing = false;
  bool _autoSyncEnabled = false;
  DateTime? _lastSyncTime;
  SyncResult? _lastResult;
  Timer? _syncTimer;
  String _sheetsServiceAccountJson = '';
  String _sheetsSpreadsheetId = '';
  int _pendingChanges = 0;

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
      _startPeriodicSync();
      await syncAll();
    } else {
      _stopPeriodicSync();
    }
  }

  void _startPeriodicSync() {
    _stopPeriodicSync();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (_autoSyncEnabled && !_isSyncing) {
        await syncAll();
      }
    });
  }

  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<String?> syncAll() async {
    if (_isSyncing) return null;
    if (_sheetsServiceAccountJson.isEmpty || _sheetsSpreadsheetId.isEmpty) {
      return 'Google Sheets not configured. Enter Sheet ID and Service Account JSON.';
    }

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
    return null;
  }

  void clearPendingChanges() {
    _pendingChanges = 0;
    notifyListeners();
  }

  void reset() {
    _stopPeriodicSync();
    _autoSyncEnabled = false;
    _lastSyncTime = null;
    _lastResult = null;
    _pendingChanges = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPeriodicSync();
    super.dispose();
  }
}
