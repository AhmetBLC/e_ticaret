import '../../data/models/shipment_model.dart';

abstract class ShipmentRepository {
  Future<List<ShipmentModel>> getAllShipments();
  Future<ShipmentModel> advanceStatus(String id, String status);
  Future<ShipmentModel> simulateDelivery(String id);
  Future<List<ShipmentModel>> initiateShipment(String workOrderId);
  Future<ShipmentModel> trackShipment(String trackingNumber);
}
