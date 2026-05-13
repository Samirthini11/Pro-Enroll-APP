import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../shared/widgets.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final Set<String> _uploaded = {};

  void _toggle(String key) {
    setState(() {
      if (_uploaded.contains(key)) {
        _uploaded.remove(key);
      } else {
        _uploaded.add(key);
      }
    });
  }

  void _submit() {
    ref.read(profileProvider.notifier).setKyc(KycStatus.inReview);
    context.go(Routes.kycPending);
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    return AppPage(
      title: l.t('kyc.docs.title'),
      child: ListView(
        children: [
          Text(l.t('kyc.docs.body'),
              style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          _docRow('tools', Icons.handyman, 'Tools / shop photo'),
          const SizedBox(height: 10),
          _docRow('cert', Icons.school_outlined, 'Skill / training certificate'),
          const SizedBox(height: 10),
          _docRow('pan', Icons.badge_outlined, 'PAN card'),
        ],
      ),
      bottom: FilledButton(
        onPressed: _submit,
        child: Text(l.t('common.submit')),
      ),
    );
  }

  Widget _docRow(String key, IconData icon, String title) {
    final uploaded = _uploaded.contains(key);
    return InfoCard(
      icon: icon,
      title: title,
      subtitle: uploaded ? 'Uploaded — tap to remove' : 'Tap to upload',
      onTap: () => _toggle(key),
      trailing: Icon(
        uploaded ? Icons.check_circle : Icons.add_circle_outline,
        color: uploaded
            ? Theme.of(context).colorScheme.primary
            : const Color(0xFF94A3B8),
      ),
    );
  }
}
