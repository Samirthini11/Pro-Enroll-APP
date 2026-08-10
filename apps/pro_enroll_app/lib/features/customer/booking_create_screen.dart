import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants.dart';
import '../../core/ist_time.dart';
import '../../core/location_service.dart';
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
import 'customer_route_params.dart';

class BookingCreateScreen extends ConsumerStatefulWidget {
  const BookingCreateScreen({super.key, required this.params});
  final Map<String, dynamic> params;

  @override
  ConsumerState<BookingCreateScreen> createState() => _BookingCreateScreenState();
}

class _BookingCreateScreenState extends ConsumerState<BookingCreateScreen> {
  final _problemCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _mapController = MapController();

  late int _cityId;
  bool _submitting = false;
  double? _addressLat;
  double? _addressLng;
  bool _locating = true;
  bool _locationConfirmed = false;
  bool _usingGps = false;
  String? _locationHint;
  late DateTime _scheduledAt;
  bool _outsideRadius = false;
  double? _distanceToProKm;

  double? get _proLat => parseRouteDouble(widget.params['pro_lat']);
  double? get _proLng => parseRouteDouble(widget.params['pro_lng']);
  int get _workRadiusKm =>
      parseRouteInt(widget.params['work_radius_km'], fallback: 5).clamp(1, 50);

  bool get _hasProBase => _proLat != null && _proLng != null;

  @override
  void initState() {
    super.initState();
    _cityId = parseRouteInt(widget.params['city_id'], fallback: 1);
    _addressLat = parseRouteDouble(widget.params['lat']);
    _addressLng = parseRouteDouble(widget.params['lng']);
    // Default: 1 hour from now in IST wall-clock.
    _scheduledAt = IstTime.wallClock(
      DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
    if (_addressLat != null && _addressLng != null) {
      _usingGps = true;
      _locationConfirmed = true;
      _locating = false;
      _recheckRadius();
    }
    Future.microtask(() {
      ref.read(customerProvider.notifier).loadBookings();
      _captureLocation();
    });
  }

  void _recheckRadius() {
    if (!_hasProBase || _addressLat == null || _addressLng == null) {
      _outsideRadius = false;
      _distanceToProKm = null;
      return;
    }
    final km = LocationService.distanceKm(
      _proLat!,
      _proLng!,
      _addressLat!,
      _addressLng!,
    );
    _distanceToProKm = km;
    _outsideRadius = km > _workRadiusKm + 0.05;
  }

  Future<void> _alertOutsideRadius() async {
    final proName = widget.params['pro_name'] as String? ?? 'This professional';
    final dist = _distanceToProKm?.toStringAsFixed(1) ?? '?';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.wrong_location_outlined, color: AppTheme.brandWarning, size: 32),
        title: const Text('Outside service area'),
        content: Text(
          '$proName serves within $_workRadiusKm km. '
          'Your pin is about $dist km away.\n\n'
          'Move the pin closer to their area, or go back and choose another professional.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Adjust pin'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (context.canPop()) context.pop();
            },
            child: const Text('Choose another'),
          ),
        ],
      ),
    );
  }

  void _onPinChanged(double lat, double lng) {
    setState(() {
      _addressLat = lat;
      _addressLng = lng;
      _locationConfirmed = false;
      _usingGps = false;
      _cityId = LocationService.nearestCity(lat, lng).id;
      _recheckRadius();
      _locationHint = _outsideRadius
          ? 'Pin is outside this professional’s $_workRadiusKm km area'
          : 'Pin updated — confirm location';
    });
    if (_outsideRadius) {
      unawaited(_alertOutsideRadius());
    }
  }

  Future<void> _captureLocation({bool force = false}) async {
    if (!force && _addressLat != null && _addressLng != null) {
      if (mounted) {
        setState(() {
          _locating = false;
          _locationConfirmed = true;
          _usingGps = true;
          _recheckRadius();
          _locationHint = _outsideRadius
              ? 'Pin is outside this professional’s $_workRadiusKm km area'
              : 'Location ready — confirm pin on map';
        });
        if (_outsideRadius) unawaited(_alertOutsideRadius());
      }
      return;
    }

    setState(() {
      _locating = true;
      _locationHint = null;
    });

    final result = await LocationService.getCurrentLocationDetailed(
      timeout: const Duration(seconds: 10),
    );
    if (!mounted) return;

    if (result.isOk) {
      final loc = result.location!;
      setState(() {
        _locating = false;
        _addressLat = loc.latitude;
        _addressLng = loc.longitude;
        _cityId = loc.nearestCity.id;
        _usingGps = true;
        _locationConfirmed = false;
        _recheckRadius();
        _locationHint = _outsideRadius
            ? 'Pin is outside this professional’s $_workRadiusKm km area'
            : 'Tap map to adjust pin, then confirm location';
      });
      _moveMapTo(loc.latitude, loc.longitude);
      if (_outsideRadius) unawaited(_alertOutsideRadius());
      return;
    }

    final city = cityById(_cityId);
    setState(() {
      _locating = false;
      _addressLat = city.latitude;
      _addressLng = city.longitude;
      _usingGps = false;
      _locationConfirmed = false;
      _locationHint = switch (result.failReason) {
        LocationFailReason.servicesDisabled =>
          'Turn on GPS, then tap “Use current location”',
        LocationFailReason.permissionDenied ||
        LocationFailReason.permissionDeniedForever =>
          'Allow location permission, then tap “Use current location”',
        LocationFailReason.timeout =>
          'GPS timed out — showing city center. Adjust pin or retry.',
        _ => 'Could not detect GPS — showing city center. Adjust pin on map.',
      };
    });
    _moveMapTo(city.latitude, city.longitude);

    if (result.failReason == LocationFailReason.permissionDeniedForever ||
        result.failReason == LocationFailReason.servicesDisabled) {
      _offerOpenSettings(result.failReason!);
    }
  }

  void _moveMapTo(double lat, double lng) {
    try {
      _mapController.move(LatLng(lat, lng), 14);
    } catch (_) {}
  }

  Future<void> _offerOpenSettings(LocationFailReason reason) async {
    if (!mounted) return;
    final openApp = reason == LocationFailReason.permissionDeniedForever;
    final action = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Location needed'),
        content: Text(
          openApp
              ? 'Location permission is blocked. Open settings to allow it for accurate booking.'
              : 'Location services are off. Open settings to turn GPS on.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Later')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
    if (action == true) {
      if (openApp) {
        await LocationService.openAppSettings();
      } else {
        await LocationService.openLocationSettings();
      }
    }
  }

  Future<void> _pickDateTime() async {
    final nowIst = IstTime.wallClock(DateTime.now().toUtc());
    final min = nowIst.add(const Duration(minutes: 30));
    final initial = _scheduledAt.isBefore(min) ? min : _scheduledAt;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(min.year, min.month, min.day),
      lastDate: DateTime(min.year, min.month, min.day).add(const Duration(days: 30)),
      helpText: 'Select visit date (IST)',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
      helpText: 'Select visit time (IST)',
    );
    if (time == null || !mounted) return;

    var picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (picked.isBefore(min)) {
      picked = min;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit time must be at least 30 minutes from now (IST)')),
        );
      }
    }
    setState(() => _scheduledAt = picked);
  }

  @override
  void dispose() {
    _problemCtrl.dispose();
    _addressCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_problemCtrl.text.trim().isEmpty || _addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in problem and address')),
      );
      return;
    }
    if (_addressLat == null || _addressLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirm your location on the map')),
      );
      return;
    }
    if (!_locationConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap “Confirm location on map” before booking')),
      );
      return;
    }
    if (_outsideRadius) {
      await _alertOutsideRadius();
      return;
    }

    final min = IstTime.wallClock(DateTime.now().toUtc()).add(const Duration(minutes: 30));
    if (_scheduledAt.isBefore(min)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a visit time at least 30 minutes from now')),
      );
      return;
    }

    final proId = parseRouteInt(widget.params['pro_id']);
    final catCode = widget.params['category_code'] as String? ?? '';
    final activeBooking = findActiveBookingWithPro(
      ref.read(customerProvider).bookings,
      professionalId: proId,
      categoryCode: catCode,
    );
    if (activeBooking != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You already have an active booking with this professional for this service.',
            ),
          ),
        );
        context.go(Routes.customerHome);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.push(Routes.customerBookingDetail, extra: activeBooking.id);
        });
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      if (ref.read(roleProvider) != AppRole.customer) {
        final switched = await ref.read(authProvider.notifier).switchRole(AppRole.customer);
        if (!switched) {
          throw StateError(
            ref.read(authProvider).errorMessage ??
                'Switch to customer mode to book a service.',
          );
        }
      }

      if (proId < 1) {
        throw StateError('Invalid professional. Go back and select again.');
      }

      final feePaise = parseRouteInt(widget.params['visit_fee_paise']);

      // Treat picker wall-clock as IST → UTC instant for API.
      final scheduledUtc = DateTime.utc(
        _scheduledAt.year,
        _scheduledAt.month,
        _scheduledAt.day,
        _scheduledAt.hour,
        _scheduledAt.minute,
      ).subtract(IstTime.offset);

      final booking = await ref.read(customerProvider.notifier).createBooking(
            professionalId: proId,
            categoryCode: widget.params['category_code'] as String,
            problemDescription: _problemCtrl.text.trim(),
            addressText: _addressCtrl.text.trim(),
            cityId: _cityId,
            scheduledAt: scheduledUtc,
            addressLat: _addressLat,
            addressLng: _addressLng,
            visitFeePaise: feePaise > 0 ? feePaise : null,
            visitFeePaid: false,
          );

      await ref.read(pushNotificationServiceProvider).syncTokenWithServer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmed · Pay visit fee after work is done'),
            backgroundColor: AppTheme.brandSuccess,
          ),
        );
        // Keep customer home under the detail so Back returns safely.
        context.go(Routes.customerHome);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.push(Routes.customerBookingDetail, extra: booking.id);
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final proName = widget.params['pro_name'] as String? ?? '';
    final catCode = widget.params['category_code'] as String? ?? '';
    final proId = parseRouteInt(widget.params['pro_id']);
    final feePaise = parseRouteInt(widget.params['visit_fee_paise']);
    final lang = ref.watch(localeProvider).languageCode;
    final cat = ref.watch(categoriesListProvider).tryByCode(catCode) ??
        supportedCategories.tryByCode(catCode);
    final hasGeo = _addressLat != null && _addressLng != null;
    final timeLabel = DateFormat('EEE, d MMM yyyy · h:mm a').format(_scheduledAt);
    final activeBooking = findActiveBookingWithPro(
      ref.watch(customerProvider).bookings,
      professionalId: proId,
      categoryCode: catCode,
    );

    return AppPage(
      title: 'Book Service',
      fallbackRoute: Routes.customerHome,
      bottom: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _submitting || activeBooking != null || _outsideRadius
              ? null
              : _submit,
          icon: const Icon(Icons.check_circle_outline),
          label: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Confirm booking'),
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () => _captureLocation(force: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activeBooking != null) ...[
                TrustBanner(
                  text:
                      'Active booking in progress (${activeBooking.displayStatusLabel}). Complete or cancel it before booking again.',
                  icon: Icons.info_outline,
                  tone: TrustBannerTone.warning,
                ),
                const SizedBox(height: 12),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.brandPrimaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(cat?.icon ?? Icons.build, color: AppTheme.brandPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              proName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              cat?.name(lang) ?? catCode,
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatPaise(feePaise),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppTheme.brandPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: AppTheme.brandPrimaryLight.withValues(alpha: 0.35),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.payments_outlined, color: AppTheme.brandPrimary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No payment now. Pay the visit fee in the app after the technician finishes.',
                          style: TextStyle(fontSize: 13, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Visit time ──────────────────────────────────────────
              const Text('Preferred visit time (IST)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickDateTime,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                icon: const Icon(Icons.schedule),
                label: Text(timeLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),

              // ── Location + map ──────────────────────────────────────
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Confirm service location',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _locating ? null : () => _captureLocation(force: true),
                    icon: _locating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, size: 18),
                    label: Text(_locating ? 'Detecting…' : 'Use GPS'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TrustBanner(
                text: _locating
                    ? 'Getting your location…'
                    : (_outsideRadius
                        ? 'Outside service area (${_distanceToProKm?.toStringAsFixed(1) ?? '?'} km · max $_workRadiusKm km)'
                        : (_locationHint ??
                            (hasGeo
                                ? (_locationConfirmed
                                    ? 'Location confirmed for dispatch'
                                    : 'Tap map to adjust, then confirm')
                                : 'Location required to book'))),
                icon: _locating
                    ? Icons.my_location
                    : (_outsideRadius
                        ? Icons.wrong_location_outlined
                        : (_locationConfirmed
                            ? Icons.verified
                            : (hasGeo ? Icons.location_on : Icons.location_off))),
                tone: _outsideRadius
                    ? TrustBannerTone.warning
                    : (_locationConfirmed
                        ? TrustBannerTone.info
                        : TrustBannerTone.warning),
              ),
              const SizedBox(height: 10),
              if (hasGeo)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: SizedBox(
                    height: 220,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      ),
                      child: MapPreview(
                        latitude: _addressLat!,
                        longitude: _addressLng!,
                        radiusKm: _hasProBase ? _workRadiusKm.toDouble() : 1,
                        interactive: true,
                        mapController: _mapController,
                        secondaryLat: _proLat,
                        secondaryLng: _proLng,
                        caption: _outsideRadius
                            ? 'Outside ${_workRadiusKm} km service area'
                            : (_usingGps
                                ? 'GPS pin · tap to adjust'
                                : 'Tap map to adjust pin'),
                        onTapLocation: _onPinChanged,
                      ),
                    ),
                  ),
                ),
              if (hasGeo) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: _locationConfirmed && !_outsideRadius
                      ? OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check_circle, color: AppTheme.brandSuccess),
                          label: const Text('Location confirmed'),
                        )
                      : FilledButton.tonalIcon(
                          onPressed: () async {
                            _recheckRadius();
                            if (_outsideRadius) {
                              setState(() {});
                              await _alertOutsideRadius();
                              return;
                            }
                            setState(() {
                              _locationConfirmed = true;
                              _locationHint = 'Location confirmed for dispatch';
                            });
                          },
                          icon: Icon(
                            _outsideRadius ? Icons.wrong_location_outlined : Icons.pin_drop,
                          ),
                          label: Text(
                            _outsideRadius
                                ? 'Location outside service area'
                                : 'Confirm location on map',
                          ),
                        ),
                ),
              ],
              const SizedBox(height: 20),

              const Text('Describe the problem', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _problemCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. AC not cooling, making noise...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Your address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Full address with landmark',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text('City', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                // ignore: deprecated_member_use
                value: _cityId,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: supportedCities
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  final city = cityById(v);
                  setState(() {
                    _cityId = v;
                    // Keep GPS pin unless user never had GPS / wants city default.
                    if (!_usingGps || !_locationConfirmed) {
                      _addressLat = city.latitude;
                      _addressLng = city.longitude;
                      _locationConfirmed = false;
                      _locationHint = 'City updated — adjust pin and confirm';
                      _moveMapTo(city.latitude, city.longitude);
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              const TrustBanner(
                text: 'You can cancel free until the technician is on the way.',
                icon: Icons.cancel_outlined,
                tone: TrustBannerTone.info,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
