import 'package:flutter/material.dart';

import '../core/theme.dart';

class ProductImage extends StatelessWidget {
  final String url;
  final String category;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ProductImage({
    super.key,
    required this.url,
    required this.category,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  bool get _needsPlaceholder => url.trim().isEmpty || url.contains('picsum.photos');

  IconData get _icon {
    switch (category) {
      case 'electronics':
        return Icons.tv_outlined;
      case 'fashion':
        return Icons.checkroom_outlined;
      case 'mobiles':
        return Icons.smartphone_outlined;
      case 'home-kitchen':
        return Icons.kitchen_outlined;
      case 'furniture':
        return Icons.chair_outlined;
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
        return Icons.inventory_2_outlined;
    }
  }

  String get _label {
    final value = category.replaceAll('-', ' ').trim();
    if (value.isEmpty) return 'Product';
    return value.split(' ').map((part) => part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    if (_needsPlaceholder) return _placeholder();
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => _placeholder(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 180),
            builder: (context, value, child) => Opacity(opacity: value, child: child),
            child: child,
          );
        }
        return Container(width: width, height: height, color: StockFlowTheme.panel2);
      },
    );
  }

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: StockFlowTheme.brandWash,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 34, color: StockFlowTheme.accent),
            const SizedBox(height: 8),
            Text(
              _label,
              style: const TextStyle(
                color: StockFlowTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}
