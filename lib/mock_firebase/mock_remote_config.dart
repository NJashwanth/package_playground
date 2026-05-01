import '../config/remote_config_keys.dart';

/// Simulates the FirebaseRemoteConfig API surface so the app compiles and runs
/// without a real Firebase project wired in. The audit scanner performs static
/// analysis on callers of getBool / getString / getInt / getDouble, so this
/// class only needs to expose those method signatures.
class MockRemoteConfig {
  static final MockRemoteConfig instance = MockRemoteConfig._();
  MockRemoteConfig._();

  final Map<String, dynamic> _values = {
    RemoteConfigKeys.enableDarkMode: false,
    RemoteConfigKeys.showPremiumBanner: true,
    RemoteConfigKeys.onboardingVariant: 'control',
    RemoteConfigKeys.homeGridColumns: 2,
    RemoteConfigKeys.enableCheckout: true,
    RemoteConfigKeys.enableNewSearch: false,
    RemoteConfigKeys.enableLiveChat: true,
    RemoteConfigKeys.apiTimeoutSeconds: 30,
    RemoteConfigKeys.maxCartItems: 10,
    RemoteConfigKeys.promoCode: 'SAVE10',
    RemoteConfigKeys.animationSpeedMultiplier: 1.0,
    // code-only keys – present here so the app runs, absent from Firebase
    RemoteConfigKeys.debugMode: false,
    RemoteConfigKeys.experimentalFeatureV2: false,
    // direct-literal keys used in the app
    'legacy_banner_enabled': false,
    'app_theme_color': '#6200EE',
    'cart_badge_style': 'dot',
  };

  bool getBool(String key) => (_values[key] as bool?) ?? false;
  String getString(String key) => (_values[key] as String?) ?? '';
  int getInt(String key) => (_values[key] as int?) ?? 0;
  double getDouble(String key) => (_values[key] as num?)?.toDouble() ?? 0.0;
}
