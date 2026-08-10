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

class CategorySelectScreen extends ConsumerStatefulWidget {
  const CategorySelectScreen({super.key});

  @override
  ConsumerState<CategorySelectScreen> createState() =>
      _CategorySelectScreenState();
}

class _CategorySelectScreenState extends ConsumerState<CategorySelectScreen> {
  static const _maxSelect = 3;
  final Set<String> _selected = {};

  void _toggle(String code) {
    setState(() {
      if (_selected.contains(code)) {
        _selected.remove(code);
      } else if (_selected.length < _maxSelect) {
        _selected.add(code);
      }
    });
  }

  Future<void> _continue() async {
    final codes = _selected.toList();
    final skills = codes
        .map((code) => ProSkill(
              categoryCode: code,
              experienceYears: 1,
              isPrimary: codes.first == code,
            ))
        .toList();
    ref.read(profileProvider.notifier).setSkills(skills);
    try {
      await ref.read(profileProvider.notifier).persistCategories(codes);
    } catch (e) {
      if (mounted) showApiError(context, e, fallback: 'Could not save skills.');
      return;
    }
    if (!mounted) return;
    context.push(Routes.onboardExperience);
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final categoriesAsync = ref.watch(categoriesProvider);
    final cols = context.gridColumns;
    final tileAspect = context.responsive<double>(xs: 0.88, sm: 0.95, md: 1.0);
    final helper = l.t('onboarding.category.helper');

    return AppPage(
      title: l.t('onboarding.category.title'),
      child: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _CategoryGrid(
          helper: helper,
          categories: ref.watch(categoriesListProvider),
          lang: lang,
          cols: cols,
          tileAspect: tileAspect,
          selected: _selected,
          maxSelect: _maxSelect,
          onToggle: _toggle,
        ),
        data: (categories) => _CategoryGrid(
          helper: helper,
          categories: categories,
          lang: lang,
          cols: cols,
          tileAspect: tileAspect,
          selected: _selected,
          maxSelect: _maxSelect,
          onToggle: _toggle,
        ),
      ),
      bottom: FilledButton(
        onPressed: _selected.isEmpty ? null : _continue,
        child: Text(l.t('common.next')),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.helper,
    required this.categories,
    required this.lang,
    required this.cols,
    required this.tileAspect,
    required this.selected,
    required this.maxSelect,
    required this.onToggle,
  });

  final String helper;
  final List<CategoryRef> categories;
  final String lang;
  final int cols;
  final double tileAspect;
  final Set<String> selected;
  final int maxSelect;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          helper,
          style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: tileAspect,
            ),
            itemCount: categories.length,
            itemBuilder: (ctx, i) {
              final c = categories[i];
              return _CategoryTile(
                category: c,
                lang: lang,
                selected: selected.contains(c.code),
                onTap: () => onToggle(c.code),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.check_circle,
                size: 18,
                color: selected.isEmpty
                    ? AppTheme.textFaint
                    : AppTheme.brandPrimary),
            const SizedBox(width: 6),
            Text(
              '${selected.length} of $maxSelect selected',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  final CategoryRef category;
  final String lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.brandPrimaryLight : Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: selected ? AppTheme.brandPrimary : AppTheme.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : AppTheme.brandPrimaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(category.icon,
                        color: AppTheme.brandPrimary, size: 22),
                  ),
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    size: 20,
                    color: selected
                        ? AppTheme.brandPrimary
                        : AppTheme.textFaint,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name(lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CategoryPriceBadges(
                    category: category,
                    lang: lang,
                    compact: true,
                    visitOnly: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
