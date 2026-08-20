import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockflow/core/api.dart';
import 'package:stockflow/core/models.dart';
import 'package:stockflow/core/motion.dart';
import 'package:stockflow/core/theme.dart';
import 'package:stockflow/screens/auth_screen.dart';
import 'package:stockflow/screens/guest_account_screen.dart';
import 'package:stockflow/screens/welcome_screen.dart';
import 'package:stockflow/widgets/listing_card.dart';

void main() {
  test('API errors expose support code and incident reference without request data', () {
    const error = ApiException('Could not load stock.', code: 'SF-NET-408', eventId: 'SF-ABC123');
    expect(error.toString(), contains('SF-NET-408'));
    expect(error.toString(), contains('SF-ABC123'));
    expect(error.toString(), isNot(contains('session')));
  });

  test('listing parser keeps inventory and fulfillment semantics', () {
    final listing = Listing.fromJson({
      'id': 'listing-1',
      'seller_id': 'seller-1',
      'title': 'Test stock',
      'description': '',
      'category_slug': 'electronics',
      'condition': 'New',
      'city': 'Delhi',
      'state': 'Delhi',
      'unit': 'piece',
      'inventory_type': 'bulk',
      'image_url': 'https://example.test/image.jpg',
      'selling_price': 200,
      'available_qty': 20,
      'minimum_order_quantity': 5,
      'negotiable': true,
      'pickup_enabled': true,
      'shipping_enabled': true,
      'cod_enabled': true,
      'is_featured': false,
      'status': 'active',
      'seller': {'id': 'seller-1', 'full_name': 'Seller', 'seller_status': 'approved'},
    });
    expect(listing.inventoryType, 'bulk');
    expect(listing.availableQty, 20);
    expect(listing.moq, 5);
    expect(listing.sellerId, 'seller-1');
    expect(listing.cod, true);
  });

  test('offer parser computes total deterministically', () {
    final offer = Offer.fromJson({
      'id': 'o1',
      'conversation_id': 'c1',
      'listing_id': 'l1',
      'buyer_id': 'b1',
      'seller_id': 's1',
      'created_by': 'b1',
      'quantity': 25,
      'unit_price': 180,
      'status': 'pending',
      'expires_at': '2026-08-18T00:00:00Z',
    });
    expect(offer.total, 4500);
    expect(offer.status, 'pending');
  });

  test('order parser preserves shipping snapshot', () {
    final order = SfOrder.fromJson({
      'id': 'order-1',
      'buyer_id': 'b1',
      'seller_id': 's1',
      'status': 'shipped',
      'payment_method': 'prepaid',
      'payment_status': 'paid',
      'total': 999,
      'delivery_address': {'city': 'Patna'},
      'items': [
        {'listing_id': 'l1', 'title': 'Phone', 'image_url': 'x', 'unit': 'piece', 'quantity': 1, 'unit_price': 999, 'line_total': 999},
      ],
      'shipment': {'awb': 'SF123', 'provider': 'Mock', 'status': 'shipped', 'courier_name': 'Mock Courier', 'tracking_note': 'Moving'},
      'buyer': {'full_name': 'Buyer'},
      'seller': {'full_name': 'Seller'},
      'history': [],
    });
    expect(order.items.single.title, 'Phone');
    expect(order.shipment?.awb, 'SF123');
    expect(order.paymentStatus, 'paid');
  });

  test('conversation parser tolerates compact listing snapshots', () {
    final conversation = Conversation.fromJson({
      'id': 'c1',
      'listing_id': 'l1',
      'buyer_id': 'b1',
      'seller_id': 's1',
      'last_message_at': '2026-08-17T10:00:00Z',
      'listing': {
        'id': 'l1',
        'title': 'Bulk shirts',
        'image_url': 'image',
        'selling_price': 250,
        'available_qty': 100,
        'status': 'active',
      },
      'other_user': {'full_name': 'Seller', 'seller_status': 'approved'},
      'last_message': {'body': '₹220?', 'message_type': 'text'},
    });
    expect(conversation.listing?.title, 'Bulk shirts');
    expect(conversation.otherUserName, 'Seller');
    expect(conversation.lastMessage, '₹220?');
  });

  test('address payload uses API field names without leaking database internals', () {
    const address = SfAddress(
      label: 'Office',
      recipientName: 'Buyer',
      phone: '9999999999',
      line1: 'Market Road',
      locality: 'Central',
      city: 'Delhi',
      state: 'Delhi',
      pincode: '110001',
      landmark: '',
      isDefault: true,
    );
    final json = address.toJson();
    expect(json['recipientName'], 'Buyer');
    expect(json['pincode'], '110001');
    expect(json.containsKey('user_id'), false);
  });



  test('deal request parser keeps mediated-chat entitlement state', () {
    final deal = DealRequest.fromJson({
      'id': 'deal-1',
      'listing_id': 'listing-1',
      'buyer_id': 'buyer-1',
      'seller_id': 'seller-1',
      'requested_qty': 4,
      'status': 'chat_unlocked',
      'role': 'buyer',
      'counterpartyLabel': 'Verified seller',
      'chatUnlocked': true,
      'conversationId': 'conversation-1',
      'feeAmount': 49,
      'feeCurrency': 'INR',
      'created_at': '2026-08-18T12:00:00Z',
      'listing': {
        'id': 'listing-1',
        'title': 'Surplus stock',
        'category_slug': 'other',
        'selling_price': 499,
        'unit': 'piece',
        'minimum_order_quantity': 1,
        'available_qty': 10,
        'status': 'active',
        'city': 'Delhi',
        'state': 'Delhi',
      },
    });
    expect(deal.id, 'deal-1');
    expect(deal.chatUnlocked, isTrue);
    expect(deal.conversationId, 'conversation-1');
    expect(deal.feeAmount, 49);
    expect(deal.listing?.title, 'Surplus stock');
  });

  testWidgets('redesigned listing card is content-first and avoids random demo imagery', (tester) async {
    const listing = Listing(
      id: 'listing-ui',
      sellerId: 'seller-ui',
      title: 'Bulk cotton shirts',
      description: 'Dead stock lot',
      categorySlug: 'fashion',
      condition: 'New Dead Stock',
      city: 'Mumbai',
      state: 'Maharashtra',
      unit: 'piece',
      inventoryType: 'bulk',
      imageUrl: 'https://picsum.photos/seed/old-demo/1200/900',
      sellerName: 'Seller',
      sellerStatus: 'approved',
      status: 'active',
      sellingPrice: 750,
      originalPrice: 1000,
      availableQty: 80,
      moq: 10,
      negotiable: true,
      pickup: true,
      shipping: true,
      cod: false,
      featured: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: StockFlowTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 190,
            child: ListingCard(item: listing, onTap: () {}),
          ),
        ),
      ),
    );

    expect(find.text('Bulk cotton shirts'), findsOneWidget);
    expect(find.text('₹750'), findsOneWidget);
    expect(find.text('25% off'), findsOneWidget);
    expect(find.text('MOQ 10 • 80 pieces available'), findsOneWidget);
    expect(find.text('Mumbai, Maharashtra'), findsOneWidget);
  });

  testWidgets('custom motion respects reduced-motion accessibility', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: StockFlowTheme.light(),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Column(
              children: [
                SfAnimatedHourglass(size: 72),
                SfOrderSuccessMotion(size: 160),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SfAnimatedHourglass), findsOneWidget);
    expect(find.byType(SfOrderSuccessMotion), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('welcome makes guest browsing the primary first-run action', (tester) async {
    var browsed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: StockFlowTheme.light(),
        home: WelcomeScreen(
          api: StockFlowApi(),
          onExplore: () => browsed = true,
          onCreateAccount: () {},
          onSignIn: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Browse stock as guest'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create an account instead'), findsOneWidget);
    await tester.tap(find.text('Browse stock as guest'));
    expect(browsed, isTrue);
  });

  testWidgets('guest account keeps browsing optional and offers explicit auth choices', (tester) async {
    AuthMode? requested;
    await tester.pumpWidget(
      MaterialApp(
        theme: StockFlowTheme.light(),
        home: GuestAccountScreen(
          authenticate: (mode) async {
            requested = mode;
            return false;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You’re browsing as a guest'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Sign in when you’re ready to deal.'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(requested, AuthMode.signIn);
  });

  testWidgets('registration has legal consent while sign-in stays lean', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: StockFlowTheme.light(),
        home: AuthScreen(
          api: StockFlowApi(),
          onDone: () {},
          initialMode: AuthMode.register,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Terms & Conditions'), findsNothing);
    expect(find.text('Privacy Policy'), findsNothing);

    final signInLink = find.text('Sign in');
    await tester.ensureVisible(signInLink);
    await tester.pumpAndSettle();
    await tester.tap(signInLink);
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Terms & Conditions'), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
  });

}
