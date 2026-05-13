import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../state/app_state.dart';
import '../shared/widgets.dart';

class EarningsTab extends ConsumerWidget {
  const EarningsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(lProvider);
    final asyncEarnings = ref.watch(earningsProvider);
    final theme = Theme.of(context);

    return asyncEarnings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (e) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Text(l.t('earnings.title'),
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Today',
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  formatPaise(e.todayPaise),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${e.jobsToday} jobs completed today',
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                    label: l.t('earnings.week'),
                    value: formatPaise(e.weekPaise),
                    icon: Icons.calendar_view_week),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                    label: l.t('earnings.month'),
                    value: formatPaise(e.monthPaise),
                    icon: Icons.calendar_month),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(l.t('earnings.payouts'),
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined,
                          color: Color(0xFF64748B)),
                      const SizedBox(width: 10),
                      const Text('Pending payout',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(formatPaise(e.pendingPayoutPaise),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Color(0xFF64748B)),
                      const SizedBox(width: 10),
                      const Text('Paid this month',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(formatPaise(e.payoutsThisMonthPaise),
                          style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Daily payouts to your UPI / bank at 7 PM IST.',
                      style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
            Icon(icon, color: const Color(0xFF64748B)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
