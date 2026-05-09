import 'escrow_model.dart';
import 'order_model.dart';
import 'swap_model.dart';

class WorkOrderModel {
  const WorkOrderModel({
    required this.id,
    this.swapId,
    this.orderId,
    required this.status,
    required this.createdAt,
    this.swap,
    this.order,
    this.escrow,
  });

  final String id;
  final String? swapId;
  final String? orderId;
  final String status;
  final DateTime createdAt;
  final SwapModel? swap;
  final OrderModel? order;
  final EscrowModel? escrow;

  factory WorkOrderModel.fromJson(Map<String, dynamic> json) {
    return WorkOrderModel(
      id: json['id'] as String,
      swapId: json['swap_id'] as String?,
      orderId: json['order_id'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      swap: json['swap'] != null
          ? SwapModel.fromJson(json['swap'] as Map<String, dynamic>)
          : null,
      order: json['order'] != null
          ? OrderModel.fromJson(json['order'] as Map<String, dynamic>)
          : null,
      escrow: EscrowModel.tryParse(json['escrow']),
    );
  }

  bool get isPending => status == 'PENDING';
}
