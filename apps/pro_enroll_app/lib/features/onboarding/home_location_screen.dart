import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../shared/widgets.dart';

class HomeLocationScreen extends ConsumerStatefulWidget {
  const HomeLocationScreen({super.key});

  @override
  ConsumerState<HomeLocationScreen> createState() =>
      _HomeLocationScreenState();
}

class _HomeLocationScreenState extends ConsumerState<HomeLocationScreen> {
  int? _cityId;
  double _radius = 5;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    _cityId = p.cityId ?? supportedCities.first.id;
    _radius = p.workRadiusKm.toDouble();
  }

  void _continue() {
    if (_cityId == null) return;
    ref.read(profileProvider.notifier).setCity(_cityId!);
    ref.read(profileProvider.notifier).setRadius(_radius.round());
    context.push(Routes.onboardFee);
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final mapHeight =
        context.responsive<double>(xs: 150, sm: 180, md: 200, lg: 240);

    return AppPage(
      title: l.t('onboarding.location.title'),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            l.t('onboarding.location.helper'),
            style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            l.t('onboarding.location.city'),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.2,
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
            onChanged: (v) => setState(() => _cityId = v),
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
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          const SizedBox(height: 4),
          Slider(
            value: _radius,
            min: 1,
            max: 25,
            divisions: 24,
            label: '${_radius.round()} km',
            onChanged: (v) => setState(() => _radius = v),
          ),
          const SizedBox(height: 8),
          Container(
            height: mapHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              gradient: const LinearGradient(
                colors: [AppTheme.brandPrimaryLight, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppTheme.border),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.infinite,
                  painter: _GridPainter(),
                ),
                Icon(
                  Icons.place,
                  size: 72,
                  color: AppTheme.brandPrimary.withValues(alpha: 0.9),
                ),
                Positioned(
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Text(
                      'Map preview',
                      style: TextStyle(
                        color: AppTheme.brandPrimaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: FilledButton(
        onPressed: _cityId == null ? null : _continue,
        child: Text(l.t('common.next')),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.brandPrimary.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
