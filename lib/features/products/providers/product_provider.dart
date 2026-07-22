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
  static const int _pageSize = 20;

  List<Product> _products = [];
  List<Product> get products => _products;

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  String? _currentCategoryId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _error;
  String? get error => _error;

  int _totalProducts = 0;
  int get totalProducts => _totalProducts;
  int _totalItems = 0;
  int get totalItems => _totalItems;
  int _inStock = 0;
  int get inStock => _inStock;
  int _lowStock = 0;
  int get lowStock => _lowStock;
  int _outOfStock = 0;
  int get outOfStock => _outOfStock;

  Future<void> loadStats({String? categoryId}) async {
    try {
      Query query = _firestore.collection('products');
      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }
      final snapshot = await query.get();
      int totalItems = 0;
      int inStock = 0;
      int lowStock = 0;
      int outOfStock = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final qty = (data['availableQuantity'] as num?)?.toInt() ?? 0;
        totalItems += qty;
        if (qty > 0) inStock++;
        if (qty > 0 && qty <= 5) lowStock++;
        if (qty <= 0) outOfStock++;
      }
      _totalProducts = snapshot.docs.length;
      _totalItems = totalItems;
      _inStock = inStock;
      _lowStock = lowStock;
      _outOfStock = outOfStock;
    } catch (_) {}
  }

  Future<void> loadProducts({String? categoryId, bool refresh = true}) async {
    if (refresh) {
      _isLoading = true;
      _error = null;
      _products = [];
      _lastDoc = null;
      _hasMore = true;
      _currentCategoryId = categoryId;
      notifyListeners();
    }

    try {
      Query query = _firestore.collection('products');
      final filterByCategory = categoryId != null && categoryId.isNotEmpty;
      if (filterByCategory) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }
      query = query.orderBy('createdAt', descending: true);
      query = query.limit(_pageSize);

      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.get();
      final products = snapshot.docs
          .map((doc) =>
              Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      if (refresh) {
        _products = products;
      } else {
        _products = [..._products, ...products];
      }
      _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMore = snapshot.docs.length >= _pageSize;
    } catch (e) {
      if (refresh) _error = e.toString();
    }
    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();

    if (refresh) {
      loadStats(categoryId: categoryId);
    }
  }

  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    await loadProducts(categoryId: _currentCategoryId, refresh: false);
  }

  Future<void> loadProductById(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('products').doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _selectedProduct = Product.fromMap(data, doc.id);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Product? _selectedProduct;
  Product? get selectedProduct => _selectedProduct;

  Future<String?> checkSerialAvailability(String serialNumber) async {
    try {
      final snap = await _firestore
          .collection('serial_numbers')
          .where('serialNumber', isEqualTo: serialNumber)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return snap.docs.first.data()['status'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<Product?> getFreshProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) return null;
      return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addProduct(Product product, List<String> serialNumbers,
      {DateTime? stockDate}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      final productRef = _firestore.collection('products').doc();
      final now = FieldValue.serverTimestamp();
      final dateAdded = stockDate ?? DateTime.now();

      if (product.isSerialized) {
        final duplicates = await _findDuplicateSerials(serialNumbers);
        if (duplicates.isNotEmpty) {
          throw DuplicateSerialException(duplicates);
        }

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
            'dateAdded': Timestamp.fromDate(dateAdded),
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
          'serialNumbers': serialNumbers,
          'dateAdded': Timestamp.fromDate(dateAdded),
          'createdAt': now,
          'reminderEnabled': false,
          'reminderTime': null,
        });
      } else {
        final addQty = product.availableQuantity;
        batch.set(productRef, {
          ...product.toMap(),
          'createdAt': now,
          'availableQuantity': addQty,
          'soldQuantity': 0,
        });

        batch.set(_firestore.collection('daily_additions').doc(), {
          'productName': product.productName,
          'categoryName': product.categoryName,
          'quantity': addQty,
          'unitPrice': product.purchasePrice,
          'totalPrice': addQty * product.purchasePrice,
          'notes': '',
          'serialNumbers': [],
          'dateAdded': Timestamp.fromDate(dateAdded),
          'createdAt': now,
          'reminderEnabled': false,
          'reminderTime': null,
        });
      }

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
      String productId, List<String> serialNumbers,
      {DateTime? stockDate}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final duplicates = await _findDuplicateSerials(serialNumbers);
      if (duplicates.isNotEmpty) {
        throw DuplicateSerialException(duplicates);
      }

      final productDoc =
          await _firestore.collection('products').doc(productId).get();
      final productData = productDoc.data() ?? {};
      final productName = productData['productName'] as String? ?? 'Unknown';
      final categoryName = productData['categoryName'] as String? ?? '';
      final purchasePrice =
          (productData['purchasePrice'] as num?)?.toDouble() ?? 0.0;
      final qty = serialNumbers.length;
      final dateAdded = stockDate ?? DateTime.now();

      final batch = _firestore.batch();
      for (final serial in serialNumbers) {
        final serialRef = _firestore.collection('serial_numbers').doc();
        batch.set(serialRef, {
          'productId': productId,
          'serialNumber': serial.trim(),
          'status': 'available',
          'createdAt': FieldValue.serverTimestamp(),
          'dateAdded': Timestamp.fromDate(dateAdded),
        });
      }
      batch.update(_firestore.collection('products').doc(productId), {
        'availableQuantity': FieldValue.increment(qty),
      });
      batch.set(_firestore.collection('daily_additions').doc(), {
        'productName': productName,
        'categoryName': categoryName,
        'quantity': qty,
        'unitPrice': purchasePrice,
        'totalPrice': qty * purchasePrice,
        'notes': '',
        'serialNumbers': serialNumbers,
        'dateAdded': Timestamp.fromDate(dateAdded),
        'createdAt': FieldValue.serverTimestamp(),
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

  Future<void> addQuantity(
      String productId, int quantity,
      {DateTime? stockDate}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final productDoc =
          await _firestore.collection('products').doc(productId).get();
      final productData = productDoc.data() ?? {};
      final productName = productData['productName'] as String? ?? 'Unknown';
      final categoryName = productData['categoryName'] as String? ?? '';
      final purchasePrice =
          (productData['purchasePrice'] as num?)?.toDouble() ?? 0.0;
      final dateAdded = stockDate ?? DateTime.now();

      final batch = _firestore.batch();
      batch.update(_firestore.collection('products').doc(productId), {
        'availableQuantity': FieldValue.increment(quantity),
      });
      batch.set(_firestore.collection('daily_additions').doc(), {
        'productName': productName,
        'categoryName': categoryName,
        'quantity': quantity,
        'unitPrice': purchasePrice,
        'totalPrice': quantity * purchasePrice,
        'notes': '',
        'serialNumbers': [],
        'dateAdded': Timestamp.fromDate(dateAdded),
        'createdAt': FieldValue.serverTimestamp(),
        'reminderEnabled': false,
        'reminderTime': null,
      });
      await batch.commit();
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
      return (
        product,
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

  Future<DuplicateSerialInfo?> checkDuplicateSerial(String serial) async {
    final trimmed = serial.trim();
    if (trimmed.isEmpty) return null;

    final snapshot = await _firestore
        .collection('serial_numbers')
        .where('serialNumber', isEqualTo: trimmed)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final data = snapshot.docs.first.data();
    final productId = data['productId'] as String? ?? '';
    if (productId.isEmpty) return null;

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
        saleDate = (saleData['saleDate'] as Timestamp?)?.toDate();
        customerName = saleData['customerName'] as String?;
        customerPhone = saleData['customerPhone'] as String?;
        salePrice = (saleData['salePrice'] as num?)?.toDouble();
      }
    }

    return DuplicateSerialInfo(
      serialNumber: trimmed,
      existingProductId: productId,
      existingProductName:
          productData['productName'] as String? ?? 'Unknown',
      existingProductModel: productData['modelNumber'] as String? ?? '',
      status: data['status'] as String? ?? 'available',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      saleId: saleId,
      saleDate: saleDate,
      customerName: customerName,
      customerPhone: customerPhone,
      salePrice: salePrice,
    );
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
}
