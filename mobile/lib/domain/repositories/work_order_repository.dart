import '../../data/models/escrow_model.dart';
import '../../data/models/pagination_model.dart';
import '../../data/models/work_order_model.dart';

abstract class WorkOrderRepository {
  Future<({List<WorkOrderModel> workOrders, PaginationModel? pagination})>
      listWorkOrders({
    int page = 1,
    int limit = 50,
  });

  Future<({WorkOrderModel workOrder, EscrowModel? escrow})> approve(
    String workOrderId,
  );

  Future<({WorkOrderModel workOrder, EscrowModel? escrow})> reject(
    String workOrderId,
  );
}
