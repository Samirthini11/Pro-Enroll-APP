import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../core/location_service.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../shared/api_errors.dart';
import '../shared/map_preview.dart';
import '../shared/widgets.dart';

/// Edit city, GPS home base, and work radius after enrollment.
class EditWorkAreaScreen extends ConsumerStatefulWidget {
  const EditWorkAreaScreen({super.key});

  @override
  ConsumerState<EditWorkAreaScreen> createState() => _EditWorkAreaScreenState();
}

class _EditWorkAreaScreenState extends ConsumerState<EditWorkAreaScreen> {
  int? _cityId;
  double _radius = 5;
  double? _latitude;
  double? _longitude;
  bool _usingGps = false;
  bool _locating = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    _cityId = p.cityId ?? supportedCities.first.id;
    _radius = p.workRadiusKm.toDouble().clamp(1, 25);
    Future.microtask(_detectLocation);
  }

  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    try {
      final loc = await LocationService.getCurrentLocation().timeout(
        const Duration(seconds: 8),
        onTimeout: () => null,
      );
      if (!mounted) return;
      if (loc != null) {
        setState(() {
          _cityId = loc.nearestCity.id;
          _latitude = loc.latitude;
          _longitude = loc.longitude;
          _usingGps = true;
          _locating = false;
        });
      } else {
        final city = cityById(_cityId ?? supportedCities.first.id);
        setState(() {
          _latitude = city.latitude;
          _longitude = city.longitude;
          _usingGps = false;
          _locating = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      final city = cityById(_cityId ?? supportedCities.first.id);
      setState(() {
        _latitude = city.latitude;
        _longitude = city.longitude;
        _usingGps = false;
        _locating = false;
      });
    }
  }

  void _onCityChanged(int? value) {
    if (value == null) return;
    final city = cityById(value);
    setState(() {
      _cityId = value;
      _latitude = city.latitude;
      _longitude = city.longitude;
      _usingGps = false;
    });
  }

  Future<void> _save() async {
    if (_cityId == null || _busy) return;
    setState(() => _busy = true);
    final pn = ref.read(profileProvider.notifier);
    pn.setCity(_cityId!);
    pn.setRadius(_radius.round());
    try {
      await pn.persistLocation(
        cityId: _cityId!,
        radiusKm: _radius.round(),
        homeLat: _latitude,
        homeLng: _longitude,
      );
      await pn.loadFromApi();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        showApiError(context, e, fallback: 'Could not update work area.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final mapHeight =
        context.responsive<double>(xs: 150, sm: 180, md: 200, lg: 240);
    final cityId = _cityId ?? supportedCities.first.id;
    final city = cityById(cityId);
    final mapLat = _latitude ?? city.latitude;
    final mapLng = _longitude ?? city.longitude;

    return AppPage(
      title: 'Work area & distance',
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const Text(
            'Update where you work and how far you travel for jobs. '
            'Customers only see you when they are within this radius.',
            style: TextStyle(color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (_locating)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Detecting location…',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          else if (_usingGps)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimaryLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.brandPrimary.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.my_location, size: 18, color: AppTheme.brandPrimaryDark),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Using your current GPS location',
                        style: TextStyle(
                          color: AppTheme.brandPrimaryDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _locating ? null : _detectLocation,
            icon: const Icon(Icons.gps_fixed, size: 18),
            label: Text(l.t('onboarding.location.use_current')),
          ),
          const SizedBox(height: 16),
          Text(
            l.t('onboarding.location.city'),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _cityId,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
            items: [
              for (final c in supportedCities)
                DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.name}, ${c.state}'),
                ),
            ],
            onChanged: _onCityChanged,
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text(
                l.t('onboarding.location.radius'),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimaryLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_radius.round()} km',
                  style: const TextStyle(
                    color: AppTheme.brandPrimaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _radius,
            min: 1,
            max: 25,
            divisions: 24,
            label: '${_radius.round()} km',
            onChanged: (v) => setState(() => _radius = v),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: SizedBox(
              height: mapHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: _locating
                    ? const Center(child: CircularProgressIndicator())
                    : MapPreview(
                        key: ValueKey(
                          '${mapLat.toStringAsFixed(4)}_${mapLng.toStringAsFixed(4)}_${_radius.round()}',
                        ),
                        latitude: mapLat,
                        longitude: mapLng,
                        radiusKm: _radius,
                        caption: '${city.name} · ${_radius.round()} km radius',
                      ),
              ),
            ),
          ),
        ],
      ),
      bottom: FilledButton(
        onPressed: _busy ? null : _save,
        child: _busy
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : const Text('Save work area'),
      ),
    );
  }
}
