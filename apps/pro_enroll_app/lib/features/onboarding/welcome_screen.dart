import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../routing/router.dart';
import '../shared/widgets.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(lProvider);
    final theme = Theme.of(context);

    return AppPage(
      showBack: false,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 8),
          // Hero card.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
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
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.engineering,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(height: 14),
                Text(
                  l.t('onboarding.welcome.title'),
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  l.t('onboarding.welcome.subtitle'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 14.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Why Pro-Enroll', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          _Bullet(
            icon: Icons.verified_user,
            title: 'Aadhaar + selfie verified',
            body: 'Pros earn the trust badge customers look for.',
          ),
          _Bullet(
            icon: Icons.location_on,
            title: 'Jobs from customers near you',
            body: 'Set a 3–25 km radius. Stay in your locality.',
          ),
          _Bullet(
            icon: Icons.currency_rupee,
            title: 'Daily payouts',
            body: 'Earnings settle to your UPI / bank every 7 PM.',
          ),
          _Bullet(
            icon: Icons.school,
            title: 'Free Pro Academy',
            body: 'Tamil video courses to upgrade your skills.',
          ),
        ],
      ),
      bottom: FilledButton(
        onPressed: () => context.go(Routes.phone),
        child: Text(l.t('onboarding.welcome.cta')),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check, color: AppTheme.brandPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
