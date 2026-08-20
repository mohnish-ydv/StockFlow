import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/ad_config.dart';
import '../core/api.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/listing_media_gallery.dart';
import '../widgets/sf_map.dart';
import '../widgets/sf_ui.dart';

class ListingDetailScreen extends StatefulWidget {
  final StockFlowApi api;
  final Listing item;
  final Future<bool> Function() requireAuth;

  const ListingDetailScreen({
    super.key,
    required this.api,
    required this.item,
    required this.requireAuth,
  });

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  bool favorite = false;
  bool busy = false;
  late Listing _item;

  Listing get item => _item;
  bool get ownListing => item.sellerId.isNotEmpty && item.sellerId == widget.api.currentUser?.id;
  String money(num value) => NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(value);

  int get discount {
    final reference = item.originalPrice;
    if (reference == null || reference <= item.sellingPrice) return 0;
    return (((reference - item.sellingPrice) / reference) * 100).round();
  }

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    unawaited(_refreshDetail());
    widget.api.markRecentlyViewed(item.id);
    unawaited(widget.api.trackListingEvent(item.id, 'view'));
    widget.api.favoriteIds().then((ids) {
      if (mounted) setState(() => favorite = ids.contains(item.id));
    });
  }

  Future<void> _refreshDetail() async {
    try {
      final fresh = await widget.api.listing(widget.item.id);
      if (mounted) setState(() => _item = fresh);
    } catch (_) {
      // The list card already has enough data for a graceful detail fallback.
    }
  }

  Future<void> _reportListing() async {
    if (!await _ensureAuth() || !mounted || ownListing) return;
    final details = TextEditingController();
    var reason = 'Misleading information';
    final submit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Report listing', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                const Text('Reports go to StockFlow moderation. The seller does not see who reported the listing.', style: TextStyle(color: StockFlowTheme.muted, height: 1.4)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  items: const ['Misleading information','Prohibited / unsafe item','Duplicate listing','Suspicious pricing','Incorrect category','Other'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: (value) => setSheet(() => reason = value ?? reason),
                ),
                const SizedBox(height: 10),
                TextField(controller: details, maxLines: 3, maxLength: 500, decoration: const InputDecoration(labelText: 'Additional details (optional)')),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(sheetContext, true), child: const Text('Submit report'))),
              ],
            ),
          ),
        ),
      ),
    );
    final note = details.text.trim();
    details.dispose();
    if (submit != true) return;
    try {
      await widget.api.reportListing(listingId: item.id, reason: reason, details: note);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report sent to StockFlow moderation.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<bool> _ensureAuth() async {
    if (widget.api.currentUser != null) return true;
    return widget.requireAuth();
  }

  Future<void> _toggleFavorite() async {
    if (!await _ensureAuth()) return;
    if (!mounted) return;
    final added = await widget.api.toggleFavorite(item.id);
    await HapticFeedback.selectionClick();
    if (mounted) setState(() => favorite = added);
  }

  Future<void> _requestInterest() async {
    if (!await _ensureAuth()) return;
    if (!mounted || busy || ownListing) return;

    final quantity = TextEditingController(text: '${item.moq}');
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: StockFlowTheme.lineStrong, borderRadius: BorderRadius.circular(99)))),
              const SizedBox(height: 22),
              Container(width: 48, height: 48, decoration: BoxDecoration(color: StockFlowTheme.brandSoft, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.handshake_outlined, color: StockFlowTheme.accentStrong)),
              const SizedBox(height: 16),
              Text('Interested in this stock?', style: Theme.of(sheetContext).textTheme.headlineSmall),
              const SizedBox(height: 7),
              const Text('StockFlow will notify the seller and keep both sides’ contact details private. Our team can coordinate the deal without opening direct buyer–seller messaging.', style: TextStyle(color: StockFlowTheme.textSecondary, height: 1.5)),
              const SizedBox(height: 18),
              TextField(
                controller: quantity,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Quantity you need', helperText: 'MOQ ${item.moq} • ${item.availableQty} available'),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: StockFlowTheme.brandWash, borderRadius: BorderRadius.circular(14)),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 19, color: StockFlowTheme.accentStrong),
                    SizedBox(width: 9),
                    Expanded(child: Text('If you later want direct in-app chat, you can unlock a protected chat with a small promise fee from Deals.', style: TextStyle(color: StockFlowTheme.textSecondary, fontSize: 12, height: 1.45))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(sheetContext, true), child: const Text('Send interest request'))),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: TextButton(onPressed: () => Navigator.pop(sheetContext, false), child: const Text('Not now'))),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) {
      quantity.dispose();
      return;
    }
    final parsedQty = int.tryParse(quantity.text);
    quantity.dispose();
    if (parsedQty == null || parsedQty < item.moq || parsedQty > item.availableQty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Choose ${item.moq}–${item.availableQty} ${item.unit}.')));
      return;
    }

    setState(() => busy = true);
    try {
      final deal = await widget.api.createDealRequest(listingId: item.id, quantity: parsedQty);
      await HapticFeedback.selectionClick();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline_rounded, color: StockFlowTheme.success),
          title: const Text('Interest sent'),
          content: Text('The seller can now see your protected interest request for ${deal.requestedQty} ${item.unit} in Deals. StockFlow can coordinate the next step. If you want direct in-app chat, open Deals and unlock it with the promise fee.'),
          actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Done'))],
        ),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _addToCart() async {
    if (!await _ensureAuth()) return;
    if (!mounted || !item.shipping || ownListing || busy) return;
    setState(() => busy = true);
    try {
      await widget.api.addToCart(item.id, item.moq);
      unawaited(widget.api.trackListingEvent(item.id, 'cart'));
      await HapticFeedback.selectionClick();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: ownListing ? _ownerBar() : _buyerBar(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 390,
            pinned: true,
            backgroundColor: StockFlowTheme.ink,
            surfaceTintColor: Colors.transparent,
            leadingWidth: 62,
            leading: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Center(
                child: SfRoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              SfRoundIconButton(
                tooltip: favorite ? 'Remove from saved' : 'Save listing',
                icon: favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                foreground: favorite ? StockFlowTheme.danger : null,
                onTap: _toggleFavorite,
              ),
              const SizedBox(width: 14),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: StockFlowTheme.surface,
                padding: const EdgeInsets.only(top: 74),
                child: ListingMediaGallery(listing: item),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 38),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '${money(item.sellingPrice)} / ${item.unit}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      if (discount > 0)
                        SfPill(label: '$discount% below ref.', color: StockFlowTheme.success),
                    ],
                  ),
                  if (item.originalPrice != null && item.originalPrice! > item.sellingPrice) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Reference ${money(item.originalPrice!)}',
                      style: const TextStyle(color: StockFlowTheme.muted, fontSize: 12, decoration: TextDecoration.lineThrough),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(item.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: StockFlowTheme.muted),
                      const SizedBox(width: 5),
                      Expanded(child: Text('${item.city}, ${item.state}', style: Theme.of(context).textTheme.bodySmall)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _QuickFacts(item: item),
                  const SizedBox(height: 28),
                  _DividerSection(
                    title: 'Fulfilment',
                    child: Column(
                      children: [
                        if (item.shipping)
                          const _DetailRow(icon: Icons.local_shipping_outlined, title: 'Shipping available', subtitle: 'Arrange delivery from the order flow.'),
                        if (item.pickup)
                          const _DetailRow(icon: Icons.storefront_outlined, title: 'Pickup available', subtitle: 'StockFlow coordinates pickup until protected chat is unlocked.'),
                        if (item.cod)
                          const _DetailRow(icon: Icons.payments_outlined, title: 'Cash on delivery', subtitle: 'Available when supported for the order.'),
                      ],
                    ),
                  ),
                  _DividerSection(
                    title: 'About this stock',
                    child: Text(
                      item.description.trim().isEmpty ? 'Seller has not added a description yet.' : item.description.trim(),
                      style: const TextStyle(color: StockFlowTheme.textSecondary, fontSize: 14, height: 1.55),
                    ),
                  ),
                  const SfAdSlot(slotId: 'listing_detail_mid'),
                  if (StockFlowAdConfig.enabled) const SizedBox(height: 18),
                  _DividerSection(
                    title: 'Seller',
                    child: _SellerBlock(item: item),
                  ),
                  if (item.hasApproximateLocation)
                    _DividerSection(
                      title: 'Posted around ${item.city}',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SfApproximateLocationMap(
                            latitude: item.approximateLatitude!,
                            longitude: item.approximateLongitude!,
                            radiusKm: item.approximateRadiusKm,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.privacy_tip_outlined, size: 17, color: StockFlowTheme.accent),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  'Approximate ${item.approximateRadiusKm.round()} km area only. The exact seller address and GPS coordinates stay private.',
                                  style: const TextStyle(color: StockFlowTheme.muted, fontSize: 11.5, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  _DividerSection(
                    title: 'Listing details',
                    child: Column(
                      children: [
                        if ((item.brand ?? '').trim().isNotEmpty) _MetaLine(label: 'Brand', value: item.brand!.trim()),
                        _MetaLine(label: 'Condition', value: _pretty(item.condition)),
                        _MetaLine(label: 'Stock type', value: _pretty(item.inventoryType)),
                        _MetaLine(label: 'Category', value: _pretty(item.categorySlug)),
                        _MetaLine(label: 'Deal flow', value: item.negotiable ? 'StockFlow-mediated • offers after chat unlock' : 'StockFlow-mediated • fixed price'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: StockFlowTheme.line))),
                    child: Row(
                      children: [
                        Expanded(child: Text('Listing ID  ${item.shortId}', style: const TextStyle(color: StockFlowTheme.muted, fontSize: 11.5, fontWeight: FontWeight.w600))),
                        if (!ownListing)
                          TextButton.icon(onPressed: _reportListing, icon: const Icon(Icons.flag_outlined, size: 17), label: const Text('Report')),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_outlined, size: 18, color: StockFlowTheme.muted),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Buyer and seller contact details stay private by default. StockFlow can mediate the deal; protected in-app chat unlocks only after the promise fee.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownerBar() => SfStickyActionBar(
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 20, color: StockFlowTheme.textSecondary),
            const SizedBox(width: 10),
            const Expanded(child: Text('This is your listing', style: TextStyle(fontWeight: FontWeight.w700))),
            Text('${item.availableQty} ${item.unit}', style: const TextStyle(color: StockFlowTheme.muted, fontSize: 12)),
          ],
        ),
      );

  Widget _buyerBar() => SfStickyActionBar(
        child: busy
            ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
            : Row(
                children: [
                  if (item.shipping) ...[
                    SfRoundIconButton(icon: Icons.shopping_bag_outlined, tooltip: 'Add to cart', onTap: _addToCart),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _requestInterest,
                      icon: const Icon(Icons.handshake_outlined),
                      label: const Text('I’m interested'),
                    ),
                  ),
                ],
              ),
      );
}

class _QuickFacts extends StatelessWidget {
  final Listing item;
  const _QuickFacts({required this.item});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: _Fact(value: '${item.moq}', label: 'MOQ')),
          Container(width: 1, height: 42, color: StockFlowTheme.line),
          Expanded(child: _Fact(value: '${item.availableQty}', label: 'Available')),
          Container(width: 1, height: 42, color: StockFlowTheme.line),
          Expanded(child: _Fact(value: _pretty(item.condition), label: 'Condition')),
        ],
      );
}

class _Fact extends StatelessWidget {
  final String value;
  final String label;
  const _Fact({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      );
}

class _DividerSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _DividerSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: StockFlowTheme.line))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _DetailRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: StockFlowTheme.brandWash, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 19, color: StockFlowTheme.accentStrong),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SellerBlock extends StatelessWidget {
  final Listing item;
  const _SellerBlock({required this.item});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SfAvatar(name: item.sellerName, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(item.sellerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700))),
                    if (item.sellerStatus == 'approved') ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.verified_rounded, size: 16, color: StockFlowTheme.accent),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(item.sellerStatus == 'approved' ? 'Seller reviewed by StockFlow' : 'Marketplace seller', style: Theme.of(context).textTheme.bodySmall),
                if (item.sellerMemberSince != null) ...[
                  const SizedBox(height: 2),
                  Text('Member since ${DateFormat('MMM yyyy').format(item.sellerMemberSince!.toLocal())}', style: const TextStyle(color: StockFlowTheme.muted, fontSize: 10.5)),
                ],
              ],
            ),
          ),
        ],
      );
}

class _MetaLine extends StatelessWidget {
  final String label;
  final String value;
  const _MetaLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 104, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
            Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

String _pretty(String raw) {
  final clean = raw.replaceAll('-', ' ').replaceAll('_', ' ').trim();
  if (clean.isEmpty) return '—';
  return clean.split(' ').where((e) => e.isNotEmpty).map((word) => '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
}
