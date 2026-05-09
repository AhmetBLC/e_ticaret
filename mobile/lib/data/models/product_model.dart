import 'product_variant_model.dart';

class ProductModel {
  const ProductModel({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    required this.userId,
    this.categoryId,
    required this.createdAt,
    required this.isAvailable,
    required this.variants,
    this.imageUrl,
    this.additionalImages = const [],
    this.city,
    this.district,
    this.slug,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.favoriteCount = 0,
    this.isFavorited = false,
  });

  final String id;
  final String title;
  final String? description;
  final double price;
  final String userId;
  final String? categoryId;
  final DateTime createdAt;
  final bool isAvailable;
  final List<ProductVariantModel> variants;
  final String? imageUrl;
  final List<String> additionalImages;
  final String? city;
  final String? district;
  final String? slug;
  final double averageRating;
  final int reviewCount;
  final int favoriteCount;
  final bool isFavorited;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final variantsJson = json['variants'] as List<dynamic>? ?? [];
    final imagesJson = json['additional_images'] as List<dynamic>? ?? [];
    
    return ProductModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      price: _toDouble(json['price']),
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isAvailable: json['is_available'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
      additionalImages: imagesJson.map((e) => e.toString()).toList(),
      city: json['city'] as String?,
      district: json['district'] as String?,
      slug: json['slug'] as String?,
      averageRating: _toDouble(json['average_rating']),
      reviewCount: json['review_count'] as int? ?? 0,
      favoriteCount: json['favorite_count'] as int? ?? 0,
      isFavorited: json['is_favorited'] as bool? ?? false,
      variants: variantsJson
          .map((e) => ProductVariantModel.fromJson(e as Map<String, dynamic>))
          .toList(),
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

  /// Display price: minimum variant price if variants exist, else product price.
  double get displayPrice {
    if (variants.isEmpty) {
      return price;
    }
    return variants
        .map((v) => v.priceOverride ?? price)
        .reduce((a, b) => a < b ? a : b);
  }
}
