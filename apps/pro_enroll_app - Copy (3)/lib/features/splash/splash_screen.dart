import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_config.dart';
import '../../core/i18n.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../routing/router.dart';
import '../../services/legal_acceptance_service.dart';
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

    final accepted =
        await LegalAcceptanceService().hasAcceptedCurrentTerms();
    if (!accepted) {
      if (mounted) context.go(Routes.termsAcceptance);
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await _navigateNext();
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;

    try {
      if (AppConfig.hasApi) {
        ref.read(categoriesProvider);
        final restored =
            await ref.read(authProvider.notifier).tryRestoreSession();
        if (!mounted) return;
        if (restored) {
          final route =
              ref.read(authProvider.notifier).routeAfterSessionRestore();
          context.go(route);
          return;
        }
      }

      if (mounted) {
        context.go(Routes.authLanding);
      }
    } catch (e) {
      debugPrint('Splash navigation error: $e');
      if (mounted) {
        context.go(Routes.authLanding);
      }
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
