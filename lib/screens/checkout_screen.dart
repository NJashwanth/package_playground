import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/remote_config_providers.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutEnabled = ref.watch(enableCheckoutProvider);
    final promoCode = ref.watch(promoCodeProvider);
    final timeout = ref.watch(apiTimeoutSecondsProvider);
    final animSpeed = ref.watch(animationSpeedMultiplierProvider);
    final showExperimental = ref.watch(experimentalFeatureV2Provider);
    final legacySpeed = ref.watch(animationSpeedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: !checkoutEnabled
          ? const Center(child: Text('Checkout is currently unavailable.'))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showExperimental)
                    const Chip(
                      label: Text('New Checkout Flow'),
                      backgroundColor: Colors.purpleAccent,
                    ),
                  const SizedBox(height: 16),
                  Text('Promo code: $promoCode',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Request timeout: ${timeout}s',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                      'Animation speed: ${animSpeed}x (legacy: ${legacySpeed}x)',
                      style: const TextStyle(color: Colors.grey)),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Place Order'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
