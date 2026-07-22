import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../shared/widgets.dart';
import 'customer_route_params.dart';
import 'customer_booking_ui.dart';

class ProDetailScreen extends ConsumerStatefulWidget {
  const ProDetailScreen({super.key, required this.params});
  final Map<String, dynamic> params;

  @override
  ConsumerState<ProDetailScreen> createState() => _ProDetailScreenState();
}

class _ProDetailScreenState extends ConsumerState<ProDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    Future.microtask(() => ref.read(customerProvider.notifier).loadBookings());
  }

  Future<void> _load() async {
    final proId = parseRouteInt(widget.params['pro_id']);
    final catCode = widget.params['category_code'] as String?;
    final lat = parseRouteDouble(widget.params['lat']);
    final lng = parseRouteDouble(widget.params['lng']);
    if (proId < 1) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final data = await ref.read(repositoryProvider).fetchProDetail(
            proId,
            categoryCode: catCode,
            lat: lat,
            lng: lng,
          );
      if (mounted) setState(() { _detail = data; _loading = false; });
    } catch (e) {
      debugPrint('fetchProDetail: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_detail == null) {
      return AppPage(
        title: 'Professional',
        child: const Center(child: Text('Could not load details')),
      );
    }

    final d = _detail!;
    final name = d['full_name'] as String? ?? '';
    final ratingAvg = (d['rating_avg'] as num?)?.toDouble() ?? 0;
    final ratingCount = (d['rating_count'] as num?)?.toInt() ?? 0;
    final jobsCompleted = (d['jobs_completed'] as num?)?.toInt() ?? 0;
    final visitFeePaise = (d['visit_fee_paise'] as num?)?.toInt() ?? 0;
    final cityId = (d['city_id'] as num?)?.toInt() ?? 1;
    final isAvailable = d['is_available'] == true;
    final distanceKm = (d['distance_km'] as num?)?.toDouble();
    final phoneE164 = d['phone_e164'] as String?;
    final phoneMasked = d['phone_masked'] as String?;
    final skills = d['skills'] as List? ?? [];
    final proId = parseRouteInt(widget.params['pro_id']);
    final catCode = widget.params['category_code'] as String? ??
        (skills.isNotEmpty ? skills[0]['category_code'] as String? : 'ac');
    final isCompact = context.deviceSize == DeviceSize.xs;
    final bookings = ref.watch(customerProvider).bookings;
    final activeBooking = findActiveBookingWithPro(
      bookings,
      professionalId: proId,
      categoryCode: catCode ?? 'ac',
    );
    final canBook = isAvailable && activeBooking == null;

    return AppPage(
      title: name,
      bottom: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: canBook
              ? () => context.push(Routes.customerBook, extra: {
                    'pro_id': proId,
                    'pro_name': name,
                    'category_code': catCode,
                    'visit_fee_paise': visitFeePaise,
                    'city_id': cityId,
                    'work_radius_km': (d['work_radius_km'] as num?)?.toInt() ?? 5,
                    if (d['home_lat'] != null) 'pro_lat': d['home_lat'],
                    if (d['home_lng'] != null) 'pro_lng': d['home_lng'],
                    if (widget.params['lat'] != null) 'lat': widget.params['lat'],
                    if (widget.params['lng'] != null) 'lng': widget.params['lng'],
                  })
              : activeBooking != null
                  ? () => context.push(Routes.customerBookingDetail, extra: activeBooking.id)
                  : null,
          icon: Icon(activeBooking != null ? Icons.event_note : Icons.calendar_today),
          label: Text(
            activeBooking != null
                ? 'Booking in progress'
                : isAvailable
                    ? 'Book Now · ${formatPaise(visitFeePaise)}'
                    : 'Currently Unavailable',
          ),
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: CircleAvatar(
                radius: isCompact ? 36 : 48,
                backgroundColor: AppTheme.brandPrimaryLight,
                child: Icon(Icons.person, size: isCompact ? 36 : 48, color: AppTheme.brandPrimary),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 8),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 6,
                children: [
                  if (distanceKm != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: distanceKm <= 2.0
                            ? AppTheme.brandSuccess.withValues(alpha: 0.1)
                            : AppTheme.brandPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.near_me, size: 14,
                              color: distanceKm <= 2.0 ? AppTheme.brandSuccess : AppTheme.brandPrimary),
                          const SizedBox(width: 4),
                          Text(
                            '${formatDistanceKm(distanceKm)} away',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: distanceKm <= 2.0 ? AppTheme.brandSuccess : AppTheme.brandPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: AppTheme.brandAccentDark, size: 18),
                      const SizedBox(width: 3),
                      Text('${ratingAvg.toStringAsFixed(1)} ($ratingCount ratings)',
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.brandSuccess, size: 16),
                      const SizedBox(width: 3),
                      Text('$jobsCompleted jobs', style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 3),
                  Text(cityById(cityId).name,
                      style: const TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (activeBooking != null)
              TrustBanner(
                text:
                    'You already have an active ${activeBooking.displayStatusLabel.toLowerCase()} booking with $name for this service.',
                icon: Icons.info_outline,
                tone: TrustBannerTone.warning,
              ),
            if (activeBooking == null && isAvailable)
              const TrustBanner(
                text: 'Verified professional · Pay only after work is done',
                icon: Icons.verified,
                tone: TrustBannerTone.success,
              ),
            if (!isAvailable)
              const TrustBanner(
                text: 'This professional is currently offline',
                icon: Icons.info_outline,
                tone: TrustBannerTone.warning,
              ),
            const SizedBox(height: 20),
            ContactActionRow(
              title: 'Contact professional',
              phoneE164: phoneE164,
              phoneMasked: phoneMasked,
              chatMessage: 'Hi $name, I would like to book a service.',
            ),
            const SizedBox(height: 20),
            Text('Skills', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in skills)
                  Chip(
                    avatar: Icon(
                      supportedCategories.where((c) => c.code == s['category_code']).firstOrNull?.icon ?? Icons.build,
                      size: 16,
                    ),
                    label: Text(
                      '${supportedCategories.where((c) => c.code == s['category_code']).firstOrNull?.nameEn ?? s['category_code']} · ${s['experience_years']}y',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(child: Text('Visit Fee', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                    Text(formatPaise(visitFeePaise),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.brandPrimary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
        ),
      ),
    );
  }
}
