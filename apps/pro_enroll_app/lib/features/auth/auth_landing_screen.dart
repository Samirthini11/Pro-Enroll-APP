import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../routing/router.dart';
import '../../state/locale_state.dart';
import 'auth_flow.dart';

/// First screen the user lands on after the splash. Shows the brand,
/// the value props in a compact list, and the two primary actions:
///
///   • **Sign in** — for pros already enrolled (skips onboarding).
///   • **Create account** — for new pros (runs the enrollment flow).
class AuthLandingScreen extends ConsumerWidget {
  const AuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = context.isCompactHeight;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: ContentMaxWidth(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: context.pageHPadding, vertical: 12),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: compact ? 8 : 16),
                        _BrandHero(compact: compact),
                        SizedBox(height: compact ? 18 : 24),
                        _ValueBullet(
                          icon: Icons.verified_user,
                          title: 'Aadhaar + selfie verified',
                          body:
                              'Pros earn the trust badge customers look for.',
                        ),
                        _ValueBullet(
                          icon: Icons.location_on,
                          title: 'Jobs from customers near you',
                          body:
                              'Set a 3 – 25 km radius. Work in your locality.',
                        ),
                        _ValueBullet(
                          icon: Icons.currency_rupee,
                          title: 'Daily payouts to UPI',
                          body:
                              'Earnings settle to your UPI / bank every 7 PM.',
                        ),
                      ],
                    ),
                  ),
                ),
                // Sticky action area.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: () => context.push(
                        Routes.phone,
                        extra: const AuthFlow(mode: AuthMode.signIn),
                      ),
                      child: const Text('Sign in'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => context.push(
                        Routes.phone,
                        extra: const AuthFlow(mode: AuthMode.signUp),
                      ),
                      child: const Text('Create account · Enroll as a Pro'),
                    ),
                    const SizedBox(height: 14),
                    _Footer(currentLang: ref.watch(localeProvider).languageCode),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, compact ? 18 : 24, 20, compact ? 18 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.brandPrimary, AppTheme.brandPrimaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandPrimary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.engineering,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 14),
          const Text(
            'Welcome to Pro-Enroll',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Local skills. Verified hands. Daily payouts.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueBullet extends StatelessWidget {
  const _ValueBullet({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.brandPrimaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppTheme.brandPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.currentLang});
  final String currentLang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: () => _showLanguageSheet(context, ref),
          icon: const Icon(Icons.translate, size: 16),
          label: Text(
            supportedLanguages
                .firstWhere(
                  (l) => l.code == currentLang,
                  orElse: () => supportedLanguages.first,
                )
                .nativeLabel,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '·',
          style: TextStyle(color: AppTheme.textFaint, fontSize: 18),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () {},
          child: const Text('Terms'),
        ),
      ],
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final current = ref.read(localeProvider).languageCode;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose your language',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                for (final lng in supportedLanguages)
                  ListTile(
                    onTap: () {
                      ref
                          .read(localeProvider.notifier)
                          .setLanguage(lng.code);
                      Navigator.pop(ctx);
                    },
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      lng.code == current
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: lng.code == current
                          ? AppTheme.brandPrimary
                          : AppTheme.textFaint,
                    ),
                    title: Text(lng.nativeLabel,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(lng.label),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
