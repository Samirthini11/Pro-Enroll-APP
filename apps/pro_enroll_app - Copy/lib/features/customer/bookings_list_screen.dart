import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../shared/widgets.dart';

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
    final isCompact = context.deviceSize == DeviceSize.xs;

    return AppPage(
      title: 'My Bookings',
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
              : ListView.separated(
                  itemCount: state.bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final b = state.bookings[i];
                    final cat = supportedCategories.where((c) => c.code == b.categoryCode).firstOrNull;
                    return Card(
                      child: InkWell(
                        onTap: () => context.push(Routes.customerBookingDetail, extra: b.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.all(isCompact ? 12 : 16),
                          child: Row(
                            children: [
                              Container(
                                width: isCompact ? 36 : 44,
                                height: isCompact ? 36 : 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.brandPrimaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(cat?.icon ?? Icons.build, color: AppTheme.brandPrimary, size: isCompact ? 18 : 22),
                              ),
                              SizedBox(width: isCompact ? 10 : 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b.professionalName,
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: isCompact ? 13 : 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text(cat?.nameEn ?? b.categoryCode,
                                        style: TextStyle(color: AppTheme.textMuted, fontSize: isCompact ? 11 : 13)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(formatPaise(b.visitFeePaise),
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: isCompact ? 13 : 14)),
                                  const SizedBox(height: 4),
                                  _StatusChip(status: b.status),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' => AppTheme.brandSuccess,
      'cancelled' => Colors.red,
      'pending' => Colors.orange,
      _ => AppTheme.brandPrimary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
