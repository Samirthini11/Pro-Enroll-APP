import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import 'profile_avatar.dart';

Future<void> switchToCustomerMode(BuildContext context, WidgetRef ref) async {
  final ok = await ref.read(authProvider.notifier).switchRole(
        AppRole.customer,
      );
  if (!context.mounted) return;
  if (ok) {
    ref.invalidate(earningsProvider);
    await ref.read(customerProvider.notifier).loadProfile();
    if (!context.mounted) return;
    ref.read(authProvider.notifier).navigateAfterCustomerAuth(
          GoRouter.of(context),
        );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.read(authProvider).errorMessage ??
              'Could not switch to customer mode.',
        ),
      ),
    );
  }
}

class BookServiceAvatar extends ConsumerWidget {
  const BookServiceAvatar({
    super.key,
    required this.name,
    required this.onTap,
    this.radius = 32,
    this.backgroundColor = Colors.white,
    this.foregroundColor = AppTheme.brandPrimary,
  });

  final String? name;
  final VoidCallback onTap;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = ref.watch(lProvider).t('profile.bookService');
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            NameInitialAvatar(
              name: name,
              radius: radius,
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              fontSize: radius * 0.68,
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: EdgeInsets.all(radius > 26 ? 5 : 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.brandPrimary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.home_repair_service,
                  size: radius > 26 ? 14 : 12,
                  color: AppTheme.brandPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookServiceChip extends ConsumerWidget {
  const BookServiceChip({super.key, required this.onTap, this.compact = false});

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(lProvider);
    return Material(
      color: AppTheme.brandPrimaryLight,
      borderRadius: BorderRadius.circular(compact ? 10 : 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 7 : 9,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.home_repair_service,
                size: compact ? 16 : 18,
                color: AppTheme.brandPrimary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l.t('profile.bookService'),
                  style: TextStyle(
                    color: AppTheme.brandPrimaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 12.5 : 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: compact ? 11 : 12,
                color: AppTheme.brandPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
