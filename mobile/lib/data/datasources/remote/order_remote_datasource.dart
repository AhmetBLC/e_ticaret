import 'api_client.dart';

class OrderRemoteDatasource {
  OrderRemoteDatasource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> fetchMyOrders({
    int page = 1,
    int limit = 50,
  }) async {
    final body = await _client.get('orders', query: {
      'page': '$page',
      'limit': '$limit',
    });
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patchOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final body = await _client.patch(
      'orders/$orderId/status',
      body: {'status': status},
    );
    return body['data'] as Map<String, dynamic>;
  }

  Future<void> postReturnRequest({
    required String orderId,
    required String reason,
  }) async {
    await _client.post('returns', {
      'order_id': orderId,
      'reason': reason,
    });
  }

  Future<Map<String, dynamic>> fetchStats() async {
    final body = await _client.get('orders/stats');
    return body['data'] as Map<String, dynamic>;
  }
}
