import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
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
    final theme = Theme.of(context);

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

    return AppPage(
      title: cat.name(lang),
      child: ListView(
        children: [
          // Status pill.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  _statusLabel(job.status),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Map placeholder.
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on,
                      size: 56, color: theme.colorScheme.primary),
                  Text('${job.distanceKm.toStringAsFixed(1)} km away',
                      style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Customer.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customer',
                      style: TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Text(job.customerName,
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(job.customerAddress,
                      style: const TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.call),
                          label: const Text('Call'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Chat'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Masked number: ${job.customerPhoneMasked}',
                      style: const TextStyle(
                          color: Color(0xFF64748B), fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

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
                          size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(job.code,
                          style:
                              const TextStyle(color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(job.problem,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.currency_rupee,
                          size: 18, color: Color(0xFF64748B)),
                      Text('Visit fee: ${formatPaise(job.visitFeePaise)}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (job.status == BookingStatus.inProgress)
            _CompleteCard(amountCtrl: _amountCtrl, onComplete: _onComplete),

          if (job.status == BookingStatus.completed)
            _CompletedSummary(job: job),

          const SizedBox(height: 32),
        ],
      ),
      bottom: _bottomCta(context, job, l),
    );
  }

  Widget? _bottomCta(BuildContext context, ActiveJob job, L l) {
    switch (job.status) {
      case BookingStatus.accepted:
        return FilledButton.icon(
          onPressed: () => ref.read(jobsProvider.notifier)
              .updateStatus(BookingStatus.onTheWay),
          icon: const Icon(Icons.navigation),
          label: Text(l.t('job.on_the_way')),
        );
      case BookingStatus.onTheWay:
        return FilledButton.icon(
          onPressed: () => ref.read(jobsProvider.notifier)
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
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
              'Tip: upload a before/after photo to win disputes faster.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.check_circle,
                color: Theme.of(context).colorScheme.primary, size: 48),
            const SizedBox(height: 8),
            Text(
              'Job completed',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Earnings ${formatPaise(job.finalAmountPaise ?? job.visitFeePaise)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text('Will be added to your next 7 PM payout.',
                style: TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}
