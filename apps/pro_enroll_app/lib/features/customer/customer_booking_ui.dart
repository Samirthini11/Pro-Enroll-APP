import 'package:flutter/material.dart';

import '../../core/contact_launcher.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../shared/widgets.dart';

/// Active booking with the same professional and service category, if any.
CustomerBooking? findActiveBookingWithPro(
  List<CustomerBooking> bookings, {
  required int professionalId,
  required String categoryCode,
}) {
  for (final b in bookings) {
    if (b.professionalId == professionalId &&
        b.categoryCode == categoryCode &&
        b.isInProcess) {
      return b;
    }
  }
  return null;
}

/// Human-readable distance from haversine km (API).
String formatDistanceKm(double? km) {
  if (km == null) return 'Distance unavailable';
  if (km < 0.1) return 'Very close';
  if (km < 1.0) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1)} km';
}

Color customerStatusColor(String status) {
  return switch (status) {
    'completed' => AppTheme.brandSuccess,
    'cancelled' => AppTheme.brandDanger,
    'awaiting_payment' => AppTheme.brandWarning,
    'en_route' || 'arrived' || 'in_progress' => AppTheme.brandPrimary,
    _ => AppTheme.brandPrimary,
  };
}

class CustomerStatusChip extends StatelessWidget {
  const CustomerStatusChip({super.key, required this.booking, this.compact = false});
  final CustomerBooking booking;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = booking.displayStatusLabel;
    final color = customerStatusColor(booking.status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class BookingAmountSummary extends StatelessWidget {
  const BookingAmountSummary({super.key, required this.booking});
  final CustomerBooking booking;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _AmountRow(
              label: 'Visit fee',
              value: formatPaise(booking.visitFeePaise),
            ),
            if (booking.visitFeePaid) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: AppTheme.brandSuccess),
                  const SizedBox(width: 6),
                  Text(
                    'Paid in app${booking.visitFeePaymentMethod != null ? ' · ${booking.visitFeePaymentMethod!.toUpperCase()}' : ''}',
                    style: const TextStyle(
                      color: AppTheme.brandSuccess,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ] else if (booking.status != 'cancelled') ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    booking.canPayVisitFee ? Icons.payment : Icons.schedule,
                    size: 16,
                    color: booking.canPayVisitFee ? AppTheme.brandWarning : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.canPayVisitFee
                          ? 'Pay visit fee now to complete this booking'
                          : 'Pay visit fee after work is done',
                      style: TextStyle(
                        color: booking.canPayVisitFee ? AppTheme.brandWarning : AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (booking.status != 'cancelled' && booking.status != 'completed') ...[
              const SizedBox(height: 8),
              const Text(
                'Visit fee is paid in the app after the job. Repair cost is settled with the technician.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.status == 'completed' ? 'Total due' : 'Visit fee total',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  formatPaise(booking.visitFeePaise),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppTheme.brandPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.muted = false,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool muted;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: muted ? AppTheme.textMuted : AppTheme.textPrimary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
            fontSize: highlight ? 16 : 14,
            color: highlight ? AppTheme.brandPrimary : (muted ? AppTheme.textMuted : null),
          ),
        ),
      ],
    );
  }
}

class BookingTrackingTimeline extends StatelessWidget {
  const BookingTrackingTimeline({super.key, required this.steps, this.status = ''});
  final List<BookingTrackingStep> steps;
  final String status;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const SizedBox.shrink();
    }

    final isCancelled = status == 'cancelled';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            for (var i = 0; i < steps.length; i++) ...[
              _TrackingRow(
                step: steps[i],
                isLast: i == steps.length - 1,
                isCancelled: isCancelled,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrackingRow extends StatelessWidget {
  const _TrackingRow({
    required this.step,
    required this.isLast,
    required this.isCancelled,
  });

  final BookingTrackingStep step;
  final bool isLast;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final isDone = step.state == 'done';
    final isActive = step.state == 'active';
    final color = isCancelled && isActive
        ? AppTheme.brandDanger
        : isDone
            ? AppTheme.brandSuccess
            : isActive
                ? AppTheme.brandPrimary
                : AppTheme.textFaint;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isDone || isActive ? color.withValues(alpha: 0.15) : AppTheme.textFaint.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: isActive ? 2 : 1),
                  ),
                  child: Icon(
                    isDone
                        ? Icons.check
                        : isCancelled && isActive
                            ? Icons.close
                            : isActive
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                    size: 12,
                    color: color,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: isDone ? AppTheme.brandSuccess.withValues(alpha: 0.4) : AppTheme.border,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Text(
                step.label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  color: isActive ? AppTheme.textPrimary : AppTheme.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact current-job progress card for the customer home dashboard.
class ActiveWorkProgressCard extends StatelessWidget {
  const ActiveWorkProgressCard({
    super.key,
    required this.booking,
    required this.onTap,
  });

  final CustomerBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final steps = booking.trackingSteps;
    BookingTrackingStep? active;
    for (final s in steps) {
      if (s.state == 'active') {
        active = s;
        break;
      }
    }
    final doneCount = steps.where((s) => s.state == 'done').length;
    final total = steps.isEmpty ? 1 : steps.length;
    final progress = steps.isEmpty
        ? 0.2
        : ((doneCount + (active != null ? 0.55 : 0)) / total).clamp(0.08, 1.0);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.brandPrimary.withValues(alpha: 0.25)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.brandPrimary.withValues(alpha: 0.06),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.handyman_outlined, size: 18, color: AppTheme.brandPrimary),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Current work',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppTheme.brandPrimary,
                      ),
                    ),
                  ),
                  CustomerStatusChip(booking: booking, compact: true),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                booking.professionalName,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                active?.label ?? booking.displayStatusLabel,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: AppTheme.border,
                  color: customerStatusColor(booking.status),
                ),
              ),
              if (steps.isNotEmpty) ...[
                const SizedBox(height: 12),
                _CompactStepRow(steps: steps, status: booking.status),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    booking.canPayVisitFee ? 'Confirm & pay visit fee' : 'View progress',
                    style: TextStyle(
                      color: booking.canPayVisitFee
                          ? AppTheme.brandWarning
                          : AppTheme.brandPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: booking.canPayVisitFee
                        ? AppTheme.brandWarning
                        : AppTheme.brandPrimary,
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

class _CompactStepRow extends StatelessWidget {
  const _CompactStepRow({required this.steps, required this.status});
  final List<BookingTrackingStep> steps;
  final String status;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Container(
                width: 14,
                height: 2,
                margin: const EdgeInsets.only(bottom: 14),
                color: steps[i - 1].state == 'done'
                    ? AppTheme.brandSuccess.withValues(alpha: 0.5)
                    : AppTheme.border,
              ),
            _MiniStepDot(step: steps[i], cancelled: status == 'cancelled'),
          ],
        ],
      ),
    );
  }
}

class _MiniStepDot extends StatelessWidget {
  const _MiniStepDot({required this.step, required this.cancelled});
  final BookingTrackingStep step;
  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    final isDone = step.state == 'done';
    final isActive = step.state == 'active';
    final color = cancelled && isActive
        ? AppTheme.brandDanger
        : isDone
            ? AppTheme.brandSuccess
            : isActive
                ? AppTheme.brandPrimary
                : AppTheme.textFaint;

    return SizedBox(
      width: 56,
      child: Column(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDone || isActive) ? color.withValues(alpha: 0.15) : AppTheme.border.withValues(alpha: 0.4),
              border: Border.all(color: color, width: isActive ? 2 : 1),
            ),
            child: Icon(
              isDone ? Icons.check : Icons.circle,
              size: isDone ? 11 : 6,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            step.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              height: 1.15,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              color: isActive || isDone ? color : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerBookingListTile extends StatelessWidget {
  const CustomerBookingListTile({
    super.key,
    required this.booking,
    this.categoryIcon,
    this.categoryName,
    required this.onTap,
  });

  final CustomerBooking booking;
  final IconData? categoryIcon;
  final String? categoryName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(categoryIcon ?? Icons.build, color: AppTheme.brandPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.professionalName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      categoryName ?? booking.categoryName ?? booking.categoryCode,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    if (booking.bookingCode != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        booking.bookingCode!,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textFaint),
                      ),
                    ],
                    const SizedBox(height: 6),
                    CustomerStatusChip(booking: booking, compact: true),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatPaise(booking.visitFeePaise),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppTheme.brandPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Visit fee',
                    style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
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

class ContactActionRow extends StatelessWidget {
  const ContactActionRow({
    super.key,
    required this.phoneE164,
    this.phoneMasked,
    this.chatMessage,
    this.title = 'Contact',
  });

  final String? phoneE164;
  final String? phoneMasked;
  final String? chatMessage;
  final String title;

  @override
  Widget build(BuildContext context) {
    final hasPhone = phoneE164 != null && phoneE164!.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (phoneMasked != null && phoneMasked!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(phoneMasked!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasPhone ? () => ContactLauncher.call(context, phoneE164) : null,
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasPhone ? () => ContactLauncher.chat(context, phoneE164, message: chatMessage) : null,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat'),
                  ),
                ),
              ],
            ),
            if (!hasPhone) ...[
              const SizedBox(height: 8),
              const Text(
                'Phone will be available once the booking is confirmed.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
