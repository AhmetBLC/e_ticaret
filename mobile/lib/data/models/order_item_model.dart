class OrderItemModel {
  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.variantId,
    required this.quantity,
    this.price,
  });

  final String id;
  final String orderId;
  final String productId;
  final String variantId;
  final int quantity;
  final double? price;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      variantId: json['variant_id'] as String,
      quantity: (json['quantity'] as num).toInt(),
      price: (json['price'] as num?)?.toDouble(),
    );
  }
}
