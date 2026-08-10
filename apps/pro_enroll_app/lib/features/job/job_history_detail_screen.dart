import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/contact_launcher.dart';
import '../../core/ist_time.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../shared/widgets.dart';

/// Read-only detail for a past / ongoing job opened from the Jobs tab history.
class JobHistoryDetailScreen extends ConsumerWidget {
  const JobHistoryDetailScreen({super.key, this.jobId});

  final String? jobId;

  static Color statusColor(String status) => switch (status) {
        'completed' => AppTheme.brandSuccess,
        'cancelled' => AppTheme.brandDanger,
        'awaiting_payment' => AppTheme.brandAccentDark,
        'in_progress' || 'arrived' || 'en_route' => AppTheme.brandPrimary,
        'confirmed' => AppTheme.brandAccent,
        _ => AppTheme.textMuted,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(jobsProvider).history;
    ProJobHistoryItem? item;
    for (final h in history) {
      if (h.id == jobId) {
        item = h;
        break;
      }
    }

    if (item == null) {
      return AppPage(
        title: 'Job details',
        fallbackRoute: Routes.home,
        child: const Center(
          child: EmptyState(
            icon: Icons.search_off,
            title: 'Job not found',
            body: 'Pull to refresh the Jobs tab and open it again.',
          ),
        ),
      );
    }

    final job = item;
    final color = statusColor(job.status);

    return AppPage(
      title: job.categoryName ?? 'Job details',
      fallbackRoute: Routes.home,
      child: ListView(
        children: [
          _HeaderCard(job: job, color: color),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Work requested',
            children: [
              Text(
                job.problem.isNotEmpty ? job.problem : 'No description provided',
                style: const TextStyle(height: 1.35),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Customer',
            children: [
              _Row(icon: Icons.person_outline, value: job.customerName),
              if (job.customerAreaName.trim().isNotEmpty)
                _Row(
                  icon: Icons.location_on_outlined,
                  value: job.customerAreaName,
                ),
              if (job.customerPhoneMasked != null)
                _Row(icon: Icons.call_outlined, value: job.customerPhoneMasked!),
              if (job.canContactCustomer) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            ContactLauncher.call(context, job.customerPhoneE164),
                        icon: const Icon(Icons.call),
                        label: const Text('Call'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ContactLauncher.chat(
                          context,
                          job.customerPhoneE164,
                        ),
                        icon: const Icon(Icons.chat),
                        label: const Text('Chat'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Payment',
            children: [
              _Row(
                icon: Icons.payments_outlined,
                label: 'Visit fee',
                value: formatPaise(job.visitFeePaise),
              ),
              if (job.proCreditPaise != null)
                _Row(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Credited to wallet',
                  value: formatPaise(job.proCreditPaise!),
                ),
              if (job.commissionWaived)
                const _Row(
                  icon: Icons.card_giftcard,
                  label: 'Platform fee',
                  value: 'Waived (free booking)',
                )
              else if (job.commissionPaise != null && job.commissionPaise! > 0)
                _Row(
                  icon: Icons.percent,
                  label: 'Platform fee',
                  value: formatPaise(job.commissionPaise!),
                ),
              _Row(
                icon: job.visitFeePaid ? Icons.check_circle : Icons.schedule,
                label: 'Status',
                value: job.visitFeePaid
                    ? 'Paid${job.visitFeePaymentMethod != null ? ' · ${job.visitFeePaymentMethod!.toUpperCase()}' : ''}'
                    : 'Not paid yet',
                valueColor:
                    job.visitFeePaid ? AppTheme.brandSuccess : AppTheme.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Timeline',
            children: [
              if (job.createdAt != null)
                _Row(
                  icon: Icons.event_available_outlined,
                  label: 'Booked',
                  value: IstTime.formatDateTime(job.createdAt!),
                ),
              if (job.completedAt != null)
                _Row(
                  icon: Icons.task_alt,
                  label: 'Completed',
                  value: IstTime.formatDateTime(job.completedAt!),
                ),
              if (job.completedAt == null && job.updatedAt != null)
                _Row(
                  icon: Icons.update,
                  label: 'Last update',
                  value: IstTime.formatDateTime(job.updatedAt!),
                ),
            ],
          ),
          if (job.ratingStars != null) ...[
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Customer rating',
              children: [
                Row(
                  children: [
                    for (var i = 0; i < 5; i++)
                      Icon(
                        i < job.ratingStars! ? Icons.star : Icons.star_border,
                        size: 20,
                        color: AppTheme.brandAccentDark,
                      ),
                  ],
                ),
                if ((job.ratingReview ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    job.ratingReview!,
                    style: const TextStyle(color: AppTheme.textMuted, height: 1.35),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
      bottom: _bottomAction(context, job),
    );
  }

  Widget? _bottomAction(BuildContext context, ProJobHistoryItem job) {
    if (job.status == 'confirmed') {
      return FilledButton.icon(
        onPressed: () => context.push(Routes.offer, extra: job.id),
        icon: const Icon(Icons.assignment_turned_in_outlined),
        label: const Text('Open offer'),
      );
    }
    if (const ['en_route', 'arrived', 'in_progress', 'awaiting_payment']
        .contains(job.status)) {
      return FilledButton.icon(
        onPressed: () => context.push(Routes.activeJob),
        icon: const Icon(Icons.work_outline),
        label: const Text('Open active job'),
      );
    }
    return null;
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.job, required this.color});
  final ProJobHistoryItem job;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.08), Colors.white],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.code.isNotEmpty ? job.code : 'Job #${job.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    fontSize: 12.5,
                  ),
                ),
              ),
              StatusPill(label: job.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            job.categoryName ?? job.categoryCode.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            formatPaise(job.visitFeePaise),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.value,
    this.label,
    this.valueColor,
  });

  final IconData icon;
  final String? label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          if (label != null) ...[
            Text(
              label!,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              value,
              textAlign: label != null ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
