import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class ApiException implements Exception {
  final String message;
  final String code;
  final String? eventId;

  const ApiException(this.message, {this.code = 'SF-API-500', this.eventId});

  @override
  String toString() => eventId == null ? '$message\nCode: $code' : '$message\nCode: $code • Reference: $eventId';
}

class StockFlowApi {
  static const projectUrl = 'https://zuzihcjpjwhrlfeushwd.supabase.co';
  static const publishableKey = 'sb_publishable_2j8UInXQwgutcLhG2qhfhA_LAMR596R';
  static const apiUrl = '$projectUrl/functions/v1/stockflow-api-v3';
  static const uploadUrl = '$projectUrl/functions/v1/stockflow-staging-upload';
  static const extensionUrl = '$projectUrl/functions/v1/stockflow-extensions';
  static const adminUrl = '$projectUrl/functions/v1/stockflow-admin';
  static const appVersion = '1.5.0';

  final Random _random = Random.secure();
  String? _token;
  SfUser? currentUser;

  bool get isLoggedIn => currentUser != null && _token != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('sf_session');
    if (_token != null) {
      try {
        currentUser = await me();
      } catch (_) {
        await logout(localOnly: true);
      }
    }
  }

  String _eventId(String prefix) {
    final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
    final salt = _random.nextInt(0xFFFFF).toRadixString(36).padLeft(4, '0').toUpperCase();
    return '$prefix-$stamp-$salt';
  }

  Map<String, String> _headers() => {
        'content-type': 'application/json',
        'apikey': publishableKey,
        if (_token != null) 'x-stockflow-session': _token!,
      };

  Future<void> _reportFailure({
    required String eventId,
    required String code,
    required String message,
    required String action,
    int? status,
  }) async {
    try {
      await http
          .post(
            Uri.parse(extensionUrl),
            headers: _headers(),
            body: jsonEncode({
              'action': 'clientLog',
              'eventId': eventId,
              'severity': 'error',
              'code': code,
              'message': message,
              'appVersion': appVersion,
              'platform': Platform.operatingSystem,
              'context': {
                'apiAction': action,
                if (status != null) 'status': status,
              },
            }),
          )
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      // Diagnostics must never make the original request fail harder.
    }
  }

  Future<Map<String, dynamic>> _post(
    String action, [
    Map<String, dynamic> body = const {},
  ]) async {
    final eventId = _eventId('SF');
    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(apiUrl),
            headers: _headers(),
            body: jsonEncode({'action': action, ...body}),
          )
          .timeout(const Duration(seconds: 25));
    } on TimeoutException {
      unawaited(_reportFailure(eventId: eventId, code: 'SF-NET-408', message: 'Request timed out.', action: action));
      throw ApiException('Connection timed out. Check your internet and try again.', code: 'SF-NET-408', eventId: eventId);
    } on SocketException {
      unawaited(_reportFailure(eventId: eventId, code: 'SF-NET-000', message: 'No network connection.', action: action));
      throw ApiException('No internet connection. Check mobile data or Wi-Fi and try again.', code: 'SF-NET-000', eventId: eventId);
    } on http.ClientException {
      unawaited(_reportFailure(eventId: eventId, code: 'SF-NET-502', message: 'HTTP client connection failed.', action: action));
      throw ApiException('Could not connect to StockFlow. Check your internet and try again.', code: 'SF-NET-502', eventId: eventId);
    }

    Map<String, dynamic> decoded = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      try {
        final value = jsonDecode(response.body);
        if (value is Map) decoded = Map<String, dynamic>.from(value);
      } catch (_) {
        unawaited(_reportFailure(eventId: eventId, code: 'SF-API-502', message: 'Unreadable server response.', action: action, status: response.statusCode));
        throw ApiException('Server returned an unreadable response.', code: 'SF-API-502', eventId: eventId);
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = '${decoded['error'] ?? 'Request failed'}';
      final serverTrace = '${decoded['traceId'] ?? ''}'.trim();
      final reference = serverTrace.isEmpty ? eventId : serverTrace;
      unawaited(_reportFailure(eventId: reference, code: 'SF-API-${response.statusCode}', message: message, action: action, status: response.statusCode));
      throw ApiException(message, code: 'SF-API-${response.statusCode}', eventId: reference);
    }
    return decoded;
  }

  Future<Map<String, dynamic>> _extensionPost(
    String action,
    Map<String, dynamic> body, {
    bool bestEffort = false,
  }) async {
    final eventId = _eventId('SFX');
    try {
      final response = await http
          .post(
            Uri.parse(extensionUrl),
            headers: _headers(),
            body: jsonEncode({'action': action, ...body}),
          )
          .timeout(const Duration(seconds: 30));
      Map<String, dynamic> decoded = <String, dynamic>{};
      if (response.body.isNotEmpty) {
        try {
          final value = jsonDecode(response.body);
          if (value is Map) decoded = Map<String, dynamic>.from(value);
        } catch (_) {}
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (bestEffort) return decoded;
        final trace = '${decoded['traceId'] ?? ''}'.trim();
        throw ApiException(
          '${decoded['error'] ?? 'Request failed'}',
          code: 'SF-EXT-${response.statusCode}',
          eventId: trace.isEmpty ? eventId : trace,
        );
      }
      return decoded;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      if (bestEffort) return const <String, dynamic>{};
      throw ApiException('The service took too long to respond.', code: 'SF-EXT-408', eventId: eventId);
    } on SocketException {
      if (bestEffort) return const <String, dynamic>{};
      throw ApiException('No internet connection. Try again when you are online.', code: 'SF-EXT-000', eventId: eventId);
    } catch (_) {
      if (bestEffort) return const <String, dynamic>{};
      throw ApiException('Could not complete this request.', code: 'SF-EXT-500', eventId: eventId);
    }
  }

  Future<SfUser> login({
    required String phone,
    required String otp,
    String fullName = '',
    String city = 'Delhi',
    String state = 'Delhi',
    String language = 'en',
    String authMode = 'signIn',
  }) async {
    final data = await _post('login', {
      'phone': phone,
      'otp': otp,
      'fullName': fullName,
      'city': city,
      'state': state,
      'language': language,
      'authMode': authMode,
    });
    _token = '${data['sessionToken']}';
    currentUser = SfUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sf_session', _token!);
    return currentUser!;
  }

  Future<SfUser> me() async {
    final data = await _post('me');
    currentUser = SfUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    return currentUser!;
  }

  Future<void> logout({bool localOnly = false}) async {
    if (!localOnly && _token != null) {
      try {
        await _post('logout');
      } catch (_) {}
    }
    _token = null;
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sf_session');
  }

  Future<List<CategoryItem>> categories() async {
    final data = await _post('categories');
    return (data['categories'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => CategoryItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Listing>> feed({
    String? categorySlug,
    String? search,
    bool shipping = false,
    bool cod = false,
    bool bulk = false,
    bool negotiable = false,
  }) async {
    final data = await _post('feed', {
      if (categorySlug != null) 'categorySlug': categorySlug,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (shipping) 'shipping': true,
      if (cod) 'cod': true,
      if (bulk) 'bulk': true,
      if (negotiable) 'negotiable': true,
    });
    return (data['listings'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Listing.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Listing> listing(String id) async {
    final data = await _post('listing', {'id': id});
    return Listing.fromJson(Map<String, dynamic>.from(data['listing'] as Map));
  }


  Future<Map<String, dynamic>> marketplaceConfig() async {
    final data = await _post('marketplaceConfig');
    return data['banner'] is Map
        ? Map<String, dynamic>.from(data['banner'] as Map)
        : <String, dynamic>{'enabled': false};
  }

  Future<void> applySeller(Map<String, dynamic> data) async {
    await _post('applySeller', data);
    await me();
  }

  Future<Map<String, dynamic>> sellerStatus() => _post('sellerStatus');
  Future<Map<String, dynamic>> sellerDashboard() => _post('sellerDashboard');

  Future<List<Listing>> myListings() async {
    final data = await _post('myListings');
    return (data['listings'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => Listing.fromJson({
            ...Map<String, dynamic>.from(e),
            'seller': {
              'id': currentUser?.id,
              'full_name': currentUser?.fullName,
              'seller_status': currentUser?.sellerStatus,
            },
          }),
        )
        .toList();
  }

  Future<Listing> createListing(Map<String, dynamic> data) async {
    final result = await _post('createListing', data);
    return Listing.fromJson({
      ...Map<String, dynamic>.from(result['listing'] as Map),
      'seller': {
        'id': currentUser?.id,
        'full_name': currentUser?.fullName,
        'seller_status': 'approved',
      },
    });
  }


  Future<Listing> resubmitListing(Map<String, dynamic> data) async {
    final result = await _post('resubmitListing', data);
    return Listing.fromJson({
      ...Map<String, dynamic>.from(result['listing'] as Map),
      'seller': {
        'id': currentUser?.id,
        'full_name': currentUser?.fullName,
        'seller_status': currentUser?.sellerStatus ?? 'approved',
      },
    });
  }

  Future<void> reportListing({
    required String listingId,
    required String reason,
    String details = '',
  }) async {
    await _post('reportListing', {
      'listingId': listingId,
      'reason': reason,
      'details': details,
    });
  }

  Future<Map<String, dynamic>> aiListingAssist({
    required String title,
    String note = '',
  }) async {
    final data = await _extensionPost('aiListingAssist', {'title': title, 'note': note});
    return data['draft'] is Map ? Map<String, dynamic>.from(data['draft'] as Map) : <String, dynamic>{};
  }

  Future<void> saveListingLocation({
    required String listingId,
    required String addressLine1,
    required String street,
    required String locality,
    required String district,
    required String city,
    required String state,
    required String pincode,
    required String landmark,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
  }) async {
    await _post('saveListingLocation', {
      'listingId': listingId,
      'addressLine1': addressLine1,
      'street': street,
      'locality': locality,
      'district': district,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'country': 'India',
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
    });
  }

  Future<void> trackListingEvent(String listingId, String eventType) async {
    await _extensionPost('trackListingEvent', {
      'listingId': listingId,
      'eventType': eventType,
    }, bestEffort: true);
  }

  Future<String?> logClientIssue({
    required String severity,
    required String code,
    required String message,
    Map<String, dynamic> context = const {},
    String? eventId,
  }) async {
    final id = eventId ?? _eventId('SF');
    final data = await _extensionPost('clientLog', {
      'eventId': id,
      'severity': severity,
      'code': code,
      'message': message,
      'context': context,
      'appVersion': appVersion,
      'platform': Platform.operatingSystem,
    }, bestEffort: true);
    return '${data['eventId'] ?? id}';
  }

  String get _sourceChannel {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  Future<DealRequest> createDealRequest({
    required String listingId,
    required int quantity,
  }) async {
    final data = await _extensionPost('createDealRequest', {
      'listingId': listingId,
      'quantity': quantity,
      'sourceChannel': _sourceChannel,
    });
    return DealRequest.fromJson(Map<String, dynamic>.from(data['deal'] as Map));
  }

  Future<List<DealRequest>> dealRequests({bool selling = false}) async {
    final data = await _extensionPost('dealRequests', {
      'mode': selling ? 'selling' : 'buying',
    });
    return (data['deals'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => DealRequest.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> promiseFeeQuote(String dealRequestId) async {
    final data = await _extensionPost('promiseFeeQuote', {
      'dealRequestId': dealRequestId,
    });
    return data['quote'] is Map
        ? Map<String, dynamic>.from(data['quote'] as Map)
        : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> capturePromiseFee(String dealRequestId) async {
    return _extensionPost('capturePromiseFee', {
      'dealRequestId': dealRequestId,
      'acknowledgeNonRefundable': true,
    });
  }

  // Chat and negotiation
  Future<String> startConversation(String listingId) async {
    final data = await _post('startConversation', {'listingId': listingId});
    return '${(data['conversation'] as Map)['id']}';
  }

  Future<List<Conversation>> conversations() async {
    final data = await _post('conversations');
    return (data['conversations'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Conversation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<ChatMessage>> messages(String conversationId) async {
    final data = await _post('messages', {'conversationId': conversationId});
    return (data['messages'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> sendMessage(String conversationId, String text) async {
    await _post('sendMessage', {'conversationId': conversationId, 'text': text});
  }

  Future<Offer> makeOffer({
    required String listingId,
    required int quantity,
    required double unitPrice,
  }) async {
    final data = await _post('makeOffer', {
      'listingId': listingId,
      'quantity': quantity,
      'unitPrice': unitPrice,
    });
    return Offer.fromJson(Map<String, dynamic>.from(data['offer'] as Map));
  }

  Future<Offer> counterOffer({
    required String offerId,
    required int quantity,
    required double unitPrice,
  }) async {
    final data = await _post('counterOffer', {
      'offerId': offerId,
      'quantity': quantity,
      'unitPrice': unitPrice,
    });
    return Offer.fromJson(Map<String, dynamic>.from(data['offer'] as Map));
  }

  Future<void> respondOffer(String offerId, String decision) =>
      _post('respondOffer', {'offerId': offerId, 'decision': decision});

  Future<List<Map<String, dynamic>>> myOffers() async {
    final data = await _post('myOffers');
    return (data['offers'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // Cart and checkout
  Future<List<CartItem>> cart() async {
    final data = await _post('cart');
    return (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> addToCart(String listingId, int quantity) =>
      _post('addCart', {'listingId': listingId, 'quantity': quantity});

  Future<void> updateCart(String listingId, int quantity) =>
      _post('updateCart', {'listingId': listingId, 'quantity': quantity});

  Future<void> removeFromCart(String listingId) =>
      _post('removeCart', {'listingId': listingId});

  Future<List<SfAddress>> addresses() async {
    final data = await _post('addresses');
    return (data['addresses'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => SfAddress.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<SfAddress> saveAddress(SfAddress address) async {
    final data = await _post('saveAddress', address.toJson());
    return SfAddress.fromJson(Map<String, dynamic>.from(data['address'] as Map));
  }

  Future<SfOrder> checkout({
    required String listingId,
    required int quantity,
    required String paymentMethod,
    required SfAddress address,
    String? offerId,
  }) async {
    final data = await _post('checkout', {
      'listingId': listingId,
      'quantity': quantity,
      'paymentMethod': paymentMethod,
      'address': address.toJson(),
      if (offerId != null) 'offerId': offerId,
    });
    return SfOrder.fromJson(Map<String, dynamic>.from(data['order'] as Map));
  }

  Future<List<SfOrder>> orders({bool seller = false}) async {
    final data = await _post('orders', {'mode': seller ? 'seller' : 'buyer'});
    return (data['orders'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => SfOrder.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<SfOrder> order(String orderId) async {
    final data = await _post('order', {'orderId': orderId});
    return SfOrder.fromJson(Map<String, dynamic>.from(data['order'] as Map));
  }

  Future<void> sellerUpdateOrder({
    required String orderId,
    required String status,
    String courierName = '',
    String note = '',
  }) =>
      _post('sellerUpdateOrder', {
        'orderId': orderId,
        'status': status,
        'courierName': courierName,
        'note': note,
      });

  // Lightweight local UX cache. Production sync is isolated from commerce data.
  Future<Set<String>> favoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('sf_favorites') ?? const <String>[]).toSet();
  }

  Future<bool> toggleFavorite(String listingId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList('sf_favorites') ?? const <String>[]).toSet();
    final added = !ids.remove(listingId);
    if (added) ids.add(listingId);
    await prefs.setStringList('sf_favorites', ids.toList());
    return added;
  }

  Future<List<String>> recentIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('sf_recent') ?? const <String>[];
  }

  Future<void> markRecentlyViewed(String listingId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('sf_recent') ?? <String>[];
    ids.remove(listingId);
    ids.insert(0, listingId);
    if (ids.length > 30) ids.removeRange(30, ids.length);
    await prefs.setStringList('sf_recent', ids);
  }

  Future<Map<String, dynamic>> uploadMedia(
    Uint8List bytes,
    String mime, {
    double? durationSeconds,
  }) async {
    final eventId = _eventId('SF-UP');
    final isVideo = mime.startsWith('video/');
    if (bytes.isEmpty) throw ApiException('Media file is empty.', code: 'SF-UP-400', eventId: eventId);
    late final http.Response ticketResponse;
    try {
      ticketResponse = await http
          .post(
            Uri.parse(uploadUrl),
            headers: _headers(),
            body: jsonEncode({
              'action': 'prepare',
              'mime': mime,
              'sizeBytes': bytes.lengthInBytes,
              if (durationSeconds != null) 'durationSeconds': durationSeconds,
            }),
          )
          .timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw ApiException('Could not prepare media upload. Try again.', code: 'SF-UP-408', eventId: eventId);
    } on SocketException {
      throw ApiException('No internet connection. Media upload could not start.', code: 'SF-UP-000', eventId: eventId);
    } on http.ClientException {
      throw ApiException('Could not connect to StockFlow for media upload.', code: 'SF-UP-502', eventId: eventId);
    }

    Map<String, dynamic> ticket = <String, dynamic>{};
    try {
      final value = jsonDecode(ticketResponse.body.isEmpty ? '{}' : ticketResponse.body);
      if (value is Map) ticket = Map<String, dynamic>.from(value);
    } catch (_) {}
    if (ticketResponse.statusCode < 200 || ticketResponse.statusCode >= 300) {
      throw ApiException('${ticket['error'] ?? 'Could not prepare media upload.'}', code: 'SF-UP-${ticketResponse.statusCode}', eventId: eventId);
    }
    final signedUrl = '${ticket['signedUrl'] ?? ''}'.trim();
    if (signedUrl.isEmpty) throw ApiException('Upload ticket was incomplete.', code: 'SF-UP-502', eventId: eventId);

    late final http.Response uploadResponse;
    try {
      uploadResponse = await http
          .put(
            Uri.parse(signedUrl),
            headers: {
              'content-type': mime,
              'cache-control': 'max-age=3600',
              'x-upsert': 'false',
            },
            body: bytes,
          )
          .timeout(Duration(seconds: isVideo ? 110 : 55));
    } on TimeoutException {
      unawaited(_reportFailure(eventId: eventId, code: 'SF-UP-408', message: 'Direct media upload timed out.', action: 'uploadMedia'));
      throw ApiException('Media upload timed out. Check your connection and try again.', code: 'SF-UP-408', eventId: eventId);
    } on SocketException {
      unawaited(_reportFailure(eventId: eventId, code: 'SF-UP-000', message: 'No network for media upload.', action: 'uploadMedia'));
      throw ApiException('Connection lost during media upload.', code: 'SF-UP-000', eventId: eventId);
    } on http.ClientException {
      unawaited(_reportFailure(eventId: eventId, code: 'SF-UP-502', message: 'Direct storage upload failed.', action: 'uploadMedia'));
      throw ApiException('Could not upload media to StockFlow storage.', code: 'SF-UP-502', eventId: eventId);
    }
    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      unawaited(_reportFailure(eventId: eventId, code: 'SF-UP-${uploadResponse.statusCode}', message: 'Storage rejected media upload.', action: 'uploadMedia'));
      throw ApiException('Storage rejected this media file. Try another file.', code: 'SF-UP-${uploadResponse.statusCode}', eventId: eventId);
    }
    return ticket;
  }

  Future<String> uploadImage(Uint8List bytes, String mime) async {
    final data = await uploadMedia(bytes, mime);
    return '${data['url'] ?? ''}';
  }

}
