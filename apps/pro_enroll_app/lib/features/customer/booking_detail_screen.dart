import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/ist_time.dart';
import '../../core/theme.dart';
import '../../data/api/api_exception.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../../state/categories_provider.dart';
import '../../state/locale_state.dart';
import '../shared/map_preview.dart';
import '../shared/widgets.dart';
import 'customer_booking_ui.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final int bookingId;

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  CustomerBooking? _booking;
  bool _loading = true;
  int _ratingStars = 0;
  final _reviewCtrl = TextEditingController();
  bool _submitting = false;
  String _paymentMethod = 'upi';
  Timer? _trackTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _trackTimer?.cancel();
    _reviewCtrl.dispose();
    super.dispose();
  }

  void _syncTrackingTimer() {
    _trackTimer?.cancel();
    final b = _booking;
    // Poll while trackable, or while waiting for stuck-cancel unlock.
    final needsPoll = b != null &&
        mounted &&
        (b.isTrackable || (b.status == 'en_route' && !b.canCancel));
    if (needsPoll) {
      _trackTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        _refreshTracking(silent: true);
      });
    }
  }

  Future<void> _load() async {
    await _refreshTracking();
    _syncTrackingTimer();
  }

  Future<void> _refreshTracking({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final b = await ref.read(repositoryProvider).fetchBookingDetail(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = b;
          if (!silent) _loading = false;
        });
        if (silent) _syncTrackingTimer();
      }
    } catch (_) {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _payVisitFee() async {
    setState(() => _submitting = true);
    try {
      final b = await ref.read(customerProvider.notifier).payVisitFee(
            widget.bookingId,
            paymentMethod: _paymentMethod,
          );
      if (mounted) {
        setState(() => _booking = b);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Confirmed · Visit fee paid · ${formatPaise(b.visitFeePaise)}'),
            backgroundColor: AppTheme.brandSuccess,
          ),
        );
      }
      ref.read(customerProvider.notifier).loadBookings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  Future<void> _cancel() async {
    final booking = _booking;
    final isStuckCancel = booking?.status == 'en_route';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text(
          isStuckCancel
              ? 'The technician has not moved for a while. Cancel so you can book another technician. No visit fee is charged.'
              : 'You can cancel free before the technician starts heading your way. No visit fee is charged at booking time.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep booking')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.brandDanger),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await ref.read(customerProvider.notifier).cancelBooking(widget.bookingId);
      ref.read(customerProvider.notifier).loadBookings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled'),
            backgroundColor: AppTheme.brandDanger,
          ),
        );
        // Leave detail so Back never exits the app on an empty stack.
        context.go(Routes.customerBookings);
      }
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException ? e.message : 'Could not cancel: $e';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  Future<void> _submitRating() async {
    if (_ratingStars < 1) return;
    setState(() => _submitting = true);
    try {
      await ref.read(customerProvider.notifier).rateBooking(
            widget.bookingId,
            stars: _ratingStars,
            reviewText: _reviewCtrl.text.trim().isNotEmpty ? _reviewCtrl.text.trim() : null,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for your rating!'), backgroundColor: AppTheme.brandSuccess),
        );
        context.go(Routes.customerHome);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _booking == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final b = _booking;
    if (b == null) {
      return AppPage(
        title: 'Booking',
        fallbackRoute: Routes.customerHome,
        child: const Center(child: Text('Not found')),
      );
    }

    final cat = ref.watch(categoriesListProvider).tryByCode(b.categoryCode) ??
        supportedCategories.tryByCode(b.categoryCode);
    final lang = ref.watch(localeProvider).languageCode;
    final title = b.bookingCode ?? 'Booking #${b.id}';

    return AppPage(
      title: title,
      fallbackRoute: Routes.customerHome,
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(cat?.icon ?? Icons.build, color: AppTheme.brandPrimary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.professionalName,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  cat?.name(lang) ?? b.categoryName ?? b.categoryCode,
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          CustomerStatusChip(booking: b),
                        ],
                      ),
                      const Divider(height: 24),
                      _DetailRow(label: 'Problem', value: b.problemDescription),
                      _DetailRow(label: 'Address', value: b.addressText),
                      _DetailRow(
                        label: 'City',
                        value: b.cityName?.isNotEmpty == true ? b.cityName! : cityById(b.cityId).name,
                      ),
                      if (b.isTrackable && b.addressLat != null && b.addressLng != null) ...[
                        const SizedBox(height: 10),
                        _LiveTrackingCard(booking: b),
                      ] else if (b.addressLat != null && b.addressLng != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 160,
                            child: MapPreview(
                              latitude: b.addressLat!,
                              longitude: b.addressLng!,
                              radiusKm: 1,
                              caption: 'Confirmed service location',
                            ),
                          ),
                        ),
                      ],
                      if (b.scheduledAt != null)
                        _DetailRow(label: 'Scheduled', value: _formatDate(b.scheduledAt!)),
                      if (b.acceptedAt != null)
                        _DetailRow(label: 'Accepted', value: _formatDate(b.acceptedAt!)),
                      _DetailRow(label: 'Booked', value: _formatDate(b.createdAt)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (b.canContactProfessional)
                ContactActionRow(
                  title: 'Contact technician',
                  phoneE164: b.professionalPhoneE164,
                  phoneMasked: b.professionalPhoneMasked,
                  chatMessage:
                      'Hi ${b.professionalName}, regarding booking ${b.bookingCode ?? '#${b.id}'} for ${b.problemDescription}.',
                ),
              if (b.canContactProfessional) const SizedBox(height: 12),
              BookingTrackingTimeline(steps: b.trackingSteps, status: b.status),
              const SizedBox(height: 12),
              BookingAmountSummary(booking: b),
              const SizedBox(height: 16),
              if (b.canCancel) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _submitting ? null : _cancel,
                    icon: const Icon(Icons.cancel_outlined, color: AppTheme.brandDanger),
                    label: Text(
                      b.status == 'en_route'
                          ? 'Cancel & book another'
                          : 'Cancel booking',
                      style: const TextStyle(color: AppTheme.brandDanger, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.brandDanger),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  b.cancelHint ??
                      (b.status == 'en_route'
                          ? 'Technician has not moved. You can cancel and book another technician.'
                          : 'You can cancel until the technician starts heading your way.'),
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                if (b.cancelsRemainingToday != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${b.cancelsRemainingToday}/${b.dailyCancelLimit} cancels left today',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 16),
              ] else if (b.cancelHint != null &&
                  (b.status == 'en_route' ||
                      (b.cancelsRemainingToday != null &&
                          b.cancelsRemainingToday! <= 0))) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.brandAccentLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.brandAccentBorder),
                  ),
                  child: Text(
                    b.cancelHint!,
                    style: const TextStyle(
                      color: AppTheme.brandAccentText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (b.canPayVisitFee) ...[
                Text('Confirm & pay visit fee', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                const Text(
                  'Paying confirms the work is done and closes this booking.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _PayMethodTile(
                  value: 'upi',
                  groupValue: _paymentMethod,
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'UPI',
                  subtitle: 'GPay / PhonePe / Paytm',
                  onChanged: (v) => setState(() => _paymentMethod = v),
                ),
                _PayMethodTile(
                  value: 'card',
                  groupValue: _paymentMethod,
                  icon: Icons.credit_card,
                  title: 'Debit / Credit card',
                  subtitle: 'Visa, Mastercard, RuPay',
                  onChanged: (v) => setState(() => _paymentMethod = v),
                ),
                _PayMethodTile(
                  value: 'netbanking',
                  groupValue: _paymentMethod,
                  icon: Icons.account_balance,
                  title: 'Net banking',
                  subtitle: 'All major banks',
                  onChanged: (v) => setState(() => _paymentMethod = v),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _payVisitFee,
                    icon: const Icon(Icons.payment),
                    label: Text('Confirm & pay ${formatPaise(b.visitFeePaise)}'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (b.canRate) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rate this service', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Center(
                          child: Wrap(
                            children: List.generate(5, (i) {
                              return IconButton(
                                onPressed: () => setState(() => _ratingStars = i + 1),
                                icon: Icon(
                                  i < _ratingStars ? Icons.star : Icons.star_border,
                                  color: AppTheme.brandAccentDark,
                                  size: 32,
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _reviewCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Write a review (optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _ratingStars > 0 && !_submitting ? _submitRating : null,
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Submit Rating'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (b.rating != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Rating', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < b.rating!.stars ? Icons.star : Icons.star_border,
                              color: AppTheme.brandAccentDark,
                              size: 22,
                            ),
                          ),
                        ),
                        if (b.rating!.reviewText != null && b.rating!.reviewText!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(b.rating!.reviewText!, style: const TextStyle(color: AppTheme.textMuted)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => IstTime.formatDateTime(dt);
}

class _LiveTrackingCard extends StatelessWidget {
  const _LiveTrackingCard({required this.booking});
  final CustomerBooking booking;

  @override
  Widget build(BuildContext context) {
    final tracking = booking.tracking;
    final etaLabel = tracking != null && tracking.etaMinutes > 0
        ? '~${tracking.etaMinutes} min'
        : 'Calculating…';
    final distanceLabel = tracking != null
        ? formatDistanceKm(tracking.distanceKm)
        : 'Updating location…';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brandSuccess.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.near_me, color: AppTheme.brandSuccess, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.professionalName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      Text(
                        booking.displayStatusLabel,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      etaLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppTheme.brandPrimary,
                      ),
                    ),
                    Text(
                      distanceLabel,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: MapPreview(
              latitude: booking.addressLat!,
              longitude: booking.addressLng!,
              secondaryLat: tracking?.proLat,
              secondaryLng: tracking?.proLng,
              radiusKm: (tracking?.distanceKm ?? 2).clamp(1, 15),
              caption: tracking != null
                  ? 'Technician · $distanceLabel · ETA $etaLabel'
                  : 'Waiting for technician location…',
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Text(
              'Live location updates every few seconds while your technician is on the way.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 72, child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12))),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}

class _PayMethodTile extends StatelessWidget {
  const _PayMethodTile({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final String value;
  final String groupValue;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppTheme.brandPrimaryLight : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: selected ? AppTheme.brandPrimary : AppTheme.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: selected ? AppTheme.brandPrimary : AppTheme.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Radio<String>(
                  value: value,
                  groupValue: groupValue,
                  onChanged: (v) {
                    if (v != null) onChanged(v);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
