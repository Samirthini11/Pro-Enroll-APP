import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../state/locale_state.dart';

/// Opens a bottom sheet to pick app language (English / Tamil).
Future<void> showLanguagePicker(BuildContext context, WidgetRef ref) async {
  final current = ref.read(localeProvider).languageCode;
  final l = ref.read(lProvider);
  await showModalBottomSheet<void>(
    context: context,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.t('lang.title'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                l.t('lang.subtitle'),
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              for (final lng in supportedLanguages)
                ListTile(
                  onTap: () {
                    ref.read(localeProvider.notifier).setLanguage(lng.code);
                    Navigator.pop(ctx);
                  },
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    lng.code == current
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: lng.code == current
                        ? AppTheme.brandPrimary
                        : AppTheme.textFaint,
                  ),
                  title: Text(
                    lng.nativeLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(lng.label),
                ),
            ],
          ),
        ),
      );
    },
  );
}

String languageNativeLabel(String code) {
  return supportedLanguages
      .firstWhere(
        (l) => l.code == code,
        orElse: () => supportedLanguages.first,
      )
      .nativeLabel;
}

/// Compact translate button for app bars / headers.
class LanguageChipButton extends ConsumerWidget {
  const LanguageChipButton({super.key, this.light = false});

  /// When true, use white styling (e.g. on brand gradient headers).
  final bool light;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final fg = light ? Colors.white : AppTheme.brandPrimary;
    final bg = light
        ? Colors.white.withValues(alpha: 0.18)
        : AppTheme.brandPrimaryLight;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showLanguagePicker(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.translate, size: 16, color: fg),
              const SizedBox(width: 4),
              Text(
                languageNativeLabel(lang),
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
