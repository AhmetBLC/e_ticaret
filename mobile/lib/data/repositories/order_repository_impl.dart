import '../../domain/repositories/order_repository.dart';
import '../datasources/remote/order_remote_datasource.dart';
import '../models/order_model.dart';
import '../models/pagination_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._remote);

  final OrderRemoteDatasource _remote;

  @override
  Future<({List<OrderModel> orders, PaginationModel? pagination})> listMyOrders({
    int page = 1,
    int limit = 50,
  }) async {
    final data = await _remote.fetchMyOrders(page: page, limit: limit);
    final list = data['orders'] as List<dynamic>? ?? [];
    final orders = list
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
    PaginationModel? pagination;
    if (data['pagination'] != null) {
      pagination = PaginationModel.fromJson(
        data['pagination'] as Map<String, dynamic>,
      );
    }
    return (orders: orders, pagination: pagination);
  }

  @override
  Future<OrderModel> advanceOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final data = await _remote.patchOrderStatus(orderId: orderId, status: status);
    final orderJson = data['order'] as Map<String, dynamic>;
    return OrderModel.fromJson(orderJson);
  }

  @override
  Future<void> requestReturn({required String orderId, required String reason}) async {
    await _remote.postReturnRequest(orderId: orderId, reason: reason);
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    final data = await _remote.fetchStats();
    return data['stats'] as Map<String, dynamic>;
  }
}
