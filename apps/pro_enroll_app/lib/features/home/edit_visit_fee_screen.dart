import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../state/app_state.dart';
import '../../state/categories_provider.dart';
import '../../state/locale_state.dart';
import '../onboarding/visit_fee_screen.dart' show VisitFeeEditor;
import '../shared/api_errors.dart';
import '../shared/widgets.dart';

/// Edit visit fee (price) anytime after enrollment.
class EditVisitFeeScreen extends ConsumerStatefulWidget {
  const EditVisitFeeScreen({super.key});

  @override
  ConsumerState<EditVisitFeeScreen> createState() => _EditVisitFeeScreenState();
}

class _EditVisitFeeScreenState extends ConsumerState<EditVisitFeeScreen> {
  late int _fee;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    _fee = (p.visitFeePaise / 100).round().clamp(50, 500);
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    final pn = ref.read(profileProvider.notifier);
    pn.setVisitFeeRupees(_fee);
    try {
      await pn.persistVisitFee();
      await pn.loadFromApi();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        showApiError(context, e, fallback: 'Could not update visit fee.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final categoriesAsync = ref.watch(categoriesProvider);
    final profile = ref.watch(profileProvider);
    final amountSize = context.responsive<double>(xs: 44, sm: 52, md: 60);

    Widget body;
    if (categoriesAsync.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final List<CategoryRef> categories =
          categoriesAsync.valueOrNull ?? ref.watch(categoriesListProvider);
      body = VisitFeeEditor(
        lang: lang,
        categories: categories,
        profile: profile,
        fee: _fee,
        amountSize: amountSize,
        helper:
            'Set your visit fee — customers see this when booking you. '
            'You can change it anytime.',
        onFeeChanged: (v) => setState(() => _fee = v),
      );
    }

    return AppPage(
      title: 'Visit fee',
      child: body,
      bottom: FilledButton(
        onPressed: _busy || categoriesAsync.isLoading ? null : _save,
        child: _busy
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : const Text('Save visit fee'),
      ),
    );
  }
}
