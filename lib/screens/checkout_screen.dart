import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/api.dart';
import '../core/location_service.dart';
import '../core/models.dart';
import '../core/platform_ui.dart';
import '../core/theme.dart';
import '../widgets/product_image.dart';
import '../widgets/sf_map.dart';
import '../widgets/sf_ui.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final StockFlowApi api;
  final Listing listing;
  final int initialQuantity;
  final double? lockedUnitPrice;
  final String? offerId;

  const CheckoutScreen({
    super.key,
    required this.api,
    required this.listing,
    required this.initialQuantity,
    this.lockedUnitPrice,
    this.offerId,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _locality = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _landmark = TextEditingController();

  int _quantity = 1;
  String _payment = 'prepaid';
  bool _busy = false;
  bool _loadingAddress = true;
  bool _locationBusy = false;
  SfResolvedAddress? _mapAddress;

  Listing get listing => widget.listing;
  double get unitPrice => widget.lockedUnitPrice ?? listing.sellingPrice;
  double get total => unitPrice * _quantity;
  String money(num value) => NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(value);

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity.clamp(listing.moq, listing.availableQty).toInt();
    _name.text = widget.api.currentUser?.fullName ?? '';
    _phone.text = widget.api.currentUser?.phone ?? '';
    _city.text = widget.api.currentUser?.city ?? '';
    _state.text = widget.api.currentUser?.state ?? '';
    _loadAddress();
  }

  @override
  void dispose() {
    for (final controller in [_name, _phone, _line1, _locality, _city, _state, _pincode, _landmark]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAddress() async {
    try {
      final addresses = await widget.api.addresses();
      if (addresses.isNotEmpty) {
        _fill(addresses.firstWhere((address) => address.isDefault, orElse: () => addresses.first));
      }
    } catch (_) {
      // The form remains usable when saved addresses cannot be loaded.
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  void _fill(SfAddress address) {
    _name.text = address.recipientName;
    _phone.text = address.phone;
    _line1.text = address.line1;
    _locality.text = address.locality;
    _city.text = address.city;
    _state.text = address.state;
    _pincode.text = address.pincode;
    _landmark.text = address.landmark;
  }

  SfAddress _address() => SfAddress(
        label: 'Delivery',
        recipientName: _name.text.trim(),
        phone: _phone.text.trim(),
        line1: _line1.text.trim(),
        locality: _locality.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim(),
        pincode: _pincode.text.trim(),
        landmark: _landmark.text.trim(),
        isDefault: true,
      );

  Future<void> _useCurrentLocation() async {
    if (_locationBusy) return;
    setState(() => _locationBusy = true);
    try {
      final resolved = await SfLocationService.currentAddress();
      if (!mounted) return;
      _mapAddress = resolved;
      final line1 = resolved.compactLine1;
      setState(() {
        if (line1.isNotEmpty) _line1.text = line1;
        if (resolved.locality.isNotEmpty) {
          _locality.text = resolved.locality;
        } else if (resolved.district.isNotEmpty) {
          _locality.text = resolved.district;
        }
        if (resolved.city.isNotEmpty) _city.text = resolved.city;
        if (resolved.state.isNotEmpty) _state.text = resolved.state;
        if (resolved.pincode.isNotEmpty) _pincode.text = resolved.pincode;
        if (resolved.landmark.isNotEmpty) _landmark.text = resolved.landmark;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resolved.addressResolved
                ? 'Address filled from your location. Check house/building and landmark before ordering.'
                : 'GPS found, but the address could not be resolved automatically. Complete it manually.',
          ),
        ),
      );
    } on SfLocationException catch (error) {
      if (!mounted) return;
      if (!error.canOpenSettings) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
        return;
      }
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(error.issue == SfLocationIssue.serviceDisabled ? Icons.location_off_outlined : Icons.gps_off_rounded),
          title: Text(error.issue == SfLocationIssue.serviceDisabled ? 'Turn on device Location' : 'Allow location for StockFlow'),
          content: Text(
            error.issue == SfLocationIssue.serviceDisabled
                ? 'Open Location settings, turn device Location on, then return and tap Use current location again.'
                : 'Open StockFlow app settings and allow location while using the app.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Not now')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Open settings')),
          ],
        ),
      );
      if (shouldOpen == true) await SfLocationService.openSettingsFor(error.issue);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _locationBusy = false);
    }
  }

  Future<void> _chooseOnMap() async {
    final result = await Navigator.push<SfResolvedAddress>(
      context,
      SfPlatform.route(context, (_) => SfLocationPickerScreen(initialAddress: _mapAddress)),
    );
    if (result == null || !mounted) return;
    _mapAddress = result;
    final line1 = result.compactLine1;
    setState(() {
      if (line1.isNotEmpty) _line1.text = line1;
      if (result.locality.isNotEmpty) _locality.text = result.locality;
      if (result.city.isNotEmpty) _city.text = result.city;
      if (result.state.isNotEmpty) _state.text = result.state;
      if (result.pincode.isNotEmpty) _pincode.text = result.pincode;
    });
  }

  Future<void> _placeOrder() async {
    if (_busy) return;
    final pincode = _pincode.text.trim();
    if (_name.text.trim().isEmpty || _phone.text.trim().length < 10 || _line1.text.trim().isEmpty || _city.text.trim().isEmpty || _state.text.trim().isEmpty || pincode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete the delivery address before placing the order.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final address = _address();
      try {
        await widget.api.saveAddress(address);
      } catch (_) {
        // Saving the address is useful but must not block checkout.
      }
      final order = await widget.api.checkout(
        listingId: listing.id,
        quantity: _quantity,
        paymentMethod: _payment,
        address: address,
        offerId: widget.offerId,
      );
      if (!mounted) return;
      await HapticFeedback.mediumImpact();
      if (!mounted) return;
      await Navigator.pushReplacement(context, SfPlatform.route(context, (_) => OrderSuccessScreen(api: widget.api, order: order)));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        bottomNavigationBar: SfStickyActionBar(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 2),
                    Text(money(total), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _busy ? null : _placeOrder,
                  child: _busy
                      ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_payment == 'cod' ? 'Place COD order' : 'Place order'),
                ),
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 34),
          children: [
            _OrderItemCard(
              listing: listing,
              unitPrice: unitPrice,
              quantity: _quantity,
              locked: widget.offerId != null,
              money: money,
              onDecrease: _quantity > listing.moq ? () => setState(() => _quantity--) : null,
              onIncrease: _quantity < listing.availableQty ? () => setState(() => _quantity++) : null,
            ),
            const SizedBox(height: 30),
            const _SectionTitle(title: 'Delivery address', subtitle: 'Only used for fulfilment and order updates.'),
            if (_loadingAddress) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(minHeight: 2),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _locationBusy ? null : _useCurrentLocation,
                    icon: _locationBusy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location_rounded),
                    label: Text(_locationBusy ? 'Finding…' : 'Current location'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(child: OutlinedButton.icon(onPressed: _chooseOnMap, icon: const Icon(Icons.map_outlined), label: const Text('Choose on map'))),
              ],
            ),
            const SizedBox(height: 9),
            const Text(
              'We’ll fill the available street/locality, city, state and pincode. Please verify the house/building before placing the order.',
              style: TextStyle(color: StockFlowTheme.muted, fontSize: 11.5, height: 1.4),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Recipient name'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone'))),
              ],
            ),
            const SizedBox(height: 10),
            TextField(controller: _line1, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'House / Flat / Building + Street')),
            const SizedBox(height: 10),
            TextField(controller: _locality, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Area / Locality')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: _city, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'City'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _state, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'State'))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: _pincode, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'Pincode', counterText: ''))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _landmark, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Landmark'))),
              ],
            ),
            const SizedBox(height: 30),
            const _SectionTitle(title: 'Payment', subtitle: 'Choose how you want to complete this order.'),
            const SizedBox(height: 6),
            _PaymentRow(
              selected: _payment == 'prepaid',
              icon: Icons.lock_outline_rounded,
              title: 'Pay online',
              subtitle: 'Secure payment before fulfilment',
              onTap: () => setState(() => _payment = 'prepaid'),
            ),
            if (listing.cod) ...[
              const Divider(height: 1, indent: 42),
              _PaymentRow(
                selected: _payment == 'cod',
                icon: Icons.payments_outlined,
                title: 'Cash on delivery',
                subtitle: 'Pay when the stock is delivered',
                onTap: () => setState(() => _payment = 'cod'),
              ),
            ],
            const SizedBox(height: 30),
            const _SectionTitle(title: 'Order summary', subtitle: 'Availability is rechecked when you place the order.'),
            const SizedBox(height: 14),
            _PriceLine(label: 'Items ($_quantity ${listing.unit})', value: money(total)),
            const SizedBox(height: 10),
            const _PriceLine(label: 'Shipping', value: 'Free'),
            const Divider(height: 28),
            _PriceLine(label: 'Total', value: money(total), strong: true),
          ],
        ),
      );
}

class _OrderItemCard extends StatelessWidget {
  final Listing listing;
  final double unitPrice;
  final int quantity;
  final bool locked;
  final String Function(num value) money;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _OrderItemCard({
    required this.listing,
    required this.unitPrice,
    required this.quantity,
    required this.locked,
    required this.money,
    this.onDecrease,
    this.onIncrease,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(width: 92, height: 104, child: ProductImage(url: listing.imageUrl, category: listing.categorySlug)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text('${money(unitPrice)} / ${listing.unit}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                if (locked)
                  Text('Accepted offer · $quantity ${listing.unit}', style: Theme.of(context).textTheme.bodySmall)
                else
                  Row(
                    children: [
                      _Qty(icon: Icons.remove_rounded, onTap: onDecrease),
                      SizedBox(width: 42, child: Text('$quantity', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))),
                      _Qty(icon: Icons.add_rounded, onTap: onIncrease),
                    ],
                  ),
              ],
            ),
          ),
        ],
      );
}

class _Qty extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _Qty({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 34,
        height: 34,
        child: IconButton.outlined(onPressed: onTap, padding: EdgeInsets.zero, icon: Icon(icon, size: 15)),
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _PaymentRow extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PaymentRow({required this.selected, required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              SizedBox(width: 38, child: Icon(icon, size: 20, color: selected ? StockFlowTheme.accent : StockFlowTheme.textSecondary)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? StockFlowTheme.accent : StockFlowTheme.lineStrong, width: selected ? 2 : 1.5)),
                child: selected ? const DecoratedBox(decoration: BoxDecoration(color: StockFlowTheme.accent, shape: BoxShape.circle)) : null,
              ),
            ],
          ),
        ),
      );
}

class _PriceLine extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  const _PriceLine({required this.label, required this.value, this.strong = false});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: strong ? StockFlowTheme.text : StockFlowTheme.muted, fontWeight: strong ? FontWeight.w700 : FontWeight.w500))),
          Text(value, style: TextStyle(fontWeight: strong ? FontWeight.w800 : FontWeight.w600, fontSize: strong ? 18 : 14)),
        ],
      );
}
