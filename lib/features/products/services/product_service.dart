import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstock/features/products/models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Product>> getProducts({
    String? categoryId,
    String? searchQuery,
  }) async {
    late Query query;
    final bool filterByCategory =
        categoryId != null && categoryId.isNotEmpty;

    if (filterByCategory) {
      query = _firestore
          .collection('products')
          .where('categoryId', isEqualTo: categoryId);
    } else {
      query = _firestore
          .collection('products')
          .orderBy('createdAt', descending: true);
    }

    final snapshot = await query.get();

    final allSerials = await _firestore.collection('serial_numbers').get();
    final serialStatusCount = <String, Map<String, int>>{};
    for (final doc in allSerials.docs) {
      final d = doc.data();
      final pid = d['productId'] as String? ?? '';
      final status = d['status'] as String? ?? 'available';
      if (pid.isEmpty) continue;
      serialStatusCount.putIfAbsent(pid, () => {'available': 0, 'sold': 0});
      serialStatusCount[pid]![status] =
          (serialStatusCount[pid]![status] ?? 0) + 1;
    }

    final products = <Product>[];

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final hasSerials = serialStatusCount.containsKey(doc.id);
      final isSerialized = (data['isSerialized'] as bool?) ?? hasSerials;
      final product = Product.fromMap({...data, 'isSerialized': isSerialized}, doc.id);
      if (isSerialized) {
        final availableCount =
            serialStatusCount[doc.id]?['available'] ?? 0;
        final soldCount = serialStatusCount[doc.id]?['sold'] ?? 0;
        products.add(product.copyWith(
          availableQuantity: availableCount,
          soldQuantity: soldCount,
        ));
      } else {
        products.add(product);
      }
    }

    if (filterByCategory) {
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final queryLower = searchQuery.toLowerCase();
      return products.where((p) {
        return p.productName.toLowerCase().contains(queryLower) ||
            p.modelNumber.toLowerCase().contains(queryLower) ||
            p.brandName.toLowerCase().contains(queryLower) ||
            p.categoryName.toLowerCase().contains(queryLower);
      }).toList();
    }

    return products;
  }

  Future<Product?> getProductById(String id) async {
    final doc = await _firestore.collection('products').doc(id).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    final hasSerials = (await _firestore
        .collection('serial_numbers')
        .where('productId', isEqualTo: id)
        .limit(1)
        .get()).docs.isNotEmpty;
    final isSerialized = (data['isSerialized'] as bool?) ?? hasSerials;
    final product = Product.fromMap({...data, 'isSerialized': isSerialized}, doc.id);
    if (isSerialized) {
      final availableCount = await _countSerialNumbers(id, 'available');
      final soldCount = await _countSerialNumbers(id, 'sold');
      return product.copyWith(
        availableQuantity: availableCount,
        soldQuantity: soldCount,
      );
    }
    return product;
  }

  Future<void> addProduct(Product product, List<String> serialNumbers) async {
    final batch = _firestore.batch();
    final productRef = _firestore.collection('products').doc();

    if (product.isSerialized) {
      final duplicates = await _findDuplicateSerials(serialNumbers);
      if (duplicates.isNotEmpty) {
        throw Exception(
            'Duplicate serial numbers found: ${duplicates.join(', ')}');
      }
      batch.set(productRef, {
        ...product.toMap(),
        'availableQuantity': serialNumbers.length,
      });
      for (final serial in serialNumbers) {
        final serialRef = _firestore.collection('serial_numbers').doc();
        batch.set(serialRef, {
          'productId': productRef.id,
          'serialNumber': serial.trim(),
          'status': 'available',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } else {
      final addQty = product.availableQuantity;
      batch.set(productRef, {
        ...product.toMap(),
        'availableQuantity': addQty,
        'soldQuantity': 0,
      });
    }

    await batch.commit();
  }

  Future<void> updateProduct(Product product) async {
    await _firestore
        .collection('products')
        .doc(product.id)
        .update(product.toMap());
  }

  Future<void> deleteProduct(String id) async {
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
  }

  Future<List<Map<String, dynamic>>> getSerialNumbers(String productId) async {
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
      };
    }).toList();
  }

  Future<Map<String, dynamic>> getStockDetails(String productId) async {
    final productDoc =
        await _firestore.collection('products').doc(productId).get();
    final productData = productDoc.data() ?? {};
    final serialNumbers = await getSerialNumbers(productId);
    final hasSerials = serialNumbers.isNotEmpty;
    final isSerialized = (productData['isSerialized'] as bool?) ?? hasSerials;

    if (!isSerialized) {
      return {
        'available': (productData['availableQuantity'] as num?)?.toInt() ?? 0,
        'sold': (productData['soldQuantity'] as num?)?.toInt() ?? 0,
        'total': ((productData['availableQuantity'] as num?)?.toInt() ?? 0) +
            ((productData['soldQuantity'] as num?)?.toInt() ?? 0),
        'serialNumbers': <Map<String, dynamic>>[],
      };
    }

    final available =
        serialNumbers.where((s) => s['status'] == 'available').length;
    final sold = serialNumbers.where((s) => s['status'] == 'sold').length;

    return {
      'available': available,
      'sold': sold,
      'total': serialNumbers.length,
      'serialNumbers': serialNumbers,
    };
  }

  Future<int> _countSerialNumbers(String productId, String status) async {
    final snapshot = await _firestore
        .collection('serial_numbers')
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: status)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<void> addSerialNumbers(
      String productId, List<String> serialNumbers) async {
    final duplicates = await _findDuplicateSerials(serialNumbers);
    if (duplicates.isNotEmpty) {
      throw Exception(
          'Duplicate serial numbers found: ${duplicates.join(', ')}');
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
  }

  Future<void> deleteSerialNumber(String serialId) async {
    await _firestore.collection('serial_numbers').doc(serialId).delete();
  }

  Future<List<String>> _findDuplicateSerials(List<String> serials) async {
    final trimmed = serials.map((s) => s.trim()).toSet();
    if (trimmed.length != serials.length) {
      final duplicates = <String>{};
      final seen = <String>{};
      for (final s in serials.map((s) => s.trim())) {
        if (!seen.add(s)) duplicates.add(s);
      }
      return duplicates.toList();
    }

    final duplicateFound = <String>[];
    for (final serial in trimmed) {
      final snapshot = await _firestore
          .collection('serial_numbers')
          .where('serialNumber', isEqualTo: serial)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        duplicateFound.add(serial);
      }
    }
    return duplicateFound;
  }
}
