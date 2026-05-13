import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../routing/router.dart';
import '../shared/widgets.dart';

class KycIntroScreen extends ConsumerWidget {
  const KycIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(lProvider);
    return AppPage(
      title: l.t('kyc.intro.title'),
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.shield,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Verified pros get 3× more jobs.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(l.t('kyc.intro.body')),
          const SizedBox(height: 24),
          const TrustBanner(
            text:
                'Your Aadhaar is encrypted. Only the last 4 digits are stored.',
            icon: Icons.lock_outline,
          ),
        ],
      ),
      bottom: FilledButton(
        onPressed: () => context.push(Routes.kycAadhaar),
        child: Text(l.t('common.continue')),
      ),
    );
  }
}
