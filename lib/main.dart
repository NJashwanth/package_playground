import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: FeatureFlagAuditTestApp()));
}

class FeatureFlagAuditTestApp extends StatelessWidget {
  const FeatureFlagAuditTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'feature_flag_audit playground',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
