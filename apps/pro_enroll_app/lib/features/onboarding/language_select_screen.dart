import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../routing/router.dart';
import '../../state/locale_state.dart';
import '../shared/widgets.dart';

class LanguageSelectScreen extends ConsumerWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(lProvider);
    final currentLang = ref.watch(localeProvider).languageCode;

    return AppPage(
      title: 'Pro-Enroll',
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(l.t('lang.title')),
          ...supportedLanguages.map((lng) {
            final selected = lng.code == currentLang;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => ref
                    .read(localeProvider.notifier)
                    .setLanguage(lng.code),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 20),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lng.nativeLabel,
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 2),
                            Text(lng.label,
                                style: const TextStyle(
                                    color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
        ],
      ),
      bottom: FilledButton(
        onPressed: () => context.go(Routes.welcome),
        child: Text(l.t('common.continue')),
      ),
    );
  }
}
