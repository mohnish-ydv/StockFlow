import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/motion.dart';
import '../core/platform_ui.dart';
import '../core/theme.dart';
import '../widgets/product_image.dart';
import 'checkout_screen.dart';

class ChatThreadScreen extends StatefulWidget {
  final StockFlowApi api;
  final String conversationId;
  final Listing? listing;
  final String otherUserName;

  const ChatThreadScreen({
    super.key,
    required this.api,
    required this.conversationId,
    this.listing,
    this.otherUserName = 'StockFlow user',
  });

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _message = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _timer;

  String money(num n) => NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);

  bool get _currentUserIsSeller => widget.listing?.sellerId == widget.api.currentUser?.id;
  bool get _otherUserIsSeller => widget.listing != null && !_currentUserIsSeller;

  @override
  void initState() {
    super.initState();
    _load(showLoader: true);
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoader = false}) async {
    if (showLoader && mounted) setState(() => _loading = true);
    try {
      final rows = await widget.api.messages(widget.conversationId);
      if (!mounted) return;
      final changed = rows.length != _messages.length ||
          (rows.isNotEmpty && _messages.isNotEmpty && rows.last.id != _messages.last.id) ||
          (rows.isNotEmpty && _messages.isNotEmpty && rows.last.offer?.status != _messages.last.offer?.status);
      setState(() {
        _messages = rows;
        _loading = false;
        _error = null;
      });
      if (changed) _jumpToBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$e';
        });
      }
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: SfMotion.reduce(context) ? Duration.zero : const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  bool _looksLikeContactExchange(String text) {
    final lower = text.toLowerCase();
    return RegExp(r'[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}', caseSensitive: false).hasMatch(lower) ||
        RegExp(r'(https?://|www\.|wa\.me|t\.me|telegram\.me|instagram\.com|facebook\.com)', caseSensitive: false).hasMatch(lower) ||
        RegExp(r'(^|[^a-z])(whatsapp|telegram|instagram|snapchat)([^a-z]|$)', caseSensitive: false).hasMatch(lower) ||
        RegExp(r'(^|[^a-z])(call|contact|text|message|dm|ping)\s+(me|us)([^a-z]|$)', caseSensitive: false).hasMatch(lower) ||
        RegExp(r'(?:^|[^0-9])(?:\+?91[\s.-]?)?[6-9](?:[\s.-]?[0-9]){9}(?:[^0-9]|$)').hasMatch(lower);
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty || _sending) return;
    if (_looksLikeContactExchange(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact details and external links are blocked. Keep the deal inside StockFlow.')),
      );
      return;
    }
    setState(() => _sending = true);
    _message.clear();
    try {
      await widget.api.sendMessage(widget.conversationId, text);
      await _load();
    } catch (e) {
      _message.text = text;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 2,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(color: StockFlowTheme.panel2, shape: BoxShape.circle),
              child: Icon(_otherUserIsSeller ? Icons.storefront_outlined : Icons.person_outline_rounded, color: StockFlowTheme.textSecondary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.otherUserName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (_otherUserIsSeller && listing?.sellerStatus == 'approved') ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: StockFlowTheme.accent, size: 15),
                      ],
                    ],
                  ),
                  const Text(
                    'Promise-fee protected chat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: StockFlowTheme.muted, fontSize: 10.5, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 6, 12, 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: StockFlowTheme.brandWash, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: StockFlowTheme.accentStrong),
                SizedBox(width: 7),
                Expanded(child: Text('Protected chat • contact details & external links are blocked', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, color: StockFlowTheme.textSecondary, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          Expanded(child: _body()),
          _composer(),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
        children: [
          if (widget.listing != null) _listingContext(widget.listing!),
          const SizedBox(height: 18),
          const _ThreadSkeleton(alignment: Alignment.centerLeft, width: 230),
          const _ThreadSkeleton(alignment: Alignment.centerRight, width: 270),
          const _ThreadSkeleton(alignment: Alignment.centerLeft, width: 190),
        ],
      );
    }
    if (_error != null && _messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, size: 42, color: StockFlowTheme.muted),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: StockFlowTheme.muted)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () => _load(showLoader: true), child: const Text('Try again')),
          ]),
        ),
      );
    }

    final extra = widget.listing == null ? 0 : 1;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
      itemCount: _messages.length + extra,
      itemBuilder: (_, index) {
        if (extra == 1 && index == 0) return _listingContext(widget.listing!);
        final message = _messages[index - extra];
        return _messageTile(message);
      },
    );
  }

  Widget _listingContext(Listing listing) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: StockFlowTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: StockFlowTheme.line),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(width: 58, height: 58, child: ProductImage(url: listing.imageUrl, category: listing.categorySlug)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${money(listing.sellingPrice)} / ${listing.unit}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('${listing.availableQty} ${listing.unit} available · MOQ ${listing.moq}', style: const TextStyle(color: StockFlowTheme.muted, fontSize: 10.5)),
                ],
              ),
            ),
            if (listing.negotiable && listing.sellerId != widget.api.currentUser?.id)
              TextButton(
                onPressed: () => _openOfferSheet(listing),
                child: const Text('Offer'),
              ),
          ],
        ),
      );

  Widget _messageTile(ChatMessage message) {
    if (message.type == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 290),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: StockFlowTheme.panel2, borderRadius: BorderRadius.circular(10)),
            child: Text(message.body, textAlign: TextAlign.center, style: const TextStyle(color: StockFlowTheme.muted, fontSize: 10.5)),
          ),
        ),
      );
    }
    if (message.type == 'offer' && message.offer != null) return _offerCard(message.offer!);
    if (message.type == 'order' && message.orderPreview != null) return _orderCard(message);

    final mine = message.senderId == widget.api.currentUser?.id;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .70),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 5),
        decoration: BoxDecoration(
          color: mine ? StockFlowTheme.brandSoft : StockFlowTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(13),
            topRight: const Radius.circular(13),
            bottomLeft: Radius.circular(mine ? 13 : 3),
            bottomRight: Radius.circular(mine ? 3 : 13),
          ),
          border: Border.all(color: mine ? StockFlowTheme.lineStrong : StockFlowTheme.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(alignment: Alignment.centerLeft, child: Text(message.body, style: const TextStyle(fontSize: 13, height: 1.28))),
            const SizedBox(height: 2),
            Text(_time(message.createdAt), style: const TextStyle(color: StockFlowTheme.muted, fontSize: 8.5)),
          ],
        ),
      ),
    );
  }

  Widget _offerCard(Offer offer) {
    final mine = offer.createdBy == widget.api.currentUser?.id;
    final canRespond = offer.status == 'pending' && !mine;
    final canCheckout = offer.status == 'accepted' && offer.buyerId == widget.api.currentUser?.id;
    final label = mine ? 'Your offer' : (_currentUserIsSeller ? 'Buyer offer' : 'Seller offer');
    final status = _offerStatus(offer.status);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedContainer(
        duration: SfMotion.reduce(context) ? Duration.zero : SfMotion.standard,
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .82),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
        decoration: BoxDecoration(
          color: status.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: status.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer_outlined, size: 16, color: status.foreground),
                const SizedBox(width: 6),
                Expanded(child: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
                AnimatedSwitcher(
                  duration: SfMotion.reduce(context) ? Duration.zero : SfMotion.standard,
                  child: _statusChip(offer.status, key: ValueKey(offer.status)),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text('${money(offer.unitPrice)} / ${widget.listing?.unit ?? 'unit'} × ${offer.quantity}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('${money(offer.total)} total', style: const TextStyle(color: StockFlowTheme.textSecondary, fontSize: 12)),
            if (offer.status == 'pending') ...[
              const SizedBox(height: 7),
              Text(
                mine ? 'Waiting for a response · ${_expires(offer.expiresAt)}' : 'Respond before ${_expires(offer.expiresAt)}',
                style: const TextStyle(color: StockFlowTheme.muted, fontSize: 10.5),
              ),
            ],
            if (canRespond) ...[
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => _respond(offer, 'rejected'), child: const Text('Decline'))),
                  const SizedBox(width: 5),
                  Expanded(child: OutlinedButton(onPressed: () => _openCounterSheet(offer), child: const Text('Counter'))),
                  const SizedBox(width: 5),
                  Expanded(child: FilledButton(onPressed: () => _respond(offer, 'accepted'), child: const Text('Accept'))),
                ],
              ),
            ],
            if (canCheckout) ...[
              const SizedBox(height: 11),
              FilledButton.icon(
                onPressed: () => _checkoutOffer(offer),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Checkout at agreed price'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _orderCard(ChatMessage message) {
    final order = message.orderPreview!;
    final status = '${order['status'] ?? ''}'.replaceAll('_', ' ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: StockFlowTheme.brandWash, borderRadius: BorderRadius.circular(13), border: Border.all(color: StockFlowTheme.lineStrong)),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.local_shipping_outlined, color: StockFlowTheme.accent, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(message.body, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
              const SizedBox(height: 2),
              Text(status, style: const TextStyle(color: StockFlowTheme.muted, fontSize: 10.5)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _composer() {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _message,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(hintText: 'Message inside StockFlow', isDense: true),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedScale(
            scale: _sending ? .92 : 1,
            duration: SfMotion.reduce(context) ? Duration.zero : SfMotion.quick,
            child: IconButton.filled(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.arrow_upward_rounded),
            ),
          ),
        ],
      ),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: StockFlowTheme.surface,
        border: Border(top: BorderSide(color: StockFlowTheme.line)),
      ),
      child: SafeArea(top: false, child: content),
    );
  }

  Widget _statusChip(String value, {Key? key}) {
    final status = _offerStatus(value);
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(color: status.chip, borderRadius: BorderRadius.circular(8)),
      child: Text(_pretty(value), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: status.foreground)),
    );
  }

  _OfferPalette _offerStatus(String value) {
    switch (value) {
      case 'accepted':
        return const _OfferPalette(StockFlowTheme.brandWash, StockFlowTheme.lineStrong, StockFlowTheme.accentStrong, StockFlowTheme.brandSoft);
      case 'rejected':
      case 'cancelled':
      case 'expired':
        return const _OfferPalette(Color(0xFFFAF5F3), Color(0xFFE5D4CE), Color(0xFF8B4F3F), Color(0xFFF1E3DE));
      case 'countered':
        return const _OfferPalette(Color(0xFFF8F6F0), Color(0xFFE1D7C1), Color(0xFF80601F), Color(0xFFF0E7D4));
      default:
        return const _OfferPalette(Color(0xFFFFFBF3), Color(0xFFE9D9B8), StockFlowTheme.amber, Color(0xFFF4E8CD));
    }
  }

  String _pretty(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  String _time(DateTime? value) {
    if (value == null) return '';
    return DateFormat('h:mm a').format(value.toLocal());
  }

  String _expires(DateTime? value) {
    if (value == null) return 'soon';
    final difference = value.toLocal().difference(DateTime.now());
    if (difference.isNegative) return 'expired';
    if (difference.inHours >= 1) return '${difference.inHours}h left';
    return '${difference.inMinutes.clamp(1, 59)}m left';
  }

  Future<void> _respond(Offer offer, String decision) async {
    try {
      await widget.api.respondOffer(offer.id, decision);
      await HapticFeedback.selectionClick();
      await _load();
      if (mounted) {
        final text = decision == 'accepted' ? 'Offer accepted' : 'Offer declined';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), duration: const Duration(milliseconds: 1200)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _openOfferSheet(Listing listing) async {
    final qty = TextEditingController(text: '${listing.moq}');
    final price = TextEditingController(text: listing.sellingPrice.toStringAsFixed(0));
    final ok = await _priceSheet(context, title: 'Make an offer', quantity: qty, price: price, unit: listing.unit, max: listing.availableQty);
    try {
      if (ok != true) return;
      final parsedQty = int.tryParse(qty.text.trim());
      final parsedPrice = double.tryParse(price.text.trim());
      if (parsedQty == null || parsedPrice == null || parsedQty < listing.moq || parsedQty > listing.availableQty || parsedPrice <= 0) {
        throw const ApiException('Enter a valid quantity and offer price.');
      }
      await widget.api.makeOffer(listingId: listing.id, quantity: parsedQty, unitPrice: parsedPrice);
      unawaited(widget.api.trackListingEvent(listing.id, 'offer'));
      await HapticFeedback.selectionClick();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer sent'), duration: Duration(milliseconds: 1100)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      qty.dispose();
      price.dispose();
    }
  }

  Future<void> _openCounterSheet(Offer offer) async {
    final qty = TextEditingController(text: '${offer.quantity}');
    final price = TextEditingController(text: offer.unitPrice.toStringAsFixed(0));
    final ok = await _priceSheet(
      context,
      title: 'Counter offer',
      quantity: qty,
      price: price,
      unit: widget.listing?.unit ?? 'units',
      max: widget.listing?.availableQty ?? 999999,
    );
    try {
      if (ok != true) return;
      final parsedQty = int.tryParse(qty.text.trim());
      final parsedPrice = double.tryParse(price.text.trim());
      if (parsedQty == null || parsedPrice == null || parsedQty < 1 || parsedPrice <= 0) {
        throw const ApiException('Enter a valid quantity and counter price.');
      }
      await widget.api.counterOffer(offerId: offer.id, quantity: parsedQty, unitPrice: parsedPrice);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      qty.dispose();
      price.dispose();
    }
  }

  Future<bool?> _priceSheet(
    BuildContext context, {
    required String title,
    required TextEditingController quantity,
    required TextEditingController price,
    required String unit,
    required int max,
  }) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, MediaQuery.viewInsetsOf(context).bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('Set quantity and your price per $unit.', style: const TextStyle(color: StockFlowTheme.muted)),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: TextField(controller: quantity, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Quantity', helperText: 'Max $max'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price / unit', prefixText: '₹ '))),
            ]),
            const SizedBox(height: 18),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send offer')),
          ]),
        ),
      );

  Future<void> _checkoutOffer(Offer offer) async {
    try {
      final listing = await widget.api.listing(offer.listingId);
      if (!mounted) return;
      if (!listing.shipping) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This offer is for local pickup. Finalize the meetup in chat.')));
        return;
      }
      await Navigator.push(
        context,
        SfPlatform.route(
          context,
          (_) => CheckoutScreen(
            api: widget.api,
            listing: listing,
            initialQuantity: offer.quantity,
            lockedUnitPrice: offer.unitPrice,
            offerId: offer.id,
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

class _OfferPalette {
  final Color background;
  final Color border;
  final Color foreground;
  final Color chip;
  const _OfferPalette(this.background, this.border, this.foreground, this.chip);
}

class _ThreadSkeleton extends StatelessWidget {
  final Alignment alignment;
  final double width;
  const _ThreadSkeleton({required this.alignment, required this.width});

  @override
  Widget build(BuildContext context) => Align(
        alignment: alignment,
        child: SfShimmer(
          child: Container(
            width: width,
            height: 54,
            margin: const EdgeInsets.only(bottom: 9),
            decoration: BoxDecoration(color: StockFlowTheme.panel2, borderRadius: BorderRadius.circular(15)),
          ),
        ),
      );
}
