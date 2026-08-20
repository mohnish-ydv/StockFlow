import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/motion.dart';
import '../core/platform_ui.dart';
import '../widgets/product_image.dart';
import '../widgets/sf_ui.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final StockFlowApi api;
  const CartScreen({super.key, required this.api});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Future<List<CartItem>>? _future;
  String money(num value) => NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(value);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() => setState(() => _future = widget.api.cart());

  Future<void> _change(CartItem item, int quantity) async {
    try {
      if (quantity < item.listing.moq) {
        await widget.api.removeFromCart(item.listing.id);
      } else {
        await widget.api.updateCart(item.listing.id, quantity);
      }
      _refresh();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: FutureBuilder<List<CartItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done && !snapshot.hasData) {
              return const Padding(padding: EdgeInsets.all(18), child: SfListSkeleton(rows: 4));
            }
            if (snapshot.hasError) {
              return SfEmptyState(icon: Icons.cloud_off_outlined, title: 'Cart unavailable', body: '${snapshot.error}', action: 'Try again', onAction: _refresh);
            }
            final items = snapshot.data ?? const <CartItem>[];
            if (items.isEmpty) {
              return const SfEmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'Your cart is empty',
                body: 'Shipping-enabled stock you add will stay here until you are ready.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 32),
              itemBuilder: (_, index) => _CartLine(
                item: items[index],
                money: money,
                onDecrease: () => _change(items[index], items[index].quantity - 1),
                onIncrease: items[index].quantity < items[index].listing.availableQty ? () => _change(items[index], items[index].quantity + 1) : null,
                onRemove: () => _change(items[index], 0),
                onCheckout: () async {
                  await Navigator.push(
                    context,
                    SfPlatform.route(
                      context,
                      (_) => CheckoutScreen(api: widget.api, listing: items[index].listing, initialQuantity: items[index].quantity),
                    ),
                  );
                  _refresh();
                },
              ),
            );
          },
        ),
      );
}

class _CartLine extends StatelessWidget {
  final CartItem item;
  final String Function(num value) money;
  final VoidCallback onDecrease;
  final VoidCallback? onIncrease;
  final VoidCallback onRemove;
  final VoidCallback onCheckout;

  const _CartLine({
    required this.item,
    required this.money,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final listing = item.listing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(width: 102, height: 112, child: ProductImage(url: listing.imageUrl, category: listing.categorySlug)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 7),
                  Text('${money(listing.sellingPrice)} / ${listing.unit}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('MOQ ${listing.moq} · ${listing.availableQty} available', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      _QtyButton(icon: Icons.remove_rounded, onTap: onDecrease),
                      SizedBox(
                        width: 42,
                        child: AnimatedSwitcher(
                          duration: SfMotion.reduce(context) ? Duration.zero : SfMotion.quick,
                          child: Text('${item.quantity}', key: ValueKey(item.quantity), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      _QtyButton(icon: Icons.add_rounded, onTap: onIncrease),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton(onPressed: onRemove, style: TextButton.styleFrom(padding: EdgeInsets.zero), child: const Text('Remove')),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Subtotal', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(money(listing.sellingPrice * item.quantity), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
            const SizedBox(width: 14),
            FilledButton(onPressed: onCheckout, style: FilledButton.styleFrom(minimumSize: const Size(112, 48)), child: const Text('Checkout')),
          ],
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 36,
        height: 36,
        child: IconButton.outlined(onPressed: onTap, padding: EdgeInsets.zero, icon: Icon(icon, size: 16)),
      );
}
