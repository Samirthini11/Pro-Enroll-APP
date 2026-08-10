import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../core/ist_time.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/api/api_exception.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../../state/locale_state.dart';
import '../shared/book_service_action.dart';
import '../shared/widgets.dart';

class JobsTab extends ConsumerStatefulWidget {
  const JobsTab({super.key});

  @override
  ConsumerState<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends ConsumerState<JobsTab> {
  bool _togglingAvailability = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  Future<void> _refresh({bool silentJobs = false}) async {
    await ref.read(profileProvider.notifier).loadFromApi();
    final profile = ref.read(profileProvider);
    if (profile.isAvailable) {
      await ref.read(jobsProvider.notifier).refresh(
            profile.skills.map((s) => s.categoryCode).toList(),
            silent: silentJobs,
          );
    }
  }

  Future<void> _onAvailabilityChanged(bool online) async {
    if (_togglingAvailability) return;
    setState(() => _togglingAvailability = true);
    try {
      await ref.read(profileProvider.notifier).setAvailability(online);
      if (!mounted) return;
      if (online) {
        final profile = ref.read(profileProvider);
        // Soft refresh — keep list mounted so the switch doesn't jump the page.
        unawaited(
          ref.read(jobsProvider.notifier).refresh(
                profile.skills.map((s) => s.categoryCode).toList(),
                silent: true,
              ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException
                ? e.message
                : 'Could not update availability.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _togglingAvailability = false);
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
            _Header(
              profile: profile,
              title: l.t('jobs.title'),
            ),
            const SizedBox(height: 16),
            _AvailabilityCard(
              available: profile.isAvailable,
              label: l.t('jobs.available_toggle'),
              onLabel: l.t('common.online'),
              offLabel: l.t('common.offline'),
              enabled: !profile.listingHeld && !_togglingAvailability,
              onChanged: _onAvailabilityChanged,
            ),
            if (profile.listingHeld) ...[
              const SizedBox(height: 12),
              const TrustBanner(
                tone: TrustBannerTone.warning,
                icon: Icons.pause_circle_filled,
                text:
                    'Listing paused — wallet is below ₹50. Recharge and wait for admin approval; it unlocks automatically after approval.',
              ),
            ],
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
            const SizedBox(height: 24),
            Text('Job history', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (jobs.history.isEmpty && !jobs.loading)
              const EmptyState(
                icon: Icons.history,
                title: 'No jobs yet',
                body: 'Accepted and completed jobs will show here with status.',
              )
            else
              for (final h in jobs.history) ...[
                _HistoryCard(item: h),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.profile, required this.title});
  final ProProfile profile;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(earningsProvider);
    final walletPaise = earnings.maybeWhen(
      data: (e) => e.walletBalancePaise,
      orElse: () => null,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        gradient: LinearGradient(
          colors: [
            AppTheme.brandPrimary.withValues(alpha: 0.08),
            AppTheme.brandPrimaryLight.withValues(alpha: 0.45),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              BookServiceAvatar(
                name: profile.fullName,
                radius: 24,
                backgroundColor: Colors.white,
                onTap: () =>
                    ref.read(homeShellTabProvider.notifier).state = 3,
              ),
            ],
          ),
          if (walletPaise != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      color: AppTheme.brandPrimary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Wallet',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatPaise(walletPaise),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTheme.brandPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          BookServiceChip(
            compact: true,
            onTap: () => switchToCustomerMode(context, ref),
          ),
        ],
      ),
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
    this.enabled = true,
  });
  final bool available;
  final String label;
  final String onLabel;
  final String offLabel;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        color: available ? AppTheme.brandPrimary : Colors.white,
        border: Border.all(
          color: available ? AppTheme.brandPrimaryDark : AppTheme.border,
        ),
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
            onChanged: enabled ? onChanged : null,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white.withValues(alpha: 0.4),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppTheme.border,
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
    final active = ref.watch(jobsProvider).activeJob;
    final busy = active != null &&
        active.status != BookingStatus.completed &&
        active.status != BookingStatus.cancelled;
    final expired = !offer.expiresAt.isAfter(DateTime.now().toUtc());
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
              if (offer.commissionPreview != null) ...[
                const SizedBox(height: 6),
                Text(
                  offer.commissionPreview!.isFreeBooking
                      ? 'Free job · no wallet cut (${offer.commissionPreview!.freeBookingsRemaining} left)'
                      : 'Visit ${formatPaise(offer.commissionPreview!.proCreditPaise)} · wallet −${formatPaise(offer.commissionPreview!.commissionPaise)} (${offer.commissionPreview!.visitCommissionPercent}%)',
                  style: TextStyle(
                    color: offer.commissionPreview!.isFreeBooking
                        ? AppTheme.brandSuccess
                        : AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              if (busy) ...[
                Text(
                  l.t('offer.finish_before_accept'),
                  style: const TextStyle(
                    color: AppTheme.brandWarning,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              LayoutBuilder(builder: (ctx, bc) {
                final tight = bc.maxWidth < 280;
                final reject = OutlinedButton(
                  onPressed: expired
                      ? null
                      : () => ref.read(jobsProvider.notifier).reject(offer),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: Text(l.t('offer.reject')),
                );
                final accept = FilledButton(
                  onPressed: expired
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.t('offer.expired'))),
                          );
                        }
                      : busy
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text(l.t('offer.finish_before_accept')),
                                ),
                              );
                            }
                          : () async {
                              try {
                                await ref
                                    .read(jobsProvider.notifier)
                                    .accept(offer);
                                if (context.mounted) {
                                  context.push(Routes.activeJob);
                                }
                              } catch (e) {
                                if (!context.mounted) return;
                                final msg = e is ApiException
                                    ? e.message
                                    : 'Could not accept offer';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(msg)),
                                );
                              }
                            },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor:
                        expired || busy ? AppTheme.textFaint : null,
                  ),
                  child: Text(
                    expired ? l.t('offer.expired_short') : l.t('offer.accept'),
                  ),
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
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});
  final ProJobHistoryItem item;

  Color get _statusColor {
    return switch (item.status) {
      'completed' => AppTheme.brandSuccess,
      'cancelled' => AppTheme.brandDanger,
      'awaiting_payment' => AppTheme.brandAccentDark,
      'in_progress' || 'arrived' || 'en_route' => AppTheme.brandPrimary,
      'confirmed' => AppTheme.brandAccent,
      _ => AppTheme.textMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final when = item.displayAt;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: () => context.push(Routes.jobHistoryDetail, extra: item.id),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.border),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.code.isNotEmpty ? item.code : 'Job #${item.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  StatusPill(label: item.statusLabel, color: _statusColor),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.problem,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                  Text(
                    formatPaise(item.visitFeePaise),
                    style: const TextStyle(
                      color: AppTheme.brandPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (item.customerAreaName.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 15, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.customerAreaName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      when != null
                          ? IstTime.format(when, pattern: 'd MMM, h:mm a')
                          : '',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Text(
                    'View details',
                    style: TextStyle(
                      color: AppTheme.brandPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppTheme.brandPrimary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
