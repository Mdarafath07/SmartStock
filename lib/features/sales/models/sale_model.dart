import 'package:cloud_firestore/cloud_firestore.dart';

class Sale {
  final String id;
  final String productId;
  final String productName;
  final String modelNumber;
  final String serialNumber;
  final String serialNumberId;
  final String categoryId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final double salePrice;
  final double purchasePrice;
  final double profit;
  final DateTime saleDate;
  final DateTime warrantyExpiryDate;
  final DateTime createdAt;
  final String imageUrl;
  final String saleType;
  final String? relatedSaleId;
  final String? oldSerialNumber;
  final bool warrantyClaimed;
  final String? newSerialNumber;
  final DateTime? claimDate;

  Sale({
    this.id = '',
    this.productId = '',
    this.productName = '',
    this.modelNumber = '',
    this.serialNumber = '',
    this.serialNumberId = '',
    this.categoryId = '',
    this.customerId = '',
    this.customerName = '',
    this.customerPhone = '',
    this.salePrice = 0.0,
    this.purchasePrice = 0.0,
    this.profit = 0.0,
    DateTime? saleDate,
    DateTime? warrantyExpiryDate,
    DateTime? createdAt,
    this.imageUrl = '',
    this.saleType = 'normal',
    this.relatedSaleId,
    this.oldSerialNumber,
    this.warrantyClaimed = false,
    this.newSerialNumber,
    this.claimDate,
  })  : saleDate = saleDate ?? DateTime.now(),
        warrantyExpiryDate = warrantyExpiryDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  bool get isReplacement => saleType == 'replacement';
  bool get isWarrantyClaim => saleType == 'warranty_claim';
  bool get isWarrantyClaimable =>
      saleType == 'normal' && warrantyExpiryDate.isAfter(DateTime.now()) && !warrantyClaimed;

  factory Sale.fromJson(Map<String, dynamic> json, String id) {
    return Sale(
      id: id,
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      modelNumber: json['modelNumber'] as String? ?? '',
      serialNumber: json['serialNumber'] as String? ?? '',
      serialNumberId: json['serialNumberId'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
      saleDate: (json['saleDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      warrantyExpiryDate:
          (json['warrantyExpiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: json['imageUrl'] as String? ?? '',
      saleType: json['saleType'] as String? ?? 'normal',
      relatedSaleId: json['relatedSaleId'] as String?,
      oldSerialNumber: json['oldSerialNumber'] as String?,
      warrantyClaimed: json['warrantyClaimed'] as bool? ?? false,
      newSerialNumber: json['newSerialNumber'] as String?,
      claimDate: (json['claimDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'modelNumber': modelNumber,
      'serialNumber': serialNumber,
      'serialNumberId': serialNumberId,
      'categoryId': categoryId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'salePrice': salePrice,
      'purchasePrice': purchasePrice,
      'profit': profit,
      'saleDate': Timestamp.fromDate(saleDate),
      'warrantyExpiryDate': Timestamp.fromDate(warrantyExpiryDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
      'saleType': saleType,
      'relatedSaleId': relatedSaleId,
      'oldSerialNumber': oldSerialNumber,
      'warrantyClaimed': warrantyClaimed,
      'newSerialNumber': newSerialNumber,
      'claimDate': claimDate != null ? Timestamp.fromDate(claimDate!) : null,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  Sale copyWith({
    String? id,
    String? productId,
    String? productName,
    String? modelNumber,
    String? serialNumber,
    String? serialNumberId,
    String? categoryId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    double? salePrice,
    double? purchasePrice,
    double? profit,
    DateTime? saleDate,
    DateTime? warrantyExpiryDate,
    DateTime? createdAt,
    String? imageUrl,
    String? saleType,
    String? relatedSaleId,
    String? oldSerialNumber,
    bool? warrantyClaimed,
    String? newSerialNumber,
    DateTime? claimDate,
  }) {
    return Sale(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      modelNumber: modelNumber ?? this.modelNumber,
      serialNumber: serialNumber ?? this.serialNumber,
      serialNumberId: serialNumberId ?? this.serialNumberId,
      categoryId: categoryId ?? this.categoryId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      salePrice: salePrice ?? this.salePrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      profit: profit ?? this.profit,
      saleDate: saleDate ?? this.saleDate,
      warrantyExpiryDate: warrantyExpiryDate ?? this.warrantyExpiryDate,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      saleType: saleType ?? this.saleType,
      relatedSaleId: relatedSaleId ?? this.relatedSaleId,
      oldSerialNumber: oldSerialNumber ?? this.oldSerialNumber,
      warrantyClaimed: warrantyClaimed ?? this.warrantyClaimed,
      newSerialNumber: newSerialNumber ?? this.newSerialNumber,
      claimDate: claimDate ?? this.claimDate,
    );
  }
}
