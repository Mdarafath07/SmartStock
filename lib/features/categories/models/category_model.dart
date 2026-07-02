import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String icon;
  final DateTime createdAt;

  const Category({
    this.id = '',
    required this.name,
    this.icon = 'inventory_2_rounded',
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? 'inventory_2_rounded',
      createdAt: (json['createdAt'] as dynamic) is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt'] as String? ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
