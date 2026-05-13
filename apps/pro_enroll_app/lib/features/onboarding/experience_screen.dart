import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../../state/locale_state.dart';
import '../shared/widgets.dart';

class ExperienceScreen extends ConsumerStatefulWidget {
  const ExperienceScreen({super.key});

  @override
  ConsumerState<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends ConsumerState<ExperienceScreen> {
  late TextEditingController _nameCtrl;
  late Map<String, int> _years;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: ref.read(profileProvider).fullName ?? '');
    _years = {
      for (final s in ref.read(profileProvider).skills) s.categoryCode: s.experienceYears,
    };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _continue() {
    final profile = ref.read(profileProvider);
    ref.read(profileProvider.notifier).setName(_nameCtrl.text.trim());
    ref.read(profileProvider.notifier).setSkills([
      for (final s in profile.skills)
        ProSkill(
          categoryCode: s.categoryCode,
          experienceYears: _years[s.categoryCode] ?? 1,
          isPrimary: s.isPrimary,
        ),
    ]);
    context.push(Routes.onboardLocation);
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final profile = ref.watch(profileProvider);

    return AppPage(
      title: l.t('onboarding.experience.title'),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 24),
          for (final s in profile.skills) ...[
            _skillRow(context, lang, s),
            const SizedBox(height: 16),
          ],
        ],
      ),
      bottom: FilledButton(
        onPressed: _nameCtrl.text.trim().length < 3 ? null : _continue,
        child: Text(l.t('common.next')),
      ),
    );
  }

  Widget _skillRow(BuildContext context, String lang, ProSkill skill) {
    final cat = supportedCategories.firstWhere(
      (c) => c.code == skill.categoryCode,
      orElse: () => supportedCategories.first,
    );
    final yrs = _years[skill.categoryCode] ?? 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cat.icon,
                  color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.name(lang),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('$yrs ${yrs == 1 ? 'year' : 'years'} experience',
                      style: const TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: yrs <= 0
                  ? null
                  : () => setState(() => _years[skill.categoryCode] = yrs - 1),
            ),
            Text('$yrs',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            IconButton(
              icon: const Icon(Icons.add_circle),
              color: Theme.of(context).colorScheme.primary,
              onPressed: yrs >= 50
                  ? null
                  : () => setState(() => _years[skill.categoryCode] = yrs + 1),
            ),
          ],
        ),
      ),
    );
  }
}
