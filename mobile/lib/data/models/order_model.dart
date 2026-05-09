import 'order_item_model.dart';

class OrderModel {
  const OrderModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.items,
    this.trackingNumber,
    this.cargoStatus,
  });

  final String id;
  final String userId;
  final String status;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  /// Set when order moves to `SHIPPED` (cargo simulation).
  final String? trackingNumber;
  final String? cargoStatus;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      trackingNumber: json['tracking_number'] as String?,
      cargoStatus: json['cargo_status'] as String?,
      items: itemsJson
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
