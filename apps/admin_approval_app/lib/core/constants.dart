/// Category codes and labels shared with the Pro-Enroll app.
class Categories {
  Categories._();

  static const Map<String, String> labels = {
    'ac': 'AC Mechanic',
    'plumber': 'Plumber',
    'electrician': 'Electrician',
    'ro': 'RO Water Service',
    'fridge': 'Fridge Repair',
    'wash': 'Washing Machine',
    'bike': 'Bike Mechanic',
    'car': 'Car Mechanic',
    'carpenter': 'Carpenter',
    'painter': 'Painter',
  };

  static String label(String code) => labels[code] ?? code;
}

/// Rejection reasons shown when declining a pro application.
class RejectReasons {
  RejectReasons._();

  static const List<String> kyc = [
    'Aadhaar mismatch with selfie',
    'Blurry or unreadable documents',
    'Incomplete profile information',
    'Duplicate account detected',
    'Other (see notes)',
  ];

  static const List<String> document = [
    'Shop photo does not match location',
    'Certificate appears forged or expired',
    'Document quality too poor to verify',
    'Wrong document type uploaded',
    'Other (see notes)',
  ];
}
