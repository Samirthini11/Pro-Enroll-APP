import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.engineering,
                    size: 64, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    l.t('onboarding.welcome.title'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l.t('onboarding.welcome.subtitle'),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _bullet(context, Icons.verified_user,
              'Aadhaar + selfie KYC for trust'),
          _bullet(context, Icons.location_on,
              'Get jobs from customers near you'),
          _bullet(context, Icons.currency_rupee,
              'Daily payouts to your UPI / bank'),
          _bullet(context, Icons.school,
              'Free Pro Academy training in Tamil'),
          const Spacer(),
        ],
      ),
      bottom: FilledButton(
        onPressed: () => context.go(Routes.phone),
        child: Text(l.t('onboarding.welcome.cta')),
      ),
    );
  }

  Widget _bullet(BuildContext context, IconData icon, String text) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: c.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
