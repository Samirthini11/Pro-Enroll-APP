import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
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
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.engineering,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              const Text(
                'Pro-Enroll',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SectionTitle(
            l.t('lang.title'),
            subtitle:
                'You can change this any time from your profile.',
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              itemCount: supportedLanguages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final lng = supportedLanguages[i];
                final selected = lng.code == currentLang;
                return _LanguageTile(
                  selected: selected,
                  nativeLabel: lng.nativeLabel,
                  label: lng.label,
                  onTap: () => ref
                      .read(localeProvider.notifier)
                      .setLanguage(lng.code),
                );
              },
            ),
          ),
        ],
      ),
      bottom: FilledButton(
        onPressed: () => context.go(Routes.welcome),
        child: Text(l.t('common.continue')),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.selected,
    required this.nativeLabel,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String nativeLabel;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: selected ? AppTheme.brandPrimary : AppTheme.border,
              width: selected ? 2 : 1,
            ),
            color: selected ? AppTheme.brandPrimaryLight : Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nativeLabel,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style:
                          const TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  key: ValueKey(selected),
                  color: selected
                      ? AppTheme.brandPrimary
                      : AppTheme.textFaint,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
