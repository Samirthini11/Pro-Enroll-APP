import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_config.dart';
import '../../core/i18n.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../routing/router.dart';
import '../../services/legal_acceptance_service.dart';
import '../../state/app_state.dart';
import '../../state/categories_provider.dart';
import '../../state/locale_state.dart';
import 'terms_content.dart';

/// Shown once after install (and again if [LegalAcceptanceService.currentTermsVersion] changes).
class TermsAcceptanceScreen extends ConsumerStatefulWidget {
  const TermsAcceptanceScreen({super.key, this.viewOnly = false});

  /// Read-only view from Help — no acceptance required.
  final bool viewOnly;

  @override
  ConsumerState<TermsAcceptanceScreen> createState() =>
      _TermsAcceptanceScreenState();
}

class _TermsAcceptanceScreenState extends ConsumerState<TermsAcceptanceScreen> {
  bool _agreed = false;
  bool _busy = false;

  Future<void> _acceptAndContinue() async {
    if (!_agreed || _busy) return;
    setState(() => _busy = true);
    await LegalAcceptanceService().acceptCurrentTerms();
    if (!mounted) return;

    if (AppConfig.hasApi) {
      ref.read(categoriesProvider);
      final restored =
          await ref.read(authProvider.notifier).tryRestoreSession();
      if (!mounted) return;
      if (restored) {
        final route =
            ref.read(authProvider.notifier).routeAfterSessionRestore();
        context.go(route);
        return;
      }
    }

    if (mounted) context.go(Routes.authLanding);
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final sections = TermsContent.sections(lang);
    final hPad = context.pageHPadding;

    return PopScope(
      canPop: widget.viewOnly,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: widget.viewOnly
            ? AppBar(title: Text(l.t('legal.terms.title')))
            : null,
        body: SafeArea(
          child: ContentMaxWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.viewOnly) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.brandPrimary,
                          AppTheme.brandPrimaryDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.t('legal.terms.welcome'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.t('legal.terms.subtitle'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      if (widget.viewOnly)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            l.t('legal.terms.updated'),
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      for (final section in sections) ...[
                        Text(
                          section.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          section.body,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.5,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ],
                  ),
                ),
                if (!widget.viewOnly)
                  Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Material(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            onTap: () => setState(() => _agreed = !_agreed),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(
                                  color: _agreed
                                      ? AppTheme.brandPrimary
                                      : AppTheme.border,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: _agreed,
                                    onChanged: (v) =>
                                        setState(() => _agreed = v ?? false),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Text(
                                        l.t('legal.terms.checkbox'),
                                        style: const TextStyle(
                                          height: 1.4,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed:
                              _agreed && !_busy ? _acceptAndContinue : null,
                          child: _busy
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(l.t('legal.terms.accept')),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
