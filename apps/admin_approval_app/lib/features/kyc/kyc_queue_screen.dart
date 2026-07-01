import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/admin_state.dart';
import '../shared/widgets.dart';

class KycQueueScreen extends ConsumerStatefulWidget {
  const KycQueueScreen({super.key});

  @override
  ConsumerState<KycQueueScreen> createState() => _KycQueueScreenState();
}

class _KycQueueScreenState extends ConsumerState<KycQueueScreen> {
  ReviewStatus? _filter = ReviewStatus.inReview;

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(kycQueueProvider(_filter));
    final dateFmt = DateFormat('dd MMM, hh:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pro User Approval',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text(
                'Review Pro-Enroll KYC applications',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'In Review',
                      selected: _filter == ReviewStatus.inReview,
                      onTap: () =>
                          setState(() => _filter = ReviewStatus.inReview),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Verified',
                      selected: _filter == ReviewStatus.verified,
                      onTap: () =>
                          setState(() => _filter = ReviewStatus.verified),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Rejected',
                      selected: _filter == ReviewStatus.rejected,
                      onTap: () =>
                          setState(() => _filter = ReviewStatus.rejected),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: queueAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Text(
                    'No applications in this queue',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(kycQueueProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final app = items[i];
                    return _KycCard(
                      app: app,
                      dateFmt: dateFmt,
                      onTap: () => context.push(Routes.kycDetailPath(app.proId)),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _KycCard extends StatelessWidget {
  const _KycCard({
    required this.app,
    required this.dateFmt,
    required this.onTap,
  });

  final PendingProApplication app;
  final DateFormat dateFmt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (app.status) {
      ReviewStatus.inReview => AppTheme.brandWarning,
      ReviewStatus.verified => AppTheme.brandSuccess,
      ReviewStatus.rejected => AppTheme.brandDanger,
    };

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      app.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  StatusChip(label: app.status.label, color: statusColor),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                app.fullName,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _MetaChip(
                    icon: Icons.category_outlined,
                    text: Categories.label(app.primaryCategory),
                  ),
                  _MetaChip(
                    icon: Icons.location_on_outlined,
                    text: app.city,
                  ),
                  _MetaChip(
                    icon: Icons.face_retouching_natural,
                    text: 'Face ${(app.faceMatchScore * 100).toStringAsFixed(0)}%',
                  ),
                  if (app.pendingDocCount > 0)
                    _MetaChip(
                      icon: Icons.pending_outlined,
                      text: '${app.pendingDocCount} docs pending',
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Submitted ${dateFmt.format(app.submittedAt)}',
                style: const TextStyle(
                  color: AppTheme.textFaint,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
