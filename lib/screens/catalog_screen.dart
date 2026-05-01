import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/remote_config_providers.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enableNewSearch = ref.watch(enableNewSearchProvider);
    final enableLiveChat = ref.watch(enableLiveChatProvider);
    final maxCart = ref.watch(maxCartItemsProvider);
    final showLegacyBanner = ref.watch(legacyBannerEnabledProvider);
    final cartBadgeStyle = ref.watch(cartBadgeStyleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog'),
        actions: [
          if (enableLiveChat)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () {},
            ),
        ],
      ),
      body: Column(
        children: [
          if (showLegacyBanner)
            MaterialBanner(
              content: const Text('Legacy sale banner is active'),
              actions: [
                TextButton(onPressed: () {}, child: const Text('Dismiss')),
              ],
            ),
          if (enableNewSearch)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SearchBar(
                hintText: 'Search products…',
                onSubmitted: (_) {},
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: 8,
              itemBuilder: (_, i) => ListTile(
                leading: Badge(
                  label: Text(cartBadgeStyle == 'dot' ? '•' : '$i'),
                  child: const Icon(Icons.shopping_bag),
                ),
                title: Text('Item ${i + 1}'),
                subtitle: Text('Max $maxCart in cart'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
