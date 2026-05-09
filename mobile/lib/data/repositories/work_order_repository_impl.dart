import '../../domain/repositories/work_order_repository.dart';
import '../datasources/remote/work_order_remote_datasource.dart';
import '../models/escrow_model.dart';
import '../models/pagination_model.dart';
import '../models/work_order_model.dart';

class WorkOrderRepositoryImpl implements WorkOrderRepository {
  WorkOrderRepositoryImpl(this._remote);

  final WorkOrderRemoteDatasource _remote;

  @override
  Future<({List<WorkOrderModel> workOrders, PaginationModel? pagination})>
      listWorkOrders({
    int page = 1,
    int limit = 50,
  }) async {
    final data = await _remote.fetchWorkOrders(page: page, limit: limit);
    final list = data['work_orders'] as List<dynamic>? ?? [];
    final workOrders = list
        .map((e) => WorkOrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
    PaginationModel? pagination;
    if (data['pagination'] != null) {
      pagination = PaginationModel.fromJson(
        data['pagination'] as Map<String, dynamic>,
      );
    }
    return (workOrders: workOrders, pagination: pagination);
  }

  @override
  Future<({WorkOrderModel workOrder, EscrowModel? escrow})> approve(
    String workOrderId,
  ) async {
    final data = await _remote.approve(workOrderId);
    final wo = WorkOrderModel.fromJson(
      data['work_order'] as Map<String, dynamic>,
    );
    return (workOrder: wo, escrow: EscrowModel.tryParse(data['escrow']));
  }

  @override
  Future<({WorkOrderModel workOrder, EscrowModel? escrow})> reject(
    String workOrderId,
  ) async {
    final data = await _remote.reject(workOrderId);
    final wo = WorkOrderModel.fromJson(
      data['work_order'] as Map<String, dynamic>,
    );
    return (workOrder: wo, escrow: EscrowModel.tryParse(data['escrow']));
  }
}
