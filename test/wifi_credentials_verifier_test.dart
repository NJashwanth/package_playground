import 'package:flutter_test/flutter_test.dart';
import 'package:package_playground/src/wifi_credentials_verifier.dart';

void main() {
  const service = WifiCredentialsVerifierService();

  test('rejects empty ssid', () async {
    final result = await service.verify(ssid: '   ', password: '12345678');

    expect(result.status, WifiCredentialCheckStatus.invalidSsid);
    expect(result.message, contains('SSID is required'));
  });

  test('rejects invalid password length', () async {
    final result = await service.verify(ssid: 'OfficeWiFi', password: 'short');

    expect(result.status, WifiCredentialCheckStatus.invalidPassword);
    expect(result.message, contains('8-63 characters'));
  });

  test('accepts valid passphrase format', () async {
    final result = await service.verify(
      ssid: 'OfficeWiFi',
      password: 'correct-horse-battery-staple',
    );

    expect(result.status, WifiCredentialCheckStatus.validFormatOnly);
    expect(result.isFormatValid, isTrue);
  });

  test('accepts open network when allowed', () async {
    final result = await service.verify(
      ssid: 'GuestWiFi',
      password: '',
      allowOpenNetwork: true,
    );

    expect(result.status, WifiCredentialCheckStatus.validFormatOnly);
  });
}
