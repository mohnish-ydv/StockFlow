import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/platform_ui.dart';
import '../core/theme.dart';
import 'legal_screens.dart';

class SettingsScreen extends StatelessWidget {
  final SfUser user;
  const SettingsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          const _Label('Preferences'),
          _SettingsRow(icon: Icons.language_rounded, title: 'Language', subtitle: user.preferredLanguage == 'hi' ? 'हिन्दी' : 'English'),
          const Divider(height: 1, indent: 42),
          const _SettingsRow(icon: Icons.notifications_none_rounded, title: 'Notifications', subtitle: 'Managed through your device settings'),
          const SizedBox(height: 24),
          const _Label('Legal & privacy'),
          _SettingsRow(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () => Navigator.push(context, SfPlatform.route(context, (_) => const TermsConditionsScreen())),
          ),
          const Divider(height: 1, indent: 42),
          _SettingsRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => Navigator.push(context, SfPlatform.route(context, (_) => const PrivacyPolicyScreen())),
          ),
          const Divider(height: 1, indent: 42),
          const _SettingsRow(icon: Icons.lock_outline_rounded, title: 'Contact privacy', subtitle: 'Phone numbers are not displayed on public listings'),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: const TextStyle(color: StockFlowTheme.muted, fontSize: 11.5, fontWeight: FontWeight.w700)),
      );
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  const _SettingsRow({required this.icon, required this.title, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        minLeadingWidth: 30,
        leading: Icon(icon, size: 20, color: StockFlowTheme.textSecondary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: subtitle == null ? null : Text(subtitle!, style: const TextStyle(color: StockFlowTheme.muted, fontSize: 11.5)),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded, color: StockFlowTheme.muted),
      );
}
