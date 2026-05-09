import 'package:image_picker/image_picker.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/remote/product_remote_datasource.dart';
import '../models/pagination_model.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remote);

  final ProductRemoteDatasource _remote;

  @override
  Future<({List<ProductModel> products, PaginationModel? pagination})> getProducts({
    int page = 1,
    int limit = 20,
    String? query,
    String? categoryId,
    String? city,
  }) async {
    final data = await _remote.fetchProducts(
      page: page,
      limit: limit,
      query: query,
      categoryId: categoryId,
      city: city,
    );
    final list = data['products'] as List<dynamic>? ?? [];
    final products = list
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
    PaginationModel? pagination;
    if (data['pagination'] != null) {
      pagination = PaginationModel.fromJson(
        data['pagination'] as Map<String, dynamic>,
      );
    }
    return (products: products, pagination: pagination);
  }

  @override
  Future<({List<ProductModel> products, PaginationModel? pagination})> getMyProducts({
    int page = 1,
    int limit = 100,
  }) async {
    final data = await _remote.fetchMyProducts(page: page, limit: limit);
    final list = data['products'] as List<dynamic>? ?? [];
    final products = list
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
    PaginationModel? pagination;
    if (data['pagination'] != null) {
      pagination = PaginationModel.fromJson(
        data['pagination'] as Map<String, dynamic>,
      );
    }
    return (products: products, pagination: pagination);
  }

  @override
  Future<ProductModel> getProduct(String id) async {
    final data = await _remote.fetchProductById(id);
    final productJson = data['product'] as Map<String, dynamic>;
    return ProductModel.fromJson(productJson);
  }

  @override
  Future<ProductModel> createListing({
    required String title,
    String? description,
    required double price,
    String? imageUrl,
    String? city,
    String? district,
    String? categoryId,
    List<Map<String, dynamic>>? variants,
    List<String>? additionalImages,
  }) async {
    final data = await _remote.createProduct(
      title: title,
      description: description,
      price: price,
      imageUrl: imageUrl,
      city: city,
      district: district,
      categoryId: categoryId,
      variants: variants,
      additionalImages: additionalImages,
    );
    final productJson = data['product'] as Map<String, dynamic>;
    return ProductModel.fromJson(productJson);
  }

  @override
  Future<({bool success, String? trackingCode})> checkout({
    required List<Map<String, dynamic>> items,
    String? shippingAddressId,
    required String cardLastFour,
    required String cardBrand,
    bool skip3ds = false,
    String? couponCode,
  }) async {
    final data = await _remote.checkout(
      items: items,
      shippingAddressId: shippingAddressId,
      cardLastFour: cardLastFour,
      cardBrand: cardBrand,
      skip3ds: skip3ds,
      couponCode: couponCode,
    );
    return (
      success: data['success'] as bool? ?? false,
      trackingCode: data['order']?['tracking_code'] as String?,
    );
  }

  @override
  Future<({List<Map<String, dynamic>> reviews, double averageRating, int reviewCount})> getProductReviews(String productId) async {
    final data = await _remote.fetchProductReviews(productId);
    final reviews = (data['reviews'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final double avg = (data['averageRating'] ?? 0).toDouble();
    final int count = (data['reviewCount'] ?? 0) as int;
    return (reviews: reviews, averageRating: avg, reviewCount: count);
  }

  @override
  Future<String> uploadFile(XFile file) async {
    final data = await _remote.uploadImage(file);
    return data['url'] as String;
  }

  @override
  Future<List<ProductModel>> getFavorites() async {
    final list = await _remote.fetchFavorites();
    return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<bool> toggleFavorite(String productId) async {
    final data = await _remote.toggleFavorite(productId);
    return data['favorited'] as bool? ?? false;
  }
}
