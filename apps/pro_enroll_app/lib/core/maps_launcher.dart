import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens Google Maps (or a geo fallback) for navigation to a service location.
class MapsLauncher {
  MapsLauncher._();

  /// Directions from the device's current location to [destLat]/[destLng].
  /// Optional [originLat]/[originLng] pin the start when already known.
  static Future<void> openDirections(
    BuildContext context, {
    required double destLat,
    required double destLng,
    double? originLat,
    double? originLng,
    String? label,
  }) async {
    final dest = '$destLat,$destLng';
    final destLabel = (label != null && label.trim().isNotEmpty)
        ? label.trim()
        : 'Service location';

    final buffer = StringBuffer(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${Uri.encodeComponent(dest)}'
      '&travelmode=driving',
    );
    if (originLat != null && originLng != null) {
      buffer.write(
        '&origin=${Uri.encodeComponent('$originLat,$originLng')}',
      );
    }
    final gmaps = Uri.parse(buffer.toString());

    try {
      final ok = await launchUrl(gmaps, mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (_) {}

    // Android Google Navigation intent.
    final nav = Uri.parse('google.navigation:q=$dest&mode=d');
    try {
      if (await canLaunchUrl(nav)) {
        final ok = await launchUrl(nav, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
    } catch (_) {}

    // Generic geo pin fallback.
    final geo = Uri.parse(
      'geo:$dest?q=${Uri.encodeComponent('$dest($destLabel)')}',
    );
    try {
      final ok = await launchUrl(geo, mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (_) {}

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }
}
