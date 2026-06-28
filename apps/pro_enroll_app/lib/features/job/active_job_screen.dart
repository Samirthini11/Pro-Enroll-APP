import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/contact_launcher.dart';
import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../state/locale_state.dart';
import '../shared/map_preview.dart';
import '../shared/widgets.dart';

class ActiveJobScreen extends ConsumerStatefulWidget {
  const ActiveJobScreen({super.key});

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen> {
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final job = ref.watch(jobsProvider).activeJob;

    if (job == null) {
      return AppPage(
        title: 'Active job',
        child: const Center(child: Text('No active job.')),
      );
    }
    final cat = supportedCategories.firstWhere(
      (c) => c.code == job.categoryCode,
      orElse: () => supportedCategories.first,
    );
    final mapH = context.responsive<double>(xs: 150, sm: 170, md: 200);
    final fallbackCity = cityById(ref.watch(profileProvider).cityId ?? supportedCities.first.id);
    final mapLat = job.customerLat ?? fallbackCity.latitude;
    final mapLng = job.customerLng ?? fallbackCity.longitude;

    return AppPage(
      title: cat.name(lang),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          StatusPill(
            label: _statusLabel(job.status),
            color: _statusColor(job.status),
          ),
          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: SizedBox(
              height: mapH,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: MapPreview(
                  latitude: mapLat,
                  longitude: mapLng,
                  radiusKm: job.distanceKm.clamp(1, 25),
                  caption:
                      '${job.distanceKm.toStringAsFixed(1)} km away',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Customer card.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(job.customerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(job.customerAddress,
                      style: const TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 14),
                  LayoutBuilder(builder: (ctx, bc) {
                    final tight = bc.maxWidth < 300;
                    final call = OutlinedButton.icon(
                      onPressed: () => ContactLauncher.call(context, job.customerPhoneE164),
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                    );
                    final chat = OutlinedButton.icon(
                      onPressed: () => ContactLauncher.chat(
                        context,
                        job.customerPhoneE164,
                        message: 'Hi ${job.customerName}, regarding job ${job.code}.',
                      ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Chat'),
                    );
                    if (tight) {
                      return Column(
                        children: [
                          SizedBox(width: double.infinity, child: call),
                          const SizedBox(height: 8),
                          SizedBox(width: double.infinity, child: chat),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: call),
                        const SizedBox(width: 10),
                        Expanded(child: chat),
                      ],
                    );
                  }),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined,
                          size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text('Masked number: ${job.customerPhoneMasked}',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Job details.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tag,
                          size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(job.code,
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.problem,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.currency_rupee,
                          size: 18, color: AppTheme.textMuted),
                      Text(
                        'Visit fee: ${formatPaise(job.visitFeePaise)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (job.status == BookingStatus.inProgress)
            _CompleteCard(
                amountCtrl: _amountCtrl, onComplete: _onComplete),
          if (job.status == BookingStatus.completed)
            _CompletedSummary(job: job),

          const SizedBox(height: 28),
        ],
      ),
      bottom: _bottomCta(context, job, l),
    );
  }

  Widget? _bottomCta(BuildContext context, ActiveJob job, L l) {
    switch (job.status) {
      case BookingStatus.accepted:
        return FilledButton.icon(
          onPressed: () async => ref
              .read(jobsProvider.notifier)
              .updateStatus(BookingStatus.onTheWay),
          icon: const Icon(Icons.navigation),
          label: Text(l.t('job.on_the_way')),
        );
      case BookingStatus.onTheWay:
        return FilledButton.icon(
          onPressed: () async => ref
              .read(jobsProvider.notifier)
              .updateStatus(BookingStatus.inProgress),
          icon: const Icon(Icons.build_outlined),
          label: Text(l.t('job.start')),
        );
      case BookingStatus.completed:
        return FilledButton(
          onPressed: () {
            ref.read(jobsProvider.notifier).clearActive();
            context.pop();
          },
          child: const Text('Done'),
        );
      default:
        return null;
    }
  }

  Future<void> _onComplete() async {
    final v = int.tryParse(_amountCtrl.text.trim());
    if (v == null || v <= 0) return;
    await ref.read(jobsProvider.notifier).complete(v);
  }

  String _statusLabel(BookingStatus s) {
    switch (s) {
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.onTheWay:
        return 'On the way';
      case BookingStatus.inProgress:
        return 'In progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.pendingAcceptance:
        return 'Pending';
    }
  }

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.completed:
        return AppTheme.brandSuccess;
      case BookingStatus.cancelled:
        return AppTheme.brandDanger;
      case BookingStatus.inProgress:
        return AppTheme.brandAccent;
      default:
        return AppTheme.brandPrimary;
    }
  }
}

class _CompleteCard extends ConsumerWidget {
  const _CompleteCard({required this.amountCtrl, required this.onComplete});
  final TextEditingController amountCtrl;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(lProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.t('job.complete'),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l.t('job.final_amount'),
                prefixIcon: const Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onComplete, child: Text(l.t('common.submit'))),
            const SizedBox(height: 8),
            const Text(
              'Tip: upload a before / after photo to win disputes faster.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedSummary extends StatelessWidget {
  const _CompletedSummary({required this.job});
  final ActiveJob job;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        gradient: const LinearGradient(
          colors: [AppTheme.brandPrimary, AppTheme.brandPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.check_circle, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 10),
          const Text(
            'Job completed',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Earnings ${formatPaise(job.finalAmountPaise ?? job.visitFeePaise)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Will be added to your next 7 PM payout.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
