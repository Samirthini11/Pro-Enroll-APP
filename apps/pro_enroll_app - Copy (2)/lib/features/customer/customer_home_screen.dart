import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/location_service.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../../state/categories_provider.dart';
import '../../state/locale_state.dart';
import '../shared/category_price_badges.dart';
import '../shared/profile_avatar.dart';
import '../shared/widgets.dart';
import 'customer_booking_ui.dart';
import 'customer_route_params.dart';

final _customerCityProvider = StateProvider<int>((ref) => 1);
final _customerLatProvider = StateProvider<double?>((ref) => null);
final _customerLngProvider = StateProvider<double?>((ref) => null);
final _locationLoadingProvider = StateProvider<bool>((ref) => true);

Future<void> refreshCustomerHomeTab(WidgetRef ref) async {
  await ref.read(customerProvider.notifier).loadProfile();
  final cityId = ref.read(_customerCityProvider);
  final lat = ref.read(_customerLatProvider);
  final lng = ref.read(_customerLngProvider);
  if (lat != null && lng != null) {
    await ref.read(customerProvider.notifier).searchPros(cityId: cityId, lat: lat, lng: lng);
  } else {
    await ref.read(customerProvider.notifier).searchPros(cityId: cityId);
  }
}

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(customerProvider.notifier).loadProfile();
      await _detectLocationAndSearch();
    });
  }

  Future<void> _detectLocationAndSearch() async {
    ref.read(_locationLoadingProvider.notifier).state = true;
    try {
      final loc = await LocationService.getCurrentLocation()
          .timeout(const Duration(seconds: 8), onTimeout: () => null);
      if (!mounted) return;

      if (loc != null) {
        ref.read(_customerLatProvider.notifier).state = loc.latitude;
        ref.read(_customerLngProvider.notifier).state = loc.longitude;
        ref.read(_customerCityProvider.notifier).state = loc.nearestCity.id;
        await ref.read(customerProvider.notifier).searchPros(
              cityId: loc.nearestCity.id,
              lat: loc.latitude,
              lng: loc.longitude,
            );
      } else {
        final cityId = ref.read(_customerCityProvider);
        await ref.read(customerProvider.notifier).searchPros(cityId: cityId);
      }
    } catch (e) {
      debugPrint('_detectLocationAndSearch: $e');
      if (mounted) {
        final cityId = ref.read(_customerCityProvider);
        await ref.read(customerProvider.notifier).searchPros(cityId: cityId);
      }
    } finally {
      if (mounted) {
        ref.read(_locationLoadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          _HomeTab(),
          _BookingsTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) {
          setState(() => _tabIndex = i);
          if (i == 1) {
            ref.read(customerProvider.notifier).loadBookings();
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(customerProvider).profile;
    final name = profile?.fullName ?? 'there';
    final hPad = context.pageHPadding;
    final columns = context.gridColumns;
    final cityId = ref.watch(_customerCityProvider);
    final city = cityById(cityId);
    final state = ref.watch(customerProvider);
    final locLoading = ref.watch(_locationLoadingProvider);
    final hasGps = ref.watch(_customerLatProvider) != null;
    final categories = ref.watch(categoriesListProvider);
    final lang = ref.watch(localeProvider).languageCode;

    return SafeArea(
      child: ContentMaxWidth(
        child: RefreshIndicator(
          onRefresh: () => refreshCustomerHomeTab(ref),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.responsive(xs: 18.0, sm: 20.0, md: 24.0)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.brandPrimary, AppTheme.brandPrimaryDark],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi $name!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.responsive(xs: 18.0, sm: 20.0, md: 22.0),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'What do you need fixed?',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Location selector
              InkWell(
                onTap: () => _showCityPicker(context, ref),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      if (locLoading)
                        const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          hasGps ? Icons.my_location : Icons.location_on,
                          color: hasGps ? AppTheme.brandSuccess : AppTheme.brandPrimary,
                          size: 20,
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locLoading
                                  ? 'Detecting your location...'
                                  : hasGps
                                      ? 'Using your current location'
                                      : 'Your location',
                              style: TextStyle(
                                color: hasGps ? AppTheme.brandSuccess : AppTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text('${city.name}, ${city.state}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          ],
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text('Services', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: context.responsive(xs: 1.15, sm: 1.25, md: 1.35),
                ),
                itemCount: categories.length,
                itemBuilder: (ctx, i) {
                  final cat = categories[i];
                  return _CategoryTile(
                    cat: cat,
                    lang: lang,
                    compact: context.deviceSize == DeviceSize.xs,
                    onTap: () => context.push(
                      Routes.customerSearch,
                      extra: {
                        'city_id': cityId,
                        'category_code': cat.code,
                        if (hasGps) 'lat': ref.read(_customerLatProvider),
                        if (hasGps) 'lng': ref.read(_customerLngProvider),
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Nearby professionals section
              Row(
                children: [
                  Text('Online Professionals', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push(Routes.customerSearch, extra: {
                      'city_id': cityId,
                      if (hasGps) 'lat': ref.read(_customerLatProvider),
                      if (hasGps) 'lng': ref.read(_customerLngProvider),
                    }),
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (state.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.searchResults.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: EmptyState(
                    icon: Icons.location_off,
                    title: 'No online pros nearby',
                    body: 'Professionals must be online to accept bookings. Try another category or location.',
                  ),
                )
              else
                ...state.searchResults.take(5).map((pro) {
                  final cat = categories.tryByCode(pro.categoryCode);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _NearbyProCard(
                      pro: pro,
                      cat: cat,
                      onTap: () => context.push(
                        Routes.customerProDetail,
                        extra: proDetailExtras(
                          proId: pro.id,
                          categoryCode: pro.categoryCode,
                          lat: hasGps ? ref.read(_customerLatProvider) : null,
                          lng: hasGps ? ref.read(_customerLngProvider) : null,
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 16),
            ],
          ),
        ),
        ),
      ),
    );
  }

  static void _showCityPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(_customerCityProvider);
    final hasGps = ref.read(_customerLatProvider) != null;
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
                const Text('Select your location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('We\'ll show professionals near you',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                const SizedBox(height: 12),
                ListTile(
                  onTap: () async {
                    Navigator.pop(ctx);
                    ref.read(_locationLoadingProvider.notifier).state = true;
                    final loc = await LocationService.getCurrentLocation();
                    if (loc != null) {
                      ref.read(_customerLatProvider.notifier).state = loc.latitude;
                      ref.read(_customerLngProvider.notifier).state = loc.longitude;
                      ref.read(_customerCityProvider.notifier).state = loc.nearestCity.id;
                      ref.read(customerProvider.notifier).searchPros(
                        cityId: loc.nearestCity.id,
                        lat: loc.latitude,
                        lng: loc.longitude,
                      );
                    }
                    ref.read(_locationLoadingProvider.notifier).state = false;
                  },
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.my_location,
                      color: hasGps ? AppTheme.brandSuccess : AppTheme.brandPrimary),
                  title: const Text('Use my current location',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(hasGps ? 'GPS active' : 'Tap to enable GPS'),
                  trailing: hasGps
                      ? const Icon(Icons.check_circle, color: AppTheme.brandSuccess, size: 20)
                      : null,
                ),
                const Divider(),
                for (final c in supportedCities)
                  ListTile(
                    onTap: () {
                      ref.read(_customerCityProvider.notifier).state = c.id;
                      ref.read(_customerLatProvider.notifier).state = null;
                      ref.read(_customerLngProvider.notifier).state = null;
                      ref.read(customerProvider.notifier).searchPros(cityId: c.id);
                      Navigator.pop(ctx);
                    },
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      c.id == current && !hasGps ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: c.id == current && !hasGps ? AppTheme.brandPrimary : AppTheme.textFaint,
                    ),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(c.state),
                    trailing: c.id == current && !hasGps
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.brandPrimaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Current',
                                style: TextStyle(
                                    color: AppTheme.brandPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                          )
                        : null,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NearbyProCard extends StatelessWidget {
  const _NearbyProCard({required this.pro, this.cat, required this.onTap});
  final ProSearchResult pro;
  final CategoryRef? cat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCompact = context.deviceSize == DeviceSize.xs;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: isCompact ? 20 : 24,
                backgroundColor: AppTheme.brandPrimaryLight,
                child: Icon(cat?.icon ?? Icons.person, color: AppTheme.brandPrimary, size: isCompact ? 20 : 24),
              ),
              SizedBox(width: isCompact ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pro.fullName,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: isCompact ? 13 : 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        if (pro.distanceKm != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.near_me, size: 12, color: AppTheme.brandPrimary),
                              const SizedBox(width: 2),
                              Text(formatDistanceKm(pro.distanceKm),
                                  style: const TextStyle(fontSize: 11, color: AppTheme.brandPrimary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 12, color: Colors.amber.shade700),
                            const SizedBox(width: 2),
                            Text('${pro.ratingAvg.toStringAsFixed(1)}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                        if (cat != null)
                          Text(cat!.nameEn,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
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
                          fontWeight: FontWeight.w800, fontSize: isCompact ? 13 : 14, color: AppTheme.brandPrimary)),
                  const SizedBox(height: 2),
                  Text('${pro.jobsCompleted} jobs',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.cat,
    required this.lang,
    required this.onTap,
    this.compact = false,
  });

  final CategoryRef cat;
  final String lang;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: compact ? 40 : 48,
                height: compact ? 40 : 48,
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimaryLight,
                  borderRadius: BorderRadius.circular(compact ? 10 : 14),
                ),
                child: Icon(cat.icon, color: AppTheme.brandPrimary, size: compact ? 22 : 26),
              ),
              SizedBox(height: compact ? 6 : 10),
              Text(
                cat.name(lang),
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: compact ? 11 : 13),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              CategoryPriceBadges(
                category: cat,
                lang: lang,
                compact: compact,
                visitOnly: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingsTab extends ConsumerStatefulWidget {
  const _BookingsTab();

  @override
  ConsumerState<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends ConsumerState<_BookingsTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(customerProvider.notifier).loadBookings());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProvider);
    final hPad = context.pageHPadding;
    final categories = ref.watch(categoriesListProvider);

    return SafeArea(
      child: ContentMaxWidth(
        child: Padding(
          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Bookings', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              if (state.loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (state.bookings.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, size: 48, color: AppTheme.textFaint),
                        const SizedBox(height: 12),
                        const Text('No bookings yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ref.read(customerProvider.notifier).loadBookings(),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.bookings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final b = state.bookings[i];
                        final cat = categories.tryByCode(b.categoryCode);
                        return CustomerBookingListTile(
                          booking: b,
                          categoryIcon: cat?.icon,
                          categoryName: cat?.nameEn,
                          onTap: () => context.push(Routes.customerBookingDetail, extra: b.id),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(customerProvider).profile;
    final hPad = context.pageHPadding;
    final cityId = ref.watch(_customerCityProvider);
    final city = cityById(cityId);

    return SafeArea(
      child: ContentMaxWidth(
        child: RefreshIndicator(
          onRefresh: () => ref.read(customerProvider.notifier).loadProfile(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      NameInitialAvatar(
                        name: profile?.fullName,
                        radius: 28,
                        fontSize: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.fullName ?? 'Customer',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile?.phoneE164 ?? '',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: AppTheme.brandPrimary),
                  title: const Text('Location', style: TextStyle(fontSize: 14)),
                  subtitle: Text('${city.name}, ${city.state}', style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textFaint),
                  onTap: () => _HomeTab._showCityPicker(context, ref),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.swap_horiz, color: AppTheme.brandPrimary),
                  title: const Text('Switch to Professional', style: TextStyle(fontSize: 14)),
                  subtitle: const Text(
                    'Receive jobs for your enrolled services (AC, Plumber, …)',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () async {
                    final ok = await ref.read(authProvider.notifier).switchRole(
                          AppRole.professional,
                        );
                    if (!context.mounted) return;
                    if (ok) {
                      context.go(Routes.home);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ref.read(authProvider).errorMessage ??
                                'Enroll as a Pro first, or sign in as professional.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.red, fontSize: 14)),
                  onTap: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) context.go(Routes.authLanding);
                  },
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
