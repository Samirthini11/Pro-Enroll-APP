import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_config.dart';
import '../../core/i18n.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/app_repository.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../services/kyc_preview_service.dart';
import '../../services/legal_acceptance_service.dart';
import '../../services/push_notification_service.dart';
import '../../state/categories_provider.dart';
import '../../state/app_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_boot);
  }

  Future<void> _boot() async {
    if (!mounted) return;

    // Capture notification tap ASAP; defer permission UI so it can't break
    // cold-start routing on the first notification.
    if (AppConfig.hasApi) {
      await ref.read(pushNotificationServiceProvider).init(
            deferPermissionPrompt: true,
          );
      final preferred = PushNotificationService.pendingRequiredRole;
      // Optimistic JWT restore so GoRouter never treats boot as logged-out.
      await ref.read(authProvider.notifier).bootstrapSessionFromDisk(
            preferredRole: preferred,
          );
    }

    final accepted =
        await LegalAcceptanceService().hasAcceptedCurrentTerms();
    if (!accepted) {
      if (mounted) context.go(Routes.termsAcceptance);
      return;
    }

    // Restore KYC preview unlock (continue-before-approval).
    final preview = await KycPreviewService.isUnlocked();
    if (mounted) {
      ref.read(kycPreviewUnlockedProvider.notifier).state = preview;
    }

    // Warm API while splash shows — reduces first OTP / login timeout.
    if (AppConfig.hasApi) {
      final repo = ref.read(repositoryProvider);
      if (repo is AppRepository) {
        unawaited(repo.warmUp());
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 700));
    await _navigateNext();
  }

  Future<void> _openAfterRestore() async {
    if (!mounted) return;
    final route = ref.read(authProvider.notifier).routeAfterSessionRestore();
    final router = GoRouter.of(context);
    await ref.read(authProvider.notifier).navigateRespectingPush(
          router,
          route,
        );
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;

    try {
      if (AppConfig.hasApi) {
        ref.read(categoriesProvider);
        await ref.read(pushNotificationServiceProvider).init(
              deferPermissionPrompt: PushNotificationService.hasPending,
            );
        final preferredRole = PushNotificationService.pendingRequiredRole;
        var restored = await ref
            .read(authProvider.notifier)
            .tryRestoreSession(preferredRole: preferredRole);

        // Last resort: JWT still on disk after a soft failure — keep session.
        if (!restored) {
          final tokens = ref.read(jwtTokenServiceProvider);
          for (final role in [
            ?preferredRole,
            ...AppRole.values,
          ]) {
            if (await tokens.hasTokenForRole(role)) {
              restored = await ref
                  .read(authProvider.notifier)
                  .tryRestoreSession(preferredRole: role);
              if (restored) break;
            }
          }
        }

        // Notification cold start: never drop to login while a JWT exists.
        if (!restored && PushNotificationService.hasPending) {
          restored = await ref
              .read(authProvider.notifier)
              .bootstrapSessionFromDisk(preferredRole: preferredRole);
        }

        if (!mounted) return;
        if (restored) {
          await _openAfterRestore();
          return;
        }
      }

      if (!mounted) return;
      // Only go to login when there is truly no session token.
      final tokens = ref.read(jwtTokenServiceProvider);
      final hasJwt = await tokens.hasTokenAsync() ||
          await tokens.hasTokenForRole(AppRole.professional) ||
          await tokens.hasTokenForRole(AppRole.customer);
      if (hasJwt) {
        final restored = await ref
            .read(authProvider.notifier)
            .bootstrapSessionFromDisk(
              preferredRole: PushNotificationService.pendingRequiredRole,
            );
        if (restored && mounted) {
          await _openAfterRestore();
          return;
        }
      }

      await ref.read(pushNotificationServiceProvider).init();
      if (ref.read(authProvider).isAuthenticated) {
        await _openAfterRestore();
        return;
      }
      // Keep pending deep-link; do not clear it when sending to login.
      context.go(Routes.authLanding);
      await ref
          .read(pushNotificationServiceProvider)
          .markReadyAndFlush(authenticated: false);
    } catch (e) {
      debugPrint('Splash navigation error: $e');
      if (!mounted) return;
      final tokens = ref.read(jwtTokenServiceProvider);
      final hasJwt = await tokens.hasTokenAsync() ||
          await tokens.hasTokenForRole(AppRole.professional) ||
          await tokens.hasTokenForRole(AppRole.customer);
      if (hasJwt || ref.read(authProvider).isAuthenticated) {
        final restored = await ref
            .read(authProvider.notifier)
            .bootstrapSessionFromDisk(
              preferredRole: PushNotificationService.pendingRequiredRole,
            );
        if (restored && mounted) {
          await _openAfterRestore();
          return;
        }
      }
      if (!mounted) return;
      await ref.read(pushNotificationServiceProvider).init();
      if (ref.read(authProvider).isAuthenticated) {
        await _openAfterRestore();
        return;
      }
      context.go(Routes.authLanding);
      await ref
          .read(pushNotificationServiceProvider)
          .markReadyAndFlush(authenticated: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final iconSize = context.responsive<double>(xs: 76, sm: 88, md: 96);
    final iconBox = context.responsive<double>(xs: 24, sm: 26, md: 28);

    return Scaffold(
      backgroundColor: AppTheme.brandPrimary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: context.pageHPadding + 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(iconBox),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/branding/app_icon_1024.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'QuickFix',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.responsive<double>(xs: 26, sm: 30, md: 32),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l.t('splash.tagline'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 36),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
