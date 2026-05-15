import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
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
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            l.t('kyc.docs.body'),
            style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 20),
          _docRow(context, 'tools', Icons.handyman, 'Tools / shop photo',
              'Helps build trust with new customers.'),
          const SizedBox(height: 10),
          _docRow(context, 'cert', Icons.school_outlined,
              'Skill / training certificate', 'Increases your Pro Score.'),
          const SizedBox(height: 10),
          _docRow(context, 'pan', Icons.badge_outlined, 'PAN card',
              'Required for higher monthly payouts.'),
        ],
      ),
      bottom: FilledButton(
        onPressed: _submit,
        child: Text(l.t('common.submit')),
      ),
    );
  }

  Widget _docRow(
      BuildContext context, String key, IconData icon, String title, String body) {
    final uploaded = _uploaded.contains(key);
    return InfoCard(
      icon: icon,
      title: title,
      subtitle: uploaded ? 'Uploaded — tap to remove' : body,
      onTap: () => _toggle(key),
      trailing: Icon(
        uploaded ? Icons.check_circle : Icons.add_circle_outline,
        color:
            uploaded ? AppTheme.brandSuccess : AppTheme.brandPrimary,
      ),
    );
  }
}
