import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/sf_ui.dart';

class WelcomeScreen extends StatelessWidget {
  final StockFlowApi api;
  final VoidCallback onExplore;
  final VoidCallback onCreateAccount;
  final VoidCallback onSignIn;

  const WelcomeScreen({
    super.key,
    required this.api,
    required this.onExplore,
    required this.onCreateAccount,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: StockFlowTheme.surface,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 700;
              return Stack(
                children: [
                  const Positioned(left: -126, top: -184, child: _Blob(size: 390, color: StockFlowTheme.accent)),
                  const Positioned(right: -88, top: 172, child: _Blob(size: 188, color: Color(0xFFDCE7FF))),
                  Positioned(
                    left: 22,
                    right: 22,
                    top: 18,
                    bottom: 20,
                    child: Column(
                      children: [
                        const Align(alignment: Alignment.centerLeft, child: SfWordmark(compact: true, light: true)),
                        Spacer(flex: compact ? 2 : 3),
                        const _WelcomeMark(),
                        SizedBox(height: compact ? 26 : 34),
                        Text('StockFlow', style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 292),
                          child: const Text(
                            'Surplus stock, ready when you are.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, height: 1.5, color: StockFlowTheme.textSecondary),
                          ),
                        ),
                        Spacer(flex: compact ? 2 : 3),
                        SizedBox(width: double.infinity, child: FilledButton(onPressed: onExplore, child: const Text('Browse stock as guest'))),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account?', style: TextStyle(fontSize: 12.5, color: StockFlowTheme.muted)),
                            const SizedBox(width: 3),
                            TextButton(onPressed: onSignIn, child: const Text('Sign in')),
                          ],
                        ),
                        const SizedBox(height: 2),
                        TextButton(onPressed: onCreateAccount, child: const Text('Create an account instead')),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _WelcomeMark extends StatelessWidget {
  const _WelcomeMark();

  @override
  Widget build(BuildContext context) => Container(
        width: 122,
        height: 122,
        decoration: BoxDecoration(
          color: StockFlowTheme.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 28, offset: Offset(0, 10))],
        ),
        child: const Center(child: SfBrandMark(size: 74)),
      );
}
