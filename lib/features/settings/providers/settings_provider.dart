import 'package:flutter/foundation.dart';
import 'package:smartstock/features/settings/services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _service = SettingsService();

  String _storeName = 'My Store';
  String _currency = 'USD';
  String _currencySymbol = r'$';
  String _timezone = 'UTC';
  String _ownerName = 'Store Owner';
  String _ownerEmail = 'owner@smartstock.com';
  int _lowStockThreshold = 5;
  int _overstockThreshold = 100;
  bool _isLoading = false;

  String get storeName => _storeName;
  String get currency => _currency;
  String get currencySymbol => _currencySymbol;
  String get timezone => _timezone;
  String get ownerName => _ownerName;
  String get ownerEmail => _ownerEmail;
  int get lowStockThreshold => _lowStockThreshold;
  int get overstockThreshold => _overstockThreshold;
  bool get isLoading => _isLoading;

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

  Future<void> updateStoreName(String value) async {
    _storeName = value;
    await _service.saveSettings({'storeName': value});
    notifyListeners();
  }

  Future<void> updateCurrency(String value) async {
    _currency = value;
    _currencySymbol = SettingsService.currencySymbol(value);
    await _service.saveSettings({'currency': value, 'currencySymbol': _currencySymbol});
    notifyListeners();
  }

  Future<void> updateTimezone(String value) async {
    _timezone = value;
    await _service.saveSettings({'timezone': value});
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
    await _service.saveSettings({'lowStockThreshold': value});
    notifyListeners();
  }

  Future<void> updateOverstockThreshold(int value) async {
    _overstockThreshold = value;
    await _service.saveSettings({'overstockThreshold': value});
    notifyListeners();
  }

  void _apply(Map<String, dynamic> data) {
    _storeName = data['storeName'] as String? ?? _storeName;
    _currency = data['currency'] as String? ?? _currency;
    _currencySymbol = data['currencySymbol'] as String? ?? _currencySymbol;
    _timezone = data['timezone'] as String? ?? _timezone;
    _ownerName = data['ownerName'] as String? ?? _ownerName;
    _ownerEmail = data['ownerEmail'] as String? ?? _ownerEmail;
    _lowStockThreshold = (data['lowStockThreshold'] as num?)?.toInt() ?? _lowStockThreshold;
    _overstockThreshold = (data['overstockThreshold'] as num?)?.toInt() ?? _overstockThreshold;
  }
}
