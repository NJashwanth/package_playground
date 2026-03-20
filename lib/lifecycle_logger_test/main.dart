import 'package:flutter/material.dart';
import 'package:lifecycle_logger/lifecycle_logger.dart';

void main() {
  runApp(const LifecycleLoggerTestApp());
}

class LifecycleLoggerTestApp extends StatelessWidget {
  const LifecycleLoggerTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lifecycle Logger Test',
      home: const LifecycleLoggerTestHome(),
    );
  }
}

class LifecycleLoggerTestHome extends StatefulWidget {
  const LifecycleLoggerTestHome({super.key});

  @override
  State<LifecycleLoggerTestHome> createState() =>
      _LifecycleLoggerTestHomeState();
}

class _LifecycleLoggerTestHomeState extends State<LifecycleLoggerTestHome>
    with WidgetsBindingObserver {
  String _lifecycleState = 'App started';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _lifecycleState =
          'Lifecycle state: '
          '${state.toString().split('.').last}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lifecycle Logger Test')),
      body: Center(
        child: Text(_lifecycleState, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
