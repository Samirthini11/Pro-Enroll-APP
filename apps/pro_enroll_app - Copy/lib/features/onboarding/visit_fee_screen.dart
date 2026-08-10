import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../../state/categories_provider.dart';
import '../../state/locale_state.dart';
import '../shared/api_errors.dart';
import '../shared/category_price_badges.dart';
import '../shared/widgets.dart';

class VisitFeeScreen extends ConsumerStatefulWidget {
  const VisitFeeScreen({super.key});

  @override
  ConsumerState<VisitFeeScreen> createState() => _VisitFeeScreenState();
}

class _VisitFeeScreenState extends ConsumerState<VisitFeeScreen> {
  int _fee = 150;
  bool _feeLocked = false;

  void _applyFeeFromCategories(List<CategoryRef> categories) {
    if (_feeLocked) return;
    final profile = ref.read(profileProvider);
    final stored = (profile.visitFeePaise / 100).round();
    if (stored >= 100) {
      setState(() {
        _fee = stored;
        _feeLocked = true;
      });
      return;
    }
    final suggested = suggestedVisitFeeRupees(
      categories,
      profile.skills.map((s) => s.categoryCode),
    );
    setState(() => _fee = suggested);
  }

  Future<void> _continue() async {
    final pn = ref.read(profileProvider.notifier);
    pn.setVisitFeeRupees(_fee);
    try {
      await pn.persistVisitFee();
    } catch (e) {
      if (mounted) {
        showApiError(context, e, fallback: 'Could not save visit fee.');
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
    final amountSize = context.responsive<double>(xs: 44, sm: 52, md: 60);

    ref.listen<AsyncValue<List<CategoryRef>>>(categoriesProvider, (prev, next) {
      next.whenData((cats) {
        if (mounted) _applyFeeFromCategories(cats);
      });
    });

    Widget body;
    if (categoriesAsync.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final List<CategoryRef> categories =
          categoriesAsync.valueOrNull ?? ref.watch(categoriesListProvider);
      body = _VisitFeeBody(
        lang: lang,
        categories: categories,
        profile: profile,
        fee: _fee,
        amountSize: amountSize,
        helper: l.t('onboarding.fee.helper'),
        onFeeChanged: (v) => setState(() {
          _fee = v;
          _feeLocked = true;
        }),
      );
    }

    return AppPage(
      title: l.t('onboarding.fee.title'),
      child: body,
      bottom: FilledButton(
        onPressed: categoriesAsync.isLoading ? null : _continue,
        child: Text(l.t('common.continue')),
      ),
    );
  }
}

class _VisitFeeBody extends StatelessWidget {
  const _VisitFeeBody({
    required this.lang,
    required this.categories,
    required this.profile,
    required this.fee,
    required this.amountSize,
    required this.helper,
    required this.onFeeChanged,
  });

  final String lang;
  final List<CategoryRef> categories;
  final ProProfile profile;
  final int fee;
  final double amountSize;
  final String helper;
  final ValueChanged<int> onFeeChanged;

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
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...selected.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimaryLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppTheme.brandPrimary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(cat.icon, size: 20, color: AppTheme.brandPrimaryDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cat.name(lang),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    CategoryPriceBadges(
                      category: cat,
                      lang: lang,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              gradient: const LinearGradient(
                colors: [AppTheme.brandPrimary, AppTheme.brandPrimaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brandPrimary.withValues(alpha: 0.22),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Your visit fee',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹$fee',
                  style: TextStyle(
                    fontSize: amountSize,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            IconButton.filledTonal(
              style: IconButton.styleFrom(
                minimumSize: const Size.square(44),
                shape: const CircleBorder(),
              ),
              onPressed: fee <= 50 ? null : () => onFeeChanged(fee - 25),
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: Slider(
                value: fee.toDouble().clamp(50, 500),
                min: 50,
                max: 500,
                divisions: 18,
                label: '₹$fee',
                onChanged: (v) => onFeeChanged(v.round()),
              ),
            ),
            IconButton.filledTonal(
              style: IconButton.styleFrom(
                minimumSize: const Size.square(44),
                shape: const CircleBorder(),
              ),
              onPressed: fee >= 500 ? null : () => onFeeChanged(fee + 25),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const TrustBanner(
          icon: Icons.info_outline,
          text:
              'Base price and visit fee are loaded from the category API (MySQL).',
        ),
      ],
    );
  }
}
