import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../shared/widgets.dart';

class PendingReviewScreen extends ConsumerWidget {
  const PendingReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(lProvider);
    final c = Theme.of(context).colorScheme;
    return AppPage(
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: c.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.hourglass_top,
                size: 64, color: c.primary),
          ),
          const SizedBox(height: 24),
          Text(l.t('kyc.pending.title'),
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              l.t('kyc.pending.body'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
            ),
          ),
          const SizedBox(height: 32),
          _StepRow(
            done: true,
            label: 'Profile + skills',
          ),
          _StepRow(done: true, label: 'Aadhaar verified'),
          _StepRow(done: true, label: 'Selfie captured'),
          _StepRow(done: false, label: 'Admin review (in progress)'),
        ],
      ),
      bottom: OutlinedButton(
        onPressed: () {
          // For demo / scaffold: skip waiting and "approve" instantly.
          ref.read(profileProvider.notifier).setKyc(KycStatus.verified);
          ref.read(profileProvider.notifier).seedDemoStats();
          context.go(Routes.home);
        },
        child: const Text('Continue (demo: simulate approval)'),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.done, required this.label});
  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? c.primary : const Color(0xFFCBD5E1),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: done ? c.primary : const Color(0xFF64748B),
              )),
        ],
      ),
    );
  }
}
