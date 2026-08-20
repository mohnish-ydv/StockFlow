import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/platform_ui.dart';
import '../core/theme.dart';
import '../widgets/listing_card.dart';
import '../widgets/sf_ui.dart';
import 'listing_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final StockFlowApi api;
  final Future<bool> Function() requireAuth;

  const SearchScreen({super.key, required this.api, required this.requireAuth});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final q = TextEditingController();
  Timer? timer;
  Future<List<Listing>>? results;
  Set<String> favorites = <String>{};

  bool bulk = false;
  bool shipping = false;
  bool cod = false;
  bool negotiable = false;
  String condition = 'any';
  String location = '';
  double? minPrice;
  double? maxPrice;
  String sort = 'newest';

  static const _conditions = <String>[
    'any',
    'New Dead Stock',
    'New',
    'Open Box',
    'Display Unit',
    'Refurbished',
    'Used - Like New',
    'Used - Good',
  ];

  @override
  void initState() {
    super.initState();
    results = widget.api.feed();
    widget.api.favoriteIds().then((value) {
      if (mounted) setState(() => favorites = value);
    });
  }

  void changed(String value) {
    setState(() {});
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 320), () {
      if (mounted) setState(() => results = widget.api.feed(search: value));
    });
  }

  List<Listing> applyFilters(List<Listing> source) {
    final locationNeedle = location.trim().toLowerCase();
    final items = source.where((item) {
      if (bulk && item.inventoryType != 'bulk') return false;
      if (shipping && !item.shipping) return false;
      if (cod && !item.cod) return false;
      if (negotiable && !item.negotiable) return false;
      if (condition != 'any' && item.condition != condition) return false;
      if (minPrice != null && item.sellingPrice < minPrice!) return false;
      if (maxPrice != null && item.sellingPrice > maxPrice!) return false;
      if (locationNeedle.isNotEmpty) {
        final haystack = '${item.city} ${item.state}'.toLowerCase();
        if (!haystack.contains(locationNeedle)) return false;
      }
      return true;
    }).toList();

    switch (sort) {
      case 'price_low':
        items.sort((a, b) => a.sellingPrice.compareTo(b.sellingPrice));
        break;
      case 'price_high':
        items.sort((a, b) => b.sellingPrice.compareTo(a.sellingPrice));
        break;
      default:
        break;
    }
    return items;
  }

  int get activeFilterCount {
    var count = [bulk, shipping, cod, negotiable].where((value) => value).length;
    if (condition != 'any') count++;
    if (location.trim().isNotEmpty) count++;
    if (minPrice != null || maxPrice != null) count++;
    return count;
  }

  String get sortLabel {
    switch (sort) {
      case 'price_low':
        return 'Lowest price';
      case 'price_high':
        return 'Highest price';
      default:
        return 'Newest';
    }
  }

  Future<void> openListing(Listing item) async {
    await widget.api.markRecentlyViewed(item.id);
    if (!mounted) return;
    await Navigator.push(
      context,
      SfPlatform.route(
        context,
        (_) => ListingDetailScreen(api: widget.api, item: item, requireAuth: widget.requireAuth),
      ),
    );
  }

  Future<void> toggleFavorite(Listing item) async {
    final added = await widget.api.toggleFavorite(item.id);
    if (!mounted) return;
    setState(() {
      if (added) {
        favorites.add(item.id);
      } else {
        favorites.remove(item.id);
      }
    });
  }

  Future<void> _showFilters() async {
    var nextBulk = bulk;
    var nextShipping = shipping;
    var nextCod = cod;
    var nextNegotiable = negotiable;
    var nextCondition = condition;
    final locationController = TextEditingController(text: location);
    final minController = TextEditingController(text: minPrice?.toStringAsFixed(0) ?? '');
    final maxController = TextEditingController(text: maxPrice?.toStringAsFixed(0) ?? '');

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Filter stock', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setSheetState(() {
                        nextBulk = false;
                        nextShipping = false;
                        nextCod = false;
                        nextNegotiable = false;
                        nextCondition = 'any';
                        locationController.clear();
                        minController.clear();
                        maxController.clear();
                      }),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'City or state',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: nextCondition,
                  decoration: const InputDecoration(labelText: 'Condition'),
                  items: _conditions
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value == 'any' ? 'Any condition' : value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setSheetState(() => nextCondition = value ?? 'any'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Min price', prefixText: '₹ '),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: maxController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Max price', prefixText: '₹ '),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _FilterSwitch(label: 'Bulk lots', value: nextBulk, onChanged: (value) => setSheetState(() => nextBulk = value)),
                _FilterSwitch(label: 'Shipping available', value: nextShipping, onChanged: (value) => setSheetState(() => nextShipping = value)),
                _FilterSwitch(label: 'Cash on Delivery', value: nextCod, onChanged: (value) => setSheetState(() => nextCod = value)),
                _FilterSwitch(label: 'Negotiable', value: nextNegotiable, onChanged: (value) => setSheetState(() => nextNegotiable = value)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: const Text('Show results'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (applied == true && mounted) {
      setState(() {
        bulk = nextBulk;
        shipping = nextShipping;
        cod = nextCod;
        negotiable = nextNegotiable;
        condition = nextCondition;
        location = locationController.text.trim();
        minPrice = double.tryParse(minController.text.trim());
        maxPrice = double.tryParse(maxController.text.trim());
      });
    }

    locationController.dispose();
    minController.dispose();
    maxController.dispose();
  }

  void _resetFilters() {
    setState(() {
      bulk = false;
      shipping = false;
      cod = false;
      negotiable = false;
      condition = 'any';
      location = '';
      minPrice = null;
      maxPrice = null;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    q.dispose();
    super.dispose();
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
      backgroundColor: StockFlowTheme.ink,
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
            child: SfSearchBar(
              controller: q,
              autofocus: true,
              onChanged: changed,
              onSubmitted: changed,
              onFilter: _showFilters,
            ),
          ),
          if (activeFilterCount > 0)
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: [
                  if (location.isNotEmpty) SfPill(label: location, selected: true, onTap: () => setState(() => location = '')),
                  if (condition != 'any') ...[
                    if (location.isNotEmpty) const SizedBox(width: 8),
                    SfPill(label: condition, selected: true, onTap: () => setState(() => condition = 'any')),
                  ],
                  if (bulk) ...[
                    const SizedBox(width: 8),
                    SfPill(label: 'Bulk', selected: true, onTap: () => setState(() => bulk = false)),
                  ],
                  if (shipping) ...[
                    const SizedBox(width: 8),
                    SfPill(label: 'Shipping', selected: true, onTap: () => setState(() => shipping = false)),
                  ],
                  if (cod) ...[
                    const SizedBox(width: 8),
                    SfPill(label: 'COD', selected: true, onTap: () => setState(() => cod = false)),
                  ],
                  if (negotiable) ...[
                    const SizedBox(width: 8),
                    SfPill(label: 'Negotiable', selected: true, onTap: () => setState(() => negotiable = false)),
                  ],
                  const SizedBox(width: 4),
                  TextButton(onPressed: _resetFilters, child: const Text('Clear')),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Listing>>(
              future: results,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
                    child: SfListingGridSkeleton(columns: columns, itemCount: columns * 3),
                  );
                }
                if (snapshot.hasError) {
                  return SfEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Search unavailable',
                    body: '${snapshot.error}',
                    action: 'Try again',
                    onAction: () => setState(() => results = widget.api.feed(search: q.text)),
                  );
                }
                final items = applyFilters(snapshot.data ?? const []);
                if (items.isEmpty) {
                  return const SfEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No matching stock',
                    body: 'Try a broader search, location or price range.',
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 12, 8),
                      child: Row(
                        children: [
                          Text(
                            q.text.trim().isEmpty ? 'Explore ${items.length} lots' : '${items.length} results',
                            style: const TextStyle(fontSize: 12, color: StockFlowTheme.muted),
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            tooltip: 'Sort results',
                            initialValue: sort,
                            onSelected: (value) => setState(() => sort = value),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'newest', child: Text('Newest first')),
                              PopupMenuItem(value: 'price_low', child: Text('Price: low to high')),
                              PopupMenuItem(value: 'price_high', child: Text('Price: high to low')),
                            ],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.swap_vert_rounded, size: 16, color: StockFlowTheme.muted),
                                  const SizedBox(width: 5),
                                  Text(sortLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          childAspectRatio: columns == 2 ? .57 : .62,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 22,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, index) {
                          final item = items[index];
                          return ListingCard(
                            item: item,
                            isFavorite: favorites.contains(item.id),
                            onFavorite: () => toggleFavorite(item),
                            onTap: () => openListing(item),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FilterSwitch({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => SwitchListTile(
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      );
}
