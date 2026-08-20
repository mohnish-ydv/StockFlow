import 'package:flutter/material.dart';

import '../core/theme.dart';

class HelpSafetyScreen extends StatelessWidget {
  const HelpSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & safety')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          Text('Safer marketplace deals', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'Keep the listing, negotiation and fulfilment details connected so both sides have the same deal context.',
            style: TextStyle(color: StockFlowTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          const _SafetyRow(icon: Icons.photo_camera_back_outlined, title: 'Check the stock', body: 'Review photos, condition, quantity, MOQ, seller status and location before committing.'),
          const Divider(height: 1, indent: 40),
          const _SafetyRow(icon: Icons.forum_outlined, title: 'Keep negotiation in chat', body: 'Use listing-linked chat and structured offers so quantity and price changes remain clear.'),
          const Divider(height: 1, indent: 40),
          const _SafetyRow(icon: Icons.payments_outlined, title: 'Confirm before payment', body: 'Check the delivery or pickup arrangement and final order details before paying.'),
          const Divider(height: 1, indent: 40),
          const _SafetyRow(icon: Icons.report_outlined, title: 'Avoid suspicious deals', body: 'Do not proceed when listing details conflict, a user pressures you off-platform, or the deal appears unrealistic.'),
        ],
      ),
    );
  }
}

class _SafetyRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _SafetyRow({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: StockFlowTheme.textSecondary, size: 21),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(body, style: const TextStyle(color: StockFlowTheme.muted, fontSize: 12.5, height: 1.48)),
                ],
              ),
            ),
          ],
        ),
      );
}
