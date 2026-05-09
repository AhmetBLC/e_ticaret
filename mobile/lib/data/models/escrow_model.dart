/// Escrow row for swap price-difference simulation (`escrows` table).
class EscrowModel {
  const EscrowModel({
    required this.id,
    this.swapId,
    this.orderId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String? swapId;
  final String? orderId;
  final double amount;
  final String status;
  final DateTime createdAt;

  static EscrowModel? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }
    final amountRaw = json['amount'];
    return EscrowModel(
      id: json['id'] as String,
      swapId: json['swap_id'] as String?,
      orderId: json['order_id'] as String?,
      amount: amountRaw is num ? amountRaw.toDouble() : double.parse('$amountRaw'),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  factory EscrowModel.fromJson(Map<String, dynamic> json) {
    final e = tryParse(json);
    if (e == null) {
      throw ArgumentError('Invalid escrow json');
    }
    return e;
  }

  bool get isHeld => status == 'HELD';
  bool get isReleased => status == 'RELEASED';
  bool get isRefunded => status == 'REFUNDED';
}

String escrowStatusLabelTr(String status) {
  switch (status) {
    case 'HELD':
      return 'Emanette (fiyat farkı)';
    case 'RELEASED':
      return 'Serbest bırakıldı';
    case 'REFUNDED':
      return 'İade edildi';
    default:
      return status;
  }
}
