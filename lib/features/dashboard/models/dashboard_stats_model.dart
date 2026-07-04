class DashboardStats {
  final int totalCategories;
  final int totalProducts;
  final int totalAvailableStock;
  final double todaySalesAmount;
  final double todayProfit;
  final int todaySoldProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final List<TopSellingProduct> topSellingProducts;
  final List<ProductSummary> mostStockedProducts;
  final List<ProductSummary> recentlyAddedProducts;
  final List<ProductSummary> recentlySoldProducts;
  final List<double> dailySales;
  final List<double> dailyProfit;

  const DashboardStats({
    this.totalCategories = 0,
    this.totalProducts = 0,
    this.totalAvailableStock = 0,
    this.todaySalesAmount = 0.0,
    this.todayProfit = 0.0,
    this.todaySoldProducts = 0,
    this.lowStockProducts = 0,
    this.outOfStockProducts = 0,
    this.topSellingProducts = const [],
    this.mostStockedProducts = const [],
    this.recentlyAddedProducts = const [],
    this.recentlySoldProducts = const [],
    this.dailySales = const [],
    this.dailyProfit = const [],
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalCategories: (json['totalCategories'] as num?)?.toInt() ?? 0,
      totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
      totalAvailableStock:
          (json['totalAvailableStock'] as num?)?.toInt() ?? 0,
      todaySalesAmount: (json['todaySalesAmount'] as num?)?.toDouble() ?? 0.0,
      todayProfit: (json['todayProfit'] as num?)?.toDouble() ?? 0.0,
      todaySoldProducts: (json['todaySoldProducts'] as num?)?.toInt() ?? 0,
      lowStockProducts: (json['lowStockProducts'] as num?)?.toInt() ?? 0,
      outOfStockProducts: (json['outOfStockProducts'] as num?)?.toInt() ?? 0,
      topSellingProducts:
          (json['topSellingProducts'] as List<dynamic>?)
                  ?.map((e) =>
                      TopSellingProduct.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
      mostStockedProducts:
          (json['mostStockedProducts'] as List<dynamic>?)
                  ?.map((e) =>
                      ProductSummary.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
      recentlyAddedProducts:
          (json['recentlyAddedProducts'] as List<dynamic>?)
                  ?.map((e) =>
                      ProductSummary.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
      recentlySoldProducts:
          (json['recentlySoldProducts'] as List<dynamic>?)
                  ?.map((e) =>
                      ProductSummary.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
      dailySales: (json['dailySales'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      dailyProfit: (json['dailyProfit'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCategories': totalCategories,
      'totalProducts': totalProducts,
      'totalAvailableStock': totalAvailableStock,
      'todaySalesAmount': todaySalesAmount,
      'todayProfit': todayProfit,
      'todaySoldProducts': todaySoldProducts,
      'lowStockProducts': lowStockProducts,
      'outOfStockProducts': outOfStockProducts,
      'topSellingProducts': topSellingProducts.map((e) => e.toJson()).toList(),
      'mostStockedProducts': mostStockedProducts.map((e) => e.toJson()).toList(),
      'recentlyAddedProducts':
          recentlyAddedProducts.map((e) => e.toJson()).toList(),
      'recentlySoldProducts':
          recentlySoldProducts.map((e) => e.toJson()).toList(),
      'dailySales': dailySales,
      'dailyProfit': dailyProfit,
    };
  }

  DashboardStats copyWith({
    int? totalCategories,
    int? totalProducts,
    int? totalAvailableStock,
    double? todaySalesAmount,
    double? todayProfit,
    int? todaySoldProducts,
    int? lowStockProducts,
    int? outOfStockProducts,
    List<TopSellingProduct>? topSellingProducts,
    List<ProductSummary>? mostStockedProducts,
    List<ProductSummary>? recentlyAddedProducts,
    List<ProductSummary>? recentlySoldProducts,
    List<double>? dailySales,
    List<double>? dailyProfit,
  }) {
    return DashboardStats(
      totalCategories: totalCategories ?? this.totalCategories,
      totalProducts: totalProducts ?? this.totalProducts,
      totalAvailableStock: totalAvailableStock ?? this.totalAvailableStock,
      todaySalesAmount: todaySalesAmount ?? this.todaySalesAmount,
      todayProfit: todayProfit ?? this.todayProfit,
      todaySoldProducts: todaySoldProducts ?? this.todaySoldProducts,
      lowStockProducts: lowStockProducts ?? this.lowStockProducts,
      outOfStockProducts: outOfStockProducts ?? this.outOfStockProducts,
      topSellingProducts: topSellingProducts ?? this.topSellingProducts,
      mostStockedProducts: mostStockedProducts ?? this.mostStockedProducts,
      recentlyAddedProducts:
          recentlyAddedProducts ?? this.recentlyAddedProducts,
      recentlySoldProducts: recentlySoldProducts ?? this.recentlySoldProducts,
      dailySales: dailySales ?? this.dailySales,
      dailyProfit: dailyProfit ?? this.dailyProfit,
    );
  }
}

class TopSellingProduct {
  final String productId;
  final String productName;
  final String modelNumber;
  final String imageUrl;
  final int totalSold;

  const TopSellingProduct({
    required this.productId,
    required this.productName,
    required this.modelNumber,
    this.imageUrl = '',
    this.totalSold = 0,
  });

  factory TopSellingProduct.fromJson(Map<String, dynamic> json) {
    return TopSellingProduct(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      modelNumber: json['modelNumber'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      totalSold: (json['totalSold'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'modelNumber': modelNumber,
      'imageUrl': imageUrl,
      'totalSold': totalSold,
    };
  }
}

class ProductSummary {
  final String productId;
  final String productName;
  final String modelNumber;
  final String imageUrl;
  final String categoryName;
  final int availableQuantity;
  final int soldCount;
  final DateTime? createdAt;

  const ProductSummary({
    required this.productId,
    required this.productName,
    required this.modelNumber,
    this.imageUrl = '',
    this.categoryName = '',
    this.availableQuantity = 0,
    this.soldCount = 0,
    this.createdAt,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      modelNumber: json['modelNumber'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
      soldCount: (json['soldCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as dynamic)?.toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'modelNumber': modelNumber,
      'imageUrl': imageUrl,
      'categoryName': categoryName,
      'availableQuantity': availableQuantity,
      'soldCount': soldCount,
    };
  }
}
