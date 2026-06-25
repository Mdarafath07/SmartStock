import 'package:cloud_firestore/cloud_firestore.dart';

class Warranty {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final String modelNumber;
  final String serialNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final int warrantyMonths;
  final String imageUrl;
  final double salePrice;
  final bool warrantyClaimed;
  final String? relatedSaleId;
  final String? newSerialNumber;
  final String saleType;
  final String? oldSerialNumber;
  final DateTime? oldPurchaseDate;
  final DateTime? claimDate;

  const Warranty({
    this.id = '',
    this.saleId = '',
    this.productId = '',
    this.productName = '',
    this.modelNumber = '',
    this.serialNumber = '',
    this.customerId = '',
    this.customerName = '',
    this.customerPhone = '',
    required this.purchaseDate,
    required this.expiryDate,
    this.warrantyMonths = 0,
    this.imageUrl = '',
    this.salePrice = 0.0,
    this.warrantyClaimed = false,
    this.relatedSaleId,
    this.newSerialNumber,
    this.saleType = 'normal',
    this.oldSerialNumber,
    this.oldPurchaseDate,
    this.claimDate,
  });

  bool get isActive => expiryDate.isAfter(DateTime.now()) && !warrantyClaimed;
  bool get isClaimable => isActive;

  factory Warranty.fromSale({
    required String saleId,
    required String productId,
    required String productName,
    required String modelNumber,
    required String serialNumber,
    required String customerId,
    required String customerName,
    required String customerPhone,
    required DateTime purchaseDate,
    required DateTime expiryDate,
    int warrantyMonths = 0,
    String imageUrl = '',
    double salePrice = 0.0,
  }) {
    return Warranty(
      id: saleId,
      saleId: saleId,
      productId: productId,
      productName: productName,
      modelNumber: modelNumber,
      serialNumber: serialNumber,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      purchaseDate: purchaseDate,
      expiryDate: expiryDate,
      warrantyMonths: warrantyMonths,
      imageUrl: imageUrl,
      salePrice: salePrice,
    );
  }

  factory Warranty.fromJson(Map<String, dynamic> json, String id) {
    return Warranty(
      id: id,
      saleId: json['saleId'] as String? ?? id,
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      modelNumber: json['modelNumber'] as String? ?? '',
      serialNumber: json['serialNumber'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      purchaseDate: (json['purchaseDate'] as Timestamp?)?.toDate() ??
          (json['saleDate'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      expiryDate: (json['expiryDate'] as Timestamp?)?.toDate() ??
          (json['warrantyExpiryDate'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      warrantyMonths: (json['warrantyMonths'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0.0,
      warrantyClaimed: json['warrantyClaimed'] as bool? ?? false,
      relatedSaleId: json['relatedSaleId'] as String?,
      newSerialNumber: json['newSerialNumber'] as String?,
      saleType: json['saleType'] as String? ?? 'normal',
      oldSerialNumber: json['oldSerialNumber'] as String?,
      oldPurchaseDate: (json['oldPurchaseDate'] as Timestamp?)?.toDate(),
      claimDate: (json['claimDate'] as Timestamp?)?.toDate(),
    );
  }

  int get calculatedMonths {
    if (warrantyMonths > 0) return warrantyMonths;
    final diff = expiryDate.difference(purchaseDate).inDays;
    return (diff / 30).round();
  }

  Map<String, dynamic> toJson() {
    return {
      'saleId': saleId,
      'productId': productId,
      'productName': productName,
      'modelNumber': modelNumber,
      'serialNumber': serialNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'warrantyMonths': warrantyMonths,
      'imageUrl': imageUrl,
      'salePrice': salePrice,
      'warrantyClaimed': warrantyClaimed,
      'relatedSaleId': relatedSaleId,
      'newSerialNumber': newSerialNumber,
      'saleType': saleType,
      'oldSerialNumber': oldSerialNumber,
      'oldPurchaseDate': oldPurchaseDate != null ? Timestamp.fromDate(oldPurchaseDate!) : null,
      'claimDate': claimDate != null ? Timestamp.fromDate(claimDate!) : null,
    };
  }

  Warranty copyWith({
    String? id,
    String? saleId,
    String? productId,
    String? productName,
    String? modelNumber,
    String? serialNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    int? warrantyMonths,
    String? imageUrl,
    double? salePrice,
    bool? warrantyClaimed,
    String? relatedSaleId,
    String? newSerialNumber,
    String? saleType,
    String? oldSerialNumber,
    DateTime? oldPurchaseDate,
    DateTime? claimDate,
  }) {
    return Warranty(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      modelNumber: modelNumber ?? this.modelNumber,
      serialNumber: serialNumber ?? this.serialNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      imageUrl: imageUrl ?? this.imageUrl,
      salePrice: salePrice ?? this.salePrice,
      warrantyClaimed: warrantyClaimed ?? this.warrantyClaimed,
      relatedSaleId: relatedSaleId ?? this.relatedSaleId,
      newSerialNumber: newSerialNumber ?? this.newSerialNumber,
      saleType: saleType ?? this.saleType,
      oldSerialNumber: oldSerialNumber ?? this.oldSerialNumber,
      oldPurchaseDate: oldPurchaseDate ?? this.oldPurchaseDate,
      claimDate: claimDate ?? this.claimDate,
    );
  }
}
