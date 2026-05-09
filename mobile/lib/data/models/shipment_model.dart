class ShipmentModel {
  const ShipmentModel({
    required this.id,
    required this.orderId,
    required this.swapId,
    required this.trackingNumber,
    required this.status,
    required this.carrier,
    this.estimatedDelivery,
    this.senderName,
    this.receiverName,
    this.productTitle,
  });

  final String id;
  final String? orderId;
  final String? swapId;
  final String trackingNumber;
  final String status;
  final String carrier;
  final DateTime? estimatedDelivery;
  final String? senderName;
  final String? receiverName;
  final String? productTitle;

  factory ShipmentModel.fromJson(Map<String, dynamic> json) {
    return ShipmentModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String?,
      swapId: json['swap_id'] as String?,
      trackingNumber: json['tracking_number'] as String,
      status: json['status'] as String,
      carrier: json['carrier'] as String,
      estimatedDelivery: json['estimated_delivery'] != null 
        ? DateTime.parse(json['estimated_delivery'] as String) 
        : null,
      senderName: json['sender_name'] as String?,
      receiverName: json['receiver_name'] as String?,
      productTitle: json['product_title'] as String?,
    );
  }
}
