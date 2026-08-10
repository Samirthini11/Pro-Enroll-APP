import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../../state/categories_provider.dart';
import '../../state/locale_state.dart';
import '../shared/api_errors.dart';
import '../shared/widgets.dart';

class VisitFeeScreen extends ConsumerStatefulWidget {
  const VisitFeeScreen({super.key});

  @override
  ConsumerState<VisitFeeScreen> createState() => _VisitFeeScreenState();
}

class _VisitFeeScreenState extends ConsumerState<VisitFeeScreen> {
  Map<String, int> _fees = {};
  bool _initialized = false;

  void _ensureFees(List<CategoryRef> categories, ProProfile profile) {
    if (_initialized && _fees.isNotEmpty) return;
    final next = <String, int>{};
    for (final s in profile.skills) {
      final cat = categories.tryByCode(s.categoryCode);
      final fromSkill = s.visitFeePaise > 0
          ? (s.visitFeePaise / 100).round()
          : (profile.visitFeePaise / 100).round();
      next[s.categoryCode] = clampVisitFeeRupees(
        fromSkill > 0
            ? fromSkill
            : (cat?.defaultVisitFee ?? suggestedVisitFeeRupees(
                categories,
                [s.categoryCode],
              )),
      );
    }
    if (next.isEmpty) return;
    setState(() {
      _fees = next;
      _initialized = true;
    });
  }

  Future<void> _continue() async {
    final pn = ref.read(profileProvider.notifier);
    pn.setSkillVisitFeesRupees(_fees);
    try {
      await pn.persistVisitFee();
    } catch (e) {
      if (mounted) {
        showApiError(context, e, fallback: 'Could not save visiting charge.');
      }
      return;
    }
    if (!mounted) return;
    context.push(Routes.kycIntro);
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final categoriesAsync = ref.watch(categoriesProvider);
    final profile = ref.watch(profileProvider);

    Widget body;
    if (categoriesAsync.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final List<CategoryRef> categories = ref.watch(categoriesListProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureFees(categories, profile);
      });
      body = VisitFeeEditor(
        lang: lang,
        categories: categories,
        profile: profile,
        feesRupees: _fees,
        helper: l.t('onboarding.fee.helper'),
        suggestedHint: l.t('onboarding.fee.suggestedHint'),
        onFeeChanged: (code, rupees) => setState(() {
          _fees = {..._fees, code: clampVisitFeeRupees(rupees)};
        }),
      );
    }

    return AppPage(
      title: l.t('onboarding.fee.title'),
      child: body,
      bottom: FilledButton(
        onPressed: categoriesAsync.isLoading || _fees.isEmpty ? null : _continue,
        child: Text(l.t('common.continue')),
      ),
    );
  }
}

class VisitFeeEditor extends StatelessWidget {
  const VisitFeeEditor({
    super.key,
    required this.lang,
    required this.categories,
    required this.profile,
    required this.feesRupees,
    required this.helper,
    required this.onFeeChanged,
    this.suggestedHint,
  });

  final String lang;
  final List<CategoryRef> categories;
  final ProProfile profile;
  final Map<String, int> feesRupees;
  final String helper;
  final void Function(String categoryCode, int rupees) onFeeChanged;
  final String? suggestedHint;

  @override
  Widget build(BuildContext context) {
    final selected = [
      for (final s in profile.skills)
        categories.tryByCode(s.categoryCode),
    ].whereType<CategoryRef>().toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          helper,
          style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
        ),
        const SizedBox(height: 8),
        Text(
          'Set a visiting charge for each service.',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        if (selected.isEmpty)
          const TrustBanner(
            icon: Icons.info_outline,
            text: 'Select at least one service first.',
          )
        else
          ...selected.map((cat) {
            final fee = feesRupees[cat.code] ??
                clampVisitFeeRupees(cat.defaultVisitFee);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ServiceFeeCard(
                category: cat,
                lang: lang,
                fee: fee,
                onFeeChanged: (v) => onFeeChanged(cat.code, v),
              ),
            );
          }),
        const SizedBox(height: 8),
        TrustBanner(
          icon: Icons.info_outline,
          text: suggestedHint ??
              'Suggested from each service — adjust if needed. Customers see the fee for the service they book.',
        ),
      ],
    );
  }
}

class _ServiceFeeCard extends StatelessWidget {
  const _ServiceFeeCard({
    required this.category,
    required this.lang,
    required this.fee,
    required this.onFeeChanged,
  });

  final CategoryRef category;
  final String lang;
  final int fee;
  final ValueChanged<int> onFeeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, size: 22, color: AppTheme.brandPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.name(lang),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
              ),
              Text(
                '₹$fee',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppTheme.brandPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Suggested ₹${category.defaultVisitFee}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          Row(
            children: [
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(40),
                  shape: const CircleBorder(),
                ),
                onPressed: fee <= visitFeeMinRupees
                    ? null
                    : () => onFeeChanged(fee - visitFeeStepRupees),
                icon: const Icon(Icons.remove, size: 18),
              ),
              Expanded(
                child: Slider(
                  value: fee.toDouble().clamp(
                        visitFeeMinRupees.toDouble(),
                        visitFeeMaxRupees.toDouble(),
                      ),
                  min: visitFeeMinRupees.toDouble(),
                  max: visitFeeMaxRupees.toDouble(),
                  divisions:
                      (visitFeeMaxRupees - visitFeeMinRupees) ~/
                          visitFeeStepRupees,
                  label: '₹$fee',
                  onChanged: (v) =>
                      onFeeChanged(clampVisitFeeRupees(v.round())),
                ),
              ),
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(40),
                  shape: const CircleBorder(),
                ),
                onPressed: fee >= visitFeeMaxRupees
                    ? null
                    : () => onFeeChanged(
                          clampVisitFeeRupees(fee + visitFeeStepRupees),
                        ),
                icon: const Icon(Icons.add, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
