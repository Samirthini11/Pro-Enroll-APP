import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/api/api_exception.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../services/kyc_preview_service.dart';
import '../../state/app_state.dart';
import '../shared/widgets.dart';

class PendingReviewScreen extends ConsumerStatefulWidget {
  const PendingReviewScreen({super.key});

  @override
  ConsumerState<PendingReviewScreen> createState() =>
      _PendingReviewScreenState();
}

class _PendingReviewScreenState extends ConsumerState<PendingReviewScreen> {
  bool _busy = false;

  Future<void> _continueToApp() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // Dev/live-debug APIs may approve immediately; live usually returns 403.
      try {
        await ref.read(repositoryProvider).simulateKycApproval();
        ref.read(profileProvider.notifier).setKyc(KycStatus.verified);
        ref.read(profileProvider.notifier).seedDemoStats();
        await ref.read(profileProvider.notifier).loadFromApi();
      } on ApiException catch (e) {
        debugPrint('KYC simulate unavailable (${e.statusCode}): ${e.message}');
      } catch (e) {
        debugPrint('KYC simulate failed: $e');
      }

      // Always unlock preview so the pro can explore the app while waiting.
      await KycPreviewService.unlock();
      ref.read(kycPreviewUnlockedProvider.notifier).state = true;

      if (!mounted) return;
      context.go(Routes.home);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              l.t('kyc.pending.preview_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.35,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
      bottom: FilledButton(
        onPressed: _busy ? null : _continueToApp,
        child: _busy
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Text(l.t('kyc.pending.continue')),
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
    return const Padding(
      padding: EdgeInsets.only(left: 12),
      child: SizedBox(
        height: 12,
        child: Align(
          alignment: Alignment.centerLeft,
          child: VerticalDivider(width: 2, thickness: 2),
        ),
      ),
    );
  }
}
