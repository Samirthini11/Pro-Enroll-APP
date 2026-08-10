import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../state/app_state.dart';
import '../../state/categories_provider.dart';
import '../../state/locale_state.dart';
import '../onboarding/visit_fee_screen.dart' show VisitFeeEditor;
import '../shared/api_errors.dart';
import '../shared/widgets.dart';

/// Edit visit fee per enrolled service anytime after enrollment.
class EditVisitFeeScreen extends ConsumerStatefulWidget {
  const EditVisitFeeScreen({super.key});

  @override
  ConsumerState<EditVisitFeeScreen> createState() => _EditVisitFeeScreenState();
}

class _EditVisitFeeScreenState extends ConsumerState<EditVisitFeeScreen> {
  Map<String, int> _fees = {};
  bool _busy = false;
  bool _initialized = false;

  void _ensureFees() {
    if (_initialized) return;
    final p = ref.read(profileProvider);
    final cats = ref.read(categoriesListProvider);
    final next = <String, int>{};
    for (final s in p.skills) {
      final cat = cats.tryByCode(s.categoryCode);
      final rupees = s.visitFeePaise > 0
          ? (s.visitFeePaise / 100).round()
          : (p.visitFeePaise / 100).round();
      next[s.categoryCode] = clampVisitFeeRupees(
        rupees > 0 ? rupees : (cat?.defaultVisitFee ?? 150),
      );
    }
    _fees = next;
    _initialized = true;
  }

  Future<void> _save() async {
    if (_busy || _fees.isEmpty) return;
    setState(() => _busy = true);
    final pn = ref.read(profileProvider.notifier);
    pn.setSkillVisitFeesRupees(_fees);
    try {
      await pn.persistVisitFee();
      await pn.loadFromApi();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        showApiError(context, e, fallback: 'Could not update visiting charge.');
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
    _ensureFees();

    Widget body;
    if (categoriesAsync.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final List<CategoryRef> categories = ref.watch(categoriesListProvider);
      body = VisitFeeEditor(
        lang: lang,
        categories: categories,
        profile: profile,
        feesRupees: _fees,
        helper:
            'Set visiting charge for each service. Customers see the fee for '
            'the service they book. You can change it anytime.',
        onFeeChanged: (code, rupees) => setState(() {
          _fees = {..._fees, code: clampVisitFeeRupees(rupees)};
        }),
      );
    }

    return AppPage(
      title: 'Visiting charges',
      child: body,
      bottom: FilledButton(
        onPressed: _busy || categoriesAsync.isLoading || _fees.isEmpty
            ? null
            : _save,
        child: _busy
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text('Save visiting charges'),
      ),
    );
  }
}
