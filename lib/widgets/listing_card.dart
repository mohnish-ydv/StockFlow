import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/models.dart';
import '../core/theme.dart';
import 'product_image.dart';

class ListingCard extends StatelessWidget {
  final Listing item;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final bool compact;
  final bool horizontal;

  const ListingCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.compact = false,
    this.horizontal = false,
  });

  String get money => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: item.sellingPrice % 1 == 0 ? 0 : 2,
      ).format(item.sellingPrice);

  String get location => [item.city, item.state]
      .where((value) => value.trim().isNotEmpty)
      .join(', ');

  int? get discount {
    final original = item.originalPrice;
    if (original == null || original <= item.sellingPrice || original <= 0) return null;
    return (((original - item.sellingPrice) / original) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    if (horizontal) return _horizontal(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(StockFlowTheme.radiusLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: compact ? 1.18 : 1.04,
              child: _image(),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    money,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.25,
                      color: StockFlowTheme.text,
                    ),
                  ),
                ),
                if (discount != null)
                  Text(
                    '${discount!}% off',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: StockFlowTheme.success,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 12.5 : 13.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: StockFlowTheme.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'MOQ ${item.moq} • ${item.availableQty} ${item.unit}${item.availableQty == 1 ? '' : 's'} available',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: StockFlowTheme.textSecondary),
            ),
            if (location.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 12, color: StockFlowTheme.muted),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, color: StockFlowTheme.muted),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _image() => ClipRRect(
        borderRadius: BorderRadius.circular(StockFlowTheme.radiusLarge),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ProductImage(url: item.imageUrl, category: item.categorySlug),
            if (item.featured)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xEFFFFFFF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Featured',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: StockFlowTheme.text),
                  ),
                ),
              ),
            if (onFavorite != null)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.white.withValues(alpha: .92),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onFavorite,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 19,
                        color: isFavorite ? StockFlowTheme.danger : StockFlowTheme.text,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _horizontal(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: ProductImage(url: item.imageUrl, category: item.categorySlug),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.25),
                      ),
                      const SizedBox(height: 7),
                      Text(money, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(
                        'MOQ ${item.moq} • ${item.availableQty} available',
                        style: const TextStyle(fontSize: 10.5, color: StockFlowTheme.textSecondary),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, color: StockFlowTheme.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onFavorite != null)
                  IconButton(
                    onPressed: onFavorite,
                    icon: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFavorite ? StockFlowTheme.danger : StockFlowTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}
