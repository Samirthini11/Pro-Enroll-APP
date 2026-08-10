import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../core/ist_time.dart';
import '../../core/maps_launcher.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/api/api_exception.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../../state/locale_state.dart';
import '../shared/map_preview.dart';
import '../shared/widgets.dart';

class OfferDetailScreen extends ConsumerStatefulWidget {
  const OfferDetailScreen({super.key, this.offerId});
  final String? offerId;

  @override
  ConsumerState<OfferDetailScreen> createState() =>
      _OfferDetailScreenState();
}

class _OfferDetailScreenState extends ConsumerState<OfferDetailScreen> {
  Timer? _ticker;
  Duration _timeLeft = Duration.zero;
  JobOffer? _fetched;
  bool _loadingOffer = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(pushNotificationServiceProvider).syncTokenWithServer();
      await _ensureOffer();
      _syncCountdown();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _syncCountdown();
    });
  }

  void _syncCountdown() {
    final offer = _findOffer();
    if (offer == null) return;
    final left = offer.expiresAt.difference(DateTime.now().toUtc());
    final next = left.isNegative ? Duration.zero : left;
    final justExpired = _timeLeft > Duration.zero && next == Duration.zero;
    setState(() => _timeLeft = next);
    if (justExpired && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(lProvider).t('offer.expired'))),
      );
      // Drop stale offer from local list so Jobs tab refreshes cleanly.
      unawaited(ref.read(jobsProvider.notifier).refresh(
            ref.read(profileProvider).skills.map((s) => s.categoryCode).toList(),
            silent: true,
          ));
    }
  }

  String _formatCountdown(Duration d) {
    if (d.inDays >= 1) {
      final h = d.inHours % 24;
      return '${d.inDays}d ${h}h';
    }
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }

  Future<void> _ensureOffer() async {
    final id = widget.offerId;
    if (id == null || id.isEmpty) return;
    if (_findOffer() != null) return;
    setState(() {
      _loadingOffer = true;
      _loadError = null;
    });
    try {
      final offer = await ref.read(repositoryProvider).fetchOffer(id);
      if (!mounted) return;
      setState(() {
        _fetched = offer;
        _loadingOffer = false;
        if (offer == null) {
          _loadError = 'This offer is no longer available.';
        }
      });
      // Keep jobs list in sync for accept/reject.
      if (offer != null) {
        final skills = ref.read(profileProvider).skills.map((s) => s.categoryCode).toList();
        unawaited(ref.read(jobsProvider.notifier).refresh(skills));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingOffer = false;
        _loadError = e is ApiException ? e.message : 'Could not load offer.';
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  JobOffer? _findOffer() {
    if (_fetched != null && (widget.offerId == null || _fetched!.id == widget.offerId)) {
      return _fetched;
    }
    final offers = ref.read(jobsProvider).offers;
    for (final o in offers) {
      if (o.id == widget.offerId) return o;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final jobs = ref.watch(jobsProvider);
    final active = jobs.activeJob;
    final busy = active != null &&
        active.status != BookingStatus.completed &&
        active.status != BookingStatus.cancelled;
    final offer = _findOffer();
    if (_loadingOffer && offer == null) {
      return AppPage(
        title: l.t('offer.title'),
        fallbackRoute: Routes.home,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (offer == null) {
      return AppPage(
        title: l.t('offer.title'),
        fallbackRoute: Routes.home,
        child: Center(
          child: Text(_loadError ?? 'This offer is no longer available.'),
        ),
      );
    }
    final cat = supportedCategories.firstWhere(
      (c) => c.code == offer.categoryCode,
      orElse: () => supportedCategories.first,
    );
    final startLabel = _fmtTime(offer.preferredTime);
    final leftLabel = _formatCountdown(_timeLeft);
    final hasTimeLeft = _timeLeft > Duration.zero;
    final mapH = context.responsive<double>(xs: 150, sm: 170, md: 200);
    final hasLoc = offer.hasServiceLocation;

    return AppPage(
      title: l.t('offer.title'),
      fallbackRoute: Routes.home,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // Countdown until scheduled work start — reject anytime before then.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.brandAccentLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.brandAccentBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: AppTheme.brandAccentText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasTimeLeft
                        ? l.t('offer.timer_left', {'time': leftLabel})
                        : l.t('offer.timer', {'time': startLabel}),
                    style: const TextStyle(
                      color: AppTheme.brandAccentText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Service pin so the pro can decide accept / reject before starting.
          if (hasLoc) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: SizedBox(
                height: mapH,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MapPreview(
                        latitude: offer.customerLat!,
                        longitude: offer.customerLng!,
                        radiusKm: offer.distanceKm.clamp(1, 25),
                        caption:
                            '${offer.distanceKm.toStringAsFixed(1)} km · Tap to preview route',
                      ),
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _openServiceLocation(context, offer),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Material(
                          color: Colors.white,
                          elevation: 2,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _openServiceLocation(context, offer),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.directions,
                                      size: 16, color: AppTheme.brandPrimary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Maps',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: AppTheme.brandPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check the service location before you accept.',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.brandPrimaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(cat.icon,
                            color: AppTheme.brandPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cat.name(lang),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                            Text(offer.code,
                                style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _row(Icons.report_problem_outlined, 'Problem',
                      offer.problem, multi: true),
                  const SizedBox(height: 10),
                  _row(Icons.person_outline, 'Customer', offer.customerName),
                  const SizedBox(height: 10),
                  _row(
                    Icons.location_on_outlined,
                    'Area',
                    '${offer.customerAreaName} (${offer.distanceKm.toStringAsFixed(1)} km)',
                  ),
                  const SizedBox(height: 10),
                  _row(Icons.schedule, 'Preferred',
                      _fmtTime(offer.preferredTime)),
                  const SizedBox(height: 10),
                  _row(Icons.currency_rupee, 'Visit fee',
                      formatPaise(offer.visitFeePaise)),
                  if (offer.commissionPreview != null) ...[
                    const SizedBox(height: 10),
                    _row(
                      Icons.account_balance_wallet_outlined,
                      'Your credit',
                      formatPaise(offer.commissionPreview!.proCreditPaise),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TrustBanner(
            tone: offer.commissionPreview?.isFreeBooking == true
                ? TrustBannerTone.success
                : TrustBannerTone.info,
            icon: Icons.shield,
            text: offer.commissionPreview?.label ??
                'Visit fee is paid by the customer after work is done. Platform fee is on visit charge only.',
          ),
        ],
      ),
      bottom: LayoutBuilder(builder: (ctx, bc) {
        final tight = bc.maxWidth < 320;
        final reject = OutlinedButton(
          onPressed: !hasTimeLeft || !offer.canReject
              ? null
              : () async {
                  try {
                    await ref.read(jobsProvider.notifier).reject(offer);
                    if (ctx.mounted) context.pop();
                  } catch (e) {
                    if (!ctx.mounted) return;
                    final msg = e is ApiException
                        ? e.message
                        : 'Could not reject offer';
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  }
                },
          child: Text(l.t('offer.reject')),
        );
        final accept = FilledButton(
          onPressed: !hasTimeLeft
              ? () {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(l.t('offer.expired'))),
                  );
                }
              : busy
                  ? () {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(l.t('offer.finish_before_accept')),
                        ),
                      );
                    }
                  : () async {
                      try {
                        await ref.read(jobsProvider.notifier).accept(offer);
                        if (ctx.mounted) context.go(Routes.activeJob);
                      } catch (e) {
                        if (!ctx.mounted) return;
                        final msg = e is ApiException
                            ? e.message
                            : 'Could not accept offer';
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(msg)),
                        );
                        if (e is ApiException && e.code == 'offer_expired') {
                          unawaited(ref.read(jobsProvider.notifier).refresh(
                                ref
                                    .read(profileProvider)
                                    .skills
                                    .map((s) => s.categoryCode)
                                    .toList(),
                                silent: true,
                              ));
                        }
                      }
                    },
          style: FilledButton.styleFrom(
            backgroundColor:
                !hasTimeLeft || busy ? AppTheme.textFaint : null,
          ),
          child: Text(
            hasTimeLeft ? l.t('offer.accept') : l.t('offer.expired_short'),
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
            const SizedBox(width: 12),
            Expanded(child: accept),
          ],
        );
      }),
    );
  }

  Future<void> _openServiceLocation(BuildContext context, JobOffer offer) async {
    if (!offer.hasServiceLocation) return;
    await MapsLauncher.openDirections(
      context,
      destLat: offer.customerLat!,
      destLng: offer.customerLng!,
      label: offer.customerAreaName,
    );
  }

  Widget _row(IconData icon, String label, String value,
      {bool multi = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: 10),
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: multi ? 4 : 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  String _fmtTime(DateTime t) => IstTime.format(t, pattern: 'EEE, d MMM · h:mm a');
}
