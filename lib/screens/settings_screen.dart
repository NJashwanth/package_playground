import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/remote_config_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = ref.watch(onboardingVariantProvider);
    final promo = ref.watch(promoCodeProvider);
    final darkMode = ref.watch(enableDarkModeProvider);
    final themeColor = ref.watch(appThemeColorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: darkMode,
            onChanged: (_) {},
          ),
          ListTile(
            title: const Text('Onboarding Variant'),
            subtitle: Text(variant),
          ),
          ListTile(
            title: const Text('Active Promo'),
            subtitle: Text(promo.isEmpty ? 'None' : promo),
          ),
          ListTile(
            title: const Text('Theme Colour'),
            subtitle: Text(themeColor.isEmpty ? 'Default' : themeColor),
          ),
          const Divider(),
          const ListTile(
            title: Text('About', style: TextStyle(color: Colors.grey)),
            subtitle: Text(
              'feature_flag_audit test playground\n'
              'All flags served from MockRemoteConfig.\n'
              'Run: dart run feature_flag_audit',
            ),
          ),
        ],
      ),
    );
  }
}
