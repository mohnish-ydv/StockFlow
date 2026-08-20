import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/theme.dart';

class SfBrandMark extends StatelessWidget {
  final double size;
  final bool inverted;

  const SfBrandMark({super.key, this.size = 42, this.inverted = false});

  @override
  Widget build(BuildContext context) {
    final background = inverted ? Colors.white : StockFlowTheme.accent;
    final foreground = inverted ? StockFlowTheme.accentStrong : Colors.white;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * .28),
      ),
      child: Icon(Icons.inventory_2_rounded, color: foreground, size: size * .46),
    );
  }
}

class SfWordmark extends StatelessWidget {
  final bool compact;
  final bool light;
  const SfWordmark({super.key, this.compact = false, this.light = false});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SfBrandMark(size: compact ? 34 : 40, inverted: light),
          SizedBox(width: compact ? 9 : 11),
          Text(
            'StockFlow',
            style: TextStyle(
              fontSize: compact ? 18 : 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
              color: light ? Colors.white : StockFlowTheme.text,
            ),
          ),
        ],
      );
}

class SfRoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool filled;
  final Color? foreground;

  const SfRoundIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.filled = false,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: filled ? StockFlowTheme.brandSoft : StockFlowTheme.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 21,
            color: foreground ?? (filled ? StockFlowTheme.accentStrong : StockFlowTheme.text),
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class SfSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  const SfSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action!),
            ),
        ],
      );
}

class SfSearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilter;
  final String hint;
  final bool autofocus;

  const SfSearchBar({
    super.key,
    this.onTap,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onFilter,
    this.hint = 'Search stock, brands or categories',
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final interactiveField = controller != null;
    final body = Container(
      height: 52,
      decoration: BoxDecoration(
        color: StockFlowTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StockFlowTheme.line),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          const Icon(Icons.search_rounded, size: 22, color: StockFlowTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: interactiveField
                ? TextField(
                    controller: controller,
                    autofocus: autofocus,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: hint,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                : Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: StockFlowTheme.muted, fontSize: 14),
                  ),
          ),
          if (onFilter != null) ...[
            Container(width: 1, height: 24, color: StockFlowTheme.line),
            IconButton(
              onPressed: onFilter,
              tooltip: 'Filters',
              icon: const Icon(Icons.tune_rounded, size: 20),
            ),
          ] else
            const SizedBox(width: 14),
        ],
      ),
    );
    if (onTap == null || interactiveField) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: IgnorePointer(child: body),
      ),
    );
  }
}

class SfPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;

  const SfPill({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? (selected ? StockFlowTheme.accentStrong : StockFlowTheme.textSecondary);
    final background = selected ? StockFlowTheme.brandSoft : StockFlowTheme.surface;
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? StockFlowTheme.lineStrong : StockFlowTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: foreground)),
        ],
      ),
    );
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: child,
      ),
    );
  }
}

class SfAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? background;

  const SfAvatar({super.key, required this.name, this.size = 44, this.background});

  String get initial {
    final value = name.trim();
    return value.isEmpty ? 'S' : value.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background ?? StockFlowTheme.brandSoft,
          shape: BoxShape.circle,
        ),
        child: Text(
          initial,
          style: TextStyle(
            color: StockFlowTheme.accentStrong,
            fontSize: size * .38,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class SfListRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;

  const SfListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = destructive ? StockFlowTheme.danger : StockFlowTheme.text;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              SizedBox(
                width: 38,
                child: Icon(icon, size: 21, color: destructive ? StockFlowTheme.danger : StockFlowTheme.textSecondary),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: foreground)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(subtitle!, style: const TextStyle(fontSize: 11.5, color: StockFlowTheme.muted)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ?? const Icon(Icons.chevron_right_rounded, size: 20, color: StockFlowTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class SfStickyActionBar extends StatelessWidget {
  final Widget child;
  const SfStickyActionBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: StockFlowTheme.surface,
          border: Border(top: BorderSide(color: StockFlowTheme.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: child,
          ),
        ),
      );
}

class SfStatusDot extends StatelessWidget {
  final Color color;
  final double size;
  const SfStatusDot({super.key, required this.color, this.size = 8});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class SfSkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const SfSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SfSkeletonBox> createState() => _SfSkeletonBoxState();
}

class _SfSkeletonBoxState extends State<SfSkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1050))..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SfMotion.reduce(context)) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: StockFlowTheme.panel2,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      ),
    );
    if (SfMotion.reduce(context)) return box;
    return FadeTransition(
        opacity: Tween<double>(begin: .48, end: .88).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
        child: box,
      );
  }
}

class SfListingGridSkeleton extends StatelessWidget {
  final int columns;
  final int itemCount;

  const SfListingGridSkeleton({super.key, this.columns = 2, this.itemCount = 6});

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 22,
          childAspectRatio: .67,
        ),
        itemBuilder: (_, __) => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: SfSkeletonBox(height: 180, borderRadius: BorderRadius.all(Radius.circular(18)))),
            SizedBox(height: 10),
            SfSkeletonBox(height: 16, width: 92),
            SizedBox(height: 7),
            SfSkeletonBox(height: 13),
            SizedBox(height: 6),
            SfSkeletonBox(height: 11, width: 118),
          ],
        ),
      );
}

class SfListSkeleton extends StatelessWidget {
  final int rows;
  const SfListSkeleton({super.key, this.rows = 5});

  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(
          rows,
          (index) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                SfSkeletonBox(width: 58, height: 58, borderRadius: BorderRadius.all(Radius.circular(14))),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SfSkeletonBox(height: 14),
                      SizedBox(height: 8),
                      SfSkeletonBox(height: 11, width: 170),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
