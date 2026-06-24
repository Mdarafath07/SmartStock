import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _docId = 'app_settings';

  Future<Map<String, dynamic>> loadSettings() async {
    final doc = await _firestore.collection('settings').doc(_docId).get();
    if (!doc.exists) return _defaults();
    return doc.data() as Map<String, dynamic>;
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _firestore.collection('settings').doc(_docId).set(settings, SetOptions(merge: true));
  }

  Map<String, dynamic> _defaults() {
    return {
      'storeName': 'My Store',
      'currency': 'USD',
      'currencySymbol': r'$',
      'timezone': 'UTC',
      'ownerName': 'Store Owner',
      'ownerEmail': 'owner@smartstock.com',
      'lowStockThreshold': 5,
      'overstockThreshold': 100,
    };
  }

  static String currencySymbol(String code) {
    switch (code) {
      case 'USD': return r'$';
      case 'EUR': return '€';
      case 'BDT': return '৳';
      case 'GBP': return '£';
      case 'JPY': return '¥';
      case 'INR': return '₹';
      case 'PKR': return '₨';
      case 'CAD': return r'C$';
      case 'AUD': return r'A$';
      case 'CNY': return '¥';
      default: return r'$';
    }
  }

  static const List<String> currencies = [
    'USD', 'EUR', 'BDT', 'GBP', 'INR', 'JPY', 'CAD', 'AUD', 'PKR', 'CNY',
  ];

  static const List<String> timezones = [
    'UTC', 'Asia/Dhaka', 'Asia/Kolkata', 'Asia/Karachi',
    'Asia/Dubai', 'Asia/Singapore', 'Asia/Shanghai', 'Asia/Tokyo',
    'America/New_York', 'America/Chicago', 'America/Denver', 'America/Los_Angeles',
    'Europe/London', 'Europe/Paris', 'Europe/Berlin', 'Europe/Moscow',
    'Australia/Sydney', 'Pacific/Auckland', 'Africa/Cairo', 'Africa/Lagos',
  ];
}
