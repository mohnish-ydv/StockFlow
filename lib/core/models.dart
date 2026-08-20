class SfUser {
  final String id;
  final String phone;
  final String fullName;
  final String city;
  final String state;
  final String role;
  final String sellerStatus;
  final String preferredLanguage;
  final String accountStatus;
  final DateTime? createdAt;

  const SfUser({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.city,
    required this.state,
    required this.role,
    required this.sellerStatus,
    required this.preferredLanguage,
    this.accountStatus = 'active',
    this.createdAt,
  });

  factory SfUser.fromJson(Map<String, dynamic> j) => SfUser(
        id: '${j['id'] ?? ''}',
        phone: '${j['phone'] ?? ''}',
        fullName: '${j['full_name'] ?? ''}',
        city: '${j['city'] ?? ''}',
        state: '${j['state'] ?? ''}',
        role: '${j['role'] ?? 'user'}',
        sellerStatus: '${j['seller_status'] ?? 'not_applied'}',
        preferredLanguage: '${j['preferred_language'] ?? 'en'}',
        accountStatus: '${j['account_status'] ?? 'active'}',
        createdAt: DateTime.tryParse('${j['created_at'] ?? ''}'),
      );
}

class CategoryItem {
  final String name;
  final String slug;
  final String icon;

  const CategoryItem(this.name, this.slug, this.icon);

  factory CategoryItem.fromJson(Map<String, dynamic> j) => CategoryItem(
        '${j['name'] ?? ''}',
        '${j['slug'] ?? ''}',
        '${j['icon'] ?? 'category'}',
      );
}

class ListingMedia {
  final String id;
  final String url;
  final String type;
  final String mimeType;
  final int sortOrder;
  final int sizeBytes;
  final double? durationSeconds;

  const ListingMedia({
    required this.id,
    required this.url,
    required this.type,
    required this.mimeType,
    required this.sortOrder,
    required this.sizeBytes,
    this.durationSeconds,
  });

  bool get isVideo => type == 'video';

  factory ListingMedia.fromJson(Map<String, dynamic> j) => ListingMedia(
        id: '${j['id'] ?? ''}',
        url: '${j['url'] ?? ''}',
        type: '${j['media_type'] ?? j['mediaType'] ?? 'image'}',
        mimeType: '${j['mime_type'] ?? j['mimeType'] ?? 'image/jpeg'}',
        sortOrder: int.tryParse('${j['sort_order'] ?? j['sortOrder'] ?? 0}') ?? 0,
        sizeBytes: int.tryParse('${j['size_bytes'] ?? j['sizeBytes'] ?? 0}') ?? 0,
        durationSeconds: j['duration_seconds'] == null && j['durationSeconds'] == null
            ? null
            : double.tryParse('${j['duration_seconds'] ?? j['durationSeconds']}'),
      );
}

class Listing {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final String categorySlug;
  final String condition;
  final String city;
  final String state;
  final String unit;
  final String inventoryType;
  final String imageUrl;
  final List<ListingMedia> media;
  final String sellerName;
  final String sellerStatus;
  final String status;
  final String? brand;
  final double sellingPrice;
  final double? originalPrice;
  final int availableQty;
  final int moq;
  final bool negotiable;
  final bool pickup;
  final bool shipping;
  final bool cod;
  final bool featured;
  final String? moderationNote;
  final DateTime? submittedAt;
  final int reviewRound;
  final DateTime? sellerMemberSince;
  final double? approximateLatitude;
  final double? approximateLongitude;
  final double approximateRadiusKm;

  const Listing({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.categorySlug,
    required this.condition,
    required this.city,
    required this.state,
    required this.unit,
    required this.inventoryType,
    required this.imageUrl,
    this.media = const [],
    required this.sellerName,
    required this.sellerStatus,
    required this.status,
    this.brand,
    required this.sellingPrice,
    this.originalPrice,
    required this.availableQty,
    required this.moq,
    required this.negotiable,
    required this.pickup,
    required this.shipping,
    required this.cod,
    required this.featured,
    this.moderationNote,
    this.submittedAt,
    this.reviewRound = 1,
    this.sellerMemberSince,
    this.approximateLatitude,
    this.approximateLongitude,
    this.approximateRadiusKm = 10,
  });

  bool get hasApproximateLocation => approximateLatitude != null && approximateLongitude != null;
  bool get isPendingReview => status == 'pending_review';
  bool get isRejected => status == 'rejected';
  String get shortId => id.length <= 8 ? id.toUpperCase() : id.substring(0, 8).toUpperCase();

  factory Listing.fromJson(Map<String, dynamic> j) {
    final seller = j['seller'] is Map ? Map<String, dynamic>.from(j['seller'] as Map) : <String, dynamic>{};
    final rawMedia = (j['media'] as List? ?? const []).whereType<Map>().map((e) => ListingMedia.fromJson(Map<String, dynamic>.from(e))).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final fallbackImage = '${j['image_url'] ?? ''}';
    final media = rawMedia.isNotEmpty
        ? rawMedia
        : (fallbackImage.isEmpty
            ? <ListingMedia>[]
            : [ListingMedia(id: 'legacy-${j['id'] ?? ''}', url: fallbackImage, type: 'image', mimeType: 'image/jpeg', sortOrder: 0, sizeBytes: 0)]);
    final approx = j['approximate_location'] is Map ? Map<String, dynamic>.from(j['approximate_location'] as Map) : <String, dynamic>{};
    final firstImage = media.where((e) => !e.isVideo).firstOrNull;
    return Listing(
      id: '${j['id'] ?? ''}',
      sellerId: '${j['seller_id'] ?? seller['id'] ?? ''}',
      title: '${j['title'] ?? ''}',
      description: '${j['description'] ?? ''}',
      categorySlug: '${j['category_slug'] ?? 'other'}',
      condition: '${j['condition'] ?? ''}',
      city: '${j['city'] ?? ''}',
      state: '${j['state'] ?? ''}',
      unit: '${j['unit'] ?? 'piece'}',
      inventoryType: '${j['inventory_type'] ?? 'single'}',
      imageUrl: firstImage?.url ?? fallbackImage,
      media: media,
      sellerName: '${seller['full_name'] ?? 'Verified seller'}',
      sellerStatus: '${seller['seller_status'] ?? 'approved'}',
      status: '${j['status'] ?? 'active'}',
      brand: j['brand']?.toString(),
      sellingPrice: double.tryParse('${j['selling_price']}') ?? 0,
      originalPrice: j['original_price'] == null ? null : double.tryParse('${j['original_price']}'),
      availableQty: int.tryParse('${j['available_qty']}') ?? 0,
      moq: int.tryParse('${j['minimum_order_quantity']}') ?? 1,
      negotiable: j['negotiable'] == true,
      pickup: j['pickup_enabled'] == true,
      shipping: j['shipping_enabled'] == true,
      cod: j['cod_enabled'] == true,
      featured: j['is_featured'] == true,
      moderationNote: j['moderation_note']?.toString(),
      submittedAt: DateTime.tryParse('${j['submitted_at'] ?? j['created_at'] ?? ''}'),
      reviewRound: int.tryParse('${j['review_round'] ?? 1}') ?? 1,
      sellerMemberSince: DateTime.tryParse('${seller['created_at'] ?? ''}'),
      approximateLatitude: double.tryParse('${approx['latitude'] ?? ''}'),
      approximateLongitude: double.tryParse('${approx['longitude'] ?? ''}'),
      approximateRadiusKm: double.tryParse('${approx['radiusKm'] ?? 10}') ?? 10,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class Conversation {
  final String id;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final Listing? listing;
  final String otherUserName;
  final String otherUserSellerStatus;
  final String lastMessage;
  final String lastMessageType;
  final DateTime? lastMessageAt;

  const Conversation({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.listing,
    required this.otherUserName,
    required this.otherUserSellerStatus,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) {
    final rawListing = j['listing'];
    final rawOther = j['other_user'];
    final rawLast = j['last_message'];
    final lastMap = rawLast is Map ? Map<String, dynamic>.from(rawLast) : <String, dynamic>{};
    return Conversation(
      id: '${j['id'] ?? ''}',
      listingId: '${j['listing_id'] ?? ''}',
      buyerId: '${j['buyer_id'] ?? ''}',
      sellerId: '${j['seller_id'] ?? ''}',
      listing: rawListing is Map
          ? Listing.fromJson({
              ...Map<String, dynamic>.from(rawListing),
              'seller': const <String, dynamic>{},
            })
          : null,
      otherUserName: rawOther is Map ? '${rawOther['full_name'] ?? 'StockFlow user'}' : 'StockFlow user',
      otherUserSellerStatus: rawOther is Map ? '${rawOther['seller_status'] ?? 'not_applied'}' : 'not_applied',
      lastMessage: '${lastMap['body'] ?? ''}',
      lastMessageType: '${lastMap['message_type'] ?? 'text'}',
      lastMessageAt: DateTime.tryParse('${j['last_message_at'] ?? lastMap['created_at'] ?? ''}'),
    );
  }
}

class DealRequest {
  final String id;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final int requestedQty;
  final String status;
  final String role;
  final String counterpartyLabel;
  final Listing? listing;
  final bool chatUnlocked;
  final String? conversationId;
  final double feeAmount;
  final String feeCurrency;
  final DateTime? createdAt;

  const DealRequest({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.requestedQty,
    required this.status,
    required this.role,
    required this.counterpartyLabel,
    required this.listing,
    required this.chatUnlocked,
    required this.conversationId,
    required this.feeAmount,
    required this.feeCurrency,
    required this.createdAt,
  });

  bool get isBuyer => role == 'buyer';
  bool get isSeller => role == 'seller';
  bool get isClosed => const {'closed', 'cancelled', 'converted'}.contains(status);

  factory DealRequest.fromJson(Map<String, dynamic> j) {
    final rawListing = j['listing'];
    return DealRequest(
      id: '${j['id'] ?? ''}',
      listingId: '${j['listing_id'] ?? ''}',
      buyerId: '${j['buyer_id'] ?? ''}',
      sellerId: '${j['seller_id'] ?? ''}',
      requestedQty: int.tryParse('${j['requested_qty']}') ?? 1,
      status: '${j['status'] ?? 'pending_admin'}',
      role: '${j['role'] ?? 'buyer'}',
      counterpartyLabel: '${j['counterpartyLabel'] ?? 'StockFlow member'}',
      listing: rawListing is Map
          ? Listing.fromJson({
              ...Map<String, dynamic>.from(rawListing),
              'seller': const <String, dynamic>{},
            })
          : null,
      chatUnlocked: j['chatUnlocked'] == true,
      conversationId: '${j['conversationId'] ?? ''}'.trim().isEmpty
          ? null
          : '${j['conversationId']}',
      feeAmount: double.tryParse('${j['feeAmount']}') ?? 0,
      feeCurrency: '${j['feeCurrency'] ?? 'INR'}',
      createdAt: DateTime.tryParse('${j['created_at'] ?? ''}'),
    );
  }
}

class Offer {
  final String id;
  final String conversationId;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final String createdBy;
  final int quantity;
  final double unitPrice;
  final String status;
  final DateTime? expiresAt;

  const Offer({
    required this.id,
    required this.conversationId,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.createdBy,
    required this.quantity,
    required this.unitPrice,
    required this.status,
    required this.expiresAt,
  });

  double get total => quantity * unitPrice;

  factory Offer.fromJson(Map<String, dynamic> j) => Offer(
        id: '${j['id'] ?? ''}',
        conversationId: '${j['conversation_id'] ?? ''}',
        listingId: '${j['listing_id'] ?? ''}',
        buyerId: '${j['buyer_id'] ?? ''}',
        sellerId: '${j['seller_id'] ?? ''}',
        createdBy: '${j['created_by'] ?? ''}',
        quantity: int.tryParse('${j['quantity']}') ?? 1,
        unitPrice: double.tryParse('${j['unit_price']}') ?? 0,
        status: '${j['status'] ?? 'pending'}',
        expiresAt: DateTime.tryParse('${j['expires_at'] ?? ''}'),
      );
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final String type;
  final DateTime? createdAt;
  final DateTime? readAt;
  final Offer? offer;
  final Map<String, dynamic>? orderPreview;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.readAt,
    required this.offer,
    required this.orderPreview,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: '${j['id'] ?? ''}',
        conversationId: '${j['conversation_id'] ?? ''}',
        senderId: '${j['sender_id'] ?? ''}',
        body: '${j['body'] ?? ''}',
        type: '${j['message_type'] ?? 'text'}',
        createdAt: DateTime.tryParse('${j['created_at'] ?? ''}'),
        readAt: DateTime.tryParse('${j['read_at'] ?? ''}'),
        offer: j['offer'] is Map
            ? Offer.fromJson(Map<String, dynamic>.from(j['offer'] as Map))
            : null,
        orderPreview: j['order'] is Map
            ? Map<String, dynamic>.from(j['order'] as Map)
            : null,
      );
}

class CartItem {
  final String id;
  final int quantity;
  final Listing listing;

  const CartItem({required this.id, required this.quantity, required this.listing});

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        id: '${j['id'] ?? ''}',
        quantity: int.tryParse('${j['quantity']}') ?? 1,
        listing: Listing.fromJson(Map<String, dynamic>.from(j['listing'] as Map)),
      );
}

class SfAddress {
  final String? id;
  final String label;
  final String recipientName;
  final String phone;
  final String line1;
  final String locality;
  final String city;
  final String state;
  final String pincode;
  final String landmark;
  final bool isDefault;

  const SfAddress({
    this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.line1,
    required this.locality,
    required this.city,
    required this.state,
    required this.pincode,
    required this.landmark,
    required this.isDefault,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'recipientName': recipientName,
        'phone': phone,
        'line1': line1,
        'locality': locality,
        'city': city,
        'state': state,
        'pincode': pincode,
        'landmark': landmark,
        'isDefault': isDefault,
      };

  factory SfAddress.fromJson(Map<String, dynamic> j) => SfAddress(
        id: j['id']?.toString(),
        label: '${j['label'] ?? 'Home'}',
        recipientName: '${j['recipient_name'] ?? j['recipientName'] ?? ''}',
        phone: '${j['phone'] ?? ''}',
        line1: '${j['line1'] ?? ''}',
        locality: '${j['locality'] ?? ''}',
        city: '${j['city'] ?? ''}',
        state: '${j['state'] ?? ''}',
        pincode: '${j['pincode'] ?? ''}',
        landmark: '${j['landmark'] ?? ''}',
        isDefault: j['is_default'] == true || j['isDefault'] == true,
      );
}

class OrderItem {
  final String listingId;
  final String title;
  final String imageUrl;
  final String unit;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  const OrderItem({
    required this.listingId,
    required this.title,
    required this.imageUrl,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        listingId: '${j['listing_id'] ?? ''}',
        title: '${j['title'] ?? ''}',
        imageUrl: '${j['image_url'] ?? ''}',
        unit: '${j['unit'] ?? 'piece'}',
        quantity: int.tryParse('${j['quantity']}') ?? 1,
        unitPrice: double.tryParse('${j['unit_price']}') ?? 0,
        lineTotal: double.tryParse('${j['line_total']}') ?? 0,
      );
}

class Shipment {
  final String awb;
  final String provider;
  final String status;
  final String courierName;
  final String trackingNote;

  const Shipment({
    required this.awb,
    required this.provider,
    required this.status,
    required this.courierName,
    required this.trackingNote,
  });

  factory Shipment.fromJson(Map<String, dynamic> j) => Shipment(
        awb: '${j['awb'] ?? ''}',
        provider: '${j['provider'] ?? ''}',
        status: '${j['status'] ?? ''}',
        courierName: '${j['courier_name'] ?? ''}',
        trackingNote: '${j['tracking_note'] ?? ''}',
      );
}

class SfOrder {
  final String id;
  final String buyerId;
  final String sellerId;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final double total;
  final DateTime? createdAt;
  final List<OrderItem> items;
  final Shipment? shipment;
  final String buyerName;
  final String sellerName;
  final Map<String, dynamic> deliveryAddress;
  final List<Map<String, dynamic>> history;

  const SfOrder({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.total,
    required this.createdAt,
    required this.items,
    required this.shipment,
    required this.buyerName,
    required this.sellerName,
    required this.deliveryAddress,
    required this.history,
  });

  factory SfOrder.fromJson(Map<String, dynamic> j) {
    final buyer = j['buyer'] is Map ? Map<String, dynamic>.from(j['buyer'] as Map) : <String, dynamic>{};
    final seller = j['seller'] is Map ? Map<String, dynamic>.from(j['seller'] as Map) : <String, dynamic>{};
    return SfOrder(
      id: '${j['id'] ?? ''}',
      buyerId: '${j['buyer_id'] ?? ''}',
      sellerId: '${j['seller_id'] ?? ''}',
      status: '${j['status'] ?? 'created'}',
      paymentMethod: '${j['payment_method'] ?? ''}',
      paymentStatus: '${j['payment_status'] ?? ''}',
      total: double.tryParse('${j['total']}') ?? 0,
      createdAt: DateTime.tryParse('${j['created_at'] ?? ''}'),
      items: (j['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      shipment: j['shipment'] is Map
          ? Shipment.fromJson(Map<String, dynamic>.from(j['shipment'] as Map))
          : null,
      buyerName: '${buyer['full_name'] ?? 'Buyer'}',
      sellerName: '${seller['full_name'] ?? 'Seller'}',
      deliveryAddress: j['delivery_address'] is Map
          ? Map<String, dynamic>.from(j['delivery_address'] as Map)
          : <String, dynamic>{},
      history: (j['history'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }
}
