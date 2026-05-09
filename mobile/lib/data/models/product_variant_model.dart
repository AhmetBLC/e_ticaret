class ProductVariantModel {
  const ProductVariantModel({
    required this.id,
    required this.productId,
    required this.name,
    this.priceOverride,
    required this.stockQuantity,
  });

  final String id;
  final String productId;
  final String name;
  final double? priceOverride;
  final int stockQuantity;

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      name: json['name'] as String,
      priceOverride: json['price_override'] != null ? _toDouble(json['price_override']) : null,
      stockQuantity: (json['stock_quantity'] as num? ?? 0).toInt(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) {
      return 0;
    }
    if (v is num) {
      return v.toDouble();
    }
    return double.tryParse(v.toString()) ?? 0;
  }
}
