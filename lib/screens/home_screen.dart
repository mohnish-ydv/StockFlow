import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/ad_config.dart';
import '../core/api.dart';
import '../core/models.dart';
import '../core/platform_ui.dart';
import '../core/theme.dart';
import '../widgets/listing_card.dart';
import '../widgets/product_image.dart';
import '../widgets/sf_ui.dart';
import 'cart_screen.dart';
import 'listing_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final StockFlowApi api;
  final VoidCallback openSearch;
  final Future<bool> Function() requireAuth;
  final VoidCallback openSell;

  const HomeScreen({
    super.key,
    required this.api,
    required this.openSearch,
    required this.requireAuth,
    required this.openSell,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<Listing>>? _feed;
  Future<List<CategoryItem>>? _categories;
  Future<List<String>>? _recentIds;
  Future<Map<String, dynamic>>? _banner;
  Set<String> _favorites = <String>{};
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _reload();
    widget.api.favoriteIds().then((value) {
      if (mounted) setState(() => _favorites = value);
    });
  }

  void _reload() {
    _feed = widget.api.feed(categorySlug: _selectedCategory);
    _categories ??= widget.api.categories();
    _recentIds = widget.api.recentIds();
    _banner ??= widget.api.marketplaceConfig();
  }

  Future<void> _refresh() async {
    setState(() {
      _categories = widget.api.categories();
      _feed = widget.api.feed(categorySlug: _selectedCategory);
      _recentIds = widget.api.recentIds();
      _banner = widget.api.marketplaceConfig();
    });
    final favorites = await widget.api.favoriteIds();
    await Future.wait([_feed!, _categories!, _recentIds!]);
    if (mounted) setState(() => _favorites = favorites);
  }

  Future<void> _openCart() async {
    if (widget.api.currentUser == null && !await widget.requireAuth()) return;
    if (!mounted) return;
    await Navigator.push(context, SfPlatform.route(context, (_) => CartScreen(api: widget.api)));
  }

  Future<void> _openListing(Listing item) async {
    await widget.api.markRecentlyViewed(item.id);
    if (!mounted) return;
    await Navigator.push(
      context,
      SfPlatform.route(
        context,
        (_) => ListingDetailScreen(
          api: widget.api,
          item: item,
          requireAuth: widget.requireAuth,
        ),
      ),
    );
    if (mounted) setState(() => _recentIds = widget.api.recentIds());
  }

  Future<void> _toggleFavorite(Listing item) async {
    final added = await widget.api.toggleFavorite(item.id);
    if (!mounted) return;
    setState(() {
      if (added) {
        _favorites.add(item.id);
      } else {
        _favorites.remove(item.id);
      }
    });
  }

  void _selectCategory(String? slug) {
    setState(() {
      _selectedCategory = slug;
      _feed = widget.api.feed(categorySlug: slug);
    });
  }

  IconData _categoryIcon(String slug) {
    switch (slug) {
      case 'electronics':
        return Icons.devices_other_outlined;
      case 'fashion':
        return Icons.checkroom_outlined;
      case 'mobiles':
        return Icons.smartphone_outlined;
      case 'home-kitchen':
        return Icons.kitchen_outlined;
      case 'furniture':
        return Icons.chair_alt_outlined;
      case 'industrial':
        return Icons.precision_manufacturing_outlined;
      case 'automotive':
        return Icons.directions_car_outlined;
      case 'beauty':
        return Icons.spa_outlined;
      case 'sports':
        return Icons.sports_soccer_outlined;
      case 'books':
        return Icons.menu_book_outlined;
      default:
        return Icons.grid_view_rounded;
    }
  }

  int _columns(double width) {
    if (width >= 1080) return 5;
    if (width >= 820) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  String get _userLocation {
    final city = widget.api.currentUser?.city.trim() ?? '';
    final state = widget.api.currentUser?.state.trim() ?? '';
    final parts = [city, state].where((value) => value.isNotEmpty).toList();
    return parts.isEmpty ? 'India' : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 0),
              child: Row(
                children: [
                  const SfWordmark(compact: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: widget.openSearch,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 17, color: StockFlowTheme.accent),
                          const SizedBox(width: 4),
                          Flexible(child: Text(_userLocation, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700))),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: StockFlowTheme.muted),
                        ],
                      ),
                    ),
                  ),
                  SfRoundIconButton(icon: Icons.shopping_bag_outlined, onTap: _openCart, tooltip: 'Cart'),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: SfSearchBar(onTap: widget.openSearch),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _banner,
              builder: (context, snapshot) {
                final banner = snapshot.data ?? const <String, dynamic>{};
                if (banner['enabled'] != true) return const SizedBox(height: 8);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _MarketplaceBanner(data: banner, onTap: widget.openSell),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
              child: SfSectionHeader(
                title: 'Browse categories',
                action: _selectedCategory == null ? null : 'Clear',
                onAction: _selectedCategory == null ? null : () => _selectCategory(null),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<CategoryItem>>(
              future: _categories,
              builder: (context, snapshot) {
                final items = snapshot.data ?? const <CategoryItem>[];
                if (snapshot.connectionState != ConnectionState.done && items.isEmpty) {
                  return const SizedBox(height: 86, child: Center(child: LinearProgressIndicator(minHeight: 2)));
                }
                return SizedBox(
                  height: 176,
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 82,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final selected = item.slug == _selectedCategory;
                      return _CategoryTile(
                        label: item.name,
                        icon: _categoryIcon(item.slug),
                        selected: selected,
                        onTap: () => _selectCategory(selected ? null : item.slug),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<Listing>>(
              future: _feed,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 120),
                    child: _LoadingHome(columns: _columns(width)),
                  );
                }
                if (snapshot.hasError) {
                  return SizedBox(
                    height: 420,
                    child: SfEmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Marketplace unavailable',
                      body: '${snapshot.error}',
                      action: 'Try again',
                      onAction: () => setState(_reload),
                    ),
                  );
                }
                final items = snapshot.data ?? const <Listing>[];
                if (items.isEmpty) {
                  return const SizedBox(
                    height: 360,
                    child: SfEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No stock found',
                      body: 'Try another category or change your search.',
                    ),
                  );
                }
                return FutureBuilder<List<String>>(
                  future: _recentIds,
                  builder: (context, recentSnapshot) {
                    final ids = recentSnapshot.data ?? const <String>[];
                    final byId = {for (final item in items) item.id: item};
                    final recent = ids.map((id) => byId[id]).whereType<Listing>().take(5).toList();
                    return _MarketplaceBody(
                      items: items,
                      recent: recent,
                      columns: _columns(width),
                      favorites: _favorites,
                      onTap: _openListing,
                      onFavorite: _toggleFavorite,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 82,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: selected ? StockFlowTheme.accent : StockFlowTheme.panel2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 24, color: selected ? Colors.white : StockFlowTheme.textSecondary),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? StockFlowTheme.accentStrong : StockFlowTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
}

class _MarketplaceBody extends StatelessWidget {
  final List<Listing> items;
  final List<Listing> recent;
  final int columns;
  final Set<String> favorites;
  final ValueChanged<Listing> onTap;
  final ValueChanged<Listing> onFavorite;

  const _MarketplaceBody({
    required this.items,
    required this.recent,
    required this.columns,
    required this.favorites,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final featured = items.where((item) => item.featured).firstOrNull;
    final freshItems = featured == null ? items : items.where((item) => item.id != featured.id).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (featured != null) ...[
            const SfSectionHeader(title: 'Featured lot'),
            const SizedBox(height: 12),
            _FeaturedLot(item: featured, onTap: () => onTap(featured)),
            const SizedBox(height: 30),
          ],
          if (recent.isNotEmpty) ...[
            const SfSectionHeader(title: 'Recently viewed'),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: ListView.separated(
                clipBehavior: Clip.none,
                scrollDirection: Axis.horizontal,
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = recent[index];
                  return SizedBox(
                    width: 160,
                    child: ListingCard(
                      item: item,
                      compact: true,
                      isFavorite: favorites.contains(item.id),
                      onFavorite: () => onFavorite(item),
                      onTap: () => onTap(item),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
          ],
          const SfAdSlot(slotId: 'home_feed_1'),
          if (StockFlowAdConfig.enabled) const SizedBox(height: 28),
          SfSectionHeader(
            title: 'Fresh stock',
            subtitle: '${freshItems.length} active lot${freshItems.length == 1 ? '' : 's'}',
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 22,
              childAspectRatio: columns == 2 ? .57 : .62,
            ),
            itemCount: freshItems.length,
            itemBuilder: (context, index) {
              final item = freshItems[index];
              return ListingCard(
                item: item,
                isFavorite: favorites.contains(item.id),
                onFavorite: () => onFavorite(item),
                onTap: () => onTap(item),
              );
            },
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _FeaturedLot extends StatelessWidget {
  final Listing item;
  final VoidCallback onTap;

  const _FeaturedLot({required this.item, required this.onTap});

  String get money => NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(item.sellingPrice);

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 1.65,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(26),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(url: item.imageUrl, category: item.categorySlug),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x08000000), Color(0xB5000000)],
                        stops: [.35, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, height: 1.18),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(money, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            Text('MOQ ${item.moq}', style: const TextStyle(color: Color(0xDFFFFFFF), fontSize: 11.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _MarketplaceBanner extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _MarketplaceBanner({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 154),
        decoration: BoxDecoration(
          color: StockFlowTheme.accent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0x181769FF), blurRadius: 24, offset: Offset(0, 12))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              const Positioned(right: -36, top: -50, child: _BannerBlob(size: 170, opacity: .16)),
              const Positioned(right: 52, bottom: -72, child: _BannerBlob(size: 132, opacity: .10)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 19, 145, 19),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${data['eyebrow'] ?? 'STOCKFLOW'}', style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: .9)),
                    const SizedBox(height: 7),
                    Text('${data['title'] ?? 'Turn surplus stock into opportunity'}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 19, height: 1.1, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 7),
                    Text('${data['body'] ?? 'List once. StockFlow helps coordinate serious buyer interest.'}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xE8FFFFFF), fontSize: 11.5, height: 1.35)),
                    const SizedBox(height: 13),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: StockFlowTheme.accentStrong, minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 15)),
                      onPressed: onTap,
                      child: Text('${data['cta'] ?? 'Post stock'}'),
                    ),
                  ],
                ),
              ),
              const Positioned(
                right: 22,
                top: 36,
                child: Icon(Icons.inventory_2_rounded, color: Colors.white, size: 82),
              ),
            ],
          ),
        ),
      );
}

class _BannerBlob extends StatelessWidget {
  final double size;
  final double opacity;
  const _BannerBlob({required this.size, required this.opacity});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
      );
}

class _LoadingHome extends StatelessWidget {
  final int columns;
  const _LoadingHome({required this.columns});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SfSkeletonBox(width: 130, height: 20),
          const SizedBox(height: 14),
          SfListingGridSkeleton(columns: columns, itemCount: columns * 2),
        ],
      );
}
