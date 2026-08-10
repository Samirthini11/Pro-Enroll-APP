import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme.dart';

/// Interactive OSM map preview for onboarding / active job screens.
class MapPreview extends StatelessWidget {
  const MapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.radiusKm = 5,
    this.caption,
  });

  final double latitude;
  final double longitude;
  final double radiusKm;
  final String? caption;

  static double _zoomForRadius(double km) {
    if (km <= 3) return 13.0;
    if (km <= 8) return 12.0;
    if (km <= 15) return 11.0;
    return 10.0;
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(latitude, longitude);
    final zoom = _zoomForRadius(radiusKm);

    return Stack(
      fit: StackFit.expand,
      children: [
        AbsorbPointer(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: zoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.proenroll.app',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: center,
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
                    point: center,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.place,
                      size: 40,
                      color: AppTheme.brandPrimaryDark,
                      shadows: [Shadow(color: Colors.white, blurRadius: 8)],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
