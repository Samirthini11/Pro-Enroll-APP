import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
        final avgToday = e.jobsToday > 0 ? e.todayPaise ~/ e.jobsToday : 0;
        final avgWeekDay = e.weekPaise ~/ 7;
        final totalPaid = e.payoutsThisMonthPaise + e.pendingPayoutPaise;
        final paidRatio = totalPaid > 0
            ? (e.payoutsThisMonthPaise / totalPaid).clamp(0.0, 1.0)
            : 0.0;
        final payoutDest = profile.upiId ?? profile.bankAccountNo;
        final dateLabel = DateFormat('EEE, d MMM yyyy').format(DateTime.now());

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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.t('earnings.title'),
                              style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 4),
                          Text(
                            l.t('earnings.subtitle'),
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.brandPrimaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 13, color: AppTheme.brandPrimaryDark),
                          const SizedBox(width: 5),
                          Text(
                            dateLabel,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.brandPrimaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _PerformanceOverview(
                  l: l,
                  ratingAvg: ratingAvg,
                  ratingCount: ratingCount,
                  jobsDone: jobsDone,
                  proScore: profile.proScore,
                  visitFeePaise: profile.visitFeePaise,
                ),
                const SizedBox(height: 14),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l.t('earnings.today'),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (e.jobsToday > 0)
                            Text(
                              '${formatPaise(avgToday)} / job',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatPaise(e.todayPaise),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 15,
                              color: Colors.white.withValues(alpha: 0.85)),
                          const SizedBox(width: 6),
                          Text(
                            e.jobsToday == 1
                                ? l.t('earnings.jobsTodayOne')
                                : l.t('earnings.jobsTodayMany',
                                    {'count': '${e.jobsToday}'}),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(builder: (ctx, bc) {
                  final two = bc.maxWidth > 360;
                  final week = _PeriodCard(
                    label: l.t('earnings.week'),
                    value: formatPaise(e.weekPaise),
                    icon: Icons.calendar_view_week,
                    hint: l.t('earnings.dailyAvg',
                        {'amount': formatPaise(avgWeekDay)}),
                  );
                  final month = _PeriodCard(
                    label: l.t('earnings.month'),
                    value: formatPaise(e.monthPaise),
                    icon: Icons.calendar_month,
                    hint: jobsDone > 0
                        ? l.t('earnings.lifetimeJobs',
                            {'count': '$jobsDone'})
                        : l.t('earnings.noJobsYet'),
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
                const SizedBox(height: 20),
                Text(l.t('earnings.payouts'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  l.t('earnings.payoutsSubtitle'),
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _PayoutStat(
                                label: l.t('earnings.pending'),
                                value: formatPaise(e.pendingPayoutPaise),
                                icon: Icons.hourglass_top_rounded,
                                color: AppTheme.brandAccent,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 48,
                              color: AppTheme.border,
                            ),
                            Expanded(
                              child: _PayoutStat(
                                label: l.t('earnings.paidMonth'),
                                value: formatPaise(e.payoutsThisMonthPaise),
                                icon: Icons.check_circle_outline,
                                color: AppTheme.brandSuccess,
                              ),
                            ),
                          ],
                        ),
                        if (totalPaid > 0) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                l.t('earnings.paidProgress'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(paidRatio * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.brandPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: paidRatio,
                              minHeight: 8,
                              backgroundColor: AppTheme.brandPrimaryLight,
                              color: AppTheme.brandPrimary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        _LedgerRow(
                          icon: Icons.account_balance_wallet_outlined,
                          label: l.t('earnings.totalMonth'),
                          value: formatPaise(e.monthPaise),
                        ),
                        const SizedBox(height: 10),
                        _LedgerRow(
                          icon: Icons.payments_outlined,
                          label: l.t('earnings.payoutTo'),
                          value: payoutDest ?? l.t('earnings.payoutNotSet'),
                          valueMuted: payoutDest == null,
                        ),
                        const SizedBox(height: 14),
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
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.brandPrimaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.lightbulb_outline,
                                  color: AppTheme.brandPrimary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l.t('earnings.insights'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _InsightRow(
                          icon: Icons.trending_up,
                          text: e.jobsToday == 0
                              ? l.t('earnings.insightGoOnline')
                              : l.t('earnings.insightGreatDay'),
                        ),
                        const SizedBox(height: 8),
                        _InsightRow(
                          icon: Icons.star_outline,
                          text: ratingCount > 0
                              ? l.t('earnings.insightRating',
                                  {'rating': ratingAvg.toStringAsFixed(1)})
                              : l.t('earnings.insightNoRating'),
                        ),
                        const SizedBox(height: 8),
                        _InsightRow(
                          icon: Icons.currency_rupee,
                          text: l.t('earnings.insightVisitFee',
                              {'fee': formatPaise(profile.visitFeePaise)}),
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

class _PerformanceOverview extends StatelessWidget {
  const _PerformanceOverview({
    required this.l,
    required this.ratingAvg,
    required this.ratingCount,
    required this.jobsDone,
    required this.proScore,
    required this.visitFeePaise,
  });

  final L l;
  final double ratingAvg;
  final int ratingCount;
  final int jobsDone;
  final int proScore;
  final int visitFeePaise;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.t('earnings.performance'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.star_rounded,
                    iconColor: Colors.amber.shade700,
                    label: l.t('profile.rating'),
                    value: ratingCount > 0
                        ? ratingAvg.toStringAsFixed(1)
                        : '—',
                    sub: ratingCount > 0
                        ? l.t('earnings.reviews', {'count': '$ratingCount'})
                        : l.t('earnings.noReviews'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.work_outline,
                    iconColor: AppTheme.brandPrimary,
                    label: l.t('profile.jobs'),
                    value: '$jobsDone',
                    sub: l.t('earnings.completed'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.trending_up,
                    iconColor: AppTheme.brandSuccess,
                    label: l.t('profile.proScore'),
                    value: '$proScore',
                    sub: proScore >= 70
                        ? l.t('earnings.strongProfile')
                        : l.t('earnings.keepImproving'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.currency_rupee,
                    iconColor: AppTheme.brandAccent,
                    label: l.t('earnings.visitFee'),
                    value: formatPaise(visitFeePaise),
                    sub: l.t('earnings.perVisit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(fontSize: 10.5, color: AppTheme.textFaint),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.hint,
  });

  final String label;
  final String value;
  final IconData icon;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                const Spacer(),
                Icon(Icons.arrow_outward,
                    size: 16, color: AppTheme.textFaint.withValues(alpha: 0.8)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hint,
              style: const TextStyle(
                color: AppTheme.textFaint,
                fontSize: 11.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PayoutStat extends StatelessWidget {
  const _PayoutStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueMuted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool valueMuted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: valueMuted ? AppTheme.textMuted : AppTheme.textPrimary,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.brandPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
