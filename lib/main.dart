import 'package:flutter/material.dart';

void main() {
  runApp(const PackagePlaygroundApp());
}

class PackagePlaygroundApp extends StatelessWidget {
  const PackagePlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Package Playground',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(body: Center(child: Text('Package Playground'))),
    );
  }
}
