import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/contact_launcher.dart';
import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../core/location_service.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../../state/locale_state.dart';
import '../shared/map_preview.dart';
import '../shared/widgets.dart';

class ActiveJobScreen extends ConsumerStatefulWidget {
  const ActiveJobScreen({super.key});

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen> {
  bool _completing = false;
  Timer? _locationTimer;
  BookingStatus? _lastTrackedStatus;

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  bool _isTrackableStatus(BookingStatus s) =>
      s == BookingStatus.accepted ||
      s == BookingStatus.onTheWay ||
      s == BookingStatus.arrived;

  void _syncLocationSharing(BookingStatus? status) {
    _locationTimer?.cancel();
    if (status == null || !_isTrackableStatus(status)) return;
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) => _pingLocation());
    unawaited(_pingLocation());
  }

  Future<void> _pingLocation() async {
    if (!mounted) return;
    final job = ref.read(jobsProvider).activeJob;
    if (job == null || !_isTrackableStatus(job.status)) return;
    final result = await LocationService.getCurrentLocationDetailed(
      timeout: const Duration(seconds: 10),
    );
    if (!result.isOk || !mounted) return;
    await ref.read(jobsProvider.notifier).pingLocation(
          result.location!.latitude,
          result.location!.longitude,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final job = ref.watch(jobsProvider).activeJob;

    if (job != null && job.status != _lastTrackedStatus) {
      _lastTrackedStatus = job.status;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncLocationSharing(job.status);
      });
    } else if (job == null && _lastTrackedStatus != null) {
      _lastTrackedStatus = null;
      _locationTimer?.cancel();
    }

    if (job == null) {
      return AppPage(
        title: 'Active job',
        fallbackRoute: Routes.home,
        child: const Center(child: Text('No active job.')),
      );
    }
    final cat = supportedCategories.firstWhere(
      (c) => c.code == job.categoryCode,
      orElse: () => supportedCategories.first,
    );
    final mapH = context.responsive<double>(xs: 150, sm: 170, md: 200);
    final fallbackCity =
        cityById(ref.watch(profileProvider).cityId ?? supportedCities.first.id);
    final mapLat = job.customerLat ?? fallbackCity.latitude;
    final mapLng = job.customerLng ?? fallbackCity.longitude;

    return AppPage(
      title: cat.name(lang),
      fallbackRoute: Routes.home,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          StatusPill(
            label: _statusLabel(job.status),
            color: _statusColor(job.status),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: SizedBox(
              height: mapH,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: MapPreview(
                  latitude: mapLat,
                  longitude: mapLng,
                  radiusKm: job.distanceKm.clamp(1, 25),
                  caption: '${job.distanceKm.toStringAsFixed(1)} km away',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    job.customerAddress,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(builder: (ctx, bc) {
                    final tight = bc.maxWidth < 300;
                    final call = OutlinedButton.icon(
                      onPressed: () =>
                          ContactLauncher.call(context, job.customerPhoneE164),
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                    );
                    final chat = OutlinedButton.icon(
                      onPressed: () => ContactLauncher.chat(
                        context,
                        job.customerPhoneE164,
                        message:
                            'Hi, I am on the way for your ${cat.name(lang)} request.',
                      ),
                      icon: const Icon(Icons.chat),
                      label: const Text('Chat'),
                    );
                    if (tight) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [call, const SizedBox(height: 8), chat],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: call),
                        const SizedBox(width: 10),
                        Expanded(child: chat),
                      ],
                    );
                  }),
                ],
              ),
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
                      const Icon(Icons.tag, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        job.code,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.problem,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.currency_rupee,
                        size: 18,
                        color: AppTheme.textMuted,
                      ),
                      Text(
                        'Visit fee: ${formatPaise(job.visitFeePaise)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (job.commissionPreview != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      job.commissionPreview!.label ??
                          (job.commissionPreview!.isFreeBooking
                              ? 'Free booking — full visit fee credited to you'
                              : 'You receive ${formatPaise(job.commissionPreview!.proCreditPaise)} after platform fee'),
                      style: TextStyle(
                        color: job.commissionPreview!.isFreeBooking
                            ? AppTheme.brandSuccess
                            : AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (job.status == BookingStatus.inProgress)
            _CompleteCard(
              visitFeePaise: job.visitFeePaise,
              completing: _completing,
              onComplete: _onComplete,
            ),
          if (job.status == BookingStatus.completed) _CompletedSummary(job: job),
          const SizedBox(height: 28),
        ],
      ),
      bottom: _bottomCta(context, job, l),
    );
  }

  Widget? _bottomCta(BuildContext context, ActiveJob job, L l) {
    switch (job.status) {
      case BookingStatus.accepted:
        return FilledButton.icon(
          onPressed: () async => ref
              .read(jobsProvider.notifier)
              .updateStatus(BookingStatus.onTheWay),
          icon: const Icon(Icons.directions),
          label: Text(l.t('job.on_the_way')),
        );
      case BookingStatus.onTheWay:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.t('job.arrive_first'),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _markArrived(job, l),
              icon: const Icon(Icons.location_on),
              label: Text(l.t('job.arrived')),
            ),
          ],
        );
      case BookingStatus.arrived:
        return FilledButton.icon(
          onPressed: () async => ref
              .read(jobsProvider.notifier)
              .updateStatus(BookingStatus.inProgress),
          icon: const Icon(Icons.handyman),
          label: Text(l.t('job.start')),
        );
      case BookingStatus.inProgress:
        return null;
      case BookingStatus.completed:
        return FilledButton(
          onPressed: () {
            ref.read(jobsProvider.notifier).clearActive();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(Routes.home);
            }
          },
          child: const Text('Done'),
        );
      default:
        return null;
    }
  }

  /// Allow "I've arrived" only when within ~250 m of the customer pin.
  Future<void> _markArrived(ActiveJob job, L l) async {
    final custLat = job.customerLat;
    final custLng = job.customerLng;
    if (custLat != null && custLng != null) {
      final result = await LocationService.getCurrentLocationDetailed(
        timeout: const Duration(seconds: 10),
      );
      if (!mounted) return;
      if (result.isOk) {
        final km = LocationService.distanceKm(
          result.location!.latitude,
          result.location!.longitude,
          custLat,
          custLng,
        );
        if (km > 0.25) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.t('job.too_far'))),
          );
          return;
        }
        await ref.read(jobsProvider.notifier).pingLocation(
              result.location!.latitude,
              result.location!.longitude,
            );
      }
    }
    await ref.read(jobsProvider.notifier).updateStatus(BookingStatus.arrived);
  }

  Future<void> _onComplete() async {
    if (_completing) return;
    setState(() => _completing = true);
    try {
      await ref.read(jobsProvider.notifier).complete();
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  String _statusLabel(BookingStatus s) {
    switch (s) {
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.onTheWay:
        return 'On the way';
      case BookingStatus.arrived:
        return 'Arrived';
      case BookingStatus.inProgress:
        return 'In progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.pendingAcceptance:
        return 'Pending';
    }
  }

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.completed:
        return AppTheme.brandSuccess;
      case BookingStatus.cancelled:
        return AppTheme.brandDanger;
      case BookingStatus.inProgress:
        return AppTheme.brandAccent;
      case BookingStatus.arrived:
        return AppTheme.brandSuccess;
      default:
        return AppTheme.brandPrimary;
    }
  }
}

class _CompleteCard extends ConsumerWidget {
  const _CompleteCard({
    required this.visitFeePaise,
    required this.completing,
    required this.onComplete,
  });

  final int visitFeePaise;
  final bool completing;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(lProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.t('job.complete'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Customer will pay visit fee ${formatPaise(visitFeePaise)} in the app. '
              'Any repair cost is settled offline with the customer.',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: completing ? null : onComplete,
                child: completing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.t('job.complete')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedSummary extends StatelessWidget {
  const _CompletedSummary({required this.job});
  final ActiveJob job;

  @override
  Widget build(BuildContext context) {
    final credit = job.proCreditPaise ??
        job.commissionPreview?.proCreditPaise ??
        job.visitFeePaise;
    final preview = job.commissionPreview;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        gradient: const LinearGradient(
          colors: [AppTheme.brandPrimary, AppTheme.brandPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 10),
          const Text(
            'Job completed',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Visit fee credit ${formatPaise(credit)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (preview != null &&
              !preview.isFreeBooking &&
              preview.commissionPaise > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Platform fee ${formatPaise(preview.commissionPaise)} on visit charge',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Waiting for customer to pay visit fee. Tap Done to return to jobs.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
