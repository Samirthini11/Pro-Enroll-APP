import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../../state/locale_state.dart';
import '../shared/widgets.dart';

class JobsTab extends ConsumerStatefulWidget {
  const JobsTab({super.key});

  @override
  ConsumerState<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends ConsumerState<JobsTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  Future<void> _refresh() async {
    final profile = ref.read(profileProvider);
    if (profile.isAvailable) {
      await ref
          .read(jobsProvider.notifier)
          .refresh(profile.skills.map((s) => s.categoryCode).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final profile = ref.watch(profileProvider);
    final jobs = ref.watch(jobsProvider);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          // Header.
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, ${profile.fullName ?? 'Pro'} 👋',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(l.t('jobs.title'),
                        style: const TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  (profile.fullName ?? 'P').characters.first.toUpperCase(),
                  style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Availability card.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: profile.isAvailable
                  ? theme.colorScheme.primaryContainer
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: profile.isAvailable
                    ? theme.colorScheme.primary
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  profile.isAvailable ? Icons.flash_on : Icons.flash_off,
                  color: profile.isAvailable
                      ? theme.colorScheme.primary
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.t('jobs.available_toggle'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(
                        profile.isAvailable
                            ? l.t('common.online')
                            : l.t('common.offline'),
                        style: TextStyle(
                          color: profile.isAvailable
                              ? theme.colorScheme.primary
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: profile.isAvailable,
                  onChanged: (v) {
                    ref.read(profileProvider.notifier).setAvailability(v);
                    if (v) _refresh();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Active job (if any).
          if (jobs.activeJob != null) ...[
            _ActiveJobCard(job: jobs.activeJob!),
            const SizedBox(height: 24),
          ],

          // Offers.
          Text('Open offers',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          if (!profile.isAvailable)
            _EmptyState(
              icon: Icons.bedtime_outlined,
              title: 'You are offline',
              body:
                  'Turn on availability above to start receiving jobs.',
            )
          else if (jobs.loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (jobs.offers.isEmpty)
            _EmptyState(
              icon: Icons.hourglass_empty,
              title: l.t('jobs.empty.title'),
              body: l.t('jobs.empty.body'),
            )
          else
            for (final o in jobs.offers) ...[
              _OfferCard(offer: o, lang: lang),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _OfferCard extends ConsumerWidget {
  const _OfferCard({required this.offer, required this.lang});
  final JobOffer offer;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(lProvider);
    final cat = supportedCategories.firstWhere(
      (c) => c.code == offer.categoryCode,
      orElse: () => supportedCategories.first,
    );
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(Routes.offer, extra: offer.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(cat.icon,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cat.name(lang),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${offer.distanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(offer.problem,
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(offer.customerAreaName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF64748B))),
                  ),
                  Text(
                    'Fee ${formatPaise(offer.visitFeePaise)}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          ref.read(jobsProvider.notifier).reject(offer),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: Text(l.t('offer.reject')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        ref.read(jobsProvider.notifier).accept(offer);
                        context.push(Routes.activeJob);
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: Text(l.t('offer.accept')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveJobCard extends ConsumerWidget {
  const _ActiveJobCard({required this.job});
  final ActiveJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primary,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(Routes.activeJob),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.flag, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Active job',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                job.problem,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      color: Colors.white70, size: 18),
                  const SizedBox(width: 4),
                  Text(job.customerName,
                      style: const TextStyle(color: Colors.white70)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          Text(body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
