import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../../state/categories_provider.dart';
import '../../state/locale_state.dart';
import '../shared/widgets.dart';
import 'customer_booking_ui.dart';
import 'customer_home_screen.dart';
import 'customer_route_params.dart';

class ProSearchScreen extends ConsumerStatefulWidget {
  const ProSearchScreen({super.key, required this.params});
  final Map<String, dynamic> params;

  @override
  ConsumerState<ProSearchScreen> createState() => _ProSearchScreenState();
}

class _ProSearchScreenState extends ConsumerState<ProSearchScreen> {
  late int _cityId;
  String? _categoryCode;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _cityId = parseRouteInt(widget.params['city_id'], fallback: 1);
    _categoryCode = widget.params['category_code'] as String?;
    _lat = parseRouteDouble(widget.params['lat']);
    _lng = parseRouteDouble(widget.params['lng']);
    Future.microtask(() => _search());
  }

  Future<void> _search() async {
    await ref.read(customerProvider.notifier).searchPros(
          cityId: _cityId,
          categoryCode: _categoryCode,
          lat: _lat,
          lng: _lng,
        );
  }

  Future<void> _selectCity(CityRef city) async {
    setState(() {
      _cityId = city.id;
      // Drop previous GPS so search is city-based (not old Pondicherry coords).
      _lat = null;
      _lng = null;
    });
    // Keep home tab location in sync when returning from View all.
    ref.read(customerCityProvider.notifier).state = city.id;
    ref.read(customerLatProvider.notifier).state = null;
    ref.read(customerLngProvider.notifier).state = null;
    await _search();
  }

  void _showCityPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Change location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                for (final c in supportedCities)
                  ListTile(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _selectCity(c);
                    },
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      c.id == _cityId ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: c.id == _cityId ? AppTheme.brandPrimary : AppTheme.textFaint,
                    ),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(c.state),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final categories = ref.watch(categoriesListProvider);
    final catName = _categoryCode != null
        ? (categories.tryByCode(_categoryCode!) ??
                supportedCategories.tryByCode(_categoryCode!))
            ?.name(lang) ??
            'Pros'
        : 'All Pros';
    final isCompact = context.deviceSize == DeviceSize.xs;
    final city = cityById(_cityId);

    return AppPage(
      title: catName,
      child: Column(
        children: [
          InkWell(
            onTap: () => _showCityPicker(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.brandPrimary, size: 18),
                  const SizedBox(width: 8),
                  Text('${city.name}, ${city.state}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const Spacer(),
                  const Text('Change', style: TextStyle(color: AppTheme.brandPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: AppTheme.brandPrimary, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (state.searchResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.near_me, size: 14, color: AppTheme.brandPrimary),
                  const SizedBox(width: 4),
                  Text('${state.searchResults.length} pros near ${city.name}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Text('Sorted by nearest',
                      style: TextStyle(color: AppTheme.textFaint, fontSize: 11)),
                ],
              ),
            ),
          if (state.loading)
            Expanded(
              child: RefreshIndicator(
                onRefresh: _search,
                child: const SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: 320,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            )
          else if (state.searchResults.isEmpty)
            Expanded(
              child: RefreshIndicator(
                onRefresh: _search,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: const Center(
                      child: EmptyState(
                        icon: Icons.search_off,
                        title: 'No professionals found',
                        body: 'Try a different city or category.',
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _search,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                itemCount: state.searchResults.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final pro = state.searchResults[i];
                  final cat = categories.tryByCode(pro.categoryCode) ??
                      supportedCategories.tryByCode(pro.categoryCode);
                  return Card(
                    child: InkWell(
                      onTap: () => context.push(
                        Routes.customerProDetail,
                        extra: proDetailExtras(
                          proId: pro.id,
                          categoryCode: pro.categoryCode,
                          lat: _lat,
                          lng: _lng,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: EdgeInsets.all(isCompact ? 12 : 16),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: isCompact ? 22 : 26,
                                  backgroundColor: AppTheme.brandPrimaryLight,
                                  child: Icon(cat?.icon ?? Icons.person, color: AppTheme.brandPrimary, size: isCompact ? 20 : 24),
                                ),
                                if (pro.distanceKm != null && pro.distanceKm! <= 2.0)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.brandSuccess,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                      child: const Icon(Icons.near_me, size: 8, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(width: isCompact ? 10 : 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pro.fullName,
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: isCompact ? 13 : 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      if (pro.distanceKm != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: pro.distanceKm! <= 2.0
                                                ? AppTheme.brandSuccess.withValues(alpha: 0.1)
                                                : AppTheme.brandPrimary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.near_me, size: 10,
                                                  color: pro.distanceKm! <= 2.0 ? AppTheme.brandSuccess : AppTheme.brandPrimary),
                                              const SizedBox(width: 3),
                                              Text(
                                                formatDistanceKm(pro.distanceKm),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: pro.distanceKm! <= 2.0 ? AppTheme.brandSuccess : AppTheme.brandPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star, size: 13, color: AppTheme.brandAccentDark),
                                          const SizedBox(width: 2),
                                          Text('${pro.ratingAvg.toStringAsFixed(1)} (${pro.ratingCount})',
                                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle, size: 11, color: AppTheme.brandSuccess),
                                          const SizedBox(width: 2),
                                          Text('${pro.jobsCompleted} jobs',
                                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatPaise(pro.visitFeePaise),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: isCompact ? 14 : 16,
                                        color: AppTheme.brandPrimary)),
                                if (cat != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(cat.name(lang),
                                        style: const TextStyle(fontSize: 10, color: AppTheme.textFaint)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ),
        ],
      ),
    );
  }
}
