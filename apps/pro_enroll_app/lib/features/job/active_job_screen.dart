import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/contact_launcher.dart';
import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../core/location_service.dart';
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

class ActiveJobScreen extends ConsumerStatefulWidget {
  const ActiveJobScreen({super.key});

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen> {
  bool _completing = false;
  bool _cancelling = false;
  /// Locks On the way / Arrived / Start so a double-tap cannot skip a step.
  bool _advancing = false;
  Timer? _advanceCooldown;
  Timer? _locationTimer;
  BookingStatus? _lastTrackedStatus;

  @override
  void dispose() {
    _locationTimer?.cancel();
    _advanceCooldown?.cancel();
    super.dispose();
  }

  bool get _ctaLocked => _advancing || _completing || _cancelling;

  bool _isTrackableStatus(BookingStatus s) =>
      s == BookingStatus.accepted ||
      s == BookingStatus.onTheWay ||
      s == BookingStatus.arrived;

  /// Cancel only before "Start work", and under daily cancel limit.
  bool _canShowCancel(ActiveJob job) {
    if (!job.canCancel) return false;
    return job.status == BookingStatus.accepted ||
        job.status == BookingStatus.onTheWay ||
        job.status == BookingStatus.arrived;
  }

  void _syncLocationSharing(BookingStatus? status) {
    _locationTimer?.cancel();
    _locationTimer = null;
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MapPreview(
                      latitude: mapLat,
                      longitude: mapLng,
                      radiusKm: job.distanceKm.clamp(1, 25),
                      caption: '${job.distanceKm.toStringAsFixed(1)} km away · Tap for route',
                    ),
                    // Tap / double-tap → Google Maps route (current location → service).
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openServiceRoute(
                            context,
                            lat: mapLat,
                            lng: mapLng,
                            label: job.customerAddress,
                          ),
                          onDoubleTap: () => _openServiceRoute(
                            context,
                            lat: mapLat,
                            lng: mapLng,
                            label: job.customerAddress,
                          ),
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
                          onTap: () => _openServiceRoute(
                            context,
                            lat: mapLat,
                            lng: mapLng,
                            label: job.customerAddress,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.directions,
                                  size: 16,
                                  color: AppTheme.brandPrimary,
                                ),
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
                  InkWell(
                    onTap: () => _openServiceRoute(
                      context,
                      lat: mapLat,
                      lng: mapLng,
                      label: job.customerAddress,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppTheme.brandPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            job.customerAddress,
                            style: const TextStyle(
                              color: AppTheme.brandPrimary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: AppTheme.brandPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                    final navigate = FilledButton.icon(
                      onPressed: () => _openServiceRoute(
                        context,
                        lat: mapLat,
                        lng: mapLng,
                        label: job.customerAddress,
                      ),
                      icon: const Icon(Icons.directions),
                      label: const Text('Navigate'),
                    );
                    if (tight) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          navigate,
                          const SizedBox(height: 8),
                          call,
                          const SizedBox(height: 8),
                          chat,
                        ],
                      );
                    }
                    return Column(
                      children: [
                        SizedBox(width: double.infinity, child: navigate),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: call),
                            const SizedBox(width: 10),
                            Expanded(child: chat),
                          ],
                        ),
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
          if (job.status == BookingStatus.awaitingPayment)
            _PaymentReceivedCard(
              visitFeePaise: job.visitFeePaise,
              confirming: _completing,
              onConfirm: _onConfirmPayment,
            ),
          if (job.status == BookingStatus.completed) _CompletedSummary(job: job),
          if (_canShowCancel(job)) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _cancelling ? null : () => _cancelJob(l, job),
              icon: _cancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel_outlined, color: AppTheme.brandDanger),
              label: Text(
                l.t('job.cancel'),
                style: const TextStyle(color: AppTheme.brandDanger),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.t('job.cancel_hint'),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
              textAlign: TextAlign.center,
            ),
            if (job.cancelsRemainingToday != null) ...[
              const SizedBox(height: 4),
              Text(
                '${job.cancelsRemainingToday}/${job.dailyCancelLimit} cancels left today',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ] else if ((job.cancelsRemainingToday ?? 1) <= 0 &&
              (job.status == BookingStatus.accepted ||
                  job.status == BookingStatus.onTheWay ||
                  job.status == BookingStatus.arrived)) ...[
            const SizedBox(height: 16),
            Text(
              'Daily cancel limit reached (${job.dailyCancelLimit}/day). Try again tomorrow.',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 28),
        ],
      ),
      bottom: _bottomCta(context, job, l),
    );
  }

  Future<void> _openServiceRoute(
    BuildContext context, {
    required double lat,
    required double lng,
    String? label,
  }) async {
    double? originLat;
    double? originLng;
    try {
      final loc = await LocationService.getCurrentLocation()
          .timeout(const Duration(seconds: 4), onTimeout: () => null);
      if (loc != null) {
        originLat = loc.latitude;
        originLng = loc.longitude;
      }
    } catch (_) {}

    if (!context.mounted) return;
    await MapsLauncher.openDirections(
      context,
      destLat: lat,
      destLng: lng,
      originLat: originLat,
      originLng: originLng,
      label: label,
    );
  }

  Future<void> _cancelJob(L l, ActiveJob job) async {
    String? reason;
    if (job.rejectRequiresReason) {
      reason = await _pickRejectReason(l, job.rejectPenaltyPaise);
      if (reason == null || !mounted) return;
    } else {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.t('job.cancel')),
          content: Text(l.t('job.cancel_hint')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep job'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.t('job.cancel')),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _cancelling = true);
    try {
      await ref.read(jobsProvider.notifier).cancelActive(reason: reason);
      if (!mounted) return;
      context.go(Routes.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException ? e.message : 'Could not reject job',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  /// Mandatory reason picker for rejecting while on the way (en_route).
  /// Returns the chosen reason (with optional note) or null if cancelled.
  Future<String?> _pickRejectReason(L l, int penaltyPaise) {
    const reasonKeys = [
      'job.reject_reason.customer_unreachable',
      'job.reject_reason.wrong_address',
      'job.reject_reason.too_far',
      'job.reject_reason.vehicle_issue',
      'job.reject_reason.emergency',
      'job.reject_reason.other',
    ];

    return showDialog<String>(
      context: context,
      builder: (ctx) {
        String? selectedKey;
        final noteCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(l.t('job.reject_reason_title')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (penaltyPaise > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.brandDanger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: AppTheme.brandDanger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l.t('job.reject_penalty_warning').replaceAll(
                                      '{amount}',
                                      formatPaise(penaltyPaise),
                                    ),
                                style: const TextStyle(
                                    color: AppTheme.brandDanger, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (final key in reasonKeys)
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: key,
                        groupValue: selectedKey,
                        title: Text(l.t(key)),
                        onChanged: (v) => setDialogState(() => selectedKey = v),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      maxLength: 160,
                      decoration: InputDecoration(
                        labelText: l.t('job.reject_reason_notes'),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Keep job'),
                ),
                FilledButton(
                  onPressed: selectedKey == null
                      ? null
                      : () {
                          final label = l.t(selectedKey!);
                          final note = noteCtrl.text.trim();
                          Navigator.pop(
                            ctx,
                            note.isEmpty ? label : '$label — $note',
                          );
                        },
                  child: Text(l.t('job.cancel')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget? _bottomCta(BuildContext context, ActiveJob job, L l) {
    Widget loadingLabel(String text) {
      if (!_advancing) return Text(text);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(text),
        ],
      );
    }

    switch (job.status) {
      case BookingStatus.accepted:
        return FilledButton.icon(
          onPressed: _ctaLocked
              ? null
              : () => _advanceStatus(BookingStatus.onTheWay, l),
          icon: const Icon(Icons.directions),
          label: loadingLabel(l.t('job.on_the_way')),
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
              onPressed: _ctaLocked ? null : () => _markArrived(job, l),
              icon: const Icon(Icons.location_on),
              label: loadingLabel(l.t('job.arrived')),
            ),
          ],
        );
      case BookingStatus.arrived:
        return FilledButton.icon(
          onPressed: _ctaLocked
              ? null
              : () async {
                  _locationTimer?.cancel();
                  _locationTimer = null;
                  await _advanceStatus(BookingStatus.inProgress, l);
                },
          icon: const Icon(Icons.handyman),
          label: loadingLabel(l.t('job.start')),
        );
      case BookingStatus.inProgress:
        return null;
      case BookingStatus.awaitingPayment:
        return null;
      case BookingStatus.completed:
        return FilledButton(
          onPressed: _ctaLocked
              ? null
              : () {
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

  Future<void> _advanceStatus(BookingStatus status, L l) async {
    if (_advancing) return;
    final current = ref.read(jobsProvider).activeJob?.status;
    if (current == null) return;
    // Ignore stale taps that target a status that is not the next step.
    final expectedFrom = switch (status) {
      BookingStatus.onTheWay => {
          BookingStatus.accepted,
          BookingStatus.onTheWay,
        },
      BookingStatus.arrived => {BookingStatus.onTheWay},
      BookingStatus.inProgress => {BookingStatus.arrived},
      _ => <BookingStatus>{},
    };
    if (expectedFrom.isNotEmpty && !expectedFrom.contains(current)) {
      return;
    }
    if (current == status) return;

    setState(() => _advancing = true);
    try {
      await ref.read(jobsProvider.notifier).updateStatus(status);
      // Brief cooldown so the next CTA cannot receive the same double-tap.
      _advanceCooldown?.cancel();
      _advanceCooldown = Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _advancing = false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _advancing = false);
      final msg = e is ApiException
          ? e.message
          : l.t('job.finish_current_first');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  /// Allow "I've arrived" only when within ~250 m of the customer pin.
  Future<void> _markArrived(ActiveJob job, L l) async {
    if (_advancing) return;
    setState(() => _advancing = true);
    try {
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
            setState(() => _advancing = false);
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
      // Re-check status before advancing (another tap / refresh may have moved it).
      final latest = ref.read(jobsProvider).activeJob;
      if (latest == null || latest.status != BookingStatus.onTheWay) {
        if (mounted) setState(() => _advancing = false);
        return;
      }
      await ref.read(jobsProvider.notifier).updateStatus(BookingStatus.arrived);
      _advanceCooldown?.cancel();
      _advanceCooldown = Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _advancing = false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _advancing = false);
      final msg = e is ApiException ? e.message : l.t('job.finish_current_first');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _onComplete() async {
    if (_completing || _advancing) return;
    setState(() => _completing = true);
    try {
      await ref.read(jobsProvider.notifier).complete();
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _onConfirmPayment() async {
    if (_completing || _advancing) return;
    setState(() => _completing = true);
    try {
      await ref.read(jobsProvider.notifier).confirmPaymentReceived();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded · Job completed')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not confirm payment: $e')),
        );
      }
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
      case BookingStatus.awaitingPayment:
        return 'Awaiting payment';
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
      case BookingStatus.awaitingPayment:
        return AppTheme.brandAccentDark;
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
              'Mark work done. Customer can pay ${formatPaise(visitFeePaise)} in the app, '
              'or you can confirm cash/UPI received on the next step.',
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

class _PaymentReceivedCard extends StatelessWidget {
  const _PaymentReceivedCard({
    required this.visitFeePaise,
    required this.confirming,
    required this.onConfirm,
  });

  final int visitFeePaise;
  final bool confirming;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment received?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Waiting for visit fee ${formatPaise(visitFeePaise)}. '
              'If the customer paid cash or UPI outside the app, confirm below to complete the job.',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: confirming ? null : onConfirm,
                icon: confirming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.payments_outlined),
                label: Text(
                  confirming ? 'Saving…' : 'Payment received · ${formatPaise(visitFeePaise)}',
                ),
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
