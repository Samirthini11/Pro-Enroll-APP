import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../../state/locale_state.dart';
import '../shared/profile_avatar.dart';
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

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ContentMaxWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              context.pageHPadding, 16, context.pageHPadding, 28),
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          children: [
            _Header(profile: profile, title: l.t('jobs.title')),
            const SizedBox(height: 16),
            _AvailabilityCard(
              available: profile.isAvailable,
              label: l.t('jobs.available_toggle'),
              onLabel: l.t('common.online'),
              offLabel: l.t('common.offline'),
              onChanged: (v) {
                ref.read(profileProvider.notifier).setAvailability(v);
                if (v) _refresh();
              },
            ),
            const SizedBox(height: 20),
            if (jobs.activeJob != null) ...[
              _ActiveJobCard(job: jobs.activeJob!),
              const SizedBox(height: 24),
            ],
            Row(
              children: [
                Text('Open offers',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (profile.isAvailable && jobs.offers.isNotEmpty)
                  StatusPill(
                    label: '${jobs.offers.length} new',
                    color: AppTheme.brandAccent,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (!profile.isAvailable)
              EmptyState(
                icon: Icons.bedtime_outlined,
                title: 'You are offline',
                body: 'Turn on availability above to start receiving jobs.',
              )
            else if (jobs.loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (jobs.offers.isEmpty)
              EmptyState(
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
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.title});
  final ProProfile profile;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, ${profile.fullName ?? 'Pro'} 👋',
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(title, style: const TextStyle(color: AppTheme.textMuted)),
            ],
          ),
        ),
        NameInitialAvatar(name: profile.fullName, radius: 22),
      ],
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({
    required this.available,
    required this.label,
    required this.onLabel,
    required this.offLabel,
    required this.onChanged,
  });
  final bool available;
  final String label;
  final String onLabel;
  final String offLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        gradient: available
            ? const LinearGradient(
                colors: [AppTheme.brandPrimary, AppTheme.brandPrimaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: available ? null : Colors.white,
        border: Border.all(
          color: available ? Colors.transparent : AppTheme.border,
        ),
        boxShadow: available
            ? [
                BoxShadow(
                  color: AppTheme.brandPrimary.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: available
                  ? Colors.white.withValues(alpha: 0.18)
                  : AppTheme.brandPrimaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              available ? Icons.flash_on : Icons.flash_off,
              color: available ? Colors.white : AppTheme.brandPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: available ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                Text(
                  available ? onLabel : offLabel,
                  style: TextStyle(
                    color: available
                        ? Colors.white.withValues(alpha: 0.88)
                        : AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: available,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white.withValues(alpha: 0.35),
          ),
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
                      color: AppTheme.brandPrimaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(cat.icon,
                        color: AppTheme.brandPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cat.name(lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                  StatusPill(
                    label: '${offer.distanceKm.toStringAsFixed(1)} km',
                    color: AppTheme.brandAccent,
                    icon: Icons.location_on,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                offer.problem,
                style: const TextStyle(fontSize: 14, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      offer.customerAreaName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Fee ${formatPaise(offer.visitFeePaise)}',
                    style: const TextStyle(
                      color: AppTheme.brandPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(builder: (ctx, bc) {
                final tight = bc.maxWidth < 280;
                final reject = OutlinedButton(
                  onPressed: () =>
                      ref.read(jobsProvider.notifier).reject(offer),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: Text(l.t('offer.reject')),
                );
                final accept = FilledButton(
                  onPressed: () {
                    ref.read(jobsProvider.notifier).accept(offer);
                    context.push(Routes.activeJob);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: Text(l.t('offer.accept')),
                );
                if (tight) {
                  return Column(
                    children: [
                      SizedBox(width: double.infinity, child: accept),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: reject),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: reject),
                    const SizedBox(width: 10),
                    Expanded(child: accept),
                  ],
                );
              }),
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
    return Card(
      color: AppTheme.brandPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide.none,
      ),
      child: InkWell(
        onTap: () => context.push(Routes.activeJob),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Active job',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                job.problem,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      color: Colors.white70, size: 18),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const Icon(Icons.location_on_outlined,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 2),
                  Text('${job.distanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
