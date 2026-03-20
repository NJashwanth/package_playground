import 'dart:io';

import 'package:flutter_mock_server/flutter_mock_server.dart';
import 'package:path/path.dart' as p;

/// Singleton that owns the [FlutterMockServer] lifecycle.
///
/// Call [start] once (idempotent) and [stop] to clean up.
/// The server watches [configPath] for hot-reloads automatically.
class MockServerService {
  MockServerService._();

  static final instance = MockServerService._();

  FlutterMockServer? _server;

  // True when the port was already bound by an external process on start().
  bool _externallyRunning = false;

  /// Whether the server is reachable (owned by us or externally running).
  bool get isRunning => _server != null || _externallyRunning;

  Future<void> start({
    String configPath = 'mock.yaml',
    String host = 'localhost',
    int port = 8080,
  }) async {
    if (_server != null) return;
    _externallyRunning = false;

    final resolvedPath = p.isAbsolute(configPath)
        ? configPath
        : _resolveConfig(configPath);

    final server = FlutterMockServer(
      configPath: resolvedPath,
      host: host,
      port: port,
    );

    try {
      await server.start();
      _server = server;
    } on SocketException catch (e) {
      // errno 48 (macOS) / 98 (Linux) = Address already in use.
      // Another process already owns the port — treat as available.
      if (e.osError?.errorCode == 48 || e.osError?.errorCode == 98) {
        _externallyRunning = true;
        try {
          await server.stop();
        } catch (_) {} // ignore cleanup errors
      } else {
        rethrow;
      }
    }
  }

  /// Resolves a relative [configPath] to an absolute path.
  ///
  /// Walks up from the Dart executable looking for a directory that contains
  /// `pubspec.yaml` — that directory is the project root. This works
  /// reliably for Flutter macOS desktop debug builds where the executable
  /// lives inside `build/macos/Build/Products/Debug/<app>.app/Contents/MacOS/`.
  static String _resolveConfig(String configPath) {
    var dir = File(Platform.resolvedExecutable).parent;
    for (var i = 0; i < 20; i++) {
      if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
        return p.join(dir.path, configPath);
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }

    // Fallback: PWD env var (set in some launch environments).
    final pwd = Platform.environment['PWD'];
    return pwd != null ? p.join(pwd, configPath) : configPath;
  }

  Future<void> stop() async {
    await _server?.stop();
    _server = null;
    _externallyRunning = false;
  }
}
