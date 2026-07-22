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
          await Future<void>.delayed(const Duration(milliseconds: 350));
          if (!mounted) return false;
        }

        final router = ref.read(routerProvider);
        final shell = switch (requiredRole) {
          AppRole.customer => Routes.customerHome,
          AppRole.professional => Routes.home,
          _ => null,
        };

        // Leave splash/auth onto the correct shell, then open the deep link.
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

        if (shell != null && (onAuthish || current != route)) {
          if (onAuthish || (shell != route && current != shell)) {
            router.go(shell);
            await Future<void>.delayed(const Duration(milliseconds: 350));
            if (!mounted) return false;
          }
        }

        // Always go to destination (extra rebuilds booking/offer screens).
        router.go(route, extra: extra);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        // Second go covers cases where first go was ignored while shell mounted.
        router.go(route, extra: extra);
        debugPrint('[FCM] routed to $route extra=$extra');
        return true;
      } catch (e, st) {
        debugPrint('[FCM] onNavigate error: $e\n$st');
        try {
          ref.read(routerProvider).go(route, extra: extra);
          return true;
        } catch (_) {
          return false;
        }
      }
    };

    Future.microtask(() async {
      // Capture cold-start notification ASAP.
      await ref.read(pushNotificationServiceProvider).init();
      if (await ref.read(jwtTokenServiceProvider).hasTokenAsync()) {
        await ref.read(pushNotificationServiceProvider).syncTokenWithServer();
      }
    });
  }

  @override
  void dispose() {
    PushNotificationService.onNavigate = null;
    PushNotificationService.isAuthenticated = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated &&
          !(prev?.isAuthenticated ?? false) &&
          PushNotificationService.hasPending) {
        Future.microtask(() async {
          await ref.read(pushNotificationServiceProvider).init();
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
