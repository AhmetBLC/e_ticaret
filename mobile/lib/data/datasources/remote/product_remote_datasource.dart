import 'package:image_picker/image_picker.dart';
import 'api_client.dart';

class ProductRemoteDatasource {
  ProductRemoteDatasource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> fetchProducts({
    int page = 1,
    int limit = 20,
    String? query,
    String? categoryId,
    String? city,
  }) async {
    final body = await _client.get('products', query: {
      'page': '$page',
      'limit': '$limit',
      if (query != null && query.isNotEmpty) 'query': query,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (city != null && city.isNotEmpty) 'city': city,
    });
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchProductById(String id) async {
    final body = await _client.get('products/$id');
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchMyProducts({int page = 1, int limit = 100}) async {
    final body = await _client.get('products/me', query: {
      'page': '$page',
      'limit': '$limit',
    });
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createProduct({
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
    final body = await _client.post('products', {
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      'price': price,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
      if (city != null && city.isNotEmpty) 'city': city,
      if (district != null && district.isNotEmpty) 'district': district,
      if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
      'variants': variants ?? <dynamic>[],
      if (additionalImages != null && additionalImages.isNotEmpty) 'additional_images': additionalImages,
    });
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> checkout({
    required List<Map<String, dynamic>> items,
    String? shippingAddressId,
    required String cardLastFour,
    required String cardBrand,
    bool skip3ds = false,
    String? couponCode,
  }) async {
    final body = await _client.post('checkout', {
      'items': items,
      if (shippingAddressId != null) 'shipping_address_id': shippingAddressId,
      'card_last_four': cardLastFour,
      'card_brand': cardBrand,
      'skip_3ds': skip3ds,
      if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
    });
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchProductReviews(String productId) async {
    final body = await _client.get('reviews/$productId');
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadImage(XFile file) async {
    final body = await _client.postMultipart('upload', {}, 'image', file);
    return body['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchFavorites() async {
    final body = await _client.get('favorites');
    return body['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> toggleFavorite(String productId) async {
    final body = await _client.post('favorites/toggle/$productId', {});
    return body['data'] as Map<String, dynamic>;
  }
}
