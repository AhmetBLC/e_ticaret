import 'package:image_picker/image_picker.dart';
import '../../data/models/pagination_model.dart';
import '../../data/models/product_model.dart';

abstract class ProductRepository {
  Future<({List<ProductModel> products, PaginationModel? pagination})> getProducts({
    int page = 1,
    int limit = 20,
    String? query,
    String? categoryId,
    String? city,
  });

  /// Authenticated: current user's listings (`GET /products/me`).
  Future<({List<ProductModel> products, PaginationModel? pagination})> getMyProducts({
    int page = 1,
    int limit = 100,
  });

  Future<ProductModel> getProduct(String id);

  /// Creates a simple listing (no variants). **Auth required.**
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
  });

  Future<({bool success, String? trackingCode})> checkout({
    required List<Map<String, dynamic>> items,
    String? shippingAddressId,
    required String cardLastFour,
    required String cardBrand,
    bool skip3ds = false,
    String? couponCode,
  });

  Future<({List<Map<String, dynamic>> reviews, double averageRating, int reviewCount})> getProductReviews(String productId);

  /// Uploads a file and returns the accessible URL.
  Future<String> uploadFile(XFile file);

  Future<List<ProductModel>> getFavorites();

  Future<bool> toggleFavorite(String productId);
}
