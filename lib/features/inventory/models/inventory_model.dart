import 'package:smartstock/core/constants/app_constants.dart';

class InventoryItem {
  final String productId;
  final String productName;
  final String categoryName;
  final String modelNumber;
  final String imageUrl;
  final int availableStock;
  final int soldStock;
  final String stockStatus;

  const InventoryItem({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.modelNumber,
    this.imageUrl = '',
    this.availableStock = 0,
    this.soldStock = 0,
    this.stockStatus = 'out_of_stock',
  });

  InventoryItem copyWith({
    String? productId,
    String? productName,
    String? categoryName,
    String? modelNumber,
    String? imageUrl,
    int? availableStock,
    int? soldStock,
    String? stockStatus,
  }) {
    return InventoryItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      categoryName: categoryName ?? this.categoryName,
      modelNumber: modelNumber ?? this.modelNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      availableStock: availableStock ?? this.availableStock,
      soldStock: soldStock ?? this.soldStock,
      stockStatus: stockStatus ?? this.stockStatus,
    );
  }

  static String computeStockStatus(int available) {
    if (available == 0) return 'out_of_stock';
    if (available <= AppConstants.lowStockThreshold) return 'low_stock';
    if (available >= AppConstants.overstockThreshold) return 'overstock';
    return 'in_stock';
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'categoryName': categoryName,
      'modelNumber': modelNumber,
      'imageUrl': imageUrl,
      'availableStock': availableStock,
      'soldStock': soldStock,
      'stockStatus': stockStatus,
    };
  }
}
