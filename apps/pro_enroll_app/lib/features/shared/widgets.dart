import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../core/theme.dart';

/// A responsive page scaffold used across most onboarding / detail
/// screens. Handles three things you'd otherwise repeat everywhere:
///
///   • Horizontal + vertical padding that scales with viewport.
///   • An optional sticky bottom CTA inside the safe area.
///   • A `maxWidth` cap so the UI looks right on web / foldables /
///     small tablets without changing on a phone.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.child,
    this.title,
    this.bottom,
    this.actions,
    this.showBack = true,
    this.constrainWidth = true,
    this.background,
    this.padding,
    this.fallbackRoute,
  });

  final String? title;
  final Widget child;
  final Widget? bottom;
  final List<Widget>? actions;
  final bool showBack;
  final bool constrainWidth;
  final Color? background;
  final EdgeInsets? padding;

  /// Used when the stack has nothing to pop (e.g. opened via notification `go`).
  /// Prevents Android back from exiting the app.
  final String? fallbackRoute;

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    if (fallbackRoute != null && fallbackRoute!.isNotEmpty) {
      context.go(fallbackRoute!);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = context.pageHPadding;
    final vPad = context.pageVPadding;
    final pad = padding ??
        EdgeInsets.fromLTRB(hPad, title == null ? vPad : 4, hPad, 0);

    Widget body = Padding(padding: pad, child: child);
    if (constrainWidth) body = ContentMaxWidth(child: body);

    final canPop = context.canPop();
    final hasFallback = fallbackRoute != null && fallbackRoute!.isNotEmpty;

    final scaffold = Scaffold(
      backgroundColor: background,
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              automaticallyImplyLeading: false,
              leading: showBack
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => _handleBack(context),
                    )
                  : null,
              actions: actions,
            )
          : null,
      body: SafeArea(top: title == null, child: body),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 12),
                child: constrainWidth ? ContentMaxWidth(child: bottom!) : bottom!,
              ),
            ),
    );

    // System back: if stack is empty, go to fallback instead of closing the app.
    if (showBack && hasFallback) {
      return PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleBack(context);
        },
        child: scaffold,
      );
    }

    return scaffold;
  }
}

/// Compact heading-block used at the top of step screens.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.subtitle, this.bottomGap = 16});
  final String text;
  final String? subtitle;
  final double bottomGap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: theme.textTheme.headlineMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
        SizedBox(height: bottomGap),
      ],
    );
  }
}

/// Tappable card with a leading icon tile, a title and an optional
/// subtitle. Used heavily in lists.
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ??
        (danger ? AppTheme.brandDanger : theme.colorScheme.primary);
    final bg = danger
        ? AppTheme.brandDanger.withValues(alpha: 0.08)
        : theme.colorScheme.primaryContainer;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: danger ? AppTheme.brandDanger : null),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  const Icon(Icons.chevron_right, color: AppTheme.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft tinted banner used to communicate trust messages
/// ("Aadhaar verified pros only", "Pay only after work is done", …).
class TrustBanner extends StatelessWidget {
  const TrustBanner({
    super.key,
    required this.text,
    this.icon = Icons.verified,
    this.tone = TrustBannerTone.info,
  });

  final String text;
  final IconData icon;
  final TrustBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = _palette();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: palette.fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: palette.fg,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ({Color bg, Color border, Color fg}) _palette() {
    switch (tone) {
      case TrustBannerTone.info:
        return (
          bg: AppTheme.brandPrimaryLight,
          border: const Color(0xFFDBE5FA),
          fg: AppTheme.brandPrimaryDark,
        );
      case TrustBannerTone.warning:
        return (
          bg: const Color(0xFFFEF3C7),
          border: const Color(0xFFFDE68A),
          fg: const Color(0xFFB45309),
        );
      case TrustBannerTone.success:
        return (
          bg: const Color(0xFFECFDF5),
          border: const Color(0xFFA7F3D0),
          fg: AppTheme.brandSuccess,
        );
    }
  }
}

enum TrustBannerTone { info, warning, success }

/// Pill-shaped status badge.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.color,
    this.icon = Icons.circle,
  });

  final String label;
  final Color? color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// A reusable empty / placeholder state used inside lists.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.brandPrimaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.brandPrimary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Formats a paise amount as ₹X (no decimals, Indian locale-ish).
String formatPaise(int paise) {
  final r = (paise / 100).round();
  return '₹${_groupIndian(r)}';
}

String _groupIndian(int n) {
  final s = n.toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final pairs = <String>[];
  while (rest.length > 2) {
    pairs.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) pairs.insert(0, rest);
  return '${pairs.join(',')},$last3';
}
