import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/motion.dart';
import '../core/platform_ui.dart';
import '../core/theme.dart';
import '../widgets/listing_card.dart';
import '../widgets/sf_ui.dart';
import 'cart_screen.dart';
import 'help_safety_screen.dart';
import 'listing_detail_screen.dart';
import 'offers_screen.dart';
import 'orders_screen.dart';
import 'settings_screen.dart';

class AccountScreen extends StatelessWidget {
  final StockFlowApi api;
  final Future<void> Function() logout;
  final VoidCallback onOpenMyStock;
  final VoidCallback onStartSelling;

  const AccountScreen({
    super.key,
    required this.api,
    required this.logout,
    required this.onOpenMyStock,
    required this.onStartSelling,
  });

  @override
  Widget build(BuildContext context) {
    final user = api.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
        children: [
          _Profile(user: user),
          const SizedBox(height: 30),
          const _Label('Buying'),
          SfListRow(icon: Icons.shopping_bag_outlined, title: 'Cart', onTap: () => Navigator.push(context, SfPlatform.route(context, (_) => CartScreen(api: api)))),
          const Divider(height: 1, indent: 38),
          SfListRow(icon: Icons.local_shipping_outlined, title: 'Orders', onTap: () => Navigator.push(context, SfPlatform.route(context, (_) => OrdersScreen(api: api)))),
          const Divider(height: 1, indent: 38),
          SfListRow(icon: Icons.local_offer_outlined, title: 'Offers', onTap: () => Navigator.push(context, SfPlatform.route(context, (_) => OffersScreen(api: api)))),
          const Divider(height: 1, indent: 38),
          SfListRow(icon: Icons.favorite_border_rounded, title: 'Saved stock', onTap: () => Navigator.push(context, SfPlatform.route(context, (_) => _SavedScreen(api: api, recent: false)))),
          const Divider(height: 1, indent: 38),
          SfListRow(icon: Icons.history_rounded, title: 'Recently viewed', onTap: () => Navigator.push(context, SfPlatform.route(context, (_) => _SavedScreen(api: api, recent: true)))),
          const SizedBox(height: 26),
          const _Label('Selling'),
          SfListRow(icon: Icons.inventory_2_outlined, title: 'My stock', onTap: onOpenMyStock),
          const Divider(height: 1, indent: 38),
          SfListRow(
            icon: Icons.add_circle_outline_rounded,
            title: user.sellerStatus == 'approved' ? 'Post new stock' : 'Seller access',
            subtitle: user.sellerStatus == 'approved' ? 'Create a new listing' : 'Apply or check verification',
            onTap: onStartSelling,
          ),
          if (user.sellerStatus == 'approved') ...[
            const Divider(height: 1, indent: 38),
            SfListRow(icon: Icons.outbox_outlined, title: 'Seller orders', onTap: () => Navigator.push(context, SfPlatform.route(context, (_) => OrdersScreen(api: api, initialSellerMode: true)))),
          ],
          const SizedBox(height: 26),
          const _Label('Preferences'),
          SfListRow(icon: Icons.settings_outlined, title: 'Settings', onTap: () => Navigator.push(context, SfPlatform.route(context, (_) => SettingsScreen(user: user)))),
          const Divider(height: 1, indent: 38),
          SfListRow(icon: Icons.help_outline_rounded, title: 'Help & safety', onTap: () => Navigator.push(context, SfPlatform.route(context, (_) => const HelpSafetyScreen()))),
          const SizedBox(height: 28),
          TextButton.icon(
            onPressed: logout,
            icon: const Icon(Icons.logout_rounded, size: 19),
            label: const Text('Sign out'),
            style: TextButton.styleFrom(foregroundColor: StockFlowTheme.danger, alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }
}

class _Profile extends StatelessWidget {
  final SfUser user;
  const _Profile({required this.user});

  @override
  Widget build(BuildContext context) {
    final masked = user.phone.length >= 4 ? user.phone.substring(user.phone.length - 4) : user.phone;
    return Row(
      children: [
        SfAvatar(name: user.fullName.isEmpty ? 'StockFlow' : user.fullName, size: 62),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(child: Text(user.fullName.isEmpty ? 'StockFlow user' : user.fullName, style: Theme.of(context).textTheme.titleLarge)),
                  if (user.sellerStatus == 'approved') ...[
                    const SizedBox(width: 5),
                    const Icon(Icons.verified_rounded, color: StockFlowTheme.accent, size: 17),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text([user.city, user.state].where((e) => e.trim().isNotEmpty).join(', '), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text('+91 ••••••$masked', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: Theme.of(context).textTheme.labelMedium),
      );
}

class _SavedScreen extends StatefulWidget {
  final StockFlowApi api;
  final bool recent;
  const _SavedScreen({required this.api, required this.recent});

  @override
  State<_SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<_SavedScreen> {
  Future<List<Listing>>? future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<List<Listing>> load() async {
    final ids = widget.recent ? await widget.api.recentIds() : (await widget.api.favoriteIds()).toList();
    if (ids.isEmpty) return const [];
    final all = await widget.api.feed();
    final byId = {for (final item in all) item.id: item};
    return ids.map((id) => byId[id]).whereType<Listing>().toList();
  }

  int _columns(double width) {
    if (width >= 1100) return 5;
    if (width >= 820) return 4;
    if (width >= 620) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final columns = _columns(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: AppBar(title: Text(widget.recent ? 'Recently viewed' : 'Saved stock')),
      body: FutureBuilder<List<Listing>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.all(18), child: SfListSkeleton(rows: 4));
          final items = snapshot.data ?? const <Listing>[];
          if (items.isEmpty) {
            return SfEmptyState(
              icon: widget.recent ? Icons.history_rounded : Icons.favorite_border_rounded,
              title: widget.recent ? 'No recent stock' : 'Nothing saved yet',
              body: widget.recent ? 'Listings you open will appear here.' : 'Use the heart on a listing to save it here.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: columns == 2 ? .65 : .70,
              crossAxisSpacing: 12,
              mainAxisSpacing: 18,
            ),
            itemCount: items.length,
            itemBuilder: (_, index) => SfFadeSlideIn(
              index: index,
              child: ListingCard(
                item: items[index],
                onTap: () => Navigator.push(
                  context,
                  SfPlatform.route(context, (_) => ListingDetailScreen(api: widget.api, item: items[index], requireAuth: () async => true)),
                ).then((_) => setState(() => future = load())),
              ),
            ),
          );
        },
      ),
    );
  }
}
