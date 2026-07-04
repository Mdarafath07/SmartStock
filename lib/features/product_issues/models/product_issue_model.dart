class ProductIssue {
  final String id;
  final String productId;
  final String productName;
  final String modelNumber;
  final String serialNumber;
  final String issueDescription;
  final String issueType;
  final String status;
  final String? customerName;
  final String? customerPhone;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;

  const ProductIssue({
    required this.id,
    required this.productId,
    required this.productName,
    required this.modelNumber,
    required this.serialNumber,
    required this.issueDescription,
    this.issueType = 'other',
    this.status = 'open',
    this.customerName,
    this.customerPhone,
    required this.createdAt,
    this.resolvedAt,
    this.resolutionNotes,
  });

  factory ProductIssue.fromJson(Map<String, dynamic> json, String id) {
    return ProductIssue(
      id: id,
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      modelNumber: json['modelNumber'] as String? ?? '',
      serialNumber: json['serialNumber'] as String? ?? '',
      issueDescription: json['issueDescription'] as String? ?? '',
      issueType: json['issueType'] as String? ?? 'other',
      status: json['status'] as String? ?? 'open',
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      createdAt: (json['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      resolvedAt: (json['resolvedAt'] as dynamic)?.toDate(),
      resolutionNotes: json['resolutionNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'modelNumber': modelNumber,
      'serialNumber': serialNumber,
      'issueDescription': issueDescription,
      'issueType': issueType,
      'status': status,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'createdAt': createdAt,
      'resolvedAt': resolvedAt,
      'resolutionNotes': resolutionNotes,
    };
  }

  ProductIssue copyWith({
    String? id,
    String? productId,
    String? productName,
    String? modelNumber,
    String? serialNumber,
    String? issueDescription,
    String? issueType,
    String? status,
    String? customerName,
    String? customerPhone,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolutionNotes,
  }) {
    return ProductIssue(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      modelNumber: modelNumber ?? this.modelNumber,
      serialNumber: serialNumber ?? this.serialNumber,
      issueDescription: issueDescription ?? this.issueDescription,
      issueType: issueType ?? this.issueType,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
    );
  }
}
