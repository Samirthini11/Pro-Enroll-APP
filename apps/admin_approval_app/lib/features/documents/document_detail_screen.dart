import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/admin_state.dart';
import '../shared/widgets.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final int documentId;

  @override
  ConsumerState<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  bool _busy = false;
  DocumentReviewItem? _doc;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await ref.read(repositoryProvider).fetchDocumentQueue();
    if (!mounted) return;
    setState(() {
      _doc = items
          .where((d) => d.documentId == widget.documentId)
          .firstOrNull;
    });
  }

  Future<void> _approve() async {
    setState(() => _busy = true);
    final ok = await ref
        .read(repositoryProvider)
        .approveDocument(widget.documentId);
    ref.invalidate(documentQueueProvider);
    ref.invalidate(dashboardStatsProvider);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document approved')),
      );
      context.pop();
    }
  }

  Future<void> _reject() async {
    String? reason = RejectReasons.document.first;
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reject document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: [
                  for (final r in RejectReasons.document)
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
        .rejectDocument(widget.documentId, fullReason);
    ref.invalidate(documentQueueProvider);
    ref.invalidate(dashboardStatsProvider);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document rejected')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_doc == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final doc = _doc!;
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
    final canAct = doc.status == DocumentStatus.pending;

    return AppPage(
      title: 'Document Review',
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
                        : const Text('Approve'),
                  ),
                ),
              ],
            )
          : null,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StatusChip(
            label: doc.kind.label,
            color: AppTheme.brandPrimary,
          ),
          const SizedBox(height: 16),
          Text(
            doc.label,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${doc.proName} · ${doc.city}',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Submitted ${dateFmt.format(doc.submittedAt)}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          DocumentPlaceholder(kind: doc.kind, height: 220),
          const SizedBox(height: 20),
          if (doc.notes != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.brandPrimary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(doc.notes!)),
                  ],
                ),
              ),
            ),
          if (doc.rejectedReason != null) ...[
            const SizedBox(height: 12),
            Card(
              color: AppTheme.brandDanger.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Rejection reason: ${doc.rejectedReason}',
                  style: const TextStyle(color: AppTheme.brandDanger),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.push('/kyc/${doc.proId}'),
            icon: const Icon(Icons.person_search),
            label: const Text('View full pro application'),
          ),
        ],
      ),
    );
  }
}
