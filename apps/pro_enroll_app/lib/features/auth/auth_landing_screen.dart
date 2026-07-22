import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../../state/locale_state.dart';
import 'auth_flow.dart';

/// Landing: Sign in as Professional, or book as Customer.
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
              horizontal: context.pageHPadding,
              vertical: 12,
            ),
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
                        SizedBox(height: compact ? 20 : 28),
                        Text(
                          'How do you want to continue?',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Choose your role to sign in securely with OTP.',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13.5,
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: compact ? 16 : 20),
                        _RoleCard(
                          icon: Icons.handyman_rounded,
                          title: 'Sign in · Professional',
                          subtitle:
                              'Accept jobs near you, track earnings, and grow your work.',
                          accent: AppTheme.brandPrimary,
                          onTap: () {
                            ref.read(roleProvider.notifier).state =
                                AppRole.professional;
                            ref.read(authProvider.notifier).beginSignIn();
                            context.push(
                              Routes.phone,
                              extra: const AuthFlow(
                                mode: AuthMode.signIn,
                                role: AppRole.professional,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _RoleCard(
                          icon: Icons.home_repair_service_rounded,
                          title: 'Need a Service · Customer',
                          subtitle:
                              'Book verified local technicians for AC, plumbing, and more.',
                          accent: AppTheme.brandSuccess,
                          onTap: () {
                            ref.read(roleProvider.notifier).state =
                                AppRole.customer;
                            ref.read(authProvider.notifier).beginSignIn();
                            context.push(
                              Routes.phone,
                              extra: const AuthFlow(
                                mode: AuthMode.signIn,
                                role: AppRole.customer,
                              ),
                            );
                          },
                        ),
                        // Enrollment CTA kept for later — hide until re-enabled.
                        // const SizedBox(height: 12),
                        // OutlinedButton(
                        //   onPressed: () async {
                        //     ref.read(roleProvider.notifier).state =
                        //         AppRole.professional;
                        //     await ref.read(authProvider.notifier).beginSignUp();
                        //     if (context.mounted) {
                        //       context.push(
                        //         Routes.phone,
                        //         extra: const AuthFlow(
                        //           mode: AuthMode.signUp,
                        //           role: AppRole.professional,
                        //         ),
                        //       );
                        //     }
                        //   },
                        //   child: const Text('Enroll as a Professional'),
                        // ),
                      ],
                    ),
                  ),
                ),
                _Footer(currentLang: ref.watch(localeProvider).languageCode),
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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
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
          const SizedBox(height: 14),
          const Text(
            'QuickFix',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Trusted local repair services — for professionals and customers.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.currentLang});
  final String currentLang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
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
            onPressed: () => context.push(Routes.termsAcceptance, extra: true),
            child: const Text('Terms'),
          ),
        ],
      ),
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
                      ref.read(localeProvider.notifier).setLanguage(lng.code);
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
                    title: Text(
                      lng.nativeLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
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
