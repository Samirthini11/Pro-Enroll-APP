import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_error.dart';
import '../../core/theme.dart';
import '../../state/admin_state.dart';
import '../shared/widgets.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(apiErrorMessage(e, fallback: 'Could not load dashboard')),
        ),
      ),
      data: (stats) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardStatsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionTitle(
              'Platform registrations',
              subtitle: 'Total accounts in Pro-Enroll',
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                StatCard(
                  label: 'Professionals',
                  value: '${stats.totalRegisteredPros}',
                  icon: Icons.engineering_outlined,
                  color: AppTheme.brandPrimary,
                ),
                StatCard(
                  label: 'Customers',
                  value: '${stats.totalRegisteredCustomers}',
                  icon: Icons.person_outline,
                  color: AppTheme.brandSuccess,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionTitle(
              'Approval Overview',
              subtitle: 'Pro-Enroll user verification pipeline',
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                StatCard(
                  label: 'KYC pending',
                  value: '${stats.kycPending}',
                  icon: Icons.pending_actions,
                  color: AppTheme.brandWarning,
                ),
                StatCard(
                  label: 'Docs pending',
                  value: '${stats.docsPending}',
                  icon: Icons.description_outlined,
                  color: AppTheme.brandPrimary,
                ),
                StatCard(
                  label: 'Approved today',
                  value: '${stats.approvedToday}',
                  icon: Icons.check_circle_outline,
                  color: AppTheme.brandSuccess,
                ),
                StatCard(
                  label: 'Rejected today',
                  value: '${stats.rejectedToday}',
                  icon: Icons.cancel_outlined,
                  color: AppTheme.brandDanger,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.groups, color: AppTheme.brandPrimary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${stats.totalVerifiedPros} verified pros',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Text(
                            'Live on the Pro-Enroll marketplace',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle(
              'Quick actions',
              subtitle: 'Use the tabs below to review applications',
            ),
            _ActionTile(
              icon: Icons.verified_user,
              title: 'Review KYC applications',
              subtitle:
                  '${stats.kycPending} professionals waiting for approval',
              color: AppTheme.brandPrimary,
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.store,
              title: 'Verify shop & certificates',
              subtitle: '${stats.docsPending} documents need review',
              color: AppTheme.brandWarning,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
