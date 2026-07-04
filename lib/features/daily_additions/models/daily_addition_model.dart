class DailyAddition {
  final String id;
  final String productName;
  final String categoryName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String notes;
  final DateTime dateAdded;
  final DateTime createdAt;
  final bool reminderEnabled;
  final DateTime? reminderTime;

  DailyAddition({
    this.id = '',
    this.productName = '',
    this.categoryName = '',
    this.quantity = 0,
    this.unitPrice = 0.0,
    this.totalPrice = 0.0,
    this.notes = '',
    DateTime? dateAdded,
    DateTime? createdAt,
    this.reminderEnabled = false,
    this.reminderTime,
  })  : dateAdded = dateAdded ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  factory DailyAddition.fromJson(Map<String, dynamic> json) {
    return DailyAddition(
      id: json['id'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String? ?? '',
      dateAdded: (json['dateAdded'] as dynamic)?.toDate() ?? DateTime.now(),
      createdAt: (json['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      reminderTime: (json['reminderTime'] as dynamic)?.toDate(),
    );
  }

  factory DailyAddition.fromMap(Map<String, dynamic> map, String id) {
    return DailyAddition(
      id: id,
      productName: map['productName'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String? ?? '',
      dateAdded: (map['dateAdded'] as dynamic)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      reminderEnabled: map['reminderEnabled'] as bool? ?? false,
      reminderTime: (map['reminderTime'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'categoryName': categoryName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'notes': notes,
      'dateAdded': dateAdded,
      'createdAt': createdAt,
      'reminderEnabled': reminderEnabled,
      'reminderTime': reminderTime,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  DailyAddition copyWith({
    String? id,
    String? productName,
    String? categoryName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    String? notes,
    DateTime? dateAdded,
    DateTime? createdAt,
    bool? reminderEnabled,
    DateTime? reminderTime,
  }) {
    return DailyAddition(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      categoryName: categoryName ?? this.categoryName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      dateAdded: dateAdded ?? this.dateAdded,
      createdAt: createdAt ?? this.createdAt,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  @override
  String toString() => productName;
}
