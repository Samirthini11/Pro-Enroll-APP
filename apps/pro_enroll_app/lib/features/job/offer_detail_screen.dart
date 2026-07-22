import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../core/ist_time.dart';
import '../../core/theme.dart';
import '../../data/api/api_exception.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../../state/locale_state.dart';
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
  int _remaining = 60;
  JobOffer? _fetched;
  bool _loadingOffer = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(pushNotificationServiceProvider).syncTokenWithServer();
      await _ensureOffer();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = (_remaining - 1).clamp(0, 60));
      if (_remaining == 0) {
        _ticker?.cancel();
        final offer = _findOffer();
        if (offer != null) {
          ref.read(jobsProvider.notifier).reject(offer);
          if (mounted) context.pop();
        }
      }
    });
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
    ref.watch(jobsProvider); // rebuild when offers refresh
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
    final progress = _remaining / 60;

    return AppPage(
      title: l.t('offer.title'),
      fallbackRoute: Routes.home,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // Timer banner.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.brandAccentLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.brandAccentBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer, color: AppTheme.brandAccentText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.t('offer.timer', {'sec': '$_remaining'}),
                        style: const TextStyle(
                          color: AppTheme.brandAccentText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white,
                    color: AppTheme.brandAccentDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
          onPressed: () async {
            await ref.read(jobsProvider.notifier).reject(offer);
            if (ctx.mounted) context.pop();
          },
          child: Text(l.t('offer.reject')),
        );
        final accept = FilledButton(
          onPressed: () async {
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
            }
          },
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
            const SizedBox(width: 12),
            Expanded(child: accept),
          ],
        );
      }),
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
