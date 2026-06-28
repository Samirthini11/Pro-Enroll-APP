/// Parses values from GoRouter `extra` maps (int/double may arrive as num).
int parseRouteInt(dynamic raw, {int fallback = 0}) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw) ?? fallback;
  return fallback;
}

double? parseRouteDouble(dynamic raw) {
  if (raw is double) return raw;
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw);
  return null;
}

Map<String, dynamic> proDetailExtras({
  required int proId,
  required String categoryCode,
  double? lat,
  double? lng,
}) {
  return {
    'pro_id': proId,
    'category_code': categoryCode,
    if (lat != null) 'lat': lat,
    if (lng != null) 'lng': lng,
  };
}
