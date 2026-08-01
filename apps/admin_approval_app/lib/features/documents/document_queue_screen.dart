import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api_error.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/admin_state.dart';
import '../shared/widgets.dart';

class DocumentQueueScreen extends ConsumerStatefulWidget {
  const DocumentQueueScreen({super.key});

  @override
  ConsumerState<DocumentQueueScreen> createState() =>
      _DocumentQueueScreenState();
}

class _DocumentQueueScreenState extends ConsumerState<DocumentQueueScreen> {
  DocumentKind? _kindFilter;
  DocumentStatus? _statusFilter = DocumentStatus.pending;

  DocumentQueueFilter get _filter => DocumentQueueFilter(
        kind: _kindFilter,
        status: _statusFilter,
      );

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(documentQueueProvider(_filter));
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
                'Shop & Certificate Verify',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text(
                'Review shop photos and training certificates',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _KindChip(
                      label: 'All types',
                      selected: _kindFilter == null,
                      onTap: () => setState(() => _kindFilter = null),
                    ),
                    const SizedBox(width: 8),
                    _KindChip(
                      label: 'Shop photos',
                      selected: _kindFilter == DocumentKind.shopPhoto,
                      onTap: () => setState(
                        () => _kindFilter = DocumentKind.shopPhoto,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _KindChip(
                      label: 'Certificates',
                      selected: _kindFilter == DocumentKind.cert,
                      onTap: () =>
                          setState(() => _kindFilter = DocumentKind.cert),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _KindChip(
                      label: 'Pending',
                      selected: _statusFilter == DocumentStatus.pending,
                      onTap: () => setState(
                        () => _statusFilter = DocumentStatus.pending,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _KindChip(
                      label: 'Approved',
                      selected: _statusFilter == DocumentStatus.approved,
                      onTap: () => setState(
                        () => _statusFilter = DocumentStatus.approved,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _KindChip(
                      label: 'Rejected',
                      selected: _statusFilter == DocumentStatus.rejected,
                      onTap: () => setState(
                        () => _statusFilter = DocumentStatus.rejected,
                      ),
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
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(apiErrorMessage(e, fallback: 'Could not load documents')),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Text(
                    'No documents in this queue',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(documentQueueProvider(_filter)),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final doc = items[i];
                    return _DocCard(
                      doc: doc,
                      dateFmt: dateFmt,
                      onTap: () =>
                          context.push(Routes.docDetailPath(doc.documentId)),
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

class _KindChip extends StatelessWidget {
  const _KindChip({
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

class _DocCard extends StatelessWidget {
  const _DocCard({
    required this.doc,
    required this.dateFmt,
    required this.onTap,
  });

  final DocumentReviewItem doc;
  final DateFormat dateFmt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (doc.status) {
      DocumentStatus.pending => AppTheme.brandWarning,
      DocumentStatus.approved => AppTheme.brandSuccess,
      DocumentStatus.rejected => AppTheme.brandDanger,
    };

    final kindIcon = doc.kind == DocumentKind.shopPhoto
        ? Icons.storefront_outlined
        : Icons.school_outlined;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.brandPrimaryLight,
                child: Icon(kindIcon, color: AppTheme.brandPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${doc.proName} · ${doc.city}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFmt.format(doc.submittedAt),
                      style: const TextStyle(
                        color: AppTheme.textFaint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(label: doc.status.name, color: statusColor),
            ],
          ),
        ),
      ),
    );
  }
}
