class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.createdAt,
    this.productTitle,
    this.productImage,
    this.buyerEmail,
    this.sellerEmail,
  });

  final String id;
  final String buyerId;
  final String sellerId;
  final String productId;
  final DateTime createdAt;
  final String? productTitle;
  final String? productImage;
  final String? buyerEmail;
  final String? sellerEmail;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      productId: json['product_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      productTitle: json['product_title'] as String?,
      productImage: json['product_image'] as String?,
      buyerEmail: json['buyer_email'] as String?,
      sellerEmail: json['seller_email'] as String?,
    );
  }

  String getDisplayTitle(String currentUserId) {
    if (currentUserId == buyerId) {
      return sellerEmail ?? 'Satıcı';
    }
    return buyerEmail ?? 'Alıcı';
  }
}
