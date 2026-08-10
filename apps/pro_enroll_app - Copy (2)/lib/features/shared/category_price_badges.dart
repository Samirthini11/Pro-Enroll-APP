import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';

/// Shows category pricing from API (`base_price_paise`, `default_visit_fee_paise`).
class CategoryPriceBadges extends StatelessWidget {
  const CategoryPriceBadges({
    super.key,
    required this.category,
    required this.lang,
    this.compact = false,
    this.showVisitFee = true,
    this.baseOnly = false,
    this.visitOnly = false,
  });

  final CategoryRef category;
  final String lang;
  final bool compact;
  final bool showVisitFee;
  final bool baseOnly;
  final bool visitOnly;

  @override
  Widget build(BuildContext context) {
    if (visitOnly) {
      return _chip(
        label: category.visitFeeLabel(lang),
        emphasized: true,
      );
    }
    if (baseOnly) {
      return _chip(
        label: category.priceLabel(lang),
        emphasized: true,
      );
    }

    return Wrap(
      spacing: compact ? 4 : 6,
      runSpacing: compact ? 3 : 4,
      children: [
        _chip(label: category.priceLabel(lang), emphasized: true),
        if (showVisitFee)
          _chip(label: category.visitFeeLabel(lang), emphasized: false),
      ],
    );
  }

  Widget _chip({required String label, required bool emphasized}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: emphasized ? AppTheme.brandPrimaryLight : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: emphasized
              ? AppTheme.brandPrimary.withValues(alpha: 0.28)
              : AppTheme.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
          color: emphasized ? AppTheme.brandPrimaryDark : AppTheme.textMuted,
        ),
      ),
    );
  }
}
