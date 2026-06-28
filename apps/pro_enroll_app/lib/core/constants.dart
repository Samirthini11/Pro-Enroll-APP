import 'package:flutter/material.dart';

import 'category_icons.dart';

/// Reference data with local fallbacks. Categories are loaded from
/// `GET /v1/categories` when [AppConfig.hasApi] is on.

class CityRef {
  const CityRef(
    this.id,
    this.name,
    this.state, {
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String name;
  final String state;
  final double latitude;
  final double longitude;
}

const supportedCities = <CityRef>[
  CityRef(1, 'Pondicherry', 'Puducherry',
      latitude: 11.9416, longitude: 79.8083),
  CityRef(2, 'Karaikal', 'Puducherry', latitude: 10.9254, longitude: 79.8380),
  CityRef(3, 'Cuddalore', 'Tamil Nadu', latitude: 11.7480, longitude: 79.7714),
  CityRef(4, 'Villupuram', 'Tamil Nadu', latitude: 11.9401, longitude: 79.4861),
  CityRef(5, 'Tindivanam', 'Tamil Nadu', latitude: 12.2340, longitude: 79.6550),
  CityRef(6, 'Panruti', 'Tamil Nadu', latitude: 11.7766, longitude: 79.5529),
  CityRef(7, 'Neyveli', 'Tamil Nadu', latitude: 11.5436, longitude: 79.4832),
];

CityRef cityById(int id) => supportedCities.firstWhere(
      (c) => c.id == id,
      orElse: () => supportedCities.first,
    );

class CategoryRef {
  const CategoryRef({
    required this.code,
    required this.nameEn,
    required this.nameTa,
    required this.icon,
    required this.basePrice,
    required this.defaultVisitFee,
  });

  final String code;
  final String nameEn;
  final String nameTa;
  final IconData icon;
  /// Platform base / starting price in rupees (from `base_price_paise`).
  final int basePrice;
  /// Suggested visit fee in rupees (from `default_visit_fee_paise`).
  final int defaultVisitFee;

  int get basePricePaise => basePrice * 100;
  int get defaultVisitFeePaise => defaultVisitFee * 100;

  String name(String lang) => lang == 'ta' ? nameTa : nameEn;

  String priceLabel(String lang) => lang == 'ta'
      ? 'அடிப்படை ₹$basePrice'
      : 'Base price ₹$basePrice';

  String visitFeeLabel(String lang) => lang == 'ta'
      ? 'வருகை ₹$defaultVisitFee'
      : 'Visit ₹$defaultVisitFee';

  factory CategoryRef.fromApi(Map<String, dynamic> map) {
    final visitPaise =
        (map['default_visit_fee_paise'] as num?)?.toInt() ?? 15000;
    final basePaise = (map['base_price_paise'] as num?)?.toInt() ?? visitPaise;
    final iconKey = map['icon_key'] as String? ?? 'build';
    return CategoryRef(
      code: map['code'] as String? ?? '',
      nameEn: map['name_en'] as String? ?? map['code'] as String? ?? '',
      nameTa: map['name_ta'] as String? ?? map['name_en'] as String? ?? '',
      icon: categoryIconForKey(iconKey),
      basePrice: basePaise ~/ 100,
      defaultVisitFee: visitPaise ~/ 100,
    );
  }
}

extension CategoryListX on List<CategoryRef> {
  CategoryRef? tryByCode(String code) {
    for (final c in this) {
      if (c.code == code) return c;
    }
    return null;
  }

  CategoryRef byCode(String code) =>
      tryByCode(code) ?? (isNotEmpty ? first : supportedCategories.first);
}

const supportedCategories = <CategoryRef>[
  CategoryRef(
    code: 'ac',
    nameEn: 'AC Mechanic',
    nameTa: 'AC மெக்கானிக்',
    icon: Icons.ac_unit,
    basePrice: 200,
    defaultVisitFee: 200,
  ),
  CategoryRef(
    code: 'plumber',
    nameEn: 'Plumber',
    nameTa: 'பிளம்பர்',
    icon: Icons.plumbing,
    basePrice: 150,
    defaultVisitFee: 150,
  ),
  CategoryRef(
    code: 'electrician',
    nameEn: 'Electrician',
    nameTa: 'மின்சார வேலை',
    icon: Icons.electrical_services,
    basePrice: 150,
    defaultVisitFee: 150,
  ),
  CategoryRef(
    code: 'ro',
    nameEn: 'RO Water Service',
    nameTa: 'RO வாட்டர் சர்வீஸ்',
    icon: Icons.water_drop,
    basePrice: 150,
    defaultVisitFee: 150,
  ),
  CategoryRef(
    code: 'fridge',
    nameEn: 'Fridge Repair',
    nameTa: 'குளிர்சாதனம் ரிப்பேர்',
    icon: Icons.kitchen,
    basePrice: 200,
    defaultVisitFee: 200,
  ),
  CategoryRef(
    code: 'wash',
    nameEn: 'Washing Machine',
    nameTa: 'வாஷிங் மெஷின்',
    icon: Icons.local_laundry_service,
    basePrice: 200,
    defaultVisitFee: 200,
  ),
  CategoryRef(
    code: 'car',
    nameEn: 'Car Mechanic',
    nameTa: 'கார் மெக்கானிக்',
    icon: Icons.directions_car,
    basePrice: 250,
    defaultVisitFee: 250,
  ),
  CategoryRef(
    code: 'bike',
    nameEn: 'Bike Mechanic',
    nameTa: 'பைக் மெக்கானிக்',
    icon: Icons.two_wheeler,
    basePrice: 150,
    defaultVisitFee: 150,
  ),
];

class LanguageRef {
  const LanguageRef(this.code, this.label, this.nativeLabel);
  final String code;
  final String label;
  final String nativeLabel;
}

// English first for v1 (matches the default in LocaleNotifier). Tamil
// stays available as a one-tap toggle and will be promoted to the
// primary language once translations are reviewed by native speakers.
const supportedLanguages = <LanguageRef>[
  LanguageRef('en', 'English', 'English'),
  LanguageRef('ta', 'Tamil', 'தமிழ்'),
];
