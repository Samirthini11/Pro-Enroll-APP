import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../../state/locale_state.dart';
import '../../data/models.dart';
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

    return AppPage(
      title: l.t('onboarding.category.title'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(l.t('onboarding.category.helper'),
              style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: supportedCategories.length,
              itemBuilder: (ctx, i) {
                final c = supportedCategories[i];
                final selected = _selected.contains(c.code);
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _toggle(c.code),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFFE2E8F0),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(c.icon,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        Text(
                          c.name(lang),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 18,
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '₹${c.defaultVisitFee} visit',
                              style: const TextStyle(
                                  color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_selected.length} / $_maxSelect',
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
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
