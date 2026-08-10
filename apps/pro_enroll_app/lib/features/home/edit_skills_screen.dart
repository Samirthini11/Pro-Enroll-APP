import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../state/categories_provider.dart';
import '../../state/locale_state.dart';
import '../shared/api_errors.dart';
import '../shared/category_price_badges.dart';
import '../shared/widgets.dart';

/// Edit enrolled service categories (e.g. add Plumber to AC skills).
class EditSkillsScreen extends ConsumerStatefulWidget {
  const EditSkillsScreen({super.key});

  @override
  ConsumerState<EditSkillsScreen> createState() => _EditSkillsScreenState();
}

class _EditSkillsScreenState extends ConsumerState<EditSkillsScreen> {
  static const _maxSelect = 3;
  late Set<String> _selected;
  late Map<String, int> _startYears;
  late Set<String> _originalCodes;
  bool _busy = false;
  final int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    final skills = ref.read(profileProvider).skills;
    _selected = skills.map((s) => s.categoryCode).toSet();
    _originalCodes = Set<String>.from(_selected);
    _startYears = {
      for (final s in skills)
        s.categoryCode:
            s.effectiveStartYear.clamp(_currentYear - 50, _currentYear),
    };
  }

  bool get _canEditExperience =>
      ref.read(profileProvider).canEditExperience;

  bool _yearEditable(String code) =>
      _canEditExperience || !_originalCodes.contains(code);

  void _toggle(String code) {
    setState(() {
      if (_selected.contains(code)) {
        _selected.remove(code);
      } else if (_selected.length < _maxSelect) {
        _selected.add(code);
        _startYears.putIfAbsent(code, () => _currentYear);
      }
    });
  }

  int _yearsFor(String code) =>
      (_currentYear - (_startYears[code] ?? _currentYear)).clamp(0, 50);

  Future<void> _save() async {
    if (_selected.isEmpty || _busy) return;
    setState(() => _busy = true);
    final codes = _selected.toList();
    final existing = {
      for (final s in ref.read(profileProvider).skills) s.categoryCode: s,
    };
    final cats = ref.read(categoriesListProvider);
    final skills = codes
        .map(
          (code) => ProSkill(
            categoryCode: code,
            experienceStartYear: _startYears[code] ?? _currentYear,
            experienceYears: _yearsFor(code),
            isPrimary: codes.first == code,
            visitFeePaise: existing[code]?.visitFeePaise ??
                (cats.tryByCode(code)?.defaultVisitFee ?? 150) * 100,
          ),
        )
        .toList();
    try {
      await ref.read(profileProvider.notifier).persistCategories(
            codes,
            experienceStartYearByCategory: {
              for (final c in codes) c: _startYears[c] ?? _currentYear,
            },
          );
      ref.read(profileProvider.notifier).setSkills(skills);
      await ref.read(profileProvider.notifier).loadFromApi();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        showApiError(context, e, fallback: 'Could not update services.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final cols = context.gridColumns;
    final categories = ref.watch(categoriesListProvider);

    return AppPage(
      title: 'Edit services',
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const Text(
            'Select up to 3 services you offer. Customers book you by category — '
            'e.g. add Plumber if you also do plumbing work.',
            style: TextStyle(color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: [
              for (final cat in categories)
                _CategoryTile(
                  cat: cat,
                  lang: lang,
                  selected: _selected.contains(cat.code),
                  onTap: () => _toggle(cat.code),
                ),
            ],
          ),
          if (_selected.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Service start year',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              ref.watch(profileProvider).canEditExperience
                  ? 'Set when you started each service. Experience years are calculated automatically.'
                  : 'Existing experience years are locked. Request unlock from Help, or set year only for newly added services.',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
            ),
            const SizedBox(height: 8),
            for (final code in _selected)
              _ExperienceRow(
                category: categories.tryByCode(code) ??
                    supportedCategories.tryByCode(code) ??
                    supportedCategories.first,
                lang: lang,
                startYear: _startYears[code] ?? _currentYear,
                years: _yearsFor(code),
                minYear: _currentYear - 50,
                maxYear: _currentYear,
                enabled: _yearEditable(code),
                onChanged: (y) => setState(() => _startYears[code] = y),
              ),
          ],
        ],
      ),
      bottom: FilledButton(
        onPressed: _selected.isNotEmpty && !_busy ? _save : null,
        child: _busy
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text('Save services'),
      ),
    );
  }
}

class _ExperienceRow extends StatelessWidget {
  const _ExperienceRow({
    required this.category,
    required this.lang,
    required this.startYear,
    required this.years,
    required this.minYear,
    required this.maxYear,
    required this.onChanged,
    this.enabled = true,
  });

  final CategoryRef category;
  final String lang;
  final int startYear;
  final int years;
  final int minYear;
  final int maxYear;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(category.icon, color: AppTheme.brandPrimary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name(lang),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Since $startYear · $years y',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: !enabled || startYear <= minYear
                  ? null
                  : () => onChanged(startYear - 1),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '$startYear',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            IconButton(
              onPressed: !enabled || startYear >= maxYear
                  ? null
                  : () => onChanged(startYear + 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.cat,
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  final CategoryRef cat;
  final String lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.brandPrimaryLight : AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: selected ? AppTheme.brandPrimary : AppTheme.border,
              width: selected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                cat.icon,
                color: selected ? AppTheme.brandPrimary : AppTheme.textMuted,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                cat.name(lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? AppTheme.brandPrimaryDark : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              CategoryPriceBadges(
                category: cat,
                lang: lang,
                compact: true,
                visitOnly: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
