import 'package:flutter/material.dart';

import 'flutter_mock_server_demo/screens/users_screen.dart';

void main() {
  runApp(const MockServerDemoApp());
}

class MockServerDemoApp extends StatelessWidget {
  const MockServerDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mock Server Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const UsersScreen(),
    );
  }
}
