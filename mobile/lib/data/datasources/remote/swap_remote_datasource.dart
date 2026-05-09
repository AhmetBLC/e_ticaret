import 'api_client.dart';

class SwapRemoteDatasource {
  SwapRemoteDatasource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> fetchMySwaps({
    int page = 1,
    int limit = 50,
    String? status,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final body = await _client.get('swaps', query: query);
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createSwap({
    required String productOfferedId,
    required String productRequestedId,
    String? cardLastFour,
    String? cardBrand,
  }) async {
    final payload = <String, dynamic>{
      'product_offered_id': productOfferedId,
      'product_requested_id': productRequestedId,
    };
    if (cardLastFour != null) payload['card_last_four'] = cardLastFour;
    if (cardBrand != null) payload['card_brand'] = cardBrand;

    final body = await _client.post('swaps', payload);
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> acceptSwap(String swapId, {String? cardLastFour, String? cardBrand}) async {
    final payload = <String, dynamic>{};
    if (cardLastFour != null) payload['card_last_four'] = cardLastFour;
    if (cardBrand != null) payload['card_brand'] = cardBrand;

    final body = await _client.put('swaps/$swapId/accept', body: payload.isNotEmpty ? payload : null);
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rejectSwap(String swapId) async {
    final body = await _client.put('swaps/$swapId/reject');
    return body['data'] as Map<String, dynamic>;
  }
}
