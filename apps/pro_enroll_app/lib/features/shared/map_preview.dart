import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme.dart';

/// OSM map for onboarding, active job, and booking location confirm.
class MapPreview extends StatelessWidget {
  const MapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.radiusKm = 5,
    this.caption,
    this.interactive = false,
    this.onTapLocation,
    this.mapController,
    this.secondaryLat,
    this.secondaryLng,
    this.secondaryLabel,
  });

  final double latitude;
  final double longitude;
  final double radiusKm;
  final String? caption;
  final bool interactive;
  final void Function(double lat, double lng)? onTapLocation;
  final MapController? mapController;
  /// Optional second pin (e.g. technician live location).
  final double? secondaryLat;
  final double? secondaryLng;
  final String? secondaryLabel;

  static double _zoomForRadius(double km) {
    if (km <= 3) return 13.0;
    if (km <= 8) return 12.0;
    if (km <= 15) return 11.0;
    return 10.0;
  }

  static double _zoomForSpanKm(double spanKm) {
    if (spanKm <= 1) return 14.0;
    if (spanKm <= 3) return 13.0;
    if (spanKm <= 8) return 12.0;
    if (spanKm <= 15) return 11.0;
    return 10.0;
  }

  @override
  Widget build(BuildContext context) {
    final hasSecondary = secondaryLat != null && secondaryLng != null;
    final primary = LatLng(latitude, longitude);
    final center = hasSecondary
        ? LatLng(
            (latitude + secondaryLat!) / 2,
            (longitude + secondaryLng!) / 2,
          )
        : primary;
    final spanKm = hasSecondary
        ? const Distance().as(
            LengthUnit.Kilometer,
            primary,
            LatLng(secondaryLat!, secondaryLng!),
          )
        : radiusKm;
    final zoom = hasSecondary ? _zoomForSpanKm(spanKm) : _zoomForRadius(radiusKm);
    final map = FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        interactionOptions: InteractionOptions(
          flags: interactive
              ? InteractiveFlag.drag |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom
              : InteractiveFlag.none,
        ),
        onTap: interactive && onTapLocation != null
            ? (tap, point) => onTapLocation!(point.latitude, point.longitude)
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.proenroll.app',
        ),
        if (radiusKm > 0)
          CircleLayer(
            circles: [
              CircleMarker(
                // Work-area ring around pro when secondary pin exists; else around primary.
                point: hasSecondary
                    ? LatLng(secondaryLat!, secondaryLng!)
                    : primary,
                radius: radiusKm * 1000,
                useRadiusInMeter: true,
                color: AppTheme.brandPrimary.withValues(alpha: 0.08),
                borderColor: AppTheme.brandPrimary.withValues(alpha: 0.40),
                borderStrokeWidth: 2,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: primary,
              width: 40,
              height: 40,
              child: Icon(
                hasSecondary ? Icons.place : Icons.place,
                size: 40,
                color: AppTheme.brandPrimaryDark,
                shadows: const [Shadow(color: Colors.white, blurRadius: 8)],
              ),
            ),
            if (hasSecondary)
              Marker(
                point: LatLng(secondaryLat!, secondaryLng!),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.handyman,
                  size: 34,
                  color: AppTheme.brandSuccess,
                  shadows: [Shadow(color: Colors.white, blurRadius: 8)],
                ),
              ),
          ],
        ),
      ],
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        if (interactive) map else AbsorbPointer(child: map),
        if (caption != null)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  caption!,
                  style: const TextStyle(
                    color: AppTheme.brandPrimaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
