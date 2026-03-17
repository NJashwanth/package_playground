import 'dart:io';

import 'package:flutter_mock_server/flutter_mock_server.dart';

import 'mock_server_controller_stub.dart';

MockServerController createMockServerController() => _IoMockServerController();

class _IoMockServerController implements MockServerController {
  FlutterMockServer? _server;
  Directory? _tempDirectory;

  @override
  bool get supportsLocalServer =>
      Platform.isMacOS || Platform.isLinux || Platform.isWindows;

  @override
  String get unsupportedServerMessage =>
      'Mock server currently works best on desktop (macOS/Linux/Windows). '
      'The runtime here may not support file namespace/watch operations required by flutter_mock_server.';

  @override
  Future<String> start({
    required int port,
    required String sampleConfig,
  }) async {
    if (!supportsLocalServer) {
      throw UnsupportedError(unsupportedServerMessage);
    }

    final tempDirectory = await Directory.systemTemp.createTemp(
      'pkg-playground-',
    );
    final yamlFile = File('${tempDirectory.path}/mock.yaml');
    await yamlFile.writeAsString(sampleConfig);

    final server = FlutterMockServer(
      configPath: yamlFile.path,
      host: '127.0.0.1',
      port: port,
    );

    await server.start();

    _server = server;
    _tempDirectory = tempDirectory;
    return 'Running on http://127.0.0.1:$port';
  }

  @override
  Future<void> stop() async {
    final server = _server;
    if (server != null) {
      await server.stop();
    }

    final tempDirectory = _tempDirectory;
    if (tempDirectory != null && await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }

    _server = null;
    _tempDirectory = null;
  }
}
