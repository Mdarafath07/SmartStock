import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';

class CollectionConfig {
  final String sheetName;
  final String collection;
  final List<String> headers;
  final List<dynamic> Function(Map<String, dynamic> doc, String id) rowMapper;

  const CollectionConfig({
    required this.sheetName,
    required this.collection,
    required this.headers,
    required this.rowMapper,
  });
}

class GoogleSheetsBackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _collections = [
    CollectionConfig(
      sheetName: 'Products',
      collection: 'products',
      headers: [
        'ID', 'Category ID', 'Category Name', 'Brand Name',
        'Product Name', 'Model Number', 'Image URL', 'Description',
        'Purchase Price', 'Selling Price', 'Warranty Months',
        'Warranty Days', 'Available Quantity', 'Sold Quantity', 'Created At'
      ],
      rowMapper: _mapProduct,
    ),
    CollectionConfig(
      sheetName: 'Categories',
      collection: 'categories',
      headers: ['ID', 'Name', 'Icon', 'Created At'],
      rowMapper: _mapCategory,
    ),
    CollectionConfig(
      sheetName: 'Sales',
      collection: 'sales',
      headers: [
        'ID', 'Product ID', 'Product Name', 'Model Number',
        'Serial Number', 'Serial Number ID', 'Category ID',
        'Customer ID', 'Customer Name', 'Customer Phone',
        'Sale Price', 'Purchase Price', 'Profit', 'Sale Date',
        'Warranty Expiry', 'Created At', 'Image URL', 'Sale Type',
        'Related Sale ID', 'Old Serial', 'Warranty Claimed',
        'New Serial', 'Claim Date'
      ],
      rowMapper: _mapSale,
    ),
    CollectionConfig(
      sheetName: 'Serial_Numbers',
      collection: 'serial_numbers',
      headers: ['ID', 'Product ID', 'Serial Number', 'Status', 'Sale ID', 'Return Type', 'Created At'],
      rowMapper: _mapSerialNumber,
    ),
    CollectionConfig(
      sheetName: 'Customers',
      collection: 'customers',
      headers: ['ID', 'Name', 'Phone', 'Address', 'Created At', 'Total Orders', 'Lifetime Value'],
      rowMapper: _mapCustomer,
    ),
    CollectionConfig(
      sheetName: 'Daily_Additions',
      collection: 'daily_additions',
      headers: [
        'ID', 'Product Name', 'Category Name', 'Quantity',
        'Unit Price', 'Total Price', 'Notes', 'Date Added',
        'Created At', 'Reminder Enabled', 'Reminder Time'
      ],
      rowMapper: _mapDailyAddition,
    ),
    CollectionConfig(
      sheetName: 'Product_Issues',
      collection: 'product_issues',
      headers: [
        'ID', 'Product ID', 'Product Name', 'Model Number',
        'Serial Number', 'Issue Description', 'Issue Type',
        'Status', 'Customer Name', 'Customer Phone',
        'Created At', 'Resolved At', 'Resolution Notes'
      ],
      rowMapper: _mapProductIssue,
    ),
    CollectionConfig(
      sheetName: 'Replacements',
      collection: 'replacements',
      headers: [
        'ID', 'Sale ID', 'Product ID', 'Product Name',
        'Model Number', 'Old Serial', 'New Serial',
        'Customer ID', 'Customer Name', 'Customer Phone',
        'Reason', 'Type', 'Status', 'Created At',
        'Completed At', 'Notes'
      ],
      rowMapper: _mapReplacement,
    ),
    CollectionConfig(
      sheetName: 'Warranties',
      collection: 'warranty',
      headers: [
        'ID', 'Sale ID', 'Product ID', 'Product Name',
        'Model Number', 'Serial Number', 'Customer ID',
        'Customer Name', 'Customer Phone', 'Purchase Date',
        'Expiry Date', 'Warranty Months', 'Image URL',
        'Sale Price', 'Warranty Claimed', 'Related Sale ID',
        'New Serial', 'Sale Type', 'Old Serial',
        'Old Purchase Date', 'Claim Date'
      ],
      rowMapper: _mapWarranty,
    ),
  ];

  String? validateJson(String json) {
    if (json.trim().isEmpty) return 'Service Account JSON is empty';
    try {
      final parsed = jsonDecode(json);
      if (parsed['client_email'] == null) return 'client_email not found';
      if (parsed['private_key'] == null) return 'private_key not found';
    } catch (_) {
      return 'Invalid JSON format';
    }
    return null;
  }

  Future<String> testConnection(String serviceAccountJson, String spreadsheetId) async {
    try {
      final creds = ServiceAccountCredentials.fromJson(jsonDecode(serviceAccountJson));
      final client = await clientViaServiceAccount(creds, [SheetsApi.spreadsheetsScope]);
      final sheets = SheetsApi(client);
      try {
        await sheets.spreadsheets.get(spreadsheetId);
        // Try writing a test value
        const sheetName = '_test_conn';
        try {
          await sheets.spreadsheets.values.update(
            ValueRange.fromJson({
              'values': [['SmartStock OK']],
              'majorDimension': 'ROWS',
            }),
            spreadsheetId,
            '$sheetName!A1',
            valueInputOption: 'RAW',
          );
        } catch (_) {}
        return 'Connection OK';
      } finally {
        client.close();
      }
    } catch (e) {
      return 'Connection failed: $e';
    }
  }

  Future<SyncResult> syncAll(String serviceAccountJson, String spreadsheetId) async {
    final result = SyncResult();
    result.startTime = DateTime.now();

    try {
      final creds = ServiceAccountCredentials.fromJson(jsonDecode(serviceAccountJson));
      final client = await clientViaServiceAccount(creds, [SheetsApi.spreadsheetsScope]);
      final sheets = SheetsApi(client);

      try {
        final spreadsheet = await sheets.spreadsheets.get(spreadsheetId);
        final existingSheets = spreadsheet.sheets!
            .map((s) => s.properties!.title!)
            .toSet();

        for (final config in _collections) {
          try {
            final count = await _syncCollection(sheets, spreadsheetId, config, existingSheets);
            result.collectionCounts[config.sheetName] = count;
            result.successCount++;
          } catch (e) {
            result.collectionCounts[config.sheetName] = -1;
            result.errorCount++;
            result.errors.add('${config.sheetName}: $e');
          }
        }

        await _writeBackupLog(sheets, spreadsheetId, existingSheets, result);

        // Final verification: check all sheets exist
        final updatedSpreadsheet = await sheets.spreadsheets.get(spreadsheetId);
        final finalSheetNames = updatedSpreadsheet.sheets!
            .map((s) => s.properties!.title!)
            .toSet();
        for (final config in _collections) {
          if (!finalSheetNames.contains(config.sheetName)) {
            result.errors.add('${config.sheetName} sheet was not created');
            result.errorCount++;
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      result.errorCount++;
      result.errors.add('Connection error: $e');
    }

    result.endTime = DateTime.now();
    return result;
  }

  Future<int> _syncCollection(
    SheetsApi sheets,
    String spreadsheetId,
    CollectionConfig config,
    Set<String> existingSheets,
  ) async {
    final snap = await _firestore.collection(config.collection).get();

    if (!existingSheets.contains(config.sheetName)) {
      await sheets.spreadsheets.batchUpdate(
        BatchUpdateSpreadsheetRequest(requests: [
          Request(addSheet: AddSheetRequest(
            properties: SheetProperties(title: config.sheetName),
          )),
        ]),
        spreadsheetId,
      );
      existingSheets.add(config.sheetName);
    }

    // Build rows: header + data
    final allRows = [
      config.headers,
      for (final doc in snap.docs)
        config.rowMapper(doc.data(), doc.id),
    ];

    final range = '${config.sheetName}!A1';

    // First: write header
    await sheets.spreadsheets.values.update(
      ValueRange.fromJson({
        'values': [allRows.first],
        'majorDimension': 'ROWS',
      }),
      spreadsheetId,
      range,
      valueInputOption: 'RAW',
    );

    // Second: append data rows if any
    if (allRows.length > 1) {
      await sheets.spreadsheets.values.append(
        ValueRange.fromJson({
          'values': allRows.sublist(1),
          'majorDimension': 'ROWS',
        }),
        spreadsheetId,
        range,
        valueInputOption: 'RAW',
      );
    }

    // Verify: read back
    try {
      final readBack = await sheets.spreadsheets.values.get(
        spreadsheetId,
        '${config.sheetName}!A1:Z1',
      );
      if (readBack.values == null || readBack.values!.isEmpty) {
        throw Exception('Write verification failed: no data found after write');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Write verification')) rethrow;
      // Ignore read errors - write might still have worked
    }

    return allRows.length - 1;
  }

  Future<void> _writeBackupLog(
    SheetsApi sheets,
    String spreadsheetId,
    Set<String> existingSheets,
    SyncResult result,
  ) async {
    const logName = 'Backup_Log';
    if (!existingSheets.contains(logName)) {
      await sheets.spreadsheets.batchUpdate(
        BatchUpdateSpreadsheetRequest(requests: [
          Request(addSheet: AddSheetRequest(
            properties: SheetProperties(title: logName),
          )),
        ]),
        spreadsheetId,
      );
    }

    final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(result.startTime!);
    final duration = result.duration.inSeconds;
    final details = result.collectionCounts.entries
        .map((e) => '${e.key}: ${e.value >= 0 ? e.value.toString() : "FAILED"}')
        .join(', ');

    await sheets.spreadsheets.values.append(
      ValueRange.fromJson({
        'values': [
          ['Backup Time', 'Duration (s)', 'Collections Synced', 'Total Records', 'Success', 'Errors', 'Details'],
          [dateStr, duration, result.successCount + result.errorCount,
           result.totalRecords, result.successCount, result.errorCount, details],
        ],
        'majorDimension': 'ROWS',
      }),
      spreadsheetId,
      '$logName!A1',
      valueInputOption: 'RAW',
    );
  }

  // Row mappers
  static List<dynamic> _mapProduct(Map<String, dynamic> d, String id) => [
    id,
    d['categoryId'] ?? '',
    d['categoryName'] ?? '',
    d['brandName'] ?? '',
    d['productName'] ?? '',
    d['modelNumber'] ?? '',
    d['imageUrl'] ?? '',
    d['description'] ?? '',
    (d['purchasePrice'] as num?)?.toDouble() ?? 0,
    (d['sellingPrice'] as num?)?.toDouble() ?? 0,
    (d['warrantyMonths'] as num?)?.toInt() ?? 0,
    (d['warrantyDays'] as num?)?.toInt() ?? 0,
    (d['availableQuantity'] as num?)?.toInt() ?? 0,
    (d['soldQuantity'] as num?)?.toInt() ?? 0,
    _formatDate(d['createdAt']),
  ];

  static List<dynamic> _mapCategory(Map<String, dynamic> d, String id) => [
    id,
    d['name'] ?? '',
    d['icon'] ?? '',
    _formatDate(d['createdAt']),
  ];

  static List<dynamic> _mapSale(Map<String, dynamic> d, String id) => [
    id,
    d['productId'] ?? '',
    d['productName'] ?? '',
    d['modelNumber'] ?? '',
    d['serialNumber'] ?? '',
    d['serialNumberId'] ?? '',
    d['categoryId'] ?? '',
    d['customerId'] ?? '',
    d['customerName'] ?? '',
    d['customerPhone'] ?? '',
    (d['salePrice'] as num?)?.toDouble() ?? 0,
    (d['purchasePrice'] as num?)?.toDouble() ?? 0,
    (d['profit'] as num?)?.toDouble() ?? 0,
    _formatDate(d['saleDate']),
    _formatDate(d['warrantyExpiryDate']),
    _formatDate(d['createdAt']),
    d['imageUrl'] ?? '',
    d['saleType'] ?? 'normal',
    d['relatedSaleId'] ?? '',
    d['oldSerialNumber'] ?? '',
    d['warrantyClaimed'] == true ? 'Yes' : 'No',
    d['newSerialNumber'] ?? '',
    _formatDate(d['claimDate']),
  ];

  static List<dynamic> _mapSerialNumber(Map<String, dynamic> d, String id) => [
    id,
    d['productId'] ?? '',
    d['serialNumber'] ?? '',
    d['status'] ?? 'available',
    d['saleId'] ?? '',
    d['returnType'] ?? '',
    _formatDate(d['createdAt']),
  ];

  static List<dynamic> _mapCustomer(Map<String, dynamic> d, String id) => [
    id,
    d['name'] ?? '',
    d['phone'] ?? '',
    d['address'] ?? '',
    _formatDate(d['createdAt']),
    (d['totalOrders'] as num?)?.toInt() ?? 0,
    (d['lifetimeValue'] as num?)?.toDouble() ?? 0,
  ];

  static List<dynamic> _mapDailyAddition(Map<String, dynamic> d, String id) => [
    id,
    d['productName'] ?? '',
    d['categoryName'] ?? '',
    (d['quantity'] as num?)?.toInt() ?? 0,
    (d['unitPrice'] as num?)?.toDouble() ?? 0,
    (d['totalPrice'] as num?)?.toDouble() ?? 0,
    d['notes'] ?? '',
    _formatDate(d['dateAdded']),
    _formatDate(d['createdAt']),
    d['reminderEnabled'] == true ? 'Yes' : 'No',
    _formatDate(d['reminderTime']),
  ];

  static List<dynamic> _mapProductIssue(Map<String, dynamic> d, String id) => [
    id,
    d['productId'] ?? '',
    d['productName'] ?? '',
    d['modelNumber'] ?? '',
    d['serialNumber'] ?? '',
    d['issueDescription'] ?? '',
    d['issueType'] ?? 'other',
    d['status'] ?? 'open',
    d['customerName'] ?? '',
    d['customerPhone'] ?? '',
    _formatDate(d['createdAt']),
    _formatDate(d['resolvedAt']),
    d['resolutionNotes'] ?? '',
  ];

  static List<dynamic> _mapReplacement(Map<String, dynamic> d, String id) => [
    id,
    d['saleId'] ?? '',
    d['productId'] ?? '',
    d['productName'] ?? '',
    d['modelNumber'] ?? '',
    d['oldSerialNumber'] ?? '',
    d['newSerialNumber'] ?? '',
    d['customerId'] ?? '',
    d['customerName'] ?? '',
    d['customerPhone'] ?? '',
    d['reason'] ?? '',
    d['type'] ?? 'replacement',
    d['status'] ?? 'pending',
    _formatDate(d['createdAt']),
    _formatDate(d['completedAt']),
    d['notes'] ?? '',
  ];

  static List<dynamic> _mapWarranty(Map<String, dynamic> d, String id) => [
    id,
    d['saleId'] ?? id,
    d['productId'] ?? '',
    d['productName'] ?? '',
    d['modelNumber'] ?? '',
    d['serialNumber'] ?? '',
    d['customerId'] ?? '',
    d['customerName'] ?? '',
    d['customerPhone'] ?? '',
    _formatDate(d['purchaseDate'] ?? d['saleDate']),
    _formatDate(d['expiryDate'] ?? d['warrantyExpiryDate']),
    (d['warrantyMonths'] as num?)?.toInt() ?? 0,
    d['imageUrl'] ?? '',
    (d['salePrice'] as num?)?.toDouble() ?? 0,
    d['warrantyClaimed'] == true ? 'Yes' : 'No',
    d['relatedSaleId'] ?? '',
    d['newSerialNumber'] ?? '',
    d['saleType'] ?? 'normal',
    d['oldSerialNumber'] ?? '',
    _formatDate(d['oldPurchaseDate']),
    _formatDate(d['claimDate']),
  ];

  Future<String> diagnosticCheck(String serviceAccountJson, String spreadsheetId) async {
    try {
      final creds = ServiceAccountCredentials.fromJson(jsonDecode(serviceAccountJson));
      final client = await clientViaServiceAccount(creds, [SheetsApi.spreadsheetsScope]);
      final sheets = SheetsApi(client);
      try {
        final buf = StringBuffer();
        final spreadsheet = await sheets.spreadsheets.get(spreadsheetId);
        buf.writeln('Spreadsheet title: ${spreadsheet.properties?.title}');
        buf.writeln('Sheets (${spreadsheet.sheets?.length ?? 0}):');
        for (final s in spreadsheet.sheets ?? []) {
          final title = s.properties!.title!;
          buf.write('  - $title');
          try {
            final data = await sheets.spreadsheets.values.get(
              spreadsheetId,
              '$title!A1:Z10',
            );
            final rows = data.values?.length ?? 0;
            buf.writeln(' ($rows rows)');
            if (rows > 0) {
              buf.writeln('    First row: ${data.values!.first}');
            }
          } catch (e) {
            buf.writeln(' (read error: $e)');
          }
        }

        // Test write to existing sheet
        if (spreadsheet.sheets!.isNotEmpty) {
          const testSheet = 'Backup_Log';
          final hasTest = spreadsheet.sheets!
              .any((s) => s.properties!.title == testSheet);
          if (hasTest) {
            await sheets.spreadsheets.values.append(
              ValueRange.fromJson({
                'values': [['Diag test', DateTime.now().toIso8601String()]],
                'majorDimension': 'ROWS',
              }),
              spreadsheetId,
              '$testSheet!A1',
              valueInputOption: 'RAW',
            );
            buf.writeln('Append test to $testSheet: OK');
          }
        }

        return buf.toString();
      } finally {
        client.close();
      }
    } catch (e) {
      return 'Diagnostic failed: $e';
    }
  }

  static String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is Timestamp) {
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(date.toDate());
    }
    if (date is DateTime) {
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
    }
    return date.toString();
  }
}

class SyncResult {
  DateTime? startTime;
  DateTime? endTime;
  int successCount = 0;
  int errorCount = 0;
  final Map<String, int> collectionCounts = {};
  final List<String> errors = [];

  Duration get duration =>
      (endTime ?? DateTime.now()).difference(startTime ?? DateTime.now());

  int get totalRecords =>
      collectionCounts.values.fold(0, (total, c) => total + (c > 0 ? c : 0));

  bool get hasErrors => errorCount > 0;

  String get summary {
    final buf = StringBuffer();
    buf.writeln('Sync completed in ${duration.inSeconds}s');
    buf.writeln('Collections: ${successCount + errorCount}');
    buf.writeln('Records: $totalRecords');
    buf.writeln('Success: $successCount, Errors: $errorCount');
    if (hasErrors) {
      buf.writeln('Errors:');
      for (final e in errors) {
        buf.writeln('  - $e');
      }
    }
    return buf.toString();
  }
}
