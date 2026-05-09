import 'escrow_model.dart';
import 'product_summary_model.dart';

class SwapModel {
  const SwapModel({
    required this.id,
    required this.requesterUserId,
    required this.receiverUserId,
    required this.productOfferedId,
    required this.productRequestedId,
    required this.status,
    required this.createdAt,
    this.offeredProduct,
    this.requestedProduct,
    this.escrow,
    this.trackingNumber,
    this.cargoStatus,
  });

  final String id;
  final String requesterUserId;
  final String receiverUserId;
  final String productOfferedId;
  final String productRequestedId;
  final String status;
  final DateTime createdAt;
  final ProductSummary? offeredProduct;
  final ProductSummary? requestedProduct;
  final String? trackingNumber;
  final String? cargoStatus;

  /// Present when listings had a price difference and escrow was created.
  final EscrowModel? escrow;

  factory SwapModel.fromJson(Map<String, dynamic> json) {
    return SwapModel(
      id: json['id'] as String,
      requesterUserId: json['requester_user_id'] as String,
      receiverUserId: json['receiver_user_id'] as String,
      productOfferedId: json['product_offered_id'] as String,
      productRequestedId: json['product_requested_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      offeredProduct: ProductSummary.tryParse(json['offered_product']),
      requestedProduct: ProductSummary.tryParse(json['requested_product']),
      escrow: EscrowModel.tryParse(json['escrow']),
      trackingNumber: json['tracking_number'] as String?,
      cargoStatus: json['cargo_status'] as String?,
    );
  }

  bool get isPending => status == 'PENDING';

  bool isIncomingFor(String userId) => receiverUserId == userId && isPending;

  bool get isWorkshop => status == 'WORKSHOP';
}