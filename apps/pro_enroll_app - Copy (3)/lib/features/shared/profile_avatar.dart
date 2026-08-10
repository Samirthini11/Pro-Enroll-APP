import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// First letter of display name for avatar chips (multi-word → first letter of first word).
String nameInitial(String? name) {
  if (name == null || name.trim().isEmpty) return 'P';
  return name.trim().substring(0, 1).toUpperCase();
}

class NameInitialAvatar extends StatelessWidget {
  const NameInitialAvatar({
    super.key,
    required this.name,
    this.radius = 22,
    this.backgroundColor = AppTheme.brandPrimaryLight,
    this.foregroundColor = AppTheme.brandPrimaryDark,
    this.fontSize,
    this.onTap,
  });

  final String? name;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;
  final double? fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        nameInitial(name),
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w800,
          fontSize: fontSize ?? (radius * 0.85),
        ),
      ),
    );
    if (onTap == null) return avatar;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: avatar,
    );
  }
}
