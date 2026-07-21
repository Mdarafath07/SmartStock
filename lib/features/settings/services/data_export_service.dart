import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class DataExportResult {
  final String directoryPath;
  final int fileCount;
  final int totalRows;
  final List<String> errors;

  const DataExportResult({
    required this.directoryPath,
    required this.fileCount,
    required this.totalRows,
    required this.errors,
  });
}

class DataExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DataExportResult> exportAllData() async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final exportDir = await _getExportDirectory(timestamp);

    final configs = _collections;
    final errors = <String>[];
    var fileCount = 0;
    var totalRows = 0;

    for (final config in configs) {
      try {
        final snap = await _firestore
            .collection(config.collection)
            .orderBy('createdAt')
            .get();
        final csv = _buildCsv(config.headers, snap.docs, config.rowMapper);
        final file = File('${exportDir.path}/${config.fileName}.csv');
        await file.writeAsString(csv, flush: true);
        fileCount++;
        totalRows += snap.docs.length;
      } catch (e) {
        errors.add('${config.fileName}: $e');
        final file = File('${exportDir.path}/${config.fileName}.csv');
        await file.writeAsString('Error exporting: $e', flush: true);
        fileCount++;
      }
    }

    return DataExportResult(
      directoryPath: exportDir.path,
      fileCount: fileCount,
      totalRows: totalRows,
      errors: errors,
    );
  }

  Future<Directory> _getExportDirectory(String timestamp) async {
    final paths = <String>[
      '/storage/emulated/0/Download/SmartStock_Export_$timestamp',
    ];
    try {
      final ext = await getExternalStorageDirectory();
      paths.add('${ext!.path}/SmartStock_Export_$timestamp');
    } catch (_) {}
    try {
      final doc = await getApplicationDocumentsDirectory();
      paths.add('${doc.path}/SmartStock_Export_$timestamp');
    } catch (_) {}
    for (final path in paths) {
      try {
        final dir = Directory(path);
        await dir.create(recursive: true);
        return dir;
      } catch (_) {}
    }
    throw Exception('Could not create export directory');
  }

  String _buildCsv(
    List<String> headers,
    List<QueryDocumentSnapshot> docs,
    List<dynamic> Function(Map<String, dynamic> data, String id) rowMapper,
  ) {
    final buf = StringBuffer();
    buf.writeln(headers.map(_escapeCsv).join(','));
    for (final doc in docs) {
      final row = rowMapper(doc.data() as Map<String, dynamic>, doc.id);
      buf.writeln(row.map((v) => _escapeCsv(v.toString())).join(','));
    }
    return buf.toString();
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

class _CollectionExportConfig {
  final String collection;
  final String fileName;
  final List<String> headers;
  final List<dynamic> Function(Map<String, dynamic> data, String id) rowMapper;

  const _CollectionExportConfig({
    required this.collection,
    required this.fileName,
    required this.headers,
    required this.rowMapper,
  });
}

final _collections = [
  _CollectionExportConfig(
    collection: 'products',
    fileName: 'Products',
    headers: const [
      'ID', 'Category ID', 'Category Name', 'Brand Name',
      'Product Name', 'Model Number', 'Image URL', 'Description',
      'Purchase Price', 'Selling Price', 'Warranty Months',
      'Warranty Days', 'Available Quantity', 'Sold Quantity', 'Created At',
    ],
    rowMapper: _mapProduct,
  ),
  _CollectionExportConfig(
    collection: 'categories',
    fileName: 'Categories',
    headers: const ['ID', 'Name', 'Icon', 'Created At'],
    rowMapper: _mapCategory,
  ),
  _CollectionExportConfig(
    collection: 'sales',
    fileName: 'Sales',
    headers: const [
      'ID', 'Product ID', 'Product Name', 'Model Number',
      'Serial Number', 'Serial Number ID', 'Category ID',
      'Customer ID', 'Customer Name', 'Customer Phone',
      'Sale Price', 'Purchase Price', 'Profit', 'Sale Date',
      'Warranty Expiry', 'Created At', 'Image URL', 'Sale Type',
      'Related Sale ID', 'Old Serial', 'Warranty Claimed',
      'New Serial', 'Claim Date', 'Quantity',
    ],
    rowMapper: _mapSale,
  ),
  _CollectionExportConfig(
    collection: 'serial_numbers',
    fileName: 'Serial_Numbers',
    headers: const ['ID', 'Product ID', 'Serial Number', 'Status', 'Sale ID', 'Return Type', 'Created At'],
    rowMapper: _mapSerialNumber,
  ),
  _CollectionExportConfig(
    collection: 'customers',
    fileName: 'Customers',
    headers: const ['ID', 'Name', 'Phone', 'Address', 'Created At', 'Total Orders', 'Lifetime Value'],
    rowMapper: _mapCustomer,
  ),
  _CollectionExportConfig(
    collection: 'daily_additions',
    fileName: 'Daily_Additions',
    headers: const [
      'ID', 'Product Name', 'Category Name', 'Quantity',
      'Unit Price', 'Total Price', 'Notes', 'Date Added',
      'Created At', 'Reminder Enabled', 'Reminder Time',
    ],
    rowMapper: _mapDailyAddition,
  ),
  _CollectionExportConfig(
    collection: 'product_issues',
    fileName: 'Product_Issues',
    headers: const [
      'ID', 'Product ID', 'Product Name', 'Model Number',
      'Serial Number', 'Issue Description', 'Issue Type',
      'Status', 'Customer Name', 'Customer Phone',
      'Created At', 'Resolved At', 'Resolution Notes',
    ],
    rowMapper: _mapProductIssue,
  ),
  _CollectionExportConfig(
    collection: 'replacements',
    fileName: 'Replacements',
    headers: const [
      'ID', 'Sale ID', 'Product ID', 'Product Name',
      'Model Number', 'Old Serial', 'New Serial',
      'Customer ID', 'Customer Name', 'Customer Phone',
      'Reason', 'Type', 'Status', 'Created At',
      'Completed At', 'Notes',
    ],
    rowMapper: _mapReplacement,
  ),
  _CollectionExportConfig(
    collection: 'warranty',
    fileName: 'Warranties',
    headers: const [
      'ID', 'Sale ID', 'Product ID', 'Product Name',
      'Model Number', 'Serial Number', 'Customer ID',
      'Customer Name', 'Customer Phone', 'Purchase Date',
      'Expiry Date', 'Warranty Months', 'Image URL',
      'Sale Price', 'Warranty Claimed', 'Related Sale ID',
      'New Serial', 'Sale Type', 'Old Serial',
      'Old Purchase Date', 'Claim Date',
    ],
    rowMapper: _mapWarranty,
  ),
];

List<dynamic> _mapProduct(Map<String, dynamic> d, String id) => [
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
  _formatStaticDate(d['createdAt']),
];

List<dynamic> _mapCategory(Map<String, dynamic> d, String id) => [
  id,
  d['name'] ?? '',
  d['icon'] ?? '',
  _formatStaticDate(d['createdAt']),
];

List<dynamic> _mapSale(Map<String, dynamic> d, String id) => [
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
  _formatStaticDate(d['saleDate']),
  _formatStaticDate(d['warrantyExpiryDate']),
  _formatStaticDate(d['createdAt']),
  d['imageUrl'] ?? '',
  d['saleType'] ?? 'normal',
  d['relatedSaleId'] ?? '',
  d['oldSerialNumber'] ?? '',
  d['warrantyClaimed'] == true ? 'Yes' : 'No',
  d['newSerialNumber'] ?? '',
  _formatStaticDate(d['claimDate']),
  (d['quantity'] as num?)?.toInt() ?? 1,
];

List<dynamic> _mapSerialNumber(Map<String, dynamic> d, String id) => [
  id,
  d['productId'] ?? '',
  d['serialNumber'] ?? '',
  d['status'] ?? 'available',
  d['saleId'] ?? '',
  d['returnType'] ?? '',
  _formatStaticDate(d['createdAt']),
];

List<dynamic> _mapCustomer(Map<String, dynamic> d, String id) => [
  id,
  d['name'] ?? '',
  d['phone'] ?? '',
  d['address'] ?? '',
  _formatStaticDate(d['createdAt']),
  (d['totalOrders'] as num?)?.toInt() ?? 0,
  (d['lifetimeValue'] as num?)?.toDouble() ?? 0,
];

List<dynamic> _mapDailyAddition(Map<String, dynamic> d, String id) => [
  id,
  d['productName'] ?? '',
  d['categoryName'] ?? '',
  (d['quantity'] as num?)?.toInt() ?? 0,
  (d['unitPrice'] as num?)?.toDouble() ?? 0,
  (d['totalPrice'] as num?)?.toDouble() ?? 0,
  d['notes'] ?? '',
  _formatStaticDate(d['dateAdded']),
  _formatStaticDate(d['createdAt']),
  d['reminderEnabled'] == true ? 'Yes' : 'No',
  _formatStaticDate(d['reminderTime']),
];

List<dynamic> _mapProductIssue(Map<String, dynamic> d, String id) => [
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
  _formatStaticDate(d['createdAt']),
  _formatStaticDate(d['resolvedAt']),
  d['resolutionNotes'] ?? '',
];

List<dynamic> _mapReplacement(Map<String, dynamic> d, String id) => [
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
  _formatStaticDate(d['createdAt']),
  _formatStaticDate(d['completedAt']),
  d['notes'] ?? '',
];

List<dynamic> _mapWarranty(Map<String, dynamic> d, String id) => [
  id,
  d['saleId'] ?? id,
  d['productId'] ?? '',
  d['productName'] ?? '',
  d['modelNumber'] ?? '',
  d['serialNumber'] ?? '',
  d['customerId'] ?? '',
  d['customerName'] ?? '',
  d['customerPhone'] ?? '',
  _formatStaticDate(d['purchaseDate'] ?? d['saleDate']),
  _formatStaticDate(d['expiryDate'] ?? d['warrantyExpiryDate']),
  (d['warrantyMonths'] as num?)?.toInt() ?? 0,
  d['imageUrl'] ?? '',
  (d['salePrice'] as num?)?.toDouble() ?? 0,
  d['warrantyClaimed'] == true ? 'Yes' : 'No',
  d['relatedSaleId'] ?? '',
  d['newSerialNumber'] ?? '',
  d['saleType'] ?? 'normal',
  d['oldSerialNumber'] ?? '',
  _formatStaticDate(d['oldPurchaseDate']),
  _formatStaticDate(d['claimDate']),
];

String _formatStaticDate(dynamic date) {
  if (date == null) return '';
  if (date is Timestamp) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date.toDate());
  }
  if (date is DateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }
  return date.toString();
}
