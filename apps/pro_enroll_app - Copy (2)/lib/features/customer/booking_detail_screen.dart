import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final b = await ref.read(repositoryProvider).fetchBookingDetail(widget.bookingId);
      if (mounted) setState(() { _booking = b; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _complete() async {
    setState(() => _submitting = true);
    try {
      await ref.read(customerProvider.notifier).completeBooking(widget.bookingId);
      await _load();
      ref.read(customerProvider.notifier).loadBookings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
      return AppPage(title: 'Booking', child: const Center(child: Text('Not found')));
    }

    final cat = supportedCategories.where((c) => c.code == b.categoryCode).firstOrNull;
    final title = b.bookingCode ?? 'Booking #${b.id}';

    return AppPage(
      title: title,
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
                                  b.categoryName ?? cat?.nameEn ?? b.categoryCode,
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
                      if (b.scheduledAt != null)
                        _DetailRow(label: 'Scheduled', value: _formatDate(b.scheduledAt!)),
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
              if (b.canComplete) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _complete,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Mark as Complete'),
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
                                  color: Colors.amber.shade700,
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
                              color: Colors.amber.shade700,
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

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
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
