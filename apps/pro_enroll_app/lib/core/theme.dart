import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Visual identity for the Pro-Enroll app.
///
/// The Pro-Enroll professional app uses a deep, trustworthy **blue**
/// palette evocative of utilities, finance and infrastructure. The blue
/// also visually pairs well with the lighter blue planned for the
/// Pro-User customer app while keeping the two apps distinguishable
/// (Pro-Enroll = deep indigo; Pro-User = sky blue).
class AppTheme {
  AppTheme._();

  // ── Brand palette ───────────────────────────────────────────────────
  // Primary uses a deep, professional indigo-blue. Accents are warm to
  // draw attention to earnings and CTAs.
  static const Color brandPrimary = Color(0xFF1D4ED8); // indigo-700
  static const Color brandPrimaryDark = Color(0xFF1E40AF); // indigo-800
  static const Color brandPrimaryLight = Color(0xFFEFF4FF); // indigo-50ish
  static const Color brandAccent = Color(0xFFF59E0B); // amber-500
  static const Color brandSuccess = Color(0xFF059669); // emerald-600
  static const Color brandDanger = Color(0xFFDC2626); // red-600

  // ── Neutral palette ─────────────────────────────────────────────────
  static const Color surface = Color(0xFFF6F8FB); // very light blue-grey
  static const Color surfaceContainer = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0); // slate-200
  static const Color borderStrong = Color(0xFFCBD5E1); // slate-300
  static const Color textPrimary = Color(0xFF0F172A); // slate-900
  static const Color textSecondary = Color(0xFF475569); // slate-600
  static const Color textMuted = Color(0xFF64748B); // slate-500
  static const Color textFaint = Color(0xFF94A3B8); // slate-400

  // ── Common shape tokens ─────────────────────────────────────────────
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 24;

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandPrimary,
      brightness: Brightness.light,
      primary: brandPrimary,
      onPrimary: Colors.white,
      primaryContainer: brandPrimaryLight,
      onPrimaryContainer: brandPrimaryDark,
      surface: surface,
      onSurface: textPrimary,
      error: brandDanger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: surface,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      textTheme: _textTheme(textPrimary),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          backgroundColor: brandPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: borderStrong,
          disabledForegroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          side: const BorderSide(color: borderStrong),
          foregroundColor: textPrimary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textFaint),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
        border: _inputBorder(border),
        enabledBorder: _inputBorder(border),
        focusedBorder: _inputBorder(brandPrimary, width: 1.8),
        errorBorder: _inputBorder(brandDanger),
        focusedErrorBorder: _inputBorder(brandDanger, width: 1.8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainer,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: brandPrimaryLight,
        side: const BorderSide(color: border),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        secondaryLabelStyle: const TextStyle(
          color: brandPrimaryDark,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? brandPrimary
              : borderStrong,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: brandPrimary,
        inactiveTrackColor: border,
        thumbColor: brandPrimary,
        overlayColor: brandPrimary.withValues(alpha: 0.12),
        valueIndicatorColor: brandPrimaryDark,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        trackHeight: 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        height: 68,
        indicatorColor: brandPrimaryLight,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight:
                states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? brandPrimaryDark
                : textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? brandPrimaryDark
                : textMuted,
            size: 24,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brandPrimary,
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandPrimary,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme(Colors.white),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMd),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _textTheme(Color color) {
    const family = null; // System font on each platform.
    final base = ThemeData.light().textTheme;
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontFamily: family,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontFamily: family,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontFamily: family,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontFamily: family,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontFamily: family,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontFamily: family,
            fontSize: 16,
            height: 1.45,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontFamily: family,
            fontSize: 14,
            height: 1.45,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontFamily: family,
            fontSize: 12.5,
            color: textMuted,
            height: 1.45,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontFamily: family,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        )
        .apply(bodyColor: color, displayColor: color);
  }
}
