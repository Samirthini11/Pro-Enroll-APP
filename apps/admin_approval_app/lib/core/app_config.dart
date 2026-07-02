import 'package:flutter/foundation.dart';

/// Runtime flags via `--dart-define` (see README).
///
/// Live VPS (default):
///   flutter run -d android
///
/// Local PHP API (`pro_enroll_api`):
///   flutter run --dart-define=USE_LOCAL_API=true
class AppConfig {
  AppConfig._();

  /// Shared PHP API — same as `pro_enroll_v1/Pro-Enroll-APP/apps/pro_enroll_app`.
  /// Local project: `D:\krishna\pro_enroll_api` | DB: `pro_enroll` on MySQL.
  static const String localApiProjectPath = r'D:\krishna\pro_enroll_api';

  static const String liveApiBaseUrl = 'http://98.93.105.128/pro_enroll_api';
  static const String localApiBaseUrl = 'http://localhost:8080';
  static const String localApiBaseUrlAndroidEmulator = 'http://10.0.2.2:8080';

  static const bool useLocalApi =
      bool.fromEnvironment('USE_LOCAL_API', defaultValue: false);

  static const bool useApi =
      bool.fromEnvironment('USE_API', defaultValue: true);

  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv.replaceAll(RegExp(r'/+$'), '');
    }
    if (useLocalApi) {
      return _localApiBaseForPlatform();
    }
    return liveApiBaseUrl;
  }

  static String get apiV1Root =>
      '${apiBaseUrl.replaceAll(RegExp(r'/+$'), '')}/v1';

  static String _localApiBaseForPlatform() {
    if (kIsWeb) return localApiBaseUrl;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return localApiBaseUrlAndroidEmulator;
      default:
        return localApiBaseUrl;
    }
  }

  static bool get hasApi => useApi && apiBaseUrl.isNotEmpty;
}
