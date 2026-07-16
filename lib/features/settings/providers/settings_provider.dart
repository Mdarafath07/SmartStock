import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smartstock/features/settings/services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _service = SettingsService();
  Timer? _debounceTimer;

  String _storeName = 'My Store';
  String _storePhone = '';
  String _storeEmail = 'info@mystore.com';
  String _storeAddress = '123 Main Street, City';
  String _currency = 'USD';
  String _currencySymbol = r'$';
  String _timezone = 'UTC';
  String _ownerName = 'Store Owner';
  String _ownerEmail = 'owner@smartstock.com';
  int _lowStockThreshold = 5;
  int _overstockThreshold = 100;
  bool _isLoading = false;
  String _sheetsSpreadsheetId = '';
  String _sheetsServiceAccountJson = '';
  bool _isSyncing = false;
  bool _autoBackupEnabled = false;

  String get storeName => _storeName;
  String get storePhone => _storePhone;
  String get storeEmail => _storeEmail;
  String get storeAddress => _storeAddress;
  String get currency => _currency;
  String get currencySymbol => _currencySymbol;
  String get timezone => _timezone;
  String get ownerName => _ownerName;
  String get ownerEmail => _ownerEmail;
  int get lowStockThreshold => _lowStockThreshold;
  int get overstockThreshold => _overstockThreshold;
  bool get isLoading => _isLoading;
  String get sheetsSpreadsheetId => _sheetsSpreadsheetId;
  String get sheetsServiceAccountJson => _sheetsServiceAccountJson;
  bool get isSyncing => _isSyncing;
  bool get autoBackupEnabled => _autoBackupEnabled;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _service.loadSettings();
      _apply(data);
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _debouncedSave(Map<String, dynamic> data) async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      await _service.saveSettings(data);
    });
  }

  Future<void> updateStoreName(String value) async {
    _storeName = value;
    await _debouncedSave({'storeName': value});
    notifyListeners();
  }

  Future<void> updateStorePhone(String value) async {
    _storePhone = value;
    await _debouncedSave({'storePhone': value});
    notifyListeners();
  }

  Future<void> updateStoreEmail(String value) async {
    _storeEmail = value;
    await _debouncedSave({'storeEmail': value});
    notifyListeners();
  }

  Future<void> updateStoreAddress(String value) async {
    _storeAddress = value;
    await _debouncedSave({'storeAddress': value});
    notifyListeners();
  }

  Future<void> updateCurrency(String value) async {
    _currency = value;
    _currencySymbol = SettingsService.currencySymbol(value);
    await _debouncedSave({'currency': value, 'currencySymbol': _currencySymbol});
    notifyListeners();
  }

  Future<void> updateTimezone(String value) async {
    _timezone = value;
    await _debouncedSave({'timezone': value});
    notifyListeners();
  }

  Future<void> updateProfile(String name, String email) async {
    _ownerName = name;
    _ownerEmail = email;
    await _service.saveSettings({'ownerName': name, 'ownerEmail': email});
    notifyListeners();
  }

  Future<void> updateLowStockThreshold(int value) async {
    _lowStockThreshold = value;
    await _debouncedSave({'lowStockThreshold': value});
    notifyListeners();
  }

  Future<void> updateOverstockThreshold(int value) async {
    _overstockThreshold = value;
    await _debouncedSave({'overstockThreshold': value});
    notifyListeners();
  }

  Future<void> updateSheetsSpreadsheetId(String value) async {
    _sheetsSpreadsheetId = value;
    await _service.saveSettings({'sheetsSpreadsheetId': value});
    notifyListeners();
  }

  Future<void> updateSheetsServiceAccountJson(String value) async {
    _sheetsServiceAccountJson = value;
    await _service.saveSettings({'sheetsServiceAccountJson': value});
    notifyListeners();
  }

  Future<void> setSyncing(bool value) async {
    _isSyncing = value;
    notifyListeners();
  }

  Future<void> setAutoBackup(bool value) async {
    _autoBackupEnabled = value;
    await _service.saveSettings({'autoBackupEnabled': value});
    notifyListeners();
  }

  void _apply(Map<String, dynamic> data) {
    _storeName = data['storeName'] as String? ?? _storeName;
    _storePhone = data['storePhone'] as String? ?? _storePhone;
    _storeEmail = data['storeEmail'] as String? ?? _storeEmail;
    _storeAddress = data['storeAddress'] as String? ?? _storeAddress;
    _currency = data['currency'] as String? ?? _currency;
    _currencySymbol = data['currencySymbol'] as String? ?? _currencySymbol;
    _timezone = data['timezone'] as String? ?? _timezone;
    _ownerName = data['ownerName'] as String? ?? _ownerName;
    _ownerEmail = data['ownerEmail'] as String? ?? _ownerEmail;
    _lowStockThreshold = (data['lowStockThreshold'] as num?)?.toInt() ?? _lowStockThreshold;
    _overstockThreshold = (data['overstockThreshold'] as num?)?.toInt() ?? _overstockThreshold;
    _sheetsSpreadsheetId = data['sheetsSpreadsheetId'] as String? ?? '';
    _sheetsServiceAccountJson = data['sheetsServiceAccountJson'] as String? ?? '';
    _autoBackupEnabled = data['autoBackupEnabled'] as bool? ?? false;
  }
}
