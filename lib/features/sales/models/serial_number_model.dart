import 'package:cloud_firestore/cloud_firestore.dart';

class SerialNumber {
  final String id;
  final String productId;
  final String serialNumber;
  final String status;
  final String? saleId;
  final String? returnType;
  final DateTime createdAt;

  SerialNumber({
    this.id = '',
    this.productId = '',
    this.serialNumber = '',
    this.status = 'available',
    this.saleId,
    this.returnType,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SerialNumber.fromJson(Map<String, dynamic> json, String id) {
    return SerialNumber(
      id: id,
      productId: json['productId'] as String? ?? '',
      serialNumber: json['serialNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'available',
      saleId: json['saleId'] as String?,
      returnType: json['returnType'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'serialNumber': serialNumber,
      'status': status,
      'saleId': saleId,
      'returnType': returnType,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isAvailable => status == 'available';
  bool get isWarrantyReturned => returnType == 'warranty';
}
