import 'package:flutter/material.dart';

import 'theme.dart';

class StockFlowAdConfig {
  const StockFlowAdConfig._();

  /// Provider integration intentionally stays off until a production ad network
  /// is configured. Stable slot IDs below are the integration contract.
  static const enabled = false;
}

class SfAdSlot extends StatelessWidget {
  final String slotId;
  final double height;
  final Widget? child;

  const SfAdSlot({
    super.key,
    required this.slotId,
    this.height = 96,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!StockFlowAdConfig.enabled && child == null) return const SizedBox.shrink();
    return Semantics(
      label: 'Sponsored',
      container: true,
      child: Container(
        height: height,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: StockFlowTheme.panel2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: StockFlowTheme.line),
        ),
        child: child ?? const Text('Sponsored', style: TextStyle(color: StockFlowTheme.muted, fontSize: 11)),
      ),
    );
  }
}
