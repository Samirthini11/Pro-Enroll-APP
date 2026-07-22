import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../../state/categories_provider.dart';
import '../shared/widgets.dart';
import 'customer_booking_ui.dart';

class BookingsListScreen extends ConsumerStatefulWidget {
  const BookingsListScreen({super.key});

  @override
  ConsumerState<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends ConsumerState<BookingsListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(customerProvider.notifier).loadBookings());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProvider);
    final categories = ref.watch(categoriesListProvider);

    return AppPage(
      title: 'My Bookings',
      fallbackRoute: Routes.customerHome,
      child: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.bookings.isEmpty
              ? const Center(
                  child: EmptyState(
                    icon: Icons.calendar_today,
                    title: 'No bookings yet',
                    body: 'Book a professional from the home screen.',
                  ),
                )
              : RefreshIndicator(
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
    );
  }
}
