import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstock/features/daily_additions/models/daily_addition_model.dart';

class DailyAdditionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DailyAddition> _additions = [];
  List<DailyAddition> get additions => _additions;

  List<DailyAddition> _todaysAdditions = [];
  List<DailyAddition> get todaysAdditions => _todaysAdditions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isTodaysLoading = false;
  bool get isTodaysLoading => _isTodaysLoading;

  String? _error;
  String? get error => _error;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  Future<void> loadAdditionsForDate(DateTime date) async {
    _selectedDate = date;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('daily_additions')
          .where('dateAdded',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('dateAdded', isLessThan: Timestamp.fromDate(end))
          .orderBy('dateAdded', descending: true)
          .limit(100)
          .get();
      _additions = snapshot.docs
          .map((doc) => DailyAddition.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void loadTodaysAdditions() {
    _isTodaysLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    _firestore
        .collection('daily_additions')
        .where('dateAdded',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('dateAdded', isLessThan: Timestamp.fromDate(end))
        .orderBy('dateAdded', descending: true)
        .get()
        .then((snapshot) {
      _todaysAdditions = snapshot.docs
          .map((doc) =>
              DailyAddition.fromMap(doc.data(), doc.id))
          .toList();
      _isTodaysLoading = false;
      notifyListeners();
    }).catchError((e) {
      _isTodaysLoading = false;
      notifyListeners();
    });
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    loadAdditionsForDate(date);
  }

}
