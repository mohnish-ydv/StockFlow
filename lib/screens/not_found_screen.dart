import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/sf_ui.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const SfBrandMark(size: 58),
                  const SizedBox(height: 24),
                  const Text('404', style: TextStyle(fontSize: 46, fontWeight: FontWeight.w900, letterSpacing: -2, color: StockFlowTheme.accentStrong)),
                  const SizedBox(height: 8),
                  Text('This page moved', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text('The link may be outdated or the page is no longer available.', textAlign: TextAlign.center, style: TextStyle(color: StockFlowTheme.muted, height: 1.5)),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Back to StockFlow'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
