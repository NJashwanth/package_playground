import 'package:flutter/foundation.dart';

enum WifiCredentialCheckStatus { validFormatOnly, invalidSsid, invalidPassword }

class WifiCredentialCheckResult {
  const WifiCredentialCheckResult({
    required this.status,
    required this.message,
  });

  final WifiCredentialCheckStatus status;
  final String message;

  bool get isFormatValid => status == WifiCredentialCheckStatus.validFormatOnly;
}

class WifiCredentialsVerifierService {
  const WifiCredentialsVerifierService();

  Future<WifiCredentialCheckResult> verify({
    required String ssid,
    required String password,
    bool allowOpenNetwork = false,
  }) async {
    final ssidError = _validateSsid(ssid);
    if (ssidError != null) {
      return WifiCredentialCheckResult(
        status: WifiCredentialCheckStatus.invalidSsid,
        message: ssidError,
      );
    }

    final passwordError = _validatePassword(
      password: password,
      allowOpenNetwork: allowOpenNetwork,
    );
    if (passwordError != null) {
      return WifiCredentialCheckResult(
        status: WifiCredentialCheckStatus.invalidPassword,
        message: passwordError,
      );
    }

    return WifiCredentialCheckResult(
      status: WifiCredentialCheckStatus.validFormatOnly,
      message:
          '${_platformHint()} Credentials look valid by format. '
          'Definitive verification requires attempting a real Wi-Fi connection.',
    );
  }

  String? _validateSsid(String ssid) {
    final trimmed = ssid.trim();
    if (trimmed.isEmpty) {
      return 'SSID is required.';
    }

    final utf8Length = trimmed.codeUnits.length;
    if (utf8Length > 32) {
      return 'SSID must be 1 to 32 bytes.';
    }

    if (trimmed.codeUnits.any((unit) => unit < 32 || unit == 127)) {
      return 'SSID cannot contain control characters.';
    }

    return null;
  }

  String? _validatePassword({
    required String password,
    required bool allowOpenNetwork,
  }) {
    if (allowOpenNetwork && password.isEmpty) {
      return null;
    }

    final isHex64 = RegExp(r'^[0-9A-Fa-f]{64}$').hasMatch(password);
    final isAsciiPassphrase = password.length >= 8 && password.length <= 63;

    if (!isHex64 && !isAsciiPassphrase) {
      return 'Password must be 8-63 characters or a 64-char hex key.';
    }

    return null;
  }

  String _platformHint() {
    if (kIsWeb) {
      return 'On web, browsers cannot directly validate Wi-Fi credentials.';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'On Android, you can validate by attempting to join the network.';
      case TargetPlatform.iOS:
        return 'On iOS, Wi-Fi joining APIs are restricted and app-entitlement dependent.';
      default:
        return 'Platform-specific connection APIs are required for hard verification.';
    }
  }
}
