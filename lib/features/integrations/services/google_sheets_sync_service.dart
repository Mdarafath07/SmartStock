import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';

class GoogleSheetsSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? validateJson(String json) {
    if (json.trim().isEmpty) return 'Service Account JSON is empty';
    try {
      final parsed = jsonDecode(json);
      if (parsed['client_email'] == null) return 'Invalid JSON: client_email not found';
      if (parsed['private_key'] == null) return 'Invalid JSON: private_key not found';
    } catch (_) {
      return 'Invalid JSON format';
    }
    return null;
  }

  Future<String> syncTodayToSheets(String serviceAccountJson, String spreadsheetId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final salesSnap = await _firestore
        .collection('sales')
        .where('saleDate', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where('saleDate', isLessThan: Timestamp.fromDate(tomorrow))
        .get();

    double totalSales = 0;
    double totalProfit = 0;
    int saleCount = 0;
    final List<List<Object?>> saleRows = [];

    for (final doc in salesSnap.docs) {
      final data = doc.data();
      if (data['saleType'] == 'warranty_claim') continue;
      final price = (data['salePrice'] as num?)?.toDouble() ?? 0;
      final profit = (data['profit'] as num?)?.toDouble() ?? 0;
      totalSales += price;
      totalProfit += profit;
      saleCount++;
      saleRows.add([
        data['productName'] ?? '',
        data['modelNumber'] ?? '',
        data['customerName'] ?? '',
        data['serialNumber'] ?? '',
        price,
        profit,
      ]);
    }

    final settingsDoc = await _firestore.collection('settings').doc('app_settings').get();
    final storeName = (settingsDoc.data() ?? {})['storeName'] ?? 'My Store';

    final creds = ServiceAccountCredentials.fromJson(jsonDecode(serviceAccountJson));
    final scopes = [SheetsApi.spreadsheetsScope];
    final client = await clientViaServiceAccount(creds, scopes);
    final sheets = SheetsApi(client);

    final dateStr = DateFormat('yyyy-MM-dd').format(today);

    // Ensure date sheet exists with header
    final sheetsList = await sheets.spreadsheets.get(spreadsheetId);
    final hasSheet = sheetsList.sheets!.any((s) => s.properties!.title == dateStr);
    if (!hasSheet) {
      await sheets.spreadsheets.batchUpdate(
        BatchUpdateSpreadsheetRequest(requests: [
          Request(addSheet: AddSheetRequest(properties: SheetProperties(title: dateStr))),
        ]),
        spreadsheetId,
      );
      await sheets.spreadsheets.values.append(
        ValueRange.fromJson({'values': [['Product', 'Model', 'Customer', 'Serial', 'Price', 'Profit']]}),
        spreadsheetId,
        '$dateStr!A1',
        valueInputOption: 'RAW',
      );
    }

    // Append sales
    if (saleRows.isNotEmpty) {
      await sheets.spreadsheets.values.append(
        ValueRange.fromJson({'values': saleRows}),
        spreadsheetId,
        '$dateStr!A:F',
        valueInputOption: 'RAW',
      );
    }

    // Summary
    const summaryTitle = 'Summary';
    final hasSummary = sheetsList.sheets!.any((s) => s.properties!.title == summaryTitle);
    if (!hasSummary) {
      await sheets.spreadsheets.batchUpdate(
        BatchUpdateSpreadsheetRequest(requests: [
          Request(addSheet: AddSheetRequest(properties: SheetProperties(title: summaryTitle))),
        ]),
        spreadsheetId,
      );
      await sheets.spreadsheets.values.append(
        ValueRange.fromJson({'values': [['Date', 'Sales', 'Profit', 'Transactions', 'Store']]}),
        spreadsheetId,
        '$summaryTitle!A1',
        valueInputOption: 'RAW',
      );
    }
    await sheets.spreadsheets.values.append(
      ValueRange.fromJson({'values': [[dateStr, totalSales, totalProfit, saleCount, storeName]]}),
      spreadsheetId,
      '$summaryTitle!A:E',
      valueInputOption: 'RAW',
    );

    client.close();
    return '$saleCount sales synced to $dateStr';
  }

  Future<String> syncMonthlyReport(String serviceAccountJson, String spreadsheetId, int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final salesSnap = await _firestore
        .collection('sales')
        .where('saleDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('saleDate', isLessThan: Timestamp.fromDate(end))
        .get();

    double totalSales = 0;
    double totalProfit = 0;
    int count = 0;
    for (final doc in salesSnap.docs) {
      final data = doc.data();
      if (data['saleType'] == 'warranty_claim') continue;
      totalSales += (data['salePrice'] as num?)?.toDouble() ?? 0;
      totalProfit += (data['profit'] as num?)?.toDouble() ?? 0;
      count++;
    }

    final settingsDoc = await _firestore.collection('settings').doc('app_settings').get();
    final storeName = (settingsDoc.data() ?? {})['storeName'] ?? 'My Store';

    final creds = ServiceAccountCredentials.fromJson(jsonDecode(serviceAccountJson));
    final client = await clientViaServiceAccount(creds, [SheetsApi.spreadsheetsScope]);
    final sheets = SheetsApi(client);

    final monthTitle = '$year-${month.toString().padLeft(2, '0')}';
    final sheetsList = await sheets.spreadsheets.get(spreadsheetId);
    final hasSheet = sheetsList.sheets!.any((s) => s.properties!.title == monthTitle);
    if (!hasSheet) {
      await sheets.spreadsheets.batchUpdate(
        BatchUpdateSpreadsheetRequest(requests: [
          Request(addSheet: AddSheetRequest(properties: SheetProperties(title: monthTitle))),
        ]),
        spreadsheetId,
      );
      await sheets.spreadsheets.values.append(
        ValueRange.fromJson({'values': [['Store', 'Sales', 'Profit', 'Transactions']]}),
        spreadsheetId,
        '$monthTitle!A1',
        valueInputOption: 'RAW',
      );
    }

    await sheets.spreadsheets.values.append(
      ValueRange.fromJson({'values': [[storeName, totalSales, totalProfit, count]]}),
      spreadsheetId,
      '$monthTitle!A:D',
      valueInputOption: 'RAW',
    );

    client.close();
    return 'Monthly report for $month/$year synced';
  }
}
