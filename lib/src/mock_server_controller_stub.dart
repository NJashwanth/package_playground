abstract class MockServerController {
  bool get supportsLocalServer;

  String get unsupportedServerMessage;

  Future<String> start({required int port, required String sampleConfig});

  Future<void> stop();
}

MockServerController createMockServerController() =>
    _UnsupportedMockServerController();

class _UnsupportedMockServerController implements MockServerController {
  @override
  bool get supportsLocalServer => false;

  @override
  String get unsupportedServerMessage =>
      'Mock server is not supported on web because dart:io file and socket APIs are unavailable. '
      'Use an external mock server URL instead.';

  @override
  Future<String> start({required int port, required String sampleConfig}) {
    throw UnsupportedError(unsupportedServerMessage);
  }

  @override
  Future<void> stop() async {}
}
