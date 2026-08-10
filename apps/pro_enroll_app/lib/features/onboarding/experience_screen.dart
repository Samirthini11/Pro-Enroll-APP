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

class ExperienceScreen extends ConsumerStatefulWidget {
  const ExperienceScreen({super.key});

  @override
  ConsumerState<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends ConsumerState<ExperienceScreen> {
  late TextEditingController _nameCtrl;
  /// Service start calendar year per category.
  late Map<String, int> _startYears;
  final int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameCtrl = TextEditingController(text: profile.fullName ?? '');
    _startYears = {
      for (final s in profile.skills)
        s.categoryCode: s.effectiveStartYear.clamp(_currentYear - 50, _currentYear),
    };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  int _yearsFor(String code) {
    final start = _startYears[code] ?? _currentYear;
    return (_currentYear - start).clamp(0, 50);
  }

  Future<void> _continue() async {
    final profile = ref.read(profileProvider);
    final name = _nameCtrl.text.trim();
    final pn = ref.read(profileProvider.notifier);
    pn.setName(name);
    pn.setSkills([
      for (final s in profile.skills)
        ProSkill(
          categoryCode: s.categoryCode,
          experienceStartYear: _startYears[s.categoryCode] ?? _currentYear,
          experienceYears: _yearsFor(s.categoryCode),
          isPrimary: s.isPrimary,
          visitFeePaise: s.visitFeePaise,
        ),
    ]);
    try {
      await pn.persistExperience(
        fullName: name,
        startYearByCategory: Map<String, int>.from(_startYears),
      );
    } catch (e) {
      if (mounted) {
        showApiError(context, e, fallback: 'Could not save experience.');
      }
      return;
    }
    if (!mounted) return;
    context.push(Routes.onboardLocation);
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final profile = ref.watch(profileProvider);
    final categories = ref.watch(categoriesListProvider);

    return AppPage(
      title: l.t('onboarding.experience.title'),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 4),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Full name',
              hintText: 'Murugan S.',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            l.t('onboarding.experience.start_year_label'),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          for (final s in profile.skills) ...[
            _SkillStartYearRow(
              icon: lookupCategory(categories, s.categoryCode).icon,
              label: lookupCategory(categories, s.categoryCode).name(lang),
              startYear: _startYears[s.categoryCode] ?? _currentYear,
              years: _yearsFor(s.categoryCode),
              minYear: _currentYear - 50,
              maxYear: _currentYear,
              onChange: (y) => setState(
                () => _startYears[s.categoryCode] =
                    y.clamp(_currentYear - 50, _currentYear),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
      bottom: FilledButton(
        onPressed: _nameCtrl.text.trim().length < 3 ? null : _continue,
        child: Text(l.t('common.next')),
      ),
    );
  }
}

class _SkillStartYearRow extends StatelessWidget {
  const _SkillStartYearRow({
    required this.icon,
    required this.label,
    required this.startYear,
    required this.years,
    required this.minYear,
    required this.maxYear,
    required this.onChange,
  });

  final IconData icon;
  final String label;
  final int startYear;
  final int years;
  final int minYear;
  final int maxYear;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.brandPrimaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.brandPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Since $startYear · $years ${years == 1 ? 'year' : 'years'}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            _YearStepper(
              value: startYear,
              min: minYear,
              max: maxYear,
              onChange: onChange,
            ),
          ],
        ),
      ),
    );
  }
}

class _YearStepper extends StatelessWidget {
  const _YearStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChange,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 18,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            // Older start year = more experience
            onPressed: value <= min ? null : () => onChange(value - 1),
            icon: const Icon(Icons.remove),
            color: AppTheme.textSecondary,
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            iconSize: 18,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            onPressed: value >= max ? null : () => onChange(value + 1),
            icon: const Icon(Icons.add),
            color: AppTheme.brandPrimary,
          ),
        ],
      ),
    );
  }
}
