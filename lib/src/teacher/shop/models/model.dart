class Product {
  final int id;
  final String title;
  final int coin;
  final String details;
  final String? imageUrl;
  final bool redeemable;
  final bool redeemed;

  Product({
    required this.id,
    required this.title,
    required this.coin,
    required this.details,
    this.imageUrl,
    required this.redeemable,
    required this.redeemed,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final imagePath = json['coupon_media_id'] != null
        ? json['coupon_media_id']['url'] as String?
        : null;
    final fullImageUrl = imagePath != null
        ? 'https://lifeappmedia.blr1.digitaloceanspaces.com/$imagePath'
        : null;

    return Product(
      id: json['id'],
      title: json['title'],
      coin: json['coin'],
      details: json['details'] ?? '',
      imageUrl: fullImageUrl,
      redeemable: json['redeemable'] ?? false,
      redeemed: json['redeemed'] ?? false,
    );
  }
}

class Purchase {
  final int id;
  final int couponId;
  final String productName;
  final int coinsSpent;
  final String? imageUrl;
  final String? redeemedAt;
  final String? deliveryAddress;
  final String? status;

  Purchase({
    required this.id,
    required this.couponId,
    required this.productName,
    required this.coinsSpent,
    this.imageUrl,
    this.redeemedAt,
    this.deliveryAddress,
    this.status
  });

    factory Purchase.fromJson(Map<String, dynamic> json) {
    String? imagePath;

    if (json['coupon_media_id'] != null) {
      imagePath = json['coupon_media_id']['url'] as String?;
    } else if (json['url'] != null) {
      imagePath = json['url'] as String?;
    }

    final fullImageUrl = imagePath != null
        ? 'https://lifeappmedia.blr1.digitaloceanspaces.com/$imagePath'
        : null;

    return Purchase(
      id: json['id'],
      couponId: json['coupon_id'],
      productName: json['title'] ?? 'Unknown',
      coinsSpent: json['coins_used'] ?? 0,
      imageUrl: fullImageUrl,
      redeemedAt: json['redeemed_at'],
      deliveryAddress: json['delivery_address'],
      status: json['status'],
    );
  }
}

class CoinTransaction {
  final int amount;
  final int type;
  final String typeLabel;
  final String sourceTitle;
  final String sourceType;
  final DateTime createdAt;

  CoinTransaction({
    required this.amount,
    required this.type,
    required this.typeLabel,
    required this.sourceTitle,
    required this.sourceType,
    required this.createdAt,
  });

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      amount: json['amount'],
      type: json['type'],
      typeLabel: json['type_label'],
      sourceTitle: json['source_title'],
      sourceType: json['source_type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
