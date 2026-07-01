class Product {
  final String id;
  final String categoryId;
  final String categoryName;
  final String brandName;
  final String productName;
  final String modelNumber;
  final String imageUrl;
  final String description;
  final double purchasePrice;
  final double sellingPrice;
  final int warrantyMonths;
  final int warrantyDays;
  final int availableQuantity;
  final int soldQuantity;
  final DateTime createdAt;

  Product({
    this.id = '',
    this.categoryId = '',
    this.categoryName = '',
    this.brandName = '',
    this.productName = '',
    this.modelNumber = '',
    this.imageUrl = '',
    this.description = '',
    this.purchasePrice = 0.0,
    this.sellingPrice = 0.0,
    this.warrantyMonths = 0,
    this.warrantyDays = 0,
    this.availableQuantity = 0,
    this.soldQuantity = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      brandName: json['brandName'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      modelNumber: json['modelNumber'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      warrantyMonths: (json['warrantyMonths'] as num?)?.toInt() ?? 0,
      warrantyDays: (json['warrantyDays'] as num?)?.toInt() ?? 0,
      availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
      soldQuantity: (json['soldQuantity'] as num?)?.toInt() ?? 0,
      createdAt: (json['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      brandName: map['brandName'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      modelNumber: map['modelNumber'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      description: map['description'] as String? ?? '',
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      warrantyMonths: (map['warrantyMonths'] as num?)?.toInt() ?? 0,
      warrantyDays: (map['warrantyDays'] as num?)?.toInt() ?? 0,
      availableQuantity: (map['availableQuantity'] as num?)?.toInt() ?? 0,
      soldQuantity: (map['soldQuantity'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'brandName': brandName,
      'productName': productName,
      'modelNumber': modelNumber,
      'imageUrl': imageUrl,
      'description': description,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'warrantyMonths': warrantyMonths,
      'warrantyDays': warrantyDays,
      'availableQuantity': availableQuantity,
      'soldQuantity': soldQuantity,
      'createdAt': createdAt,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Product copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    String? brandName,
    String? productName,
    String? modelNumber,
    String? imageUrl,
    String? description,
    double? purchasePrice,
    double? sellingPrice,
    int? warrantyMonths,
    int? warrantyDays,
    int? availableQuantity,
    int? soldQuantity,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      brandName: brandName ?? this.brandName,
      productName: productName ?? this.productName,
      modelNumber: modelNumber ?? this.modelNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      warrantyDays: warrantyDays ?? this.warrantyDays,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      soldQuantity: soldQuantity ?? this.soldQuantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => productName;
}
