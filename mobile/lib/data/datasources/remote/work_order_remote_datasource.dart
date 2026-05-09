import 'api_client.dart';

class WorkOrderRemoteDatasource {
  WorkOrderRemoteDatasource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> fetchWorkOrders({
    int page = 1,
    int limit = 50,
  }) async {
    final body = await _client.get('workorders', query: {
      'page': '$page',
      'limit': '$limit',
    });
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> approve(String workOrderId) async {
    final body = await _client.put('workorders/$workOrderId/approve');
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reject(String workOrderId) async {
    final body = await _client.put('workorders/$workOrderId/reject');
    return body['data'] as Map<String, dynamic>;
  }
}
