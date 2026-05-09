import '../../domain/repositories/swap_repository.dart';
import '../datasources/remote/swap_remote_datasource.dart';
import '../models/escrow_model.dart';
import '../models/pagination_model.dart';
import '../models/swap_model.dart';

class SwapRepositoryImpl implements SwapRepository {
  SwapRepositoryImpl(this._remote);

  final SwapRemoteDatasource _remote;

  @override
  Future<void> createSwap({
    required String productOfferedId,
    required String productRequestedId,
    String? cardLastFour,
    String? cardBrand,
  }) async {
    await _remote.createSwap(
      productOfferedId: productOfferedId,
      productRequestedId: productRequestedId,
      cardLastFour: cardLastFour,
      cardBrand: cardBrand,
    );
  }

  @override
  Future<({List<SwapModel> swaps, PaginationModel? pagination})> listMySwaps({
    int page = 1,
    int limit = 50,
    String? status,
  }) async {
    final data = await _remote.fetchMySwaps(page: page, limit: limit, status: status);
    final list = data['swaps'] as List<dynamic>? ?? [];
    final swaps = list
        .map((e) => SwapModel.fromJson(e as Map<String, dynamic>))
        .toList();
    PaginationModel? pagination;
    if (data['pagination'] != null) {
      pagination = PaginationModel.fromJson(
        data['pagination'] as Map<String, dynamic>,
      );
    }
    return (swaps: swaps, pagination: pagination);
  }

  @override
  Future<EscrowModel?> acceptSwap(String swapId, {String? cardLastFour, String? cardBrand}) async {
    final data = await _remote.acceptSwap(swapId, cardLastFour: cardLastFour, cardBrand: cardBrand);
    return EscrowModel.tryParse(data['escrow']);
  }

  @override
  Future<void> rejectSwap(String swapId) async {
    await _remote.rejectSwap(swapId);
  }
}
