import '../../data/models/order_model.dart';
import '../../data/models/pagination_model.dart';

abstract class OrderRepository {
  Future<({List<OrderModel> orders, PaginationModel? pagination})> listMyOrders({
    int page = 1,
    int limit = 50,
  });

  Future<OrderModel> advanceOrderStatus({
    required String orderId,
    required String status,
  });

  Future<void> requestReturn({
    required String orderId,
    required String reason,
  });

  Future<Map<String, dynamic>> getStats();
}
