import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
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
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              gradient: const LinearGradient(
                colors: [AppTheme.brandPrimaryLight, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.brandPrimary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.shield,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Verified pros get 3× more jobs',
                    style: TextStyle(
                      color: AppTheme.brandPrimaryDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _StepRow(
            number: '1',
            title: 'Aadhaar verification',
            body: 'OTP-based, takes under 30 seconds.',
            icon: Icons.credit_card,
          ),
          _StepRow(
            number: '2',
            title: 'Live selfie',
            body: 'A quick face match to confirm it’s really you.',
            icon: Icons.face,
          ),
          _StepRow(
            number: '3',
            title: 'Supporting documents',
            body: 'Shop / tools photo or certificate (optional).',
            icon: Icons.upload_file_outlined,
          ),
          const SizedBox(height: 12),
          const TrustBanner(
            icon: Icons.lock_outline,
            text:
                'Your Aadhaar is encrypted. Only the last 4 digits are stored.',
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

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.title,
    required this.body,
    required this.icon,
  });

  final String number;
  final String title;
  final String body;
  final IconData icon;

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
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimaryLight,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: AppTheme.brandPrimaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            style:
                                Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
