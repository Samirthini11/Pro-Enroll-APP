import 'dart:async';

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

class OfferDetailScreen extends ConsumerStatefulWidget {
  const OfferDetailScreen({super.key, this.offerId});
  final String? offerId;

  @override
  ConsumerState<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends ConsumerState<OfferDetailScreen> {
  Timer? _ticker;
  int _remaining = 60;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  JobOffer? _findOffer() {
    final offers = ref.read(jobsProvider).offers;
    for (final o in offers) {
      if (o.id == widget.offerId) return o;
    }
    return offers.isEmpty ? null : offers.first;
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final offer = _findOffer();
    if (offer == null) {
      return AppPage(
        title: l.t('offer.title'),
        child: const Center(child: Text('This offer is no longer available.')),
      );
    }
    final cat = supportedCategories.firstWhere(
      (c) => c.code == offer.categoryCode,
      orElse: () => supportedCategories.first,
    );
    return AppPage(
      title: l.t('offer.title'),
      child: ListView(
        children: [
          // Timer banner.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Color(0xFFB45309)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.t('offer.timer', {'sec': '$_remaining'}),
                    style: const TextStyle(
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.w700,
                    ),
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
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(cat.icon,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.name(lang),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          Text(offer.code,
                              style: const TextStyle(
                                  color: Color(0xFF64748B), fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _row(Icons.report_problem_outlined, 'Problem', offer.problem),
                  const SizedBox(height: 8),
                  _row(Icons.person_outline, 'Customer', offer.customerName),
                  const SizedBox(height: 8),
                  _row(Icons.location_on_outlined, 'Area',
                      '${offer.customerAreaName} (${offer.distanceKm.toStringAsFixed(1)} km)'),
                  const SizedBox(height: 8),
                  _row(Icons.schedule, 'Preferred time',
                      _fmtTime(offer.preferredTime)),
                  const SizedBox(height: 8),
                  _row(Icons.currency_rupee, 'Visit fee',
                      formatPaise(offer.visitFeePaise)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const TrustBanner(
            text:
                'Customer pre-paid the visit fee. You will receive it via payout.',
            icon: Icons.shield,
          ),
        ],
      ),
      bottom: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                ref.read(jobsProvider.notifier).reject(offer);
                context.pop();
              },
              child: Text(l.t('offer.reject')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: () {
                ref.read(jobsProvider.notifier).accept(offer);
                context.go(Routes.activeJob);
              },
              child: Text(l.t('offer.accept')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(color: Color(0xFF64748B))),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  String _fmtTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final ap = t.hour >= 12 ? 'PM' : 'AM';
    final m = t.minute.toString().padLeft(2, '0');
    return 'Today $h:$m $ap';
  }
}
