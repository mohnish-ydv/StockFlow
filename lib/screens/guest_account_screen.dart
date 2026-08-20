import 'package:flutter/material.dart';

import '../widgets/sf_ui.dart';
import 'auth_screen.dart';
import 'help_safety_screen.dart';
import 'legal_screens.dart';

class GuestAccountScreen extends StatelessWidget {
  final Future<bool> Function(AuthMode mode) authenticate;

  const GuestAccountScreen({super.key, required this.authenticate});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
          children: [
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SfAvatar(name: 'Guest', size: 58),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You’re browsing as a guest', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text('Sign in when you’re ready to deal.', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () => authenticate(AuthMode.signIn), child: const Text('Sign in')),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: () => authenticate(AuthMode.register), child: const Text('Create account')),
            ),
            const SizedBox(height: 34),
            Text('Help & legal', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 5),
            SfListRow(
              icon: Icons.help_outline_rounded,
              title: 'Help & safety',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSafetyScreen())),
            ),
            const Divider(height: 1, indent: 38),
            SfListRow(
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsConditionsScreen())),
            ),
            const Divider(height: 1, indent: 38),
            SfListRow(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
            ),
          ],
        ),
      );
}
