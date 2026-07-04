class Replacement {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final String modelNumber;
  final String oldSerialNumber;
  final String? newSerialNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String reason;
  final String type;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? notes;

  const Replacement({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.modelNumber,
    required this.oldSerialNumber,
    this.newSerialNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.reason,
    this.type = 'replacement',
    this.status = 'pending',
    required this.createdAt,
    this.completedAt,
    this.notes,
  });

  factory Replacement.fromJson(Map<String, dynamic> json, String id) {
    return Replacement(
      id: id,
      saleId: json['saleId'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      modelNumber: json['modelNumber'] as String? ?? '',
      oldSerialNumber: json['oldSerialNumber'] as String? ?? '',
      newSerialNumber: json['newSerialNumber'] as String?,
      customerId: json['customerId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      type: json['type'] as String? ?? 'replacement',
      status: json['status'] as String? ?? 'pending',
      createdAt: (json['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      completedAt: (json['completedAt'] as dynamic)?.toDate(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'saleId': saleId,
      'productId': productId,
      'productName': productName,
      'modelNumber': modelNumber,
      'oldSerialNumber': oldSerialNumber,
      'newSerialNumber': newSerialNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'reason': reason,
      'type': type,
      'status': status,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'notes': notes,
    };
  }

  Replacement copyWith({
    String? id,
    String? saleId,
    String? productId,
    String? productName,
    String? modelNumber,
    String? oldSerialNumber,
    String? newSerialNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? reason,
    String? type,
    String? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? notes,
  }) {
    return Replacement(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      modelNumber: modelNumber ?? this.modelNumber,
      oldSerialNumber: oldSerialNumber ?? this.oldSerialNumber,
      newSerialNumber: newSerialNumber ?? this.newSerialNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      reason: reason ?? this.reason,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }
}
