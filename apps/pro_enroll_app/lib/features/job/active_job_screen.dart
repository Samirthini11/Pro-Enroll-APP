import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../state/locale_state.dart';
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

          // Map placeholder with subtle grid.
          Container(
            height: mapH,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              gradient: const LinearGradient(
                colors: [AppTheme.brandPrimaryLight, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppTheme.border),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: Size.infinite, painter: _MapGrid()),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.brandPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.brandPrimary
                                .withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.location_on,
                          size: 30, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        '${job.distanceKm.toStringAsFixed(1)} km away',
                        style: const TextStyle(
                          color: AppTheme.brandPrimaryDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
                      onPressed: () {},
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                    );
                    final chat = OutlinedButton.icon(
                      onPressed: () {},
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
          onPressed: () => ref
              .read(jobsProvider.notifier)
              .updateStatus(BookingStatus.onTheWay),
          icon: const Icon(Icons.navigation),
          label: Text(l.t('job.on_the_way')),
        );
      case BookingStatus.onTheWay:
        return FilledButton.icon(
          onPressed: () => ref
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

  void _onComplete() {
    final v = int.tryParse(_amountCtrl.text.trim());
    if (v == null || v <= 0) return;
    ref.read(jobsProvider.notifier).complete(v);
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

class _MapGrid extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppTheme.brandPrimary.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
