import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../core/location_service.dart';
import '../../core/theme.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../shared/api_errors.dart';
import '../shared/widgets.dart';
import 'customer_home_screen.dart';

/// Collects name and city for customers who sign in via "Need a Service".
/// Shown after OTP when profile is incomplete. Auto-detects GPS city.
class CustomerProfileSetupScreen extends ConsumerStatefulWidget {
  const CustomerProfileSetupScreen({super.key});

  @override
  ConsumerState<CustomerProfileSetupScreen> createState() =>
      _CustomerProfileSetupScreenState();
}

class _CustomerProfileSetupScreenState
    extends ConsumerState<CustomerProfileSetupScreen> {
  late TextEditingController _nameCtrl;
  int? _cityId;
  bool _busy = false;
  bool _detectingLocation = true;
  String? _locationHint;

  @override
  void initState() {
    super.initState();
    final customer = ref.read(customerProvider).profile;
    final proName = ref.read(profileProvider).fullName;
    _nameCtrl = TextEditingController(
      text: customer?.fullName?.trim().isNotEmpty == true
          ? customer!.fullName
          : (proName?.trim().isNotEmpty == true ? proName : ''),
    );
    // Prefer saved city; otherwise detect GPS (do not default Pondicherry).
    _cityId = customer?.cityId;
    Future.microtask(() async {
      await ref.read(customerProvider.notifier).loadProfile();
      if (!mounted) return;
      final refreshed = ref.read(customerProvider).profile;
      if (refreshed?.fullName?.trim().isNotEmpty == true &&
          _nameCtrl.text.trim().isEmpty) {
        _nameCtrl.text = refreshed!.fullName!.trim();
      }
      if (refreshed?.cityId != null && _cityId == null) {
        setState(() => _cityId = refreshed!.cityId);
      }
      // Returning users with a complete profile can skip this screen.
      if (refreshed?.isProfileComplete == true) {
        ref.read(customerCityProvider.notifier).state = refreshed!.cityId!;
        context.go(Routes.customerHome);
        return;
      }
      await _detectCurrentLocation();
    });
  }

  Future<void> _detectCurrentLocation() async {
    final l = ref.read(lProvider);

    // Keep an existing profile city if the customer already chose one.
    if (_cityId != null) {
      ref.read(customerCityProvider.notifier).state = _cityId!;
      if (mounted) {
        setState(() {
          _detectingLocation = false;
          _locationHint = null;
        });
      }
      // Still try GPS in background for nearby pro search coords.
      try {
        final loc = await LocationService.getCurrentLocation()
            .timeout(const Duration(seconds: 8), onTimeout: () => null);
        if (!mounted || loc == null) return;
        ref.read(customerLatProvider.notifier).state = loc.latitude;
        ref.read(customerLngProvider.notifier).state = loc.longitude;
      } catch (_) {}
      return;
    }

    if (mounted) {
      setState(() {
        _detectingLocation = true;
        _locationHint = l.t('customer.setup.detecting');
      });
    }

    try {
      final loc = await LocationService.getCurrentLocation()
          .timeout(const Duration(seconds: 8), onTimeout: () => null);
      if (!mounted) return;

      if (loc != null) {
        ref.read(customerCityProvider.notifier).state = loc.nearestCity.id;
        ref.read(customerLatProvider.notifier).state = loc.latitude;
        ref.read(customerLngProvider.notifier).state = loc.longitude;
        setState(() {
          _cityId = loc.nearestCity.id;
          _detectingLocation = false;
          _locationHint = l.t('customer.setup.using_location', {
            'city': loc.nearestCity.name,
          });
        });
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    // GPS unavailable — fall back to first city, but label it clearly.
    setState(() {
      _cityId ??= supportedCities.first.id;
      _detectingLocation = false;
      _locationHint = l.t('customer.setup.gps_failed');
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final cityId = _cityId;
    if (name.isEmpty || cityId == null || _busy) return;

    setState(() => _busy = true);
    try {
      await ref.read(customerProvider.notifier).saveProfile(
            fullName: name,
            cityId: cityId,
          );
      // Keep home search aligned with the city chosen here.
      ref.read(customerCityProvider.notifier).state = cityId;
    } catch (e) {
      if (mounted) {
        showApiError(context, e, fallback: 'Could not save your details.');
      }
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (!mounted) return;
    await ref.read(pushNotificationServiceProvider).syncTokenWithServer();
    if (!mounted) return;
    context.go(Routes.customerHome);
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final auth = ref.watch(authProvider);
    final phone =
        auth.phoneE164 ?? ref.watch(customerProvider).profile?.phoneE164 ?? '';

    return AppPage(
      title: l.t('customer.setup.title'),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            l.t('customer.setup.subtitle'),
            style: const TextStyle(color: AppTheme.textMuted, height: 1.45),
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l.t('customer.setup.phone', {'phone': phone}),
              style: const TextStyle(
                color: AppTheme.textFaint,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l.t('customer.setup.name'),
              hintText: l.t('customer.setup.name_hint'),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (_detectingLocation)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.t('customer.setup.detecting'),
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          DropdownButtonFormField<int>(
            // Controlled value so GPS update replaces the default city.
            value: _cityId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.t('customer.setup.city')),
            items: [
              for (final city in supportedCities)
                DropdownMenuItem(
                  value: city.id,
                  child: Text('${city.name}, ${city.state}'),
                ),
            ],
            onChanged: _detectingLocation
                ? null
                : (v) {
                    setState(() => _cityId = v);
                    if (v != null) {
                      ref.read(customerCityProvider.notifier).state = v;
                      // Manual city pick — clear GPS so search is city-based.
                      ref.read(customerLatProvider.notifier).state = null;
                      ref.read(customerLngProvider.notifier).state = null;
                      setState(() {
                        _locationHint = l.t('customer.setup.city_selected', {
                          'city': cityById(v).name,
                        });
                      });
                    }
                  },
          ),
          if (_locationHint != null) ...[
            const SizedBox(height: 8),
            Text(
              _locationHint!,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ],
          if (!_detectingLocation) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() => _cityId = null);
                _detectCurrentLocation();
              },
              icon: const Icon(Icons.my_location, size: 18),
              label: Text(l.t('customer.setup.use_current')),
            ),
          ],
        ],
      ),
      bottom: FilledButton(
        onPressed: _nameCtrl.text.trim().isNotEmpty &&
                _cityId != null &&
                !_busy &&
                !_detectingLocation
            ? _save
            : null,
        child: _busy
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(l.t('common.continue')),
      ),
    );
  }
}
