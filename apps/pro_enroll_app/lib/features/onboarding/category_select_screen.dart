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
import '../../state/locale_state.dart';
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

  void _continue() {
    final skills = _selected
        .map((code) => ProSkill(
              categoryCode: code,
              experienceYears: 1,
              isPrimary: _selected.first == code,
            ))
        .toList();
    ref.read(profileProvider.notifier).setSkills(skills);
    context.push(Routes.onboardExperience);
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final cols = context.gridColumns;
    final tileAspect = context.responsive<double>(xs: 0.95, sm: 1.0, md: 1.05);

    return AppPage(
      title: l.t('onboarding.category.title'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.t('onboarding.category.helper'),
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
              itemCount: supportedCategories.length,
              itemBuilder: (ctx, i) {
                final c = supportedCategories[i];
                final selected = _selected.contains(c.code);
                return _CategoryTile(
                  icon: c.icon,
                  label: c.name(lang),
                  feeText: '₹${c.defaultVisitFee} visit',
                  selected: selected,
                  onTap: () => _toggle(c.code),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.check_circle,
                  size: 18,
                  color: _selected.isEmpty
                      ? AppTheme.textFaint
                      : AppTheme.brandPrimary),
              const SizedBox(width: 6),
              Text(
                '${_selected.length} of $_maxSelect selected',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
      bottom: FilledButton(
        onPressed: _selected.isEmpty ? null : _continue,
        child: Text(l.t('common.next')),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.feeText,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String feeText;
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
                    child: Icon(icon, color: AppTheme.brandPrimary, size: 22),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.circle_outlined,
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
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    feeText,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
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
