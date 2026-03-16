import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mock_server/flutter_mock_server.dart';
import 'package:lifecycle_logger/lifecycle_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  LifecycleLogger.attach(
    debugOnly: false,
    enableRouteObserver: true,
    sink: LifecycleStore.instance.add,
    tag: '[PackagePlayground]',
  );

  runApp(const PackagePlaygroundApp());
}

class LifecycleStore {
  LifecycleStore._();

  static final LifecycleStore instance = LifecycleStore._();

  final ValueNotifier<List<LifecycleEvent>> events =
      ValueNotifier<List<LifecycleEvent>>(<LifecycleEvent>[]);

  void add(LifecycleEvent event) {
    final nextEvents = List<LifecycleEvent>.from(events.value)
      ..insert(0, event);
    events.value = nextEvents;
  }

  void clear() {
    events.value = <LifecycleEvent>[];
  }
}

class PackagePlaygroundApp extends StatelessWidget {
  const PackagePlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Package Playground',
      debugShowCheckedModeBanner: false,
      navigatorObservers: <NavigatorObserver>[LifecycleLogger.routeObserver],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const PlaygroundHomePage(),
    );
  }
}

class PlaygroundHomePage extends StatelessWidget {
  const PlaygroundHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Package Playground'),
          bottom: const TabBar(
            tabs: <Tab>[
              Tab(icon: Icon(Icons.dns), text: 'Mock Server'),
              Tab(icon: Icon(Icons.timeline), text: 'Lifecycle'),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[MockServerPlayground(), LifecyclePlayground()],
        ),
      ),
    );
  }
}

class MockServerPlayground extends StatefulWidget {
  const MockServerPlayground({super.key});

  @override
  State<MockServerPlayground> createState() => _MockServerPlaygroundState();
}

class _MockServerPlaygroundState extends State<MockServerPlayground>
    with LifecycleAware<MockServerPlayground> {
  static const int _serverPort = 8081;

  FlutterMockServer? _server;
  Directory? _tempDirectory;
  bool _isRunning = false;
  String _status = 'Server stopped';
  String _responseBody = 'No response yet';
  final TextEditingController _externalBaseUrlController =
      TextEditingController(text: 'http://127.0.0.1:8081');

  bool get _supportsLocalServer {
    if (kIsWeb) {
      return false;
    }
    return Platform.isMacOS || Platform.isLinux || Platform.isWindows;
  }

  String get _unsupportedServerMessage {
    if (kIsWeb) {
      return 'Mock server is not supported on web because dart:io file and socket APIs are unavailable.';
    }
    return 'Mock server currently works best on desktop (macOS/Linux/Windows). '
        'The runtime here may not support file namespace/watch operations required by flutter_mock_server.';
  }

  @override
  void onDispose() {
    _externalBaseUrlController.dispose();
    _stopServer();
  }

  Uri? get _externalUsersUri {
    final baseText = _externalBaseUrlController.text.trim();
    final baseUri = Uri.tryParse(baseText);
    if (baseUri == null || !baseUri.hasScheme || baseUri.host.isEmpty) {
      return null;
    }

    final usersPath = baseUri.path.endsWith('/')
        ? '${baseUri.path}users'
        : '${baseUri.path}/users';
    return baseUri.replace(path: usersPath, queryParameters: {'limit': '3'});
  }

  Future<void> _startServer() async {
    if (!_supportsLocalServer) {
      setState(() {
        _status = _unsupportedServerMessage;
      });
      return;
    }

    if (_isRunning) {
      return;
    }

    setState(() {
      _status = 'Starting mock server...';
    });

    try {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'pkg-playground-',
      );
      final yamlFile = File('${tempDirectory.path}/mock.yaml');
      await yamlFile.writeAsString(_sampleConfig);

      final server = FlutterMockServer(
        configPath: yamlFile.path,
        host: '127.0.0.1',
        port: _serverPort,
      );

      await server.start();

      if (!mounted) {
        return;
      }

      setState(() {
        _tempDirectory = tempDirectory;
        _server = server;
        _isRunning = true;
        _status = 'Running on http://127.0.0.1:$_serverPort';
      });
    } catch (error) {
      setState(() {
        final errorText = '$error';
        if (errorText.toLowerCase().contains('unsupported operation') ||
            errorText.toLowerCase().contains('namespace')) {
          _status =
              'Failed to start server: $error\n$_unsupportedServerMessage';
          return;
        }
        _status = 'Failed to start server: $error';
      });
    }
  }

  Future<void> _stopServer() async {
    final server = _server;
    if (server != null) {
      await server.stop();
    }

    final tempDirectory = _tempDirectory;
    if (tempDirectory != null && await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _server = null;
      _tempDirectory = null;
      _isRunning = false;
      _status = 'Server stopped';
    });
  }

  Future<void> _fetchUsers() async {
    if (!_isRunning && _supportsLocalServer) {
      setState(() {
        _responseBody = 'Start the server first.';
      });
      return;
    }

    final usersUri = _supportsLocalServer
        ? Uri.parse('http://127.0.0.1:$_serverPort/users?limit=3')
        : _externalUsersUri;

    if (usersUri == null) {
      setState(() {
        _responseBody =
            'Invalid external base URL. Example: http://127.0.0.1:8081';
      });
      return;
    }

    final client = HttpClient();
    try {
      final request = await client.getUrl(usersUri);
      final response = await request.close();
      final body = await utf8.decodeStream(response);

      setState(() {
        _responseBody = 'GET $usersUri\nHTTP ${response.statusCode}\n$body';
      });
    } catch (error) {
      setState(() {
        _responseBody = 'Request failed: $error';
      });
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'flutter_mock_server quick lab',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Status: $_status',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                onPressed: (_isRunning || !_supportsLocalServer)
                    ? null
                    : _startServer,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start server'),
              ),
              FilledButton.tonalIcon(
                onPressed: _isRunning ? _stopServer : null,
                icon: const Icon(Icons.stop),
                label: const Text('Stop server'),
              ),
              OutlinedButton.icon(
                onPressed: _fetchUsers,
                icon: const Icon(Icons.download),
                label: const Text('GET /users'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_supportsLocalServer)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _unsupportedServerMessage,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _externalBaseUrlController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'External mock server base URL',
                      hintText: 'http://127.0.0.1:8081',
                    ),
                  ),
                ],
              ),
            ),
          Text(
            'Sample response',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(_responseBody),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LifecyclePlayground extends StatefulWidget {
  const LifecyclePlayground({super.key});

  @override
  State<LifecyclePlayground> createState() => _LifecyclePlaygroundState();
}

class _LifecyclePlaygroundState extends State<LifecyclePlayground>
    with LifecycleAware<LifecyclePlayground> {
  bool _showProbeWidget = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'lifecycle_logger event stream',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: () {
                  setState(() {
                    _showProbeWidget = !_showProbeWidget;
                  });
                },
                icon: const Icon(Icons.flip),
                label: Text(
                  _showProbeWidget
                      ? 'Unmount probe widget'
                      : 'Mount probe widget',
                ),
              ),
              OutlinedButton.icon(
                onPressed: LifecycleStore.instance.clear,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear logs'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_showProbeWidget) const _ProbeWidget(),
          const SizedBox(height: 12),
          Expanded(
            child: ValueListenableBuilder<List<LifecycleEvent>>(
              valueListenable: LifecycleStore.instance.events,
              builder: (context, events, _) {
                if (events.isEmpty) {
                  return const Center(
                    child: Text(
                      'No events yet. Switch tabs or background the app.',
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: events.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return ListTile(
                      dense: true,
                      title: Text(event.message),
                      subtitle: Text(
                        '${event.type.name} • ${event.timestamp.toIso8601String()}',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProbeWidget extends StatefulWidget {
  const _ProbeWidget();

  @override
  State<_ProbeWidget> createState() => _ProbeWidgetState();
}

class _ProbeWidgetState extends State<_ProbeWidget>
    with LifecycleAware<_ProbeWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            const Icon(Icons.monitor_heart),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Probe widget mounted. Toggle to force initState/dispose logs.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const String _sampleConfig = '''
seed: 42

models:
  User:
    id: uuid
    name: name
    email: email
    role:
      enum: [admin, member, viewer]

stores:
  users:
    model: User
    count: 8

routes:
  - path: /users
    method: GET
    action: list
    store: users

  - path: /users/:id
    method: GET
    action: get
    store: users
''';
