import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/platform_ui.dart';
import '../core/theme.dart';
import '../widgets/product_image.dart';
import '../widgets/sf_ui.dart';
import 'edit_listing_screen.dart';
import 'listing_detail_screen.dart';
import 'orders_screen.dart';

class MyStockScreen extends StatefulWidget {
  final StockFlowApi api;
  final VoidCallback onStartSelling;

  const MyStockScreen({super.key, required this.api, required this.onStartSelling});

  @override
  State<MyStockScreen> createState() => _MyStockScreenState();
}

class _MyStockScreenState extends State<MyStockScreen> {
  Future<Map<String, dynamic>>? statusFuture;
  Future<List<Listing>>? listingsFuture;
  int segment = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    statusFuture = widget.api.sellerStatus();
    listingsFuture = widget.api.myListings().catchError((_) => <Listing>[]);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await Future.wait([statusFuture!, listingsFuture!]);
  }

  Future<void> _editAndResubmit(Listing item) async {
    final changed = await Navigator.push<bool>(
      context,
      SfPlatform.route(context, (_) => EditListingScreen(api: widget.api, item: item)),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing resubmitted for admin review.')));
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My stock'),
        actions: [
          IconButton(
            tooltip: 'Seller orders',
            onPressed: () => Navigator.push(context, SfPlatform.route(context, (_) => OrdersScreen(api: widget.api, initialSellerMode: true))),
            icon: const Icon(Icons.local_shipping_outlined),
          ),
          IconButton(onPressed: widget.onStartSelling, tooltip: 'Post stock', icon: const Icon(Icons.add_rounded)),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Map<String, dynamic>>(
          future: statusFuture,
          builder: (context, statusSnapshot) {
            if (statusSnapshot.connectionState != ConnectionState.done) {
              return ListView(padding: const EdgeInsets.all(18), children: const [SfListSkeleton(rows: 5)]);
            }

            final status = '${statusSnapshot.data?['sellerStatus'] ?? widget.api.currentUser?.sellerStatus ?? 'not_applied'}';
            if (status != 'approved') {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 110),
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 44, color: StockFlowTheme.muted),
                  const SizedBox(height: 18),
                  Text(status == 'pending' ? 'Seller review in progress' : 'Start selling on StockFlow', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    status == 'pending'
                        ? 'Your seller profile is being reviewed. Listing tools will unlock after approval.'
                        : 'Verify your seller profile before publishing surplus inventory.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: StockFlowTheme.muted, height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(onPressed: widget.onStartSelling, child: Text(status == 'pending' ? 'View seller status' : 'Start seller verification')),
                ],
              );
            }

            return FutureBuilder<List<Listing>>(
              future: listingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return ListView(padding: const EdgeInsets.all(18), children: const [SfListSkeleton(rows: 5)]);
                }
                if (snapshot.hasError) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 70),
                      const Icon(Icons.cloud_off_outlined, size: 42, color: StockFlowTheme.muted),
                      const SizedBox(height: 12),
                      const Text('Could not load your stock', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    ],
                  );
                }

                final items = snapshot.data ?? const <Listing>[];
                final active = items.where((item) => item.status == 'active').toList();
                final other = items.where((item) => item.status != 'active').toList();
                final visible = segment == 0 ? active : other;

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
                  children: [
                    _StockTabs(
                      value: segment,
                      activeCount: active.length,
                      otherCount: other.length,
                      onChanged: (value) => setState(() => segment = value),
                    ),
                    const SizedBox(height: 8),
                    if (visible.isEmpty)
                      _EmptyStock(activeMode: segment == 0, onPost: widget.onStartSelling)
                    else
                      for (var index = 0; index < visible.length; index++) ...[
                        _StockRow(
                          item: visible[index],
                          onTap: visible[index].status == 'active'
                              ? () => Navigator.push(context, SfPlatform.route(context, (_) => ListingDetailScreen(api: widget.api, item: visible[index], requireAuth: () async => true)))
                              : () {},
                          onResubmit: visible[index].status == 'rejected' ? () => _editAndResubmit(visible[index]) : null,
                        ),
                        if (index != visible.length - 1) const Divider(height: 1, indent: 82),
                      ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StockTabs extends StatelessWidget {
  final int value;
  final int activeCount;
  final int otherCount;
  final ValueChanged<int> onChanged;

  const _StockTabs({required this.value, required this.activeCount, required this.otherCount, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: _StockTab(label: 'Active', count: activeCount, selected: value == 0, onTap: () => onChanged(0))),
          Expanded(child: _StockTab(label: 'Other', count: otherCount, selected: value == 1, onTap: () => onChanged(1))),
        ],
      );
}

class _StockTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _StockTab({required this.label, required this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: selected ? StockFlowTheme.accent : StockFlowTheme.line, width: selected ? 2 : 1))),
          child: Text('$label  $count', style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? StockFlowTheme.accentStrong : StockFlowTheme.textSecondary)),
        ),
      );
}
class _StockRow extends StatelessWidget {
  final Listing item;
  final VoidCallback onTap;
  final VoidCallback? onResubmit;
  const _StockRow({required this.item, required this.onTap, this.onResubmit});

  @override
  Widget build(BuildContext context) {
    final price = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(item.sellingPrice);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(width: 58, height: 58, child: ProductImage(url: item.imageUrl, category: item.categorySlug)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5))),
                      const SizedBox(width: 8),
                      Text(price, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${item.availableQty} ${item.unit} available • MOQ ${item.moq}', style: const TextStyle(color: StockFlowTheme.muted, fontSize: 11.5)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: item.status == 'active' ? const Color(0xFFE8F4EF) : item.status == 'rejected' ? const Color(0xFFFFF0ED) : StockFlowTheme.panel2, borderRadius: BorderRadius.circular(999)),
                        child: Text(item.status == 'pending_review' ? 'under review' : item.status.replaceAll('_', ' '), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: item.status == 'active' ? StockFlowTheme.accentStrong : item.status == 'rejected' ? StockFlowTheme.danger : StockFlowTheme.textSecondary)),
                      ),
                      const Spacer(),
                      if (onResubmit != null) TextButton(onPressed: onResubmit, child: const Text('Fix & resubmit')) else const Icon(Icons.chevron_right_rounded, size: 18, color: StockFlowTheme.muted),
                    ],
                  ),
                  if (item.status == 'rejected' && (item.moderationNote ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text('Admin: ${item.moderationNote}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: StockFlowTheme.danger, fontSize: 10.5, height: 1.3)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStock extends StatelessWidget {
  final bool activeMode;
  final VoidCallback onPost;
  const _EmptyStock({required this.activeMode, required this.onPost});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 54),
        child: Column(
          children: [
            Icon(activeMode ? Icons.inventory_2_outlined : Icons.history_rounded, size: 40, color: StockFlowTheme.muted),
            const SizedBox(height: 12),
            Text(activeMode ? 'No active stock' : 'No other listings', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            Text(activeMode ? 'Post a surplus lot to start receiving buyer interest.' : 'Pending review, rejected, sold and paused listings appear here.', textAlign: TextAlign.center, style: const TextStyle(color: StockFlowTheme.muted, fontSize: 12.5)),
            if (activeMode) ...[
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: onPost, icon: const Icon(Icons.add_rounded), label: const Text('Post stock')),
            ],
          ],
        ),
      );
}
