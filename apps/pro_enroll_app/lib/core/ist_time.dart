import 'package:intl/intl.dart';

/// India Standard Time (UTC+05:30) helpers for booking / accept times.
class IstTime {
  IstTime._();

  static const Duration offset = Duration(hours: 5, minutes: 30);

  /// Instant → IST wall-clock components as a [DateTime] (isUtc=false, not device TZ).
  static DateTime wallClock(DateTime dt) {
    final utc = dt.isUtc ? dt : dt.toUtc();
    final ist = utc.add(offset);
    return DateTime(
      ist.year,
      ist.month,
      ist.day,
      ist.hour,
      ist.minute,
      ist.second,
    );
  }

  static String format(
    DateTime dt, {
    String pattern = 'd MMM yyyy, h:mm a',
  }) {
    return '${DateFormat(pattern).format(wallClock(dt))} IST';
  }

  static String formatTime(DateTime dt) =>
      format(dt, pattern: 'h:mm a');

  static String formatDateTime(DateTime dt) =>
      format(dt, pattern: 'd MMM yyyy, h:mm a');

  /// Prefer API ISO with offset; if naive, treat digits as IST wall-clock.
  static DateTime parse(String? raw, {DateTime? fallback}) {
    final fb = fallback ?? DateTime.now().toUtc();
    if (raw == null || raw.trim().isEmpty) return fb;
    final s = raw.trim();
    final parsed = DateTime.tryParse(s);
    if (parsed != null) {
      // Has zone → trust it.
      if (RegExp(r'[Zz]|[+-]\d{2}:?\d{2}$').hasMatch(s)) {
        return parsed.toUtc();
      }
      // Naive MySQL-style — interpret as IST.
      return DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
      ).subtract(offset);
    }
    return fb;
  }
}
