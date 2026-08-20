import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/motion.dart';
import '../core/platform_ui.dart';
import '../core/theme.dart';
import '../widgets/product_image.dart';
import '../widgets/sf_ui.dart';

String _orderStatusLabel(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

class OrdersScreen extends StatefulWidget {
  final StockFlowApi api;
  final bool initialSellerMode;
  const OrdersScreen({super.key, required this.api, this.initialSellerMode = false});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late bool sellerMode;
  Future<List<SfOrder>>? _future;

  @override
  void initState() {
    super.initState();
    sellerMode = widget.initialSellerMode;
    _refresh();
  }

  void _refresh() => setState(() => _future = widget.api.orders(seller: sellerMode));

  void _setMode(bool value) {
    if (sellerMode == value) return;
    sellerMode = value;
    _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Orders')),
        body: Column(
          children: [
            _OrderModeTabs(sellerMode: sellerMode, onChanged: _setMode),
            const Divider(height: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _refresh();
                  await _future;
                },
                child: FutureBuilder<List<SfOrder>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done && !snapshot.hasData) {
                      return const Padding(padding: EdgeInsets.all(18), child: SfListSkeleton(rows: 5));
                    }
                    if (snapshot.hasError) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          const Icon(Icons.cloud_off_outlined, size: 38, color: StockFlowTheme.muted),
                          const SizedBox(height: 12),
                          const Text('Orders unavailable', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 5),
                          Text('${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: StockFlowTheme.muted, fontSize: 12)),
                        ],
                      );
                    }
                    final orders = snapshot.data ?? const <SfOrder>[];
                    if (orders.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 108, 24, 100),
                        children: [
                          Icon(sellerMode ? Icons.inventory_2_outlined : Icons.shopping_bag_outlined, size: 44, color: StockFlowTheme.muted),
                          const SizedBox(height: 14),
                          Text(
                            sellerMode ? 'No seller orders yet' : 'No purchases yet',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            sellerMode ? 'Orders from buyers will appear here.' : 'Orders you place will appear here.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: StockFlowTheme.muted, fontSize: 13, height: 1.45),
                          ),
                        ],
                      );
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 82),
                      itemBuilder: (_, index) => SfFadeSlideIn(
                        index: index,
                        child: _OrderRow(
                          order: orders[index],
                          sellerMode: sellerMode,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              SfPlatform.route(
                                context,
                                (_) => OrderDetailScreen(api: widget.api, orderId: orders[index].id, sellerMode: sellerMode),
                              ),
                            );
                            _refresh();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
}

class _OrderModeTabs extends StatelessWidget {
  final bool sellerMode;
  final ValueChanged<bool> onChanged;

  const _OrderModeTabs({required this.sellerMode, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: _OrderModeTab(label: 'Buying', selected: !sellerMode, onTap: () => onChanged(false))),
          Expanded(child: _OrderModeTab(label: 'Selling', selected: sellerMode, onTap: () => onChanged(true))),
        ],
      );
}

class _OrderModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OrderModeTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 0),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? StockFlowTheme.text : StockFlowTheme.muted,
                ),
              ),
              const SizedBox(height: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 2,
                color: selected ? StockFlowTheme.accent : Colors.transparent,
              ),
            ],
          ),
        ),
      );
}

class _OrderRow extends StatelessWidget {
  final SfOrder order;
  final bool sellerMode;
  final VoidCallback onTap;

  const _OrderRow({required this.order, required this.sellerMode, required this.onTap});

  String money(num n) => NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);

  Color _statusColor(String status) {
    if (status == 'delivered') return StockFlowTheme.success;
    if (status == 'shipped' || status == 'in_transit' || status == 'out_for_delivery') return StockFlowTheme.blue;
    if (status == 'cancelled' || status == 'failed' || status == 'refunded') return StockFlowTheme.danger;
    return StockFlowTheme.amber;
  }

  @override
  Widget build(BuildContext context) {
    final item = order.items.isEmpty ? null : order.items.first;
    final statusColor = _statusColor(order.status);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 66,
                height: 66,
                child: item != null
                    ? ProductImage(url: item.imageUrl, category: 'other')
                    : const ProductImage(url: '', category: 'other'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item?.title ?? 'StockFlow order',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sellerMode ? 'Buyer: ${order.buyerName}' : 'Seller: ${order.sellerName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: StockFlowTheme.muted, fontSize: 11.5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: .09),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          _orderStatusLabel(order.status),
                          style: TextStyle(color: statusColor, fontSize: 9.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Spacer(),
                      Text(money(order.total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Icon(Icons.chevron_right_rounded, color: StockFlowTheme.muted, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderDetailScreen extends StatefulWidget {
  final StockFlowApi api;
  final String orderId;
  final bool sellerMode;
  const OrderDetailScreen({super.key, required this.api, required this.orderId, required this.sellerMode});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Future<SfOrder>? _future;
  bool _busy = false;
  final _courier = TextEditingController(text: 'Seller-arranged courier');

  String money(num n) => NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);

  @override
  void initState() { super.initState(); _refresh(); }
  @override
  void dispose() { _courier.dispose(); super.dispose(); }
  void _refresh() => setState(() => _future = widget.api.order(widget.orderId));

  String? _next(String current) {
    const flow = ['confirmed','seller_processing','ready_to_ship','shipped','in_transit','out_for_delivery','delivered'];
    final i = flow.indexOf(current);
    if (i < 0 || i >= flow.length - 1) return null;
    return flow[i + 1];
  }

  Future<void> _advance(SfOrder order) async {
    final next = _next(order.status);
    if (next == null || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.api.sellerUpdateOrder(orderId: order.id, status: next, courierName: _courier.text.trim(), note: 'Seller updated shipment to ${_orderStatusLabel(next)}.');
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Order details')),
        body: FutureBuilder<SfOrder>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.all(18), child: SfListSkeleton(rows: 5));
            if (snapshot.hasError || snapshot.data == null) return Center(child: Text('${snapshot.error ?? 'Order unavailable'}'));
            final order = snapshot.data!;
            final item = order.items.isEmpty ? null : order.items.first;
            final next = _next(order.status);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              children: [
                const Text('Order status', style: TextStyle(color: StockFlowTheme.muted, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(_orderStatusLabel(order.status), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('#${order.id.substring(0, 8).toUpperCase()} • ${order.paymentMethod == 'cod' ? 'Cash on Delivery' : 'Prepaid'}', style: const TextStyle(color: StockFlowTheme.muted, fontSize: 12)),
                const SizedBox(height: 18),
                const Divider(height: 1),
                if (item != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 68, height: 68, child: ProductImage(url: item.imageUrl, category: 'other'))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 5),
                        Text('${item.quantity} ${item.unit} × ${money(item.unitPrice)}', style: const TextStyle(color: StockFlowTheme.muted, fontSize: 11.5)),
                        const SizedBox(height: 5),
                        Text(money(item.lineTotal), style: const TextStyle(color: StockFlowTheme.text, fontWeight: FontWeight.w700)),
                      ])),
                    ]),
                  ),
                  const Divider(height: 1),
                ],
                const SizedBox(height: 22),
                _sectionTitle('Shipment'),
                _line('AWB', order.shipment?.awb ?? 'Preparing'),
                _line('Provider', order.shipment?.courierName.isNotEmpty == true ? order.shipment!.courierName : order.shipment?.provider ?? 'Preparing'),
                _line('Tracking', _orderStatusLabel(order.shipment?.status ?? 'label_created')),
                if (order.shipment?.trackingNote.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(order.shipment!.trackingNote, style: const TextStyle(color: StockFlowTheme.muted, fontSize: 12, height: 1.45)),
                ],
                const SizedBox(height: 22),
                const Divider(height: 1),
                const SizedBox(height: 20),
                _sectionTitle('Delivery'),
                Text(_address(order.deliveryAddress), style: const TextStyle(height: 1.5, color: StockFlowTheme.textSecondary)),
                const SizedBox(height: 16),
                _sectionTitle('Timeline'),
                ...order.history.map((h) => _timeline('${h['status'] ?? ''}', '${h['note'] ?? ''}', DateTime.tryParse('${h['created_at'] ?? ''}'))),
                if (widget.sellerMode && next != null) ...[
                  const SizedBox(height: 18),
                  _sectionTitle('Seller action'),
                  TextField(controller: _courier, decoration: const InputDecoration(labelText: 'Courier / logistics provider')),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _advance(order),
                    icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_forward_rounded),
                    label: Text('Mark as ${_orderStatusLabel(next)}'),
                  ),
                ],
              ],
            );
          },
        ),
      );

  Widget _sectionTitle(String text) => Padding(padding: const EdgeInsets.fromLTRB(3, 0, 3, 7), child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)));
  Widget _line(String a, String b) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 80, child: Text(a, style: const TextStyle(color: StockFlowTheme.muted, fontSize: 11))), Expanded(child: Text(b, style: const TextStyle(fontWeight: FontWeight.w700)))]));
  Widget _timeline(String status, String note, DateTime? time) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 11, height: 11, margin: const EdgeInsets.only(top: 5), decoration: const BoxDecoration(color: StockFlowTheme.accent, shape: BoxShape.circle)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_orderStatusLabel(status), style: const TextStyle(fontWeight: FontWeight.w600)),
          if (note.isNotEmpty) Text(note, style: const TextStyle(color: StockFlowTheme.muted, fontSize: 11)),
          if (time != null) Text(DateFormat('d MMM • h:mm a').format(time.toLocal()), style: const TextStyle(color: StockFlowTheme.muted, fontSize: 9)),
        ])),
      ]));

  String _address(Map<String, dynamic> a) => [a['recipientName'], a['line1'], a['locality'], a['city'], a['state'], a['pincode']].where((x) => '${x ?? ''}'.trim().isNotEmpty).join(', ');
}
