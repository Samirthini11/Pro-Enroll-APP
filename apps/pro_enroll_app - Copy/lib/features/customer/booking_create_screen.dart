import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../core/constants.dart';

import '../../core/location_service.dart';

import '../../core/theme.dart';

import '../../routing/router.dart';

import '../../state/app_state.dart';

import '../shared/widgets.dart';



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



  @override

  void initState() {

    super.initState();

    _cityId = widget.params['city_id'] as int? ?? 1;

    _addressLat = widget.params['lat'] as double?;

    _addressLng = widget.params['lng'] as double?;

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

      await ref.read(customerProvider.notifier).createBooking(

            professionalId: widget.params['pro_id'] as int,

            categoryCode: widget.params['category_code'] as String,

            problemDescription: _problemCtrl.text.trim(),

            addressText: _addressCtrl.text.trim(),

            cityId: _cityId,

            addressLat: _addressLat,

            addressLng: _addressLng,

          );

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Booking created!'), backgroundColor: AppTheme.brandSuccess),

        );

        context.go(Routes.customerHome);

      }

    } catch (e) {

      if (mounted) {

        setState(() => _submitting = false);

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text('Failed: $e')),

        );

      }

    }

  }



  @override

  Widget build(BuildContext context) {

    final proName = widget.params['pro_name'] as String? ?? '';

    final catCode = widget.params['category_code'] as String? ?? '';

    final feePaise = widget.params['visit_fee_paise'] as int? ?? 0;

    final cat = supportedCategories.where((c) => c.code == catCode).firstOrNull;

    final hasGeo = _addressLat != null && _addressLng != null;



    return AppPage(

      title: 'Book Service',

      bottom: SizedBox(

        width: double.infinity,

        child: FilledButton(

          onPressed: _submitting ? null : _submit,

          child: _submitting

              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))

              : const Text('Confirm Booking'),

        ),

      ),

      child: SingleChildScrollView(

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

                          Text(proName,

                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),

                              maxLines: 1,

                              overflow: TextOverflow.ellipsis),

                          Text(cat?.nameEn ?? catCode, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),

                        ],

                      ),

                    ),

                    Text(formatPaise(feePaise),

                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.brandPrimary)),

                  ],

                ),

              ),

            ),

            const SizedBox(height: 16),

            TrustBanner(

              text: _locating

                  ? 'Getting your location for accurate dispatch...'

                  : hasGeo

                      ? 'Service location captured (${_addressLat!.toStringAsFixed(4)}, ${_addressLng!.toStringAsFixed(4)})'

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

              onChanged: (v) { if (v != null) setState(() => _cityId = v); },

            ),

            const SizedBox(height: 16),

            const TrustBanner(

              text: 'You only pay the visit fee after the work is done',

              icon: Icons.security,

              tone: TrustBannerTone.info,

            ),

            const SizedBox(height: 40),

          ],

        ),

      ),

    );

  }

}

