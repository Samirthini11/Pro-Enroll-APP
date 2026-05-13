import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
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
    return AppPage(
      title: l.t('onboarding.location.title'),
      child: ListView(
        children: [
          const SizedBox(height: 4),
          Text(l.t('onboarding.location.helper'),
              style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          Text(l.t('onboarding.location.city'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _cityId,
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
          const SizedBox(height: 24),
          Text(l.t('onboarding.location.radius'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.radar, color: Color(0xFF64748B)),
              Expanded(
                child: Slider(
                  value: _radius,
                  min: 1,
                  max: 25,
                  divisions: 24,
                  label: '${_radius.round()} km',
                  onChanged: (v) => setState(() => _radius = v),
                ),
              ),
              Text('${_radius.round()} km',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.map_outlined,
                    size: 96, color: Theme.of(context).colorScheme.primary),
                Positioned(
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Map preview (real map needs API key)',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600),
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
