import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/platform_ui.dart';
import '../core/theme.dart';
import '../widgets/product_image.dart';
import '../widgets/sf_ui.dart';
import 'chat_thread_screen.dart';

class ChatsScreen extends StatefulWidget {
  final StockFlowApi api;
  const ChatsScreen({super.key, required this.api});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  Future<List<DealRequest>>? _future;
  bool selling = false;
  String? busyDealId;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() => setState(() => _future = widget.api.dealRequests(selling: selling));

  String _statusLabel(String status) => switch (status) {
        'pending_admin' => 'Sent to StockFlow',
        'contacting' => 'Team coordinating',
        'awaiting_fee' => 'Chat available',
        'chat_unlocked' => 'Protected chat unlocked',
        'in_negotiation' => 'In negotiation',
        'converted' => 'Deal converted',
        'closed' => 'Closed',
        'cancelled' => 'Cancelled',
        _ => status.replaceAll('_', ' '),
      };

  String _statusBody(DealRequest deal) {
    if (deal.chatUnlocked) return 'Promise-fee protected chat is available. Contact details and external links remain blocked.';
    if (deal.isSeller) return 'A buyer has shown interest. StockFlow can coordinate both sides without exposing buyer contact details.';
    return 'Your interest is recorded. StockFlow can coordinate the deal, or you can unlock protected in-app chat with the promise fee.';
  }

  Future<void> _openChat(DealRequest deal) async {
    final id = deal.conversationId;
    if (id == null || id.isEmpty || !deal.chatUnlocked) return;
    if (deal.listingId.isNotEmpty) unawaited(widget.api.trackListingEvent(deal.listingId, 'chat'));
    await Navigator.push(
      context,
      SfPlatform.route(
        context,
        (_) => ChatThreadScreen(
          api: widget.api,
          conversationId: id,
          listing: deal.listing,
          otherUserName: deal.counterpartyLabel,
        ),
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _unlock(DealRequest deal) async {
    if (!deal.isBuyer || deal.chatUnlocked || busyDealId != null) return;
    setState(() => busyDealId = deal.id);
    try {
      final quote = await widget.api.promiseFeeQuote(deal.id);
      if (!mounted) return;
      final amount = double.tryParse('${quote['amount']}') ?? deal.feeAmount;
      final currency = '${quote['currency'] ?? deal.feeCurrency}';
      final staging = quote['staging'] == true;
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: StockFlowTheme.lineStrong, borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: StockFlowTheme.brandSoft, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.lock_open_rounded, color: StockFlowTheme.accentStrong),
                ),
                const SizedBox(height: 16),
                Text('Unlock protected chat', style: Theme.of(sheetContext).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Pay a small promise fee to open buyer–seller chat for this deal. The fee is non-refundable once chat is unlocked, except where required by law or if StockFlow fails to provide the unlock.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: StockFlowTheme.panel2, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_outlined, color: StockFlowTheme.accentStrong),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$currency ${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(staging ? 'Staging checkout — no real money is charged in this build.' : 'One-time promise fee for this deal.', style: Theme.of(sheetContext).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, size: 18, color: StockFlowTheme.muted),
                    SizedBox(width: 8),
                    Expanded(child: Text('Phone numbers, email addresses, social handles and external links are blocked in chat to keep the transaction inside StockFlow.', style: TextStyle(color: StockFlowTheme.textSecondary, fontSize: 12, height: 1.45))),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: Text(staging ? 'Confirm staging unlock' : 'Pay & unlock chat'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(onPressed: () => Navigator.pop(sheetContext, false), child: const Text('Keep admin-assisted deal')),
                ),
              ],
            ),
          ),
        ),
      );
      if (confirmed != true) return;
      final result = await widget.api.capturePromiseFee(deal.id);
      if (!mounted) return;
      final conversationId = '${result['conversationId'] ?? ''}'.trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['staging'] == true ? 'Protected chat unlocked in staging — no real money was charged.' : 'Protected chat unlocked.')),
      );
      _refresh();
      if (conversationId.isNotEmpty && deal.listing != null) {
        unawaited(widget.api.trackListingEvent(deal.listingId, 'chat'));
        await Navigator.push(
          context,
          SfPlatform.route(
            context,
            (_) => ChatThreadScreen(
              api: widget.api,
              conversationId: conversationId,
              listing: deal.listing,
              otherUserName: deal.counterpartyLabel,
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => busyDealId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deals'),
        actions: [IconButton(onPressed: _refresh, tooltip: 'Refresh', icon: const Icon(Icons.refresh_rounded))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: StockFlowTheme.panel2, borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  Expanded(child: _ModeButton(label: 'Buying', selected: !selling, onTap: () { if (selling) { selling = false; _refresh(); } })),
                  Expanded(child: _ModeButton(label: 'Selling', selected: selling, onTap: () { if (!selling) { selling = true; _refresh(); } })),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DealRequest>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.all(18), child: SfListSkeleton(rows: 5));
                if (snapshot.hasError) {
                  return _EmptyDeals(
                    icon: Icons.cloud_off_outlined,
                    title: 'Deals unavailable',
                    body: '${snapshot.error}',
                    action: 'Try again',
                    onTap: _refresh,
                  );
                }
                final deals = snapshot.data ?? const <DealRequest>[];
                if (deals.isEmpty) {
                  return _EmptyDeals(
                    icon: selling ? Icons.inventory_2_outlined : Icons.handshake_outlined,
                    title: selling ? 'No buyer interest yet' : 'No deal requests yet',
                    body: selling
                        ? 'When a buyer taps I’m interested on your stock, the request appears here without exposing their contact details.'
                        : 'Tap I’m interested on a listing. StockFlow will coordinate the deal without opening direct contact by default.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
                    itemCount: deals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _DealCard(
                      deal: deals[index],
                      statusLabel: _statusLabel(deals[index].status),
                      statusBody: _statusBody(deals[index]),
                      busy: busyDealId == deals[index].id,
                      onUnlock: () => _unlock(deals[index]),
                      onOpenChat: () => _openChat(deals[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(color: selected ? StockFlowTheme.surface : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? StockFlowTheme.text : StockFlowTheme.muted)),
        ),
      );
}

class _DealCard extends StatelessWidget {
  final DealRequest deal;
  final String statusLabel;
  final String statusBody;
  final bool busy;
  final VoidCallback onUnlock;
  final VoidCallback onOpenChat;

  const _DealCard({
    required this.deal,
    required this.statusLabel,
    required this.statusBody,
    required this.busy,
    required this.onUnlock,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    final listing = deal.listing;
    final created = deal.createdAt?.toLocal();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: StockFlowTheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: StockFlowTheme.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(width: 76, height: 76, child: ProductImage(url: listing?.imageUrl ?? '', category: listing?.categorySlug ?? 'other')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing?.title ?? 'Stock request', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text('${deal.requestedQty} ${listing?.unit ?? 'units'} • ${deal.counterpartyLabel}', style: Theme.of(context).textTheme.bodySmall),
                    if (created != null) ...[
                      const SizedBox(height: 4),
                      Text(DateFormat('d MMM • h:mm a').format(created), style: const TextStyle(fontSize: 10.5, color: StockFlowTheme.muted)),
                    ],
                  ],
                ),
              ),
              SfPill(label: deal.chatUnlocked ? 'Chat open' : 'Protected', color: deal.chatUnlocked ? StockFlowTheme.success : StockFlowTheme.accent),
            ],
          ),
          const SizedBox(height: 14),
          Text(statusLabel, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(statusBody, style: Theme.of(context).textTheme.bodySmall),
          if (!deal.isClosed) ...[
            const SizedBox(height: 14),
            if (deal.chatUnlocked)
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : onOpenChat, icon: const Icon(Icons.lock_open_rounded), label: const Text('Open protected chat')))
            else if (deal.isBuyer)
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : onUnlock, icon: busy ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.verified_user_outlined), label: Text('Unlock chat • ₹${deal.feeAmount.toStringAsFixed(0)}')))
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: StockFlowTheme.brandWash, borderRadius: BorderRadius.circular(14)),
                child: const Row(children: [Icon(Icons.support_agent_rounded, size: 19, color: StockFlowTheme.accentStrong), SizedBox(width: 9), Expanded(child: Text('StockFlow team is the contact bridge until the buyer unlocks protected chat.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: StockFlowTheme.textSecondary)))]),
              ),
          ],
        ],
      ),
    );
  }
}

class _EmptyDeals extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onTap;

  const _EmptyDeals({required this.icon, required this.title, required this.body, this.action, this.onTap});

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              Container(width: 62, height: 62, decoration: BoxDecoration(color: StockFlowTheme.brandWash, borderRadius: BorderRadius.circular(20)), child: Icon(icon, color: StockFlowTheme.accentStrong)),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 7),
              Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              if (action != null && onTap != null) ...[
                const SizedBox(height: 18),
                OutlinedButton(onPressed: onTap, child: Text(action!)),
              ],
            ],
          ),
        ),
      );
}
