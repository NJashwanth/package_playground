import '../mock_firebase/mock_remote_config.dart';

/// Wraps MockRemoteConfig with typed helper methods.
///
/// The method names below (boolConfigValueProvider, stringConfigValueProvider,
/// intConfigValueProvider, doubleConfigValueProvider) match the wrapper_methods
/// list in feature_flag_audit.yaml, so the audit scanner will detect key
/// arguments passed to these calls just like direct getBool / getString calls.
class RemoteConfigService {
  final MockRemoteConfig _rc;

  RemoteConfigService({MockRemoteConfig? rc})
      : _rc = rc ?? MockRemoteConfig.instance;

  // ── Typed wrappers (detected by feature_flag_audit as wrapper_methods) ────

  bool boolConfigValueProvider(String key, {bool defaultValue = false}) {
    try {
      return _rc.getBool(key);
    } catch (_) {
      return defaultValue;
    }
  }

  String stringConfigValueProvider(String key, {String defaultValue = ''}) {
    try {
      final value = _rc.getString(key);
      return value.isEmpty ? defaultValue : value;
    } catch (_) {
      return defaultValue;
    }
  }

  int intConfigValueProvider(String key, {int defaultValue = 0}) {
    try {
      return _rc.getInt(key);
    } catch (_) {
      return defaultValue;
    }
  }

  double doubleConfigValueProvider(String key, {double defaultValue = 0.0}) {
    try {
      return _rc.getDouble(key);
    } catch (_) {
      return defaultValue;
    }
  }
}
