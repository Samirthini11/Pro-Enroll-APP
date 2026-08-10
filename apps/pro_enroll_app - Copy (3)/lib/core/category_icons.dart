import 'package:flutter/material.dart';

/// Maps backend `icon_key` strings to Material icons.
IconData categoryIconForKey(String key) {
  switch (key) {
    case 'ac_unit':
      return Icons.ac_unit;
    case 'plumbing':
      return Icons.plumbing;
    case 'electrical_services':
      return Icons.electrical_services;
    case 'water_drop':
      return Icons.water_drop;
    case 'kitchen':
      return Icons.kitchen;
    case 'local_laundry_service':
      return Icons.local_laundry_service;
    case 'directions_car':
      return Icons.directions_car;
    case 'two_wheeler':
      return Icons.two_wheeler;
    default:
      return Icons.build;
  }
}

String categoryIconKey(IconData icon) {
  if (icon == Icons.ac_unit) return 'ac_unit';
  if (icon == Icons.plumbing) return 'plumbing';
  if (icon == Icons.electrical_services) return 'electrical_services';
  if (icon == Icons.water_drop) return 'water_drop';
  if (icon == Icons.kitchen) return 'kitchen';
  if (icon == Icons.local_laundry_service) return 'local_laundry_service';
  if (icon == Icons.directions_car) return 'directions_car';
  if (icon == Icons.two_wheeler) return 'two_wheeler';
  return 'build';
}
