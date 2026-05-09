class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.title,
    this.price,
  });

  final String id;
  final String title;
  final double? price;

  static ProductSummary? tryParse(dynamic v) {
    if (v is! Map<String, dynamic>) {
      return null;
    }
    return ProductSummary(
      id: v['id'] as String,
      title: v['title'] as String,
      price: (v['price'] as num?)?.toDouble(),
    );
  }
}
