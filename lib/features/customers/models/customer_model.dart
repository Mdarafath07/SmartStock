import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final DateTime createdAt;
  final int totalOrders;
  final double lifetimeValue;

  Customer({
    this.id = '',
    this.name = '',
    this.phone = '',
    this.address = '',
    DateTime? createdAt,
    this.totalOrders = 0,
    this.lifetimeValue = 0.0,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Customer.fromJson(Map<String, dynamic> json, String id) {
    return Customer(
      id: id,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalOrders: (json['totalOrders'] as int?) ?? 0,
      lifetimeValue: (json['lifetimeValue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'totalOrders': totalOrders,
      'lifetimeValue': lifetimeValue,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    DateTime? createdAt,
    int? totalOrders,
    double? lifetimeValue,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      totalOrders: totalOrders ?? this.totalOrders,
      lifetimeValue: lifetimeValue ?? this.lifetimeValue,
    );
  }
}
