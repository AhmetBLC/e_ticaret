import 'api_client.dart';
import '../../models/shipment_model.dart';

class ShipmentRemoteDatasource {
  ShipmentRemoteDatasource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> fetchAllShipments({int page = 1, int limit = 50}) async {
    final body = await _client.get('shipments/all', query: {
      'page': '$page',
      'limit': '$limit',
    });
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> advanceStatus(String id, String status) async {
    final body = await _client.patch('shipments/$id/status', body: {
      'status': status,
    });
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> simulateDelivery(String id) async {
    final body = await _client.post('shipments/$id/simulate-delivery', {});
    return body['data'] as Map<String, dynamic>;
  }

  Future<List<ShipmentModel>> initiateShipment(String workOrderId) async {
    final body = await _client.post('shipments/initiate/$workOrderId', {});
    final list = body['data'] as List<dynamic>;
    return list.map((e) => ShipmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> fetchShipmentByTracking(String number) async {
    final body = await _client.get('shipments/track/$number');
    return body['data'] as Map<String, dynamic>;
  }
}
