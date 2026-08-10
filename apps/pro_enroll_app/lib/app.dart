import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'data/models.dart';
import 'routing/router.dart';
import 'services/push_notification_service.dart';
import 'state/app_state.dart';
import 'state/locale_state.dart';

class ProEnrollApp extends ConsumerStatefulWidget {
  const ProEnrollApp({super.key});

  @override
  ConsumerState<ProEnrollApp> createState() => _ProEnrollAppState();
}

class _ProEnrollAppState extends ConsumerState<ProEnrollApp> {
  @override
  void initState() {
    super.initState();

    PushNotificationService.isAuthenticated = () {
      return ref.read(authProvider).isAuthenticated;
    };

    PushNotificationService.currentRole = () {
      return ref.read(roleProvider);
    };

    PushNotificationService.onNavigate = (route, {extra, requiredRole}) async {
      if (!mounted) return false;
      if (!ref.read(authProvider).isAuthenticated) return false;

      try {
        if (requiredRole != null && ref.read(roleProvider) != requiredRole) {
          final ok =
              await ref.read(authProvider.notifier).switchRole(requiredRole);
          if (!ok || !mounted) {
            debugPrint('[FCM] role switch to $requiredRole failed');
            return false;
          }
          // Re-register FCM under the role that should receive / open this alert.
          unawaited(
            ref.read(pushNotificationServiceProvider).syncTokenWithServer(
                  role: requiredRole,
                ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 450));
          if (!mounted) return false;
          if (ref.read(roleProvider) != requiredRole) {
            debugPrint('[FCM] role still mismatched after switch');
            return false;
          }
        }

        final router = ref.read(routerProvider);
        final shell = switch (requiredRole) {
          AppRole.customer => Routes.customerHome,
          AppRole.professional => Routes.home,
          _ => null,
        };

        String current = '';
        try {
          current = router.routerDelegate.currentConfiguration.uri.path;
        } catch (_) {}

        final onAuthish = current == Routes.splash ||
            current == Routes.authLanding ||
            current == Routes.phone ||
            current == Routes.otp ||
            current == Routes.termsAcceptance ||
            current.isEmpty;

        // Always land on the correct shell first (fixes logout → login → deep link).
        if (shell != null && (onAuthish || current != shell && current != route)) {
          router.go(shell);
          await Future<void>.delayed(const Duration(milliseconds: 400));
          if (!mounted || !ref.read(authProvider).isAuthenticated) return false;
        }

        // Detail screens: push on top of shell so Back returns home (not logout/exit).
        const pushRoutes = {
          Routes.customerBookingDetail,
          Routes.offer,
          Routes.activeJob,
          Routes.customerBookings,
        };

        if (pushRoutes.contains(route)) {
          router.push(route, extra: extra);
        } else if (route != shell) {
          router.go(route, extra: extra);
        }

        debugPrint('[FCM] routed to $route extra=$extra role=$requiredRole');
        return true;
      } catch (e, st) {
        debugPrint('[FCM] onNavigate error: $e\n$st');
        try {
          if (!ref.read(authProvider).isAuthenticated) return false;
          ref.read(routerProvider).go(route, extra: extra);
          return true;
        } catch (_) {
          return false;
        }
      }
    };

    Future.microtask(() async {
      // Capture cold-start notification ASAP. Defer permission only when a
      // notification tap launched the app — otherwise request permission early
      // so FCM token registration is not blocked for the whole session.
      final hasColdStartTap = PushNotificationService.hasPending;
      await ref.read(pushNotificationServiceProvider).init(
            deferPermissionPrompt: hasColdStartTap,
          );
      final preferred = PushNotificationService.pendingRequiredRole;
      if (preferred != null) {
        final tokens = ref.read(jwtTokenServiceProvider);
        if (await tokens.hasTokenForRole(preferred)) {
          await tokens.setActiveRole(preferred);
        }
      }
      await ref.read(authProvider.notifier).bootstrapSessionFromDisk(
            preferredRole: preferred,
          );
    });
  }

  @override
  void dispose() {
    PushNotificationService.onNavigate = null;
    PushNotificationService.isAuthenticated = null;
    PushNotificationService.currentRole = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      final wasAuthed = prev?.isAuthenticated ?? false;
      final isAuthed = next.isAuthenticated;

      // Only flush after login/OTP — splash owns cold-start notification routing
      // via navigateRespectingPush (avoids go(default) clobbering the deep link).
      if (isAuthed && !wasAuthed && PushNotificationService.hasPending) {
        final path = ref.read(routerProvider).routerDelegate.currentConfiguration
            .uri.path;
        // Splash owns cold-start flush via navigateRespectingPush.
        if (path == Routes.splash || path.isEmpty) return;

        Future.microtask(() async {
          await ref.read(pushNotificationServiceProvider).init(
                deferPermissionPrompt: true,
              );
          await ref
              .read(pushNotificationServiceProvider)
              .markReadyAndFlush(authenticated: true);
        });
      }
    });

    return MaterialApp.router(
      title: 'ProConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.light(),
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ta'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
