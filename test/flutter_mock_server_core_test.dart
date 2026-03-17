import 'dart:convert';
import 'dart:io';

import 'package:flutter_mock_server/flutter_mock_server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('flutter_mock_server core suite', () {
    test('returns 404 for unknown routes and method mismatches', () async {
      final running = await _spawnServer(config: _healthConfig());
      addTearDown(running.dispose);

      final missing = await running.request('GET', '/missing');
      expect(missing.statusCode, 404);
      expect(missing.jsonBody['message'], contains('No mock route found'));

      final wrongMethod = await running.request('POST', '/health');
      expect(wrongMethod.statusCode, 404);
    });

    test('supports CRUD lifecycle with path and query bindings', () async {
      final running = await _spawnServer(config: _crudConfig());
      addTearDown(running.dispose);

      final create = await running.request(
        'POST',
        '/users',
        body: {
          'name': 'Morgan',
          'email': 'morgan@sample.app',
          'role': 'member',
        },
      );
      expect(create.statusCode, 201);
      final created = create.jsonBody;
      expect(created['id'], isNotEmpty);

      final id = created['id'] as String;

      final get = await running.request('GET', '/users/$id');
      expect(get.statusCode, 200);
      expect(get.jsonBody['email'], 'morgan@sample.app');

      final update = await running.request(
        'PUT',
        '/users/$id',
        body: {'role': 'admin'},
      );
      expect(update.statusCode, 200);
      expect(update.jsonBody['role'], 'admin');

      final bind = await running.request(
        'POST',
        '/users/$id/session',
        query: {'source': 'core-suite'},
        body: {'email': 'morgan@sample.app'},
      );
      expect(bind.statusCode, 201);
      expect(bind.jsonBody['userId'], id);
      expect(bind.jsonBody['source'], 'core-suite');
      expect(bind.jsonBody['email'], 'morgan@sample.app');

      final delete = await running.request('DELETE', '/users/$id');
      expect(delete.statusCode, 200);
      expect(delete.jsonBody['deleted'], isTrue);

      final afterDelete = await running.request('GET', '/users/$id');
      expect(afterDelete.statusCode, 404);
    });

    test('applies filtering, sorting, and pagination correctly', () async {
      final running = await _spawnServer(config: _queryConfig());
      addTearDown(running.dispose);

      final rows = <Map<String, Object?>>[
        {'name': 'Zoe', 'role': 'member'},
        {'name': 'Amy', 'role': 'member'},
        {'name': 'Cara', 'role': 'member'},
        {'name': 'Bella', 'role': 'member'},
        {'name': 'Dana', 'role': 'member'},
        {'name': 'AdminOnly', 'role': 'admin'},
      ];

      for (final row in rows) {
        final create = await running.request('POST', '/users', body: row);
        expect(create.statusCode, 201);
      }

      final list = await running.request(
        'GET',
        '/users',
        query: {
          'role': 'member',
          'sort': 'name',
          'order': 'asc',
          'limit': '2',
          'page': '2',
        },
      );

      expect(list.statusCode, 200);
      final payload = list.jsonListBody;
      expect(payload, hasLength(2));
      expect(payload[0]['name'], 'Cara');
      expect(payload[1]['name'], 'Dana');
      expect(payload.every((item) => item['role'] == 'member'), isTrue);
    });

    test('supports static file responses and custom headers', () async {
      final running = await _spawnServer(
        config: _fileResponseConfig(),
        extraFiles: {'data/snapshot.json': '{"build":"1.0.0","users":[1,2,3]}'},
      );
      addTearDown(running.dispose);

      final response = await running.request('GET', '/snapshot');
      expect(response.statusCode, 202);
      expect(response.header('x-suite'), 'core');
      expect(response.jsonBody['build'], '1.0.0');
      expect(response.jsonBody['users'], [1, 2, 3]);
    });

    test('honors delay and deterministic error injection', () async {
      final running = await _spawnServer(config: _errorDelayConfig());
      addTearDown(running.dispose);

      final stopwatch = Stopwatch()..start();
      final response = await running.request('GET', '/flaky');
      stopwatch.stop();

      expect(response.statusCode, 503);
      expect(response.jsonBody['message'], 'temporary outage');
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
    });

    test('reloads config file changes while running', () async {
      final running = await _spawnServer(config: _versionConfig('v1'));
      addTearDown(running.dispose);

      final before = await running.request('GET', '/version');
      expect(before.statusCode, 200);
      expect(before.jsonBody['version'], 'v1');

      await running.configFile.writeAsString(_versionConfig('v2'));

      String? version;
      final timeout = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(timeout)) {
        final current = await running.request('GET', '/version');
        version = current.jsonBody['version'] as String?;
        if (version == 'v2') {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }

      expect(version, 'v2');
    });

    test('fails startup for invalid response payload config', () async {
      final tempDir = await Directory.systemTemp.createTemp('fms_invalid_');
      final configFile = File('${tempDir.path}/mock.yaml');
      await configFile.writeAsString('''
routes:
  - path: /broken
    method: GET
    response:
      status: 200
''');

      final server = FlutterMockServer(
        configPath: configFile.path,
        host: '127.0.0.1',
        port: await _findFreePort(),
      );

      try {
        await expectLater(server.start(), throwsA(isA<MockConfigException>()));
      } finally {
        await server.stop();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('rebuilds deterministic seeded stores after restart', () async {
      final tempDir = await Directory.systemTemp.createTemp('fms_seed_');
      final configFile = File('${tempDir.path}/mock.yaml');
      await configFile.writeAsString(_seededConfig());

      final first = await _startWithConfigFile(
        configFile,
        tempDir: tempDir,
        deleteTempDirOnDispose: false,
      );
      final firstList = (await first.request('GET', '/users')).jsonListBody;
      await first.dispose();

      final second = await _startWithConfigFile(configFile);
      addTearDown(() async {
        await second.dispose();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final secondList = (await second.request('GET', '/users')).jsonListBody;

      final firstStable = firstList
          .map((item) => {'name': item['name'], 'role': item['role']})
          .toList(growable: false);
      final secondStable = secondList
          .map((item) => {'name': item['name'], 'role': item['role']})
          .toList(growable: false);

      expect(jsonEncode(firstStable), jsonEncode(secondStable));
    });
  });
}

Future<_RunningServer> _spawnServer({
  required String config,
  Map<String, String> extraFiles = const {},
}) async {
  final tempDir = await Directory.systemTemp.createTemp('fms_core_');
  for (final entry in extraFiles.entries) {
    final file = File('${tempDir.path}/${entry.key}');
    await file.parent.create(recursive: true);
    await file.writeAsString(entry.value);
  }

  final configFile = File('${tempDir.path}/mock.yaml');
  await configFile.writeAsString(config);

  return _startWithConfigFile(configFile, tempDir: tempDir);
}

Future<_RunningServer> _startWithConfigFile(
  File configFile, {
  Directory? tempDir,
  bool deleteTempDirOnDispose = true,
}) async {
  final server = FlutterMockServer(
    configPath: configFile.path,
    host: '127.0.0.1',
    port: await _findFreePort(),
  );
  final client = HttpClient();
  await server.start();

  return _RunningServer(
    server: server,
    client: client,
    host: '127.0.0.1',
    port: server.port,
    configFile: configFile,
    tempDir: tempDir ?? configFile.parent,
    deleteTempDirOnDispose: deleteTempDirOnDispose,
  );
}

Future<int> _findFreePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

class _RunningServer {
  _RunningServer({
    required this.server,
    required this.client,
    required this.host,
    required this.port,
    required this.configFile,
    required this.tempDir,
    required this.deleteTempDirOnDispose,
  });

  final FlutterMockServer server;
  final HttpClient client;
  final String host;
  final int port;
  final File configFile;
  final Directory tempDir;
  final bool deleteTempDirOnDispose;

  Future<_ResponseData> request(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = Uri(
      scheme: 'http',
      host: host,
      port: port,
      path: path,
      queryParameters: query,
    );
    final request = await client.openUrl(method, uri);
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();

    final headers = <String, String>{};
    response.headers.forEach((name, values) {
      headers[name.toLowerCase()] = values.join(',');
    });

    return _ResponseData(
      statusCode: response.statusCode,
      body: responseBody,
      headers: headers,
    );
  }

  Future<void> dispose() async {
    client.close(force: true);
    await server.stop();
    if (deleteTempDirOnDispose && await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
}

class _ResponseData {
  const _ResponseData({
    required this.statusCode,
    required this.body,
    required this.headers,
  });

  final int statusCode;
  final String body;
  final Map<String, String> headers;

  Map<String, dynamic> get jsonBody => jsonDecode(body) as Map<String, dynamic>;

  List<Map<String, dynamic>> get jsonListBody =>
      (jsonDecode(body) as List<dynamic>).cast<Map<String, dynamic>>();

  String? header(String name) => headers[name.toLowerCase()];
}

String _healthConfig() => '''
routes:
  - path: /health
    method: GET
    response:
      body:
        status: ok
''';

String _crudConfig() => '''
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
    count: 2

routes:
  - path: /users
    method: GET
    action: list
    store: users

  - path: /users/:id
    method: GET
    action: get
    store: users

  - path: /users
    method: POST
    action: create
    store: users

  - path: /users/:id
    method: PUT
    action: update
    store: users

  - path: /users/:id
    method: DELETE
    action: delete
    store: users

  - path: /users/:id/session
    method: POST
    response:
      status: 201
      body:
        userId: "{{request.path.id}}"
        source: "{{request.query.source}}"
        email: "{{request.body.email}}"
''';

String _queryConfig() => '''
models:
  User:
    id: uuid
    name: name
    role:
      enum: [admin, member]

stores:
  users:
    model: User
    count: 0

routes:
  - path: /users
    method: GET
    action: list
    store: users

  - path: /users
    method: POST
    action: create
    store: users
''';

String _fileResponseConfig() => '''
routes:
  - path: /snapshot
    method: GET
    response:
      status: 202
      headers:
        x-suite: core
      file: data/snapshot.json
''';

String _errorDelayConfig() => '''
routes:
  - path: /flaky
    method: GET
    response:
      status: 200
      body:
        ok: true
      delay_ms: 150
      error:
        status: 503
        rate: 1.0
        delay_ms: 120
        body:
          message: temporary outage
''';

String _versionConfig(String version) =>
    '''
routes:
  - path: /version
    method: GET
    response:
      body:
        version: $version
''';

String _seededConfig() => '''
seed: 7

models:
  User:
    id: uuid
    name: name
    role:
      enum: [admin, member, viewer]

stores:
  users:
    model: User
    count: 4

routes:
  - path: /users
    method: GET
    action: list
    store: users
''';
