import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'theme.dart';

class SfPlatform {
  static bool isIOS(BuildContext context) => Theme.of(context).platform == TargetPlatform.iOS;

  static Route<T> route<T>(BuildContext context, WidgetBuilder builder) {
    if (isIOS(context)) return CupertinoPageRoute<T>(builder: builder);
    return MaterialPageRoute<T>(builder: builder);
  }
}

class SfGlass extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool border;

  const SfGlass({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.border = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(18);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .76),
            borderRadius: radius,
            border: border ? Border.all(color: Colors.white.withValues(alpha: .72)) : null,
            boxShadow: const [
              BoxShadow(color: Color(0x10000000), blurRadius: 22, offset: Offset(0, 8)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class SfSearchSurface extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const SfSearchSurface({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ios = SfPlatform.isIOS(context);
    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: ios
              ? null
              : BoxDecoration(
                  color: StockFlowTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: StockFlowTheme.line),
                ),
          child: child,
        ),
      ),
    );
    if (!ios) return content;
    return SfGlass(borderRadius: BorderRadius.circular(14), child: content);
  }
}

class SfSectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SfSectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action!),
            ),
        ],
      );
}

class SfInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SfInfoRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: StockFlowTheme.panel2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: StockFlowTheme.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!, style: const TextStyle(color: StockFlowTheme.muted, fontSize: 12)),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      );
}

class SfEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;

  const SfEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: StockFlowTheme.panel2,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: StockFlowTheme.textSecondary, size: 26),
              ),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 7),
              Text(body, textAlign: TextAlign.center, style: const TextStyle(color: StockFlowTheme.muted, height: 1.45)),
              if (action != null) ...[
                const SizedBox(height: 18),
                FilledButton(onPressed: onAction, child: Text(action!)),
              ],
            ],
          ),
        ),
      );
}
