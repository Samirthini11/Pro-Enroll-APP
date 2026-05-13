import 'package:flutter/material.dart';

/// All hard-coded reference data lives here so the rest of the app stays
/// thin. In a production build these would come from the backend
/// `/v1/cities` and `/v1/categories` endpoints.

class CityRef {
  const CityRef(this.id, this.name, this.state);
  final int id;
  final String name;
  final String state;
}

const supportedCities = <CityRef>[
  CityRef(1, 'Pondicherry', 'Puducherry'),
  CityRef(2, 'Karaikal', 'Puducherry'),
  CityRef(3, 'Cuddalore', 'Tamil Nadu'),
  CityRef(4, 'Villupuram', 'Tamil Nadu'),
  CityRef(5, 'Tindivanam', 'Tamil Nadu'),
  CityRef(6, 'Panruti', 'Tamil Nadu'),
  CityRef(7, 'Neyveli', 'Tamil Nadu'),
];

class CategoryRef {
  const CategoryRef({
    required this.code,
    required this.nameEn,
    required this.nameTa,
    required this.icon,
    required this.defaultVisitFee,
  });

  final String code;
  final String nameEn;
  final String nameTa;
  final IconData icon;
  final int defaultVisitFee; // in rupees

  String name(String lang) => lang == 'ta' ? nameTa : nameEn;
}

const supportedCategories = <CategoryRef>[
  CategoryRef(
    code: 'ac',
    nameEn: 'AC Mechanic',
    nameTa: 'AC மெக்கானிக்',
    icon: Icons.ac_unit,
    defaultVisitFee: 200,
  ),
  CategoryRef(
    code: 'plumber',
    nameEn: 'Plumber',
    nameTa: 'பிளம்பர்',
    icon: Icons.plumbing,
    defaultVisitFee: 150,
  ),
  CategoryRef(
    code: 'electrician',
    nameEn: 'Electrician',
    nameTa: 'மின்சார வேலை',
    icon: Icons.electrical_services,
    defaultVisitFee: 150,
  ),
  CategoryRef(
    code: 'ro',
    nameEn: 'RO Water Service',
    nameTa: 'RO வாட்டர் சர்வீஸ்',
    icon: Icons.water_drop,
    defaultVisitFee: 150,
  ),
  CategoryRef(
    code: 'fridge',
    nameEn: 'Fridge Repair',
    nameTa: 'குளிர்சாதனம் ரிப்பேர்',
    icon: Icons.kitchen,
    defaultVisitFee: 200,
  ),
  CategoryRef(
    code: 'wash',
    nameEn: 'Washing Machine',
    nameTa: 'வாஷிங் மெஷின்',
    icon: Icons.local_laundry_service,
    defaultVisitFee: 200,
  ),
  CategoryRef(
    code: 'car',
    nameEn: 'Car Mechanic',
    nameTa: 'கார் மெக்கானிக்',
    icon: Icons.directions_car,
    defaultVisitFee: 250,
  ),
  CategoryRef(
    code: 'bike',
    nameEn: 'Bike Mechanic',
    nameTa: 'பைக் மெக்கானிக்',
    icon: Icons.two_wheeler,
    defaultVisitFee: 150,
  ),
];

class LanguageRef {
  const LanguageRef(this.code, this.label, this.nativeLabel);
  final String code;
  final String label;
  final String nativeLabel;
}

const supportedLanguages = <LanguageRef>[
  LanguageRef('ta', 'Tamil', 'தமிழ்'),
  LanguageRef('en', 'English', 'English'),
];
