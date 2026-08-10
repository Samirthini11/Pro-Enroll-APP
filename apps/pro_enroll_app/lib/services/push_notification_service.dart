import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_config.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../routing/router.dart';

const _androidChannelId = 'proconnect_alerts';
const _pendingPrefsKey = 'fcm_pending_nav_v1';

typedef PushNavigateCallback = Future<bool> Function(
  String route, {
  Object? extra,
  AppRole? requiredRole,
});

/// FCM + local notification routing.
///
/// Pending taps are persisted until the user is authenticated, then flushed to
/// the correct screen by [type] / [status] / [route].
class PushNotificationService {
  PushNotificationService(this._repo);

  static PushNavigateCallback? onNavigate;
  static bool Function()? isAuthenticated;
  static AppRole Function()? currentRole;

  static Map<String, dynamic>? _pending;
  static int? pendingHomeTab;

  /// True when a notification tap is waiting to be routed.
  static bool get hasPending => _pending != null && _pending!.isNotEmpty;

  /// Role required by the queued notification (if any). Used on cold start so
  /// session restore picks the correct JWT (customer vs professional).
  static AppRole? get pendingRequiredRole {
    final data = _pending;
    if (data == null || data.isEmpty) return null;
    return _roleFromPayload(data);
  }

  /// Call from [main] before [runApp] so cold-start taps are not lost.
  static Future<void> captureColdStartMessage() async {
    if (kIsWeb || !AppConfig.usesFirebase) return;
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial == null) return;
      await seedPendingFromRemoteMessage(initial);
      if (kDebugMode) {
        debugPrint('[FCM] main() cold-start pending: $_pending');
      }
    } catch (e) {
      debugPrint('[FCM] early getInitialMessage failed: $e');
    }
  }

  static Future<void> seedPendingFromRemoteMessage(RemoteMessage message) async {
    final data = <String, dynamic>{};
    message.data.forEach((key, value) {
      data[key.toString()] = value?.toString() ?? '';
    });
    if (!data.containsKey('title') && message.notification?.title != null) {
      data['title'] = message.notification!.title;
    }
    if (!data.containsKey('body') && message.notification?.body != null) {
      data['body'] = message.notification!.body;
    }
    await seedPending(data);
  }

  static Future<void> seedPending(Map<String, dynamic> data) async {
    if (data.isEmpty) return;
    _pending = data;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingPrefsKey, _encodePayloadStatic(data));
    } catch (e) {
      debugPrint('[FCM] persist pending failed: $e');
    }
  }

  static String _encodePayloadStatic(Map<String, dynamic> data) {
    return data.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key.toString())}=${Uri.encodeComponent(e.value.toString())}',
        )
        .join('&');
  }

  static AppRole? _roleFromPayload(Map<String, dynamic> data) {
    final audience = (data['audience'] ?? '').toString().trim().toLowerCase();
    if (audience == 'customer') return AppRole.customer;
    if (audience == 'professional') return AppRole.professional;

    final type = (data['type'] ?? '').toString().trim();
    switch (type) {
      case 'job_offer':
      case 'booking_cancelled':
      case 'visit_fee_paid':
      case 'kyc_approved':
      case 'kyc_rejected':
      case 'kyc_pending':
        return AppRole.professional;
      case 'booking_confirmed':
      case 'booking_accepted':
      case 'booking_completed':
      case 'booking_rejected':
      case 'booking_status':
        return AppRole.customer;
    }

    final route = (data['route'] ?? '').toString().trim();
    // Prefer explicit job/kyc paths before the generic "booking" heuristic
    // (pro payloads also carry booking_id / may mention booking in text).
    if (route.contains('job') ||
        route.contains('offer') ||
        route.contains('kyc') ||
        route.contains('/home')) {
      return AppRole.professional;
    }
    if (route.contains('customer')) {
      return AppRole.customer;
    }
    return null;
  }

  final ProRepository _repo;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Future<void>? _initFuture;
  bool _readyToNavigate = false;
  bool _flushing = false;
  /// When true, skip notification-permission prompts during init (cold start
  /// from a tap already has permission; prompting can disrupt routing).
  bool _deferPermissionPrompt = false;
  bool _permissionEnsured = false;

  Future<void> init({bool deferPermissionPrompt = false}) {
    if (deferPermissionPrompt) {
      _deferPermissionPrompt = true;
    }
    _initFuture ??= _initOnce();
    return _initFuture!;
  }

  /// After splash/session restore: allow permission prompts again and register
  /// the FCM token. Cold-start deferral must not stick forever or pushes die.
  Future<void> finishColdStartAndSyncToken({AppRole? role}) async {
    _deferPermissionPrompt = false;
    _readyToNavigate = true;
    await syncTokenWithServer(role: role);
  }

  /// Clear queued deep-link after logout so the next session starts clean.
  /// Notification taps while logged out will set a new pending destination.
  Future<void> clearPendingForLogout() async {
    pendingHomeTab = null;
    _readyToNavigate = false;
    _flushing = false;
    _deferPermissionPrompt = false;
    await _clearPending();
  }

  /// Mark splash finished. Only navigates if [authenticated] is true.
  Future<bool> markReadyAndFlush({bool? authenticated}) async {
    _readyToNavigate = true;
    await _restorePendingFromDisk();
    final authed = authenticated ?? isAuthenticated?.call() ?? false;
    if (!authed) {
      if (kDebugMode && hasPending) {
        debugPrint('[FCM] ready but not authed — keeping pending: $_pending');
      }
      return false;
    }
    return flushPendingNavigation();
  }

  Future<bool> flushPendingNavigation() async {
    await _restorePendingFromDisk();
    final data = _pending;
    if (data == null || data.isEmpty) return false;

    final authed = isAuthenticated?.call() ?? false;
    if (!_readyToNavigate || onNavigate == null || !authed) {
      if (kDebugMode) {
        debugPrint(
          '[FCM] flush skipped (ready=$_readyToNavigate authed=$authed pending=$data)',
        );
      }
      return false;
    }

    if (_flushing) return false;
    _flushing = true;
    try {
      // Retry a few times — router / role switch may need a moment after splash.
      for (var attempt = 0; attempt < 4; attempt++) {
        if (attempt > 0) {
          await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        if (isAuthenticated?.call() != true || onNavigate == null) {
          return false;
        }
        final navigated = await _navigateFromPayload(Map<String, dynamic>.from(data));
        if (navigated) {
          await _clearPending();
          return true;
        }
      }
      // Don't leave an unroutable payload forever — it blocked older builds from
      // requesting notification permission / registering FCM tokens.
      if (kDebugMode) {
        debugPrint('[FCM] flush failed after retries — clearing stale pending');
      }
      await _clearPending();
      return false;
    } finally {
      _flushing = false;
    }
  }

  Future<void> _initOnce() async {
    if (_initialized || kIsWeb || !AppConfig.usesFirebase) {
      _initialized = true;
      return;
    }

    await _restorePendingFromDisk();

    // CRITICAL: capture cold-start payload BEFORE permission / channel setup.
    try {
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        final data = _messageData(initial);
        if (data.isNotEmpty) {
          await _setPending(data);
          if (kDebugMode) {
            debugPrint('[FCM] cold-start pending: $_pending');
          }
        }
      }
    } catch (e) {
      debugPrint('[FCM] getInitialMessage failed: $e');
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      settings: const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    try {
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        final payload = launch!.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          await _setPending(_decodePayload(payload));
          if (kDebugMode) {
            debugPrint('[FCM] local-launch pending: $_pending');
          }
        }
      }
    } catch (e) {
      debugPrint('[FCM] getNotificationAppLaunchDetails failed: $e');
    }

    if (Platform.isAndroid) {
      final androidPlugin = _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      const channel = AndroidNotificationChannel(
        _androidChannelId,
        'ProConnect alerts',
        description: 'Job offers, booking updates, and service alerts',
        importance: Importance.high,
      );
      await androidPlugin?.createNotificationChannel(channel);
      if (!_deferPermissionPrompt) {
        await androidPlugin?.requestNotificationsPermission();
      }
    }

    if (!_deferPermissionPrompt) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      unawaited(_queueOrNavigate(_messageData(msg)));
    });
    _messaging.onTokenRefresh.listen((token) => _registerToken(token));

    _initialized = true;
  }

  Map<String, dynamic> _messageData(RemoteMessage message) {
    final data = <String, dynamic>{};
    message.data.forEach((key, value) {
      data[key.toString()] = value?.toString() ?? '';
    });
    if (!data.containsKey('title') && message.notification?.title != null) {
      data['title'] = message.notification!.title;
    }
    if (!data.containsKey('body') && message.notification?.body != null) {
      data['body'] = message.notification!.body;
    }
    return data;
  }

  Future<void> syncTokenWithServer({AppRole? role}) async {
    if (kIsWeb || !AppConfig.hasApi) return;
    if (isAuthenticated?.call() != true) return;
    // Keep init listeners registered, but never re-enter permanent defer here.
    await init();
    try {
      await _ensureNotificationPermission();
      if (!_permissionEnsured) return;

      var token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        await Future<void>.delayed(const Duration(seconds: 2));
        token = await _messaging.getToken();
      }
      if (token != null && token.isNotEmpty) {
        await _registerToken(token, role: role);
        if (kDebugMode) {
          debugPrint(
            '[FCM] token registered role=${role ?? currentRole?.call()} '
            'len=${token.length}',
          );
        }
      } else {
        debugPrint('[FCM] getToken returned empty — notifications may not work');
      }
    } catch (e) {
      debugPrint('FCM token sync failed: $e');
    }
  }

  Future<void> _ensureNotificationPermission() async {
    if (_permissionEnsured) return;
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _local
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      }
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] notification permission denied');
        return;
      }
      _permissionEnsured = true;
      _deferPermissionPrompt = false;
    } catch (e) {
      debugPrint('[FCM] permission request failed: $e');
    }
  }

  Future<void> _registerToken(String token, {AppRole? role}) async {
    try {
      await _repo.registerPushToken(
        fcmToken: token,
        platform: Platform.isAndroid ? 'android' : 'ios',
        role: role,
      );
    } catch (e) {
      debugPrint('[FCM] registerPushToken failed: $e');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final data = _messageData(message);
    if (!_isForCurrentRole(data)) {
      if (kDebugMode) {
        debugPrint('[FCM] skip foreground (wrong role): ${data['type']} audience=${data['audience']}');
      }
      return;
    }
    final title = data['title'] ?? message.notification?.title;
    final body = data['body'] ?? message.notification?.body;
    if (title == null && body == null) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        'ProConnect alerts',
        channelDescription: 'Job offers, booking updates, and service alerts',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _local.show(
      id: message.hashCode & 0x7fffffff,
      title: title?.toString(),
      body: body?.toString(),
      notificationDetails: details,
      payload: _encodePayload(data),
    );
  }

  /// Push is for the other party only — ignore alerts meant for the other role.
  bool _isForCurrentRole(Map<String, dynamic> data) {
    final role = currentRole?.call();
    if (role == null) return true;

    final audience = (data['audience'] ?? '').toString().trim().toLowerCase();
    if (audience == 'customer') return role == AppRole.customer;
    if (audience == 'professional') return role == AppRole.professional;

    final dest = _resolveDestination(data);
    if (dest?.requiredRole == null) return true;
    return dest!.requiredRole == role;
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    unawaited(_queueOrNavigate(_decodePayload(payload)));
  }

  Future<void> _queueOrNavigate(Map<String, dynamic> data) async {
    if (data.isEmpty) return;
    await _setPending(data);
    final authed = isAuthenticated?.call() ?? false;
    if (!_readyToNavigate || onNavigate == null || !authed) {
      // Keep pending for after login. Mark ready so post-login flush can run.
      _readyToNavigate = true;
      if (kDebugMode) {
        debugPrint(
          '[FCM] queued for after login (authed=$authed): $data',
        );
      }
      return;
    }
    await flushPendingNavigation();
  }

  Future<bool> _navigateFromPayload(Map<String, dynamic> data) async {
    final navigate = onNavigate;
    if (navigate == null) return false;
    if (isAuthenticated?.call() != true) return false;

    final resolved = _resolveDestination(data);
    if (resolved == null) {
      if (kDebugMode) debugPrint('[FCM] unhandled payload: $data');
      // Drop unhandled so we don't loop forever.
      return true;
    }

    if (kDebugMode) {
      debugPrint(
        '[FCM] navigate → ${resolved.route} extra=${resolved.extra} '
        'role=${resolved.requiredRole} tab=${resolved.homeTab}',
      );
    }

    if (resolved.homeTab != null) {
      pendingHomeTab = resolved.homeTab;
    }

    try {
      return await navigate(
        resolved.route,
        extra: resolved.extra,
        requiredRole: resolved.requiredRole,
      );
    } catch (e) {
      debugPrint('[FCM] navigate failed: $e');
      return false;
    }
  }

  Future<void> _setPending(Map<String, dynamic> data) async {
    await seedPending(data);
  }

  Future<void> _clearPending() async {
    _pending = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingPrefsKey);
    } catch (_) {}
  }

  Future<void> _restorePendingFromDisk() async {
    if (hasPending) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingPrefsKey);
      if (raw != null && raw.isNotEmpty) {
        _pending = _decodePayload(raw);
        if (kDebugMode) {
          debugPrint('[FCM] restored pending from disk: $_pending');
        }
      }
    } catch (e) {
      debugPrint('[FCM] restore pending failed: $e');
    }
  }

  _PushDest? _resolveDestination(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString().trim();
    final status = (data['status'] ?? '').toString().trim();
    var route = (data['route'] ?? '').toString().trim();
    final bookingIdRaw =
        (data['booking_id'] ?? data['offer_id'] ?? '').toString().trim();
    final bookingId = int.tryParse(bookingIdRaw);

    if (route.isEmpty) {
      route = _routeFromTypeAndStatus(type, status);
    }

    route = switch (route) {
      '/job/offer' => Routes.offer,
      '/job/active' => Routes.activeJob,
      '/customer/booking' => Routes.customerBookingDetail,
      '/customer/bookings' => Routes.customerBookings,
      '/customer/home' => Routes.customerHome,
      '/kyc/pending' => Routes.kycPending,
      '/home' => Routes.home,
      _ => route,
    };

    if (type == 'booking_status' || route == Routes.customerBookingDetail) {
      if (status == 'cancelled') {
        return const _PushDest(
          Routes.customerBookings,
          requiredRole: AppRole.customer,
        );
      }
      if (bookingId != null && bookingId > 0) {
        return _PushDest(
          Routes.customerBookingDetail,
          extra: bookingId,
          requiredRole: AppRole.customer,
        );
      }
    }

    switch (route) {
      case Routes.offer:
        if (bookingIdRaw.isEmpty) return null;
        return _PushDest(
          Routes.offer,
          extra: bookingIdRaw,
          requiredRole: AppRole.professional,
        );

      case Routes.activeJob:
        return const _PushDest(
          Routes.activeJob,
          requiredRole: AppRole.professional,
        );

      case Routes.customerBookingDetail:
        if (bookingId != null && bookingId > 0) {
          return _PushDest(
            Routes.customerBookingDetail,
            extra: bookingId,
            requiredRole: AppRole.customer,
          );
        }
        return const _PushDest(
          Routes.customerBookings,
          requiredRole: AppRole.customer,
        );

      case Routes.customerBookings:
        return const _PushDest(
          Routes.customerBookings,
          requiredRole: AppRole.customer,
        );

      case Routes.customerHome:
        return const _PushDest(
          Routes.customerHome,
          requiredRole: AppRole.customer,
        );

      case Routes.kycPending:
        return const _PushDest(
          Routes.kycPending,
          requiredRole: AppRole.professional,
        );

      case Routes.home:
        final tab = switch (type) {
          'visit_fee_paid' => 1,
          _ => int.tryParse((data['tab'] ?? '').toString()),
        };
        return _PushDest(
          Routes.home,
          homeTab: tab,
          requiredRole: AppRole.professional,
        );

      default:
        return _fallbackFromType(type, status, bookingIdRaw, bookingId);
    }
  }

  String _routeFromTypeAndStatus(String type, String status) {
    switch (type) {
      case 'job_offer':
        return Routes.offer;
      case 'booking_cancelled':
      case 'visit_fee_paid':
        return Routes.home;
      case 'booking_confirmed':
      case 'booking_accepted':
      case 'booking_completed':
        return Routes.customerBookingDetail;
      case 'booking_rejected':
        return Routes.customerBookings;
      case 'booking_status':
        if (status == 'cancelled') return Routes.customerBookings;
        return Routes.customerBookingDetail;
      case 'kyc_approved':
      case 'kyc_rejected':
      case 'kyc_pending':
        return Routes.kycPending;
      default:
        return '';
    }
  }

  _PushDest? _fallbackFromType(
    String type,
    String status,
    String bookingIdRaw,
    int? bookingId,
  ) {
    switch (type) {
      case 'job_offer':
        if (bookingIdRaw.isEmpty) return null;
        return _PushDest(
          Routes.offer,
          extra: bookingIdRaw,
          requiredRole: AppRole.professional,
        );
      case 'visit_fee_paid':
        return const _PushDest(
          Routes.home,
          homeTab: 1,
          requiredRole: AppRole.professional,
        );
      case 'booking_cancelled':
        return const _PushDest(
          Routes.home,
          requiredRole: AppRole.professional,
        );
      case 'booking_accepted':
      case 'booking_confirmed':
      case 'booking_completed':
      case 'booking_status':
        if (bookingId != null && bookingId > 0) {
          return _PushDest(
            Routes.customerBookingDetail,
            extra: bookingId,
            requiredRole: AppRole.customer,
          );
        }
        return const _PushDest(
          Routes.customerBookings,
          requiredRole: AppRole.customer,
        );
      case 'booking_rejected':
        return const _PushDest(
          Routes.customerBookings,
          requiredRole: AppRole.customer,
        );
      case 'kyc_approved':
      case 'kyc_pending':
        return const _PushDest(
          Routes.kycPending,
          requiredRole: AppRole.professional,
        );
      default:
        return null;
    }
  }

  String _encodePayload(Map<String, dynamic> data) =>
      _encodePayloadStatic(data);

  Map<String, dynamic> _decodePayload(String payload) {
    final out = <String, dynamic>{};
    for (final part in payload.split('&')) {
      if (part.isEmpty) continue;
      final idx = part.indexOf('=');
      if (idx <= 0) continue;
      out[Uri.decodeComponent(part.substring(0, idx))] =
          Uri.decodeComponent(part.substring(idx + 1));
    }
    return out;
  }
}

class _PushDest {
  const _PushDest(
    this.route, {
    this.extra,
    this.homeTab,
    this.requiredRole,
  });

  final String route;
  final Object? extra;
  final int? homeTab;
  final AppRole? requiredRole;
}
