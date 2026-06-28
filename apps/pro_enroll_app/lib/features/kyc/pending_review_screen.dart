import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../shared/widgets.dart';

class PendingReviewScreen extends ConsumerWidget {
  const PendingReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(lProvider);
    final hero = context.responsive<double>(xs: 96, sm: 108, md: 120);

    return AppPage(
      showBack: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          SizedBox(height: context.isCompactHeight ? 16 : 40),
          Center(
            child: Container(
              width: hero,
              height: hero,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppTheme.brandPrimaryLight, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.hourglass_top,
                  size: 56, color: AppTheme.brandPrimary),
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Text(l.t('kyc.pending.title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              l.t('kyc.pending.body'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textMuted, height: 1.4, fontSize: 14.5),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  _Step(done: true, label: 'Profile + skills'),
                  _StepDivider(),
                  _Step(done: true, label: 'Aadhaar verified'),
                  _StepDivider(),
                  _Step(done: true, label: 'Selfie captured'),
                  _StepDivider(),
                  _Step(done: false, label: 'Admin review (in progress)'),
                ],
              ),
            ),
          ),
        ],
      ),
      bottom: OutlinedButton(
        onPressed: () async {
          await ref.read(repositoryProvider).simulateKycApproval();
          ref.read(profileProvider.notifier).setKyc(KycStatus.verified);
          ref.read(profileProvider.notifier).seedDemoStats();
          await ref.read(profileProvider.notifier).loadFromApi();
          if (context.mounted) context.go(Routes.home);
        },
        child: const Text('Continue (demo: simulate approval)'),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.done, required this.label});
  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? AppTheme.brandSuccess : AppTheme.textFaint,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: done ? AppTheme.textPrimary : AppTheme.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepDivider extends StatelessWidget {
  const _StepDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
      child: Container(
        width: 2,
        height: 16,
        color: AppTheme.border,
      ),
    );
  }
}
