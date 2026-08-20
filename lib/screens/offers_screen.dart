import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/api.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../widgets/product_image.dart';
import '../widgets/sf_ui.dart';

String _offerStatusLabel(String value) => value
    .replaceAll('_', ' ')
    .split(' ')
    .where((word) => word.isNotEmpty)
    .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

class OffersScreen extends StatefulWidget {
  final StockFlowApi api;
  const OffersScreen({super.key, required this.api});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  Future<List<Map<String, dynamic>>>? _future;
  String money(num n) => NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() => setState(() => _future = widget.api.myOffers());

  String _expiry(Map<String, dynamic> row) {
    final date = DateTime.tryParse('${row['expires_at'] ?? ''}')?.toLocal();
    if (date == null || '${row['status']}' != 'pending') return '';
    final left = date.difference(DateTime.now());
    if (left.isNegative) return 'Expired';
    if (left.inHours > 0) return '${left.inHours}h left';
    return '${left.inMinutes.clamp(1, 59)}m left';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Offers'),
              Text('Price proposals from your chats', style: TextStyle(fontSize: 11, color: StockFlowTheme.muted, fontWeight: FontWeight.w400)),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            _refresh();
            await _future;
          },
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done && !snapshot.hasData) {
                return const Padding(padding: EdgeInsets.all(18), child: SfListSkeleton(rows: 5));
              }
              if (snapshot.hasError) {
                return ListView(children: [const SizedBox(height: 120), Center(child: Text('${snapshot.error}', style: const TextStyle(color: StockFlowTheme.muted)))]);
              }
              final rows = snapshot.data ?? const [];
              if (rows.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Icon(Icons.local_offer_outlined, size: 46, color: StockFlowTheme.muted),
                    SizedBox(height: 12),
                    Text('No offers yet', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    SizedBox(height: 7),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 38),
                      child: Text('Offers you send or receive in chat will stay organised here.', textAlign: TextAlign.center, style: TextStyle(color: StockFlowTheme.muted, height: 1.4)),
                    ),
                  ],
                );
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 84),
                itemBuilder: (_, index) {
                  final row = rows[index];
                  final listing = row['listing'] is Map ? Map<String, dynamic>.from(row['listing'] as Map) : <String, dynamic>{};
                  final quantity = int.tryParse('${row['quantity']}') ?? 1;
                  final unitPrice = double.tryParse('${row['unit_price']}') ?? 0;
                  final mine = '${row['created_by']}' == widget.api.currentUser?.id;
                  final status = '${row['status'] ?? 'pending'}';
                  final expiry = _expiry(row);
                  final palette = _palette(status);

                  return SfFadeSlideIn(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(width: 68, height: 68, child: ProductImage(url: '${listing['image_url'] ?? ''}', category: 'other')),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${listing['title'] ?? 'Marketplace offer'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                      ),
                                    ),
                                    _StatusPill(label: _offerStatusLabel(status), color: palette),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${mine ? 'You proposed' : 'You received'} ${money(unitPrice)} / unit × $quantity',
                                  style: const TextStyle(color: StockFlowTheme.textSecondary, fontSize: 11.5),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('${money(quantity * unitPrice)} total', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    if (expiry.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Text('· $expiry', style: const TextStyle(color: StockFlowTheme.muted, fontSize: 10.5)),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );

  Color _palette(String status) {
    switch (status) {
      case 'accepted':
        return StockFlowTheme.accent;
      case 'rejected':
      case 'cancelled':
      case 'expired':
        return StockFlowTheme.danger;
      case 'countered':
      case 'pending':
      default:
        return StockFlowTheme.amber;
    }
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
      );
}
