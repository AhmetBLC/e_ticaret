import '../../data/datasources/remote/shipment_remote_datasource.dart';
import '../../data/models/shipment_model.dart';
import '../../domain/repositories/shipment_repository.dart';

class ShipmentRepositoryImpl implements ShipmentRepository {
  ShipmentRepositoryImpl(this._remote);

  final ShipmentRemoteDatasource _remote;

  @override
  Future<List<ShipmentModel>> getAllShipments() async {
    final data = await _remote.fetchAllShipments();
    final list = data['shipments'] as List<dynamic>? ?? [];
    return list.map((e) => ShipmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ShipmentModel> advanceStatus(String id, String status) async {
    final data = await _remote.advanceStatus(id, status);
    return ShipmentModel.fromJson(data['shipment'] as Map<String, dynamic>);
  }

  @override
  Future<ShipmentModel> simulateDelivery(String id) async {
    final data = await _remote.simulateDelivery(id);
    return ShipmentModel.fromJson(data['shipment'] as Map<String, dynamic>);
  }

  @override
  Future<ShipmentModel> trackShipment(String trackingNumber) async {
    final data = await _remote.fetchShipmentByTracking(trackingNumber);
    return ShipmentModel.fromJson(data['shipment'] as Map<String, dynamic>);
  }

  @override
  Future<List<ShipmentModel>> initiateShipment(String workOrderId) async {
    return await _remote.initiateShipment(workOrderId);
  }
}
