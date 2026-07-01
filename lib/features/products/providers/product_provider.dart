import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstock/features/products/models/product_model.dart';

class DuplicateSerialInfo {
  final String serialNumber;
  final String existingProductId;
  final String existingProductName;
  final String existingProductModel;
  final String status;
  final DateTime createdAt;
  final String? saleId;
  final DateTime? saleDate;
  final String? customerName;
  final String? customerPhone;
  final double? salePrice;

  DuplicateSerialInfo({
    required this.serialNumber,
    required this.existingProductId,
    required this.existingProductName,
    required this.existingProductModel,
    required this.status,
    required this.createdAt,
    this.saleId,
    this.saleDate,
    this.customerName,
    this.customerPhone,
    this.salePrice,
  });
}

class DuplicateSerialException implements Exception {
  final List<DuplicateSerialInfo> duplicates;
  DuplicateSerialException(this.duplicates);
}

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _subscription;

  List<Product> _products = [];
  List<Product> get products => _products;

  Product? _selectedProduct;
  Product? get selectedProduct => _selectedProduct;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void loadProducts({String? categoryId}) {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    final bool filterByCategory =
        categoryId != null && categoryId.isNotEmpty;
    Query query = _firestore.collection('products');
    if (filterByCategory) {
      query = query.where('categoryId', isEqualTo: categoryId);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    _subscription = query.snapshots().listen(
      (snapshot) async {
        final products = snapshot.docs
            .map((doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        final enriched = await _enrichWithStockCounts(products);
        _products = enriched;
        if (filterByCategory) {
          _products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<List<Product>> _enrichWithStockCounts(List<Product> products) async {
    if (products.isEmpty) return products;
    final counts = <String, Map<String, int>>{};
    final results = await Future.wait(products.map((p) async {
      final available = await _countSerialNumbers(p.id, 'available');
      final sold = await _countSerialNumbers(p.id, 'sold');
      return MapEntry(p.id, {'available': available, 'sold': sold});
    }));
    for (final entry in results) {
      counts[entry.key] = entry.value;
    }
    return products.map((p) {
      final c = counts[p.id] ?? {'available': 0, 'sold': 0};
      return p.copyWith(
        availableQuantity: c['available'],
        soldQuantity: c['sold'],
      );
    }).toList();
  }

  Future<void> loadProductById(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('products').doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final product = Product.fromMap(data, doc.id);
        final availableCount = await _countSerialNumbers(id, 'available');
        final soldCount = await _countSerialNumbers(id, 'sold');
        _selectedProduct = product.copyWith(
          availableQuantity: availableCount,
          soldQuantity: soldCount,
        );
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<int> _countSerialNumbers(String productId, String status) async {
    try {
      final snapshot = await _firestore
          .collection('serial_numbers')
          .where('productId', isEqualTo: productId)
          .where('status', isEqualTo: status)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> addProduct(Product product, List<String> serialNumbers) async {
    _isLoading = true;
    notifyListeners();

    try {
      final duplicates = await _findDuplicateSerials(serialNumbers);
      if (duplicates.isNotEmpty) {
        throw DuplicateSerialException(duplicates);
      }

      final batch = _firestore.batch();
      final productRef = _firestore.collection('products').doc();
      final now = FieldValue.serverTimestamp();

      batch.set(productRef, {
        ...product.toMap(),
        'createdAt': now,
        'availableQuantity': serialNumbers.length,
      });

      for (final serial in serialNumbers) {
        final serialRef = _firestore.collection('serial_numbers').doc();
        batch.set(serialRef, {
          'productId': productRef.id,
          'serialNumber': serial,
          'status': 'available',
          'createdAt': now,
        });
      }

      final qty = serialNumbers.length;
      batch.set(_firestore.collection('daily_additions').doc(), {
        'productName': product.productName,
        'categoryName': product.categoryName,
        'quantity': qty,
        'unitPrice': product.purchasePrice,
        'totalPrice': qty * product.purchasePrice,
        'notes': '',
        'dateAdded': now,
        'createdAt': now,
        'reminderEnabled': false,
        'reminderTime': null,
      });

      await batch.commit();
    } on DuplicateSerialException {
      rethrow;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSerialNumbers(
      String productId, List<String> serialNumbers) async {
    _isLoading = true;
    notifyListeners();

    try {
      final duplicates = await _findDuplicateSerials(serialNumbers);
      if (duplicates.isNotEmpty) {
        throw DuplicateSerialException(duplicates);
      }

      final batch = _firestore.batch();
      for (final serial in serialNumbers) {
        final serialRef = _firestore.collection('serial_numbers').doc();
        batch.set(serialRef, {
          'productId': productId,
          'serialNumber': serial.trim(),
          'status': 'available',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      batch.update(_firestore.collection('products').doc(productId), {
        'availableQuantity': FieldValue.increment(serialNumbers.length),
      });
      await batch.commit();
    } on DuplicateSerialException {
      rethrow;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .update(product.toMap());
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      batch.delete(_firestore.collection('products').doc(id));

      final serialSnapshot = await _firestore
          .collection('serial_numbers')
          .where('productId', isEqualTo: id)
          .get();

      for (final doc in serialSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getSerialNumbers(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('serial_numbers')
          .where('productId', isEqualTo: productId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'serialNumber': data['serialNumber'] as String? ?? '',
          'status': data['status'] as String? ?? 'available',
          'saleId': data['saleId'] as String?,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Finds a product by scanning a serial number barcode.
  /// Returns the product and the matching serial number doc, or null.
  Future<(Product, Map<String, dynamic>)?> findProductBySerialNumber(
      String serial) async {
    try {
      final snapshot = await _firestore
          .collection('serial_numbers')
          .where('serialNumber', isEqualTo: serial.trim())
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      final serialData = snapshot.docs.first.data();
      final productId = serialData['productId'] as String? ?? '';
      if (productId.isEmpty) return null;

      final productDoc =
          await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) return null;
      final product = Product.fromMap(
          productDoc.data() as Map<String, dynamic>, productDoc.id);
      final availableCount = await _countSerialNumbers(productId, 'available');
      final soldCount = await _countSerialNumbers(productId, 'sold');
      return (
        product.copyWith(
            availableQuantity: availableCount, soldQuantity: soldCount),
        {
          'id': snapshot.docs.first.id,
          'serialNumber': serialData['serialNumber'] as String? ?? '',
          'status': serialData['status'] as String? ?? 'available',
        },
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<DuplicateSerialInfo>> _findDuplicateSerials(
      List<String> serials) async {
    final trimmed = serials.map((s) => s.trim()).toList();
    final seen = <String>{};
    final duplicateSerials = <String>{};
    for (final s in trimmed) {
      if (!seen.add(s)) duplicateSerials.add(s);
    }

    for (final serial in trimmed) {
      final snapshot = await _firestore
          .collection('serial_numbers')
          .where('serialNumber', isEqualTo: serial)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        duplicateSerials.add(serial);
      }
    }

    if (duplicateSerials.isEmpty) return [];

    final result = <DuplicateSerialInfo>[];
    for (final serial in duplicateSerials) {
      final snapshot = await _firestore
          .collection('serial_numbers')
          .where('serialNumber', isEqualTo: serial)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) continue;
      final data = snapshot.docs.first.data();
      final productId = data['productId'] as String? ?? '';
      final productDoc =
          await _firestore.collection('products').doc(productId).get();
      final productData = productDoc.data() ?? {};

      DateTime? saleDate;
      String? customerName;
      String? customerPhone;
      double? salePrice;
      final saleId = data['saleId'] as String?;
      if (saleId != null && saleId.isNotEmpty) {
        final saleDoc =
            await _firestore.collection('sales').doc(saleId).get();
        if (saleDoc.exists) {
          final saleData = saleDoc.data()!;
          saleDate =
              (saleData['saleDate'] as Timestamp?)?.toDate();
          customerName = saleData['customerName'] as String?;
          customerPhone = saleData['customerPhone'] as String?;
          salePrice = (saleData['salePrice'] as num?)?.toDouble();
        }
      }

      result.add(DuplicateSerialInfo(
        serialNumber: serial,
        existingProductId: productId,
        existingProductName: productData['productName'] as String? ?? 'Unknown',
        existingProductModel: productData['modelNumber'] as String? ?? '',
        status: data['status'] as String? ?? 'available',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        saleId: saleId,
        saleDate: saleDate,
        customerName: customerName,
        customerPhone: customerPhone,
        salePrice: salePrice,
      ));
    }
    return result;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
