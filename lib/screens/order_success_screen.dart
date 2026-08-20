import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/motion.dart';
import '../core/platform_ui.dart';
import '../core/theme.dart';
import 'orders_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final StockFlowApi api;
  final SfOrder order;

  const OrderSuccessScreen({super.key, required this.api, required this.order});

  String money(num value) => NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(value);

  @override
  Widget build(BuildContext context) {
    final item = order.items.isEmpty ? null : order.items.first;
    final cod = order.paymentMethod == 'cod';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              const Spacer(),
              const SfOrderSuccessMotion(size: 165),
              const SizedBox(height: 14),
              Text('Order confirmed', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                cod ? 'Your order is placed. Pay on delivery.' : 'Payment confirmed. Your order is now being processed.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: StockFlowTheme.muted, height: 1.45),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: StockFlowTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: StockFlowTheme.line),
                ),
                child: Column(
                  children: [
                    if (item != null)
                      Row(
                        children: [
                          Expanded(child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                          const SizedBox(width: 12),
                          Text(money(order.total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        ],
                      ),
                    if (item != null) const Divider(height: 24),
                    Row(
                      children: [
                        const Text('Order ID', style: TextStyle(color: StockFlowTheme.muted, fontSize: 11.5)),
                        const Spacer(),
                        Text('#${order.id.substring(0, order.id.length < 8 ? order.id.length : 8).toUpperCase()}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  SfPlatform.route(context, (_) => OrderDetailScreen(api: api, orderId: order.id, sellerMode: false)),
                ),
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Track order'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Continue shopping')),
            ],
          ),
        ),
      ),
    );
  }
}
