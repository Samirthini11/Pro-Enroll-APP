import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/api/api_exception.dart';
import '../../state/app_state.dart';
import '../shared/widgets.dart';

class EarningsTab extends ConsumerWidget {
  const EarningsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(lProvider);
    final profile = ref.watch(profileProvider);
    final asyncEarnings = ref.watch(earningsProvider);

    return asyncEarnings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.textMuted, size: 40),
              const SizedBox(height: 12),
              Text(
                e is ApiException ? e.message : 'Could not load earnings.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  ref.invalidate(earningsProvider);
                  ref.read(profileProvider.notifier).loadFromApi();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (e) {
        final ratingAvg = e.ratingAvg ?? profile.ratingAvg;
        final ratingCount = e.ratingCount ?? profile.ratingCount;
        final jobsDone = e.jobsCompleted ?? profile.jobsCompleted;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(earningsProvider);
            await ref.read(profileProvider.notifier).loadFromApi();
            await ref.read(earningsProvider.future);
          },
          child: ContentMaxWidth(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  context.pageHPadding, 16, context.pageHPadding, 28),
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              children: [
                Text(l.t('earnings.title'),
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade700, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ratingCount > 0
                                    ? '${ratingAvg.toStringAsFixed(1)} rating'
                                    : 'No ratings yet',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                ratingCount > 0
                                    ? '$ratingCount reviews · $jobsDone jobs completed'
                                    : '$jobsDone jobs completed',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    gradient: const LinearGradient(
                      colors: [AppTheme.brandPrimary, AppTheme.brandPrimaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brandPrimary.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            l.t('earnings.today'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatPaise(e.todayPaise),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${e.jobsToday} jobs completed today',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(builder: (ctx, bc) {
                  final two = bc.maxWidth > 360;
                  final week = _SummaryCard(
                    label: l.t('earnings.week'),
                    value: formatPaise(e.weekPaise),
                    icon: Icons.calendar_view_week,
                  );
                  final month = _SummaryCard(
                    label: l.t('earnings.month'),
                    value: formatPaise(e.monthPaise),
                    icon: Icons.calendar_month,
                  );
                  if (two) {
                    return Row(
                      children: [
                        Expanded(child: week),
                        const SizedBox(width: 12),
                        Expanded(child: month),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      week,
                      const SizedBox(height: 10),
                      month,
                    ],
                  );
                }),
                const SizedBox(height: 22),
                Text(l.t('earnings.payouts'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _LedgerRow(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Pending payout',
                          value: formatPaise(e.pendingPayoutPaise),
                        ),
                        const Divider(height: 24),
                        _LedgerRow(
                          icon: Icons.check_circle_outline,
                          label: 'Paid this month',
                          value: formatPaise(e.payoutsThisMonthPaise),
                          accent: true,
                        ),
                        const SizedBox(height: 12),
                        const TrustBanner(
                          tone: TrustBannerTone.info,
                          icon: Icons.schedule,
                          text:
                              'Daily payouts to your UPI / bank at 7 PM IST.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.icon,
    required this.label,
    required this.value,
    this.accent = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textMuted),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: accent ? AppTheme.brandPrimary : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.brandPrimaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.brandPrimary, size: 20),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
