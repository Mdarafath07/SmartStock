class SalesReport {
  final DateTime date;
  final double totalSales;
  final double totalProfit;
  final int totalTransactions;
  final int totalProductsSold;

  const SalesReport({
    required this.date,
    this.totalSales = 0.0,
    this.totalProfit = 0.0,
    this.totalTransactions = 0,
    this.totalProductsSold = 0,
  });

  factory SalesReport.fromJson(Map<String, dynamic> json) {
    return SalesReport(
      date: DateTime.parse(json['date'] as String? ?? DateTime.now().toIso8601String()),
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (json['totalProfit'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: (json['totalTransactions'] as num?)?.toInt() ?? 0,
      totalProductsSold: (json['totalProductsSold'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalSales': totalSales,
      'totalProfit': totalProfit,
      'totalTransactions': totalTransactions,
      'totalProductsSold': totalProductsSold,
    };
  }

  SalesReport copyWith({
    DateTime? date,
    double? totalSales,
    double? totalProfit,
    int? totalTransactions,
    int? totalProductsSold,
  }) {
    return SalesReport(
      date: date ?? this.date,
      totalSales: totalSales ?? this.totalSales,
      totalProfit: totalProfit ?? this.totalProfit,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      totalProductsSold: totalProductsSold ?? this.totalProductsSold,
    );
  }
}

class CategorySales {
  final String categoryName;
  final String categoryId;
  final double totalSales;
  final int totalProducts;

  const CategorySales({
    this.categoryName = '',
    this.categoryId = '',
    this.totalSales = 0.0,
    this.totalProducts = 0,
  });

  factory CategorySales.fromJson(Map<String, dynamic> json) {
    return CategorySales(
      categoryName: json['categoryName'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0.0,
      totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryName': categoryName,
      'categoryId': categoryId,
      'totalSales': totalSales,
      'totalProducts': totalProducts,
    };
  }
}

class TopSellingProductReport {
  final String productId;
  final String productName;
  final String modelNumber;
  final String imageUrl;
  final int quantitySold;
  final double totalRevenue;

  const TopSellingProductReport({
    this.productId = '',
    this.productName = '',
    this.modelNumber = '',
    this.imageUrl = '',
    this.quantitySold = 0,
    this.totalRevenue = 0.0,
  });

  factory TopSellingProductReport.fromJson(Map<String, dynamic> json) {
    return TopSellingProductReport(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      modelNumber: json['modelNumber'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      quantitySold: (json['quantitySold'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'modelNumber': modelNumber,
      'imageUrl': imageUrl,
      'quantitySold': quantitySold,
      'totalRevenue': totalRevenue,
    };
  }
}
