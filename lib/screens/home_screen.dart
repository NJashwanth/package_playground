import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/remote_config_providers.dart';
import 'catalog_screen.dart';
import 'checkout_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(enableDarkModeProvider);
    final showPremiumBanner = ref.watch(showPremiumBannerProvider);
    final gridColumns = ref.watch(homeGridColumnsProvider);
    final isDebugMode = ref.watch(debugModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Flag Audit – Playground'),
        backgroundColor: isDarkMode ? Colors.grey[900] : null,
        actions: [
          if (isDebugMode)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.bug_report, color: Colors.orange),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          if (showPremiumBanner)
            Container(
              width: double.infinity,
              color: Colors.amber[700],
              padding: const EdgeInsets.all(12),
              child: const Text(
                'Upgrade to Premium',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridColumns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 6,
              itemBuilder: (_, i) => Card(
                child: InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CatalogScreen())),
                  child: Center(child: Text('Product ${i + 1}')),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Checkout'),
        icon: const Icon(Icons.shopping_cart),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CheckoutScreen())),
      ),
    );
  }
}
