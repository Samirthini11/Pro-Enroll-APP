import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/app_config.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../routing/router.dart';

const _androidChannelId = 'proconnect_alerts';

typedef PushNavigateCallback = void Function(String route, {Object? extra});

/// Shows FCM alerts when the app is in foreground and registers tokens with the API.
class PushNotificationService {
  PushNotificationService(this._repo);

  static PushNavigateCallback? onNavigate;

  final ProRepository _repo;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Future<void>? _initFuture;

  Future<void> init() {
    _initFuture ??= _initOnce();
    return _initFuture!;
  }

  Future<void> _initOnce() async {
    if (_initialized || kIsWeb || !AppConfig.usesFirebase) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      settings: const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

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
      await androidPlugin?.requestNotificationsPermission();
    }

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
    _messaging.onTokenRefresh.listen((token) => _registerToken(token));

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleOpenedMessage(initial);
    }

    _initialized = true;
  }

  /// Register FCM token with the API for every saved session role on this device.
  Future<void> syncTokenWithServer({AppRole? role}) async {
    if (kIsWeb || !AppConfig.hasApi) return;

    await init();

    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(token, role: role);
      }
    } catch (e) {
      debugPrint('FCM token sync failed: $e');
    }
  }

  Future<void> _registerToken(String token, {AppRole? role}) async {
    try {
      await _repo.registerPushToken(
        fcmToken: token,
        platform: Platform.isAndroid ? 'android' : 'ios',
        role: role,
      );
      debugPrint(
        '[FCM] token synced (${token.substring(0, 12)}…) '
        'scope=${role?.name ?? 'all_roles'}',
      );
    } catch (e) {
      debugPrint('[FCM] registerPushToken failed: $e');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];
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

    final payload = _encodePayload(message.data);
    await _local.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    _navigateFromPayload(_decodePayload(payload));
  }

  void _handleOpenedMessage(RemoteMessage message) {
    _navigateFromPayload(message.data);
  }

  void _navigateFromPayload(Map<String, dynamic> data) {
    final navigate = onNavigate;
    if (navigate == null) return;

    final route = data['route'] as String? ?? '';
    final bookingIdRaw = data['booking_id'] as String?;
    final bookingId = int.tryParse(bookingIdRaw ?? '');

    switch (route) {
      case '/job/offer':
        if (bookingIdRaw != null) {
          navigate(Routes.offer, extra: bookingIdRaw);
        }
        break;
      case '/job/active':
        navigate(Routes.activeJob);
        break;
      case '/customer/booking':
        if (bookingId != null) {
          navigate(Routes.customerBookingDetail, extra: bookingId);
        } else {
          navigate(Routes.customerBookings);
        }
        break;
      case '/customer/bookings':
        navigate(Routes.customerBookings);
        break;
      default:
        if (kDebugMode) {
          debugPrint('[FCM] unhandled route: $route data=$data');
        }
    }
  }

  String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  Map<String, dynamic> _decodePayload(String payload) {
    final out = <String, dynamic>{};
    for (final part in payload.split('&')) {
      final idx = part.indexOf('=');
      if (idx <= 0) continue;
      out[part.substring(0, idx)] = part.substring(idx + 1);
    }
    return out;
  }
}
