import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api_error.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/admin_state.dart';
import '../shared/widgets.dart';

class KycDetailScreen extends ConsumerStatefulWidget {
  const KycDetailScreen({super.key, required this.proId});

  final int proId;

  @override
  ConsumerState<KycDetailScreen> createState() => _KycDetailScreenState();
}

class _KycDetailScreenState extends ConsumerState<KycDetailScreen> {
  bool _busy = false;

  Future<void> _approve() async {
    setState(() => _busy = true);
    final ok =
        await ref.read(repositoryProvider).approveKyc(widget.proId);
    ref.invalidate(kycQueueProvider);
    ref.invalidate(kycDetailProvider(widget.proId));
    ref.invalidate(dashboardStatsProvider);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pro approved — now live on marketplace')),
      );
      context.pop();
    }
  }

  Future<void> _reject() async {
    String? reason = RejectReasons.kyc.first;
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reject application'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: [
                  for (final r in RejectReasons.kyc)
                    DropdownMenuItem(value: r, child: Text(r)),
                ],
                onChanged: (v) => setDialogState(() => reason = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brandDanger,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || reason == null) return;

    setState(() => _busy = true);
    final fullReason = notesCtrl.text.isEmpty
        ? reason!
        : '$reason — ${notesCtrl.text}';
    final ok = await ref
        .read(repositoryProvider)
        .rejectKyc(widget.proId, fullReason);
    ref.invalidate(kycQueueProvider);
    ref.invalidate(kycDetailProvider(widget.proId));
    ref.invalidate(dashboardStatsProvider);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application rejected')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(kycDetailProvider(widget.proId));
    final moneyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return detailAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(apiErrorMessage(e, fallback: 'Could not load application')),
          ),
        ),
      ),
      data: (app) {
        if (app == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Application not found')),
          );
        }

        final canAct = app.status == ReviewStatus.inReview;

        return AppPage(
          title: 'KYC Review',
          bottom: canAct
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : _reject,
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy ? null : _approve,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Approve Pro'),
                      ),
                    ),
                  ],
                )
              : null,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.brandPrimaryLight,
                    child: Text(
                      app.fullName.isNotEmpty ? app.fullName[0] : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.brandPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.displayName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(app.fullName),
                        Text(
                          app.phoneE164,
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _InfoSection(
                title: 'Profile',
                rows: [
                  _InfoRow('City', app.city),
                  if (app.address != null) _InfoRow('Address', app.address!),
                  _InfoRow('Work radius', '${app.workRadiusKm} km'),
                  _InfoRow(
                    'Visit fee',
                    moneyFmt.format(app.visitFeePaise / 100),
                  ),
                  _InfoRow('Aadhaar', 'XXXX-XXXX-${app.aadhaarLast4}'),
                  _InfoRow(
                    'Face match',
                    '${(app.faceMatchScore * 100).toStringAsFixed(1)}%',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoSection(
                title: 'Skills',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in app.skills)
                      Chip(
                        label: Text(
                          '${Categories.label(s.categoryCode)} · ${s.experienceYears}y',
                        ),
                        avatar: s.isPrimary
                            ? const Icon(Icons.star, size: 16)
                            : null,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionTitle('Documents'),
              for (final doc in app.documents) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                doc.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            StatusChip(
                              label: doc.status.name,
                              color: switch (doc.status) {
                                DocumentStatus.pending =>
                                  AppTheme.brandWarning,
                                DocumentStatus.approved =>
                                  AppTheme.brandSuccess,
                                DocumentStatus.rejected =>
                                  AppTheme.brandDanger,
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DocumentPlaceholder(kind: doc.kind, height: 120),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (app.rejectedReason != null) ...[
                const SizedBox(height: 8),
                Card(
                  color: AppTheme.brandDanger.withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Rejection reason: ${app.rejectedReason}',
                      style: const TextStyle(color: AppTheme.brandDanger),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    this.rows = const [],
    this.child,
  });

  final String title;
  final List<_InfoRow> rows;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 12),
            if (child != null) child!,
            for (final row in rows) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      row.label,
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              if (row != rows.last) const Divider(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;
}
