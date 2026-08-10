import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/location_service.dart';
import '../../core/theme.dart';
import '../../data/api/api_exception.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../shared/widgets.dart';
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
  late int _cityId;
  bool _submitting = false;
  double? _addressLat;
  double? _addressLng;
  bool _locating = true;
  String _paymentMethod = 'upi';

  @override
  void initState() {
    super.initState();
    _cityId = parseRouteInt(widget.params['city_id'], fallback: 1);
    _addressLat = parseRouteDouble(widget.params['lat']);
    _addressLng = parseRouteDouble(widget.params['lng']);
    Future.microtask(_captureLocation);
  }

  Future<void> _captureLocation() async {
    if (_addressLat != null && _addressLng != null) {
      if (mounted) setState(() => _locating = false);
      return;
    }

    final loc = await LocationService.getCurrentLocation();
    if (!mounted) return;

    setState(() {
      _locating = false;
      if (loc != null) {
        _addressLat = loc.latitude;
        _addressLng = loc.longitude;
        _cityId = loc.nearestCity.id;
      }
    });
  }

  Future<void> _refreshLocation() async {
    setState(() => _locating = true);
    final loc = await LocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (loc != null) {
        _addressLat = loc.latitude;
        _addressLng = loc.longitude;
        _cityId = loc.nearestCity.id;
      }
    });
  }

  @override
  void dispose() {
    _problemCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_problemCtrl.text.trim().isEmpty || _addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      if (ref.read(roleProvider) != AppRole.customer) {
        final switched = await ref.read(authProvider.notifier).switchRole(AppRole.customer);
        if (!switched) {
          throw StateError(
            ref.read(authProvider).errorMessage ?? 'Switch to customer mode to book a service.',
          );
        }
      }

      final proId = parseRouteInt(widget.params['pro_id']);
      if (proId < 1) {
        throw StateError('Invalid professional. Go back and select again.');
      }

      final feePaise = parseRouteInt(widget.params['visit_fee_paise']);

      final booking = await ref.read(customerProvider.notifier).createBooking(
            professionalId: proId,
            categoryCode: widget.params['category_code'] as String,
            problemDescription: _problemCtrl.text.trim(),
            addressText: _addressCtrl.text.trim(),
            cityId: _cityId,
            addressLat: _addressLat,
            addressLng: _addressLng,
            visitFeePaise: feePaise > 0 ? feePaise : null,
            visitFeePaid: true,
            visitFeePaymentMethod: _paymentMethod,
          );

      await ref.read(pushNotificationServiceProvider).syncTokenWithServer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit fee paid · Booking confirmed'),
            backgroundColor: AppTheme.brandSuccess,
          ),
        );
        context.go(Routes.customerBookingDetail, extra: booking.id);
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
    final feePaise = parseRouteInt(widget.params['visit_fee_paise']);
    final cat = supportedCategories.where((c) => c.code == catCode).firstOrNull;
    final hasGeo = _addressLat != null && _addressLng != null;

    return AppPage(
      title: 'Book Service',
      bottom: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: const Icon(Icons.payment),
          label: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text('Pay ${formatPaise(feePaise)} visit fee & book'),
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshLocation,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                            Text(cat?.nameEn ?? catCode, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          ],
                        ),
                      ),
                      Text(
                        formatPaise(feePaise),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.brandPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: AppTheme.brandPrimaryLight.withValues(alpha: 0.35),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long, color: AppTheme.brandPrimary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Visit fee (pay in app)',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            Text(
                              formatPaise(feePaise),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.brandPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Only the visit fee is collected in the app. Final repair cost is settled after the job.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Pay visit fee via', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _PaymentMethodTile(
                value: 'upi',
                groupValue: _paymentMethod,
                icon: Icons.account_balance_wallet_outlined,
                title: 'UPI',
                subtitle: 'GPay / PhonePe / Paytm',
                onChanged: (v) => setState(() => _paymentMethod = v),
              ),
              _PaymentMethodTile(
                value: 'card',
                groupValue: _paymentMethod,
                icon: Icons.credit_card,
                title: 'Debit / Credit card',
                subtitle: 'Visa, Mastercard, RuPay',
                onChanged: (v) => setState(() => _paymentMethod = v),
              ),
              _PaymentMethodTile(
                value: 'netbanking',
                groupValue: _paymentMethod,
                icon: Icons.account_balance,
                title: 'Net banking',
                subtitle: 'All major banks',
                onChanged: (v) => setState(() => _paymentMethod = v),
              ),
              const SizedBox(height: 16),
              TrustBanner(
                text: _locating
                    ? 'Getting your location for accurate dispatch...'
                    : hasGeo
                        ? 'Service location captured for distance & dispatch'
                        : 'Location unavailable — booking will use your city only',
                icon: _locating ? Icons.my_location : (hasGeo ? Icons.location_on : Icons.location_off),
                tone: hasGeo ? TrustBannerTone.info : TrustBannerTone.warning,
              ),
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
                value: _cityId,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: supportedCities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _cityId = v);
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

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
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
