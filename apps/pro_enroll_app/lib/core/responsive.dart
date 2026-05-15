import 'package:flutter/material.dart';

/// Responsive helpers for the Pro-Enroll app.
///
/// We target a mobile-first range of devices: from tiny phones
/// (320 dp wide, e.g. Galaxy Fold front display) all the way up to
/// large phones, foldables in landscape, and 7" tablets. We deliberately
/// do *not* try to be a full tablet app yet — that comes after the
/// pilot.
class Breakpoints {
  Breakpoints._();

  /// < 360 dp wide → very small Android phones, e.g. Galaxy A01 / Fold front.
  static const double xs = 360;

  /// 360 – 412 dp → typical Indian budget phones (Redmi 9A class).
  static const double sm = 412;

  /// 412 – 600 dp → larger phones, OnePlus, Pixel Pro.
  static const double md = 600;

  /// 600 – 905 dp → foldables unfolded, small tablets.
  static const double lg = 905;
}

enum DeviceSize { xs, sm, md, lg }

extension ResponsiveContext on BuildContext {
  Size get screen => MediaQuery.sizeOf(this);
  double get screenW => screen.width;
  double get screenH => screen.height;

  /// Bucketise the current screen into a coarse size.
  DeviceSize get deviceSize {
    final w = screenW;
    if (w < Breakpoints.xs) return DeviceSize.xs;
    if (w < Breakpoints.sm) return DeviceSize.sm;
    if (w < Breakpoints.md) return DeviceSize.md;
    return DeviceSize.lg;
  }

  /// Horizontal page padding that scales with viewport width.
  double get pageHPadding {
    switch (deviceSize) {
      case DeviceSize.xs:
        return 14;
      case DeviceSize.sm:
        return 18;
      case DeviceSize.md:
        return 20;
      case DeviceSize.lg:
        return 28;
    }
  }

  /// Vertical page padding, slightly tighter on small phones.
  double get pageVPadding {
    switch (deviceSize) {
      case DeviceSize.xs:
        return 12;
      case DeviceSize.sm:
        return 16;
      case DeviceSize.md:
        return 20;
      case DeviceSize.lg:
        return 24;
    }
  }

  EdgeInsets get pagePadding =>
      EdgeInsets.symmetric(horizontal: pageHPadding, vertical: pageVPadding);

  /// Number of grid columns for category-style pickers.
  int get gridColumns {
    final w = screenW;
    if (w < 320) return 2; // safe baseline
    if (w >= 720) return 4;
    if (w >= 520) return 3;
    return 2;
  }

  /// A capped maximum width for forms / content on wide screens (foldables,
  /// small tablets, web). On narrow phones this just returns the full width.
  double get contentMaxWidth =>
      screenW > 720 ? 560 : screenW;

  bool get isCompactHeight => screenH < 680;

  /// Helper to pick one value across our four device buckets.
  T responsive<T>({required T xs, T? sm, T? md, T? lg}) {
    switch (deviceSize) {
      case DeviceSize.xs:
        return xs;
      case DeviceSize.sm:
        return sm ?? xs;
      case DeviceSize.md:
        return md ?? sm ?? xs;
      case DeviceSize.lg:
        return lg ?? md ?? sm ?? xs;
    }
  }
}

/// Constrains a child to [BuildContext.contentMaxWidth] and centers it.
///
/// Use for forms and onboarding flows so the UI doesn't stretch
/// uncomfortably wide on foldables or in the browser.
class ContentMaxWidth extends StatelessWidget {
  const ContentMaxWidth({
    super.key,
    required this.child,
    this.maxWidth,
  });

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? context.contentMaxWidth,
        ),
        child: child,
      ),
    );
  }
}
