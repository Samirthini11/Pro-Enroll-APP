import 'package:flutter/foundation.dart';



/// Runtime flags via `--dart-define` (see README).

///

/// Live VPS (default for debug + release):

///   flutter run -d android

///   flutter build apk --release

/// Local PHP API:

///   flutter run --dart-define=USE_LOCAL_API=true

class AppConfig {

  AppConfig._();



  /// Local PHP API project: `D:\krishna\pro_enroll_api`

  /// Run: `php -S localhost:8080 -t public`

  static const String localApiProjectPath = r'D:\krishna\pro_enroll_api';



  /// Production VPS — routes resolve to `…/pro_enroll_api/v1/*`.

  static const String liveApiBaseUrl =

      'http://98.93.105.128/pro_enroll_api';



  /// Local XAMPP / `php -S localhost:8080 -t public`

  static const String localApiBaseUrl = 'http://localhost:8080';



  /// Android emulator → host machine localhost.

  static const String localApiBaseUrlAndroidEmulator = 'http://10.0.2.2:8080';



  /// Force local API. `--dart-define=USE_LOCAL_API=true`

  static const bool useLocalApi =

      bool.fromEnvironment('USE_LOCAL_API', defaultValue: false);



  /// Optional Google Static Maps key for map previews. When empty, OpenStreetMap

  /// tiles are used instead (no billing account required).

  static const String googleMapsApiKey =

      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');



  /// PHP API base URL (without `/v1`; paths in [ApiClient] add `/v1/...`).

  /// Precedence: `API_BASE_URL` → `USE_LOCAL_API` → live VPS (default).

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



  /// Full v1 root, e.g. `http://98.93.105.128/pro_enroll_api/v1`.

  static String get apiV1Root => '${apiBaseUrl.replaceAll(RegExp(r'/+$'), '')}/v1';



  static String _localApiBaseForPlatform() {

    if (kIsWeb) {

      return localApiBaseUrl;

    }

    switch (defaultTargetPlatform) {

      case TargetPlatform.android:

        return localApiBaseUrlAndroidEmulator;

      default:

        return localApiBaseUrl;

    }

  }



  /// Use the PHP API for OTP, JWT auth, and all screen endpoints.

  static const bool useApi = bool.fromEnvironment('USE_API', defaultValue: true);



  /// Send OTP via Firebase Phone Auth (real SMS). Enable with:

  /// `--dart-define=USE_FIREBASE_SMS_OTP=true`

  static const bool useFirebaseSmsOtp =

      bool.fromEnvironment('USE_FIREBASE_SMS_OTP', defaultValue: false);



  static bool get hasApi => useApi && apiBaseUrl.isNotEmpty;



  static bool get usesFirebaseSmsOtp => useFirebaseSmsOtp && hasApi;

  /// Firebase Core (FCM push + optional Phone Auth SMS).
  static bool get usesFirebase => !kIsWeb && hasApi;



  static bool get isLiveApi {

    final base = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');

    final live = liveApiBaseUrl.replaceAll(RegExp(r'/+$'), '');

    return base == live;

  }

}


