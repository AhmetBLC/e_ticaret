import '../../data/models/escrow_model.dart';
import '../../data/models/pagination_model.dart';
import '../../data/models/swap_model.dart';

abstract class SwapRepository {
  Future<void> createSwap({
    required String productOfferedId,
    required String productRequestedId,
    String? cardLastFour,
    String? cardBrand,
  });

  Future<({List<SwapModel> swaps, PaginationModel? pagination})> listMySwaps({
    int page = 1,
    int limit = 50,
    String? status,
  });

  /// Returns escrow row when a price-difference hold was created.
  Future<EscrowModel?> acceptSwap(String swapId, {String? cardLastFour, String? cardBrand});

  Future<void> rejectSwap(String swapId);
}
