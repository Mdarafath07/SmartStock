import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstock/features/settings/services/email_service.dart';
import 'package:smartstock/features/settings/services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _service = SettingsService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
  String _verifiedEmail = '';
  bool _isEmailVerified = false;
  String? _pendingOtp;

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
  String get verifiedEmail => _verifiedEmail;
  bool get isEmailVerified => _isEmailVerified;

  String _generateOtp() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10).toString()).join();
  }

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
    await _service.saveSettings({'shetsServiceAccountJson': value});
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

  Future<String> sendOtp(String email) async {
    _pendingOtp = _generateOtp();
    final now = DateTime.now();

    await _firestore.collection('otps').doc(email).set({
      'otp': _pendingOtp,
      'createdAt': now.toIso8601String(),
      'expiresAt': now.add(const Duration(minutes: 5)).toIso8601String(),
      'verified': false,
    });

    if (EmailService.isConfigured) {
      await EmailService.sendOtp(email, _pendingOtp!);
    }

    return _pendingOtp!;
  }

  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final doc = await _firestore.collection('otps').doc(email).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final storedOtp = data['otp'] as String?;
      final expiresAt = DateTime.parse(data['expiresAt'] as String);

      if (storedOtp != otp) return false;
      if (DateTime.now().isAfter(expiresAt)) return false;

      await _firestore.collection('otps').doc(email).update({'verified': true});

      _verifiedEmail = email;
      _isEmailVerified = true;
      _pendingOtp = null;
      await _service.saveSettings({
        'verifiedEmail': _verifiedEmail,
        'isEmailVerified': true,
      });
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> sendChangeOtp(String email) async {
    _pendingOtp = _generateOtp();
    final now = DateTime.now();

    await _firestore.collection('otps').doc(email).set({
      'otp': _pendingOtp,
      'createdAt': now.toIso8601String(),
      'expiresAt': now.add(const Duration(minutes: 5)).toIso8601String(),
      'verified': false,
    });

    if (EmailService.isConfigured) {
      await EmailService.sendChangeOtp(email, _pendingOtp!);
    }
  }

  Future<bool> verifyChangeOtp(String email, String otp) async {
    try {
      final doc = await _firestore.collection('otps').doc(email).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final storedOtp = data['otp'] as String?;
      final expiresAt = DateTime.parse(data['expiresAt'] as String);

      if (storedOtp != otp) return false;
      if (DateTime.now().isAfter(expiresAt)) return false;

      await _firestore.collection('otps').doc(email).update({'verified': true});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changeEmail(String currentEmail, String newEmail, String otp) async {
    final verified = await verifyChangeOtp(currentEmail, otp);
    if (!verified) return false;

    final newOtp = _generateOtp();
    final now = DateTime.now();
    await _firestore.collection('otps').doc(newEmail).set({
      'otp': newOtp,
      'createdAt': now.toIso8601String(),
      'expiresAt': now.add(const Duration(minutes: 5)).toIso8601String(),
      'verified': false,
    });

    _pendingOtp = newOtp;

    _verifiedEmail = '';
    _isEmailVerified = false;
    await _service.saveSettings({
      'verifiedEmail': '',
      'isEmailVerified': false,
    });
    notifyListeners();
    return true;
  }

  Future<bool> verifyNewEmail(String newEmail, String otp) async {
    final verified = await verifyOtp(newEmail, otp);
    return verified;
  }

  static const List<String> _allCollections = [
    'products', 'sales', 'serial_numbers', 'categories', 'customers',
    'daily_additions', 'product_issues', 'settings', 'otps', 'replacements',
    'restrictions', 'warranty',
  ];

  Future<void> eraseAllData() async {
    for (final collection in _allCollections) {
      final snapshot = await _firestore.collection(collection).get();
      final docs = snapshot.docs;
      for (var i = 0; i < docs.length; i += 500) {
        final batch = _firestore.batch();
        final chunk = docs.sublist(i, (i + 500 > docs.length) ? docs.length : i + 500);
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }
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
    _verifiedEmail = data['verifiedEmail'] as String? ?? '';
    _isEmailVerified = data['isEmailVerified'] as bool? ?? false;
  }
}
