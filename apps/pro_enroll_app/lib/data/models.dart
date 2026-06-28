/// Plain Dart models used through the app. Hand-written to avoid pulling
/// in `build_runner` for the MVP scaffold.
///
/// All money is stored in **paise** (Indian rupees × 100) to avoid
/// floating-point rounding, matching the backend schema in
/// `docs/05-database-schema.md`.
library;

enum KycStatus { notStarted, aadhaarPending, selfiePending, inReview, verified, rejected }

extension KycStatusX on KycStatus {
  bool get isVerified => this == KycStatus.verified;
  bool get isInReview => this == KycStatus.inReview;
  bool get isRejected => this == KycStatus.rejected;
}

enum BookingStatus {
  pendingAcceptance,
  accepted,
  onTheWay,
  inProgress,
  completed,
  cancelled,
}

class ProSkill {
  ProSkill({
    required this.categoryCode,
    required this.experienceYears,
    this.isPrimary = false,
  });

  final String categoryCode;
  final int experienceYears;
  final bool isPrimary;
}

class ProProfile {
  ProProfile({
    this.fullName,
    this.phoneE164,
    this.cityId,
    this.workRadiusKm = 5,
    this.visitFeePaise = 15000,
    this.skills = const [],
    this.isAvailable = false,
    this.kycStatus = KycStatus.notStarted,
    this.aadhaarLast4,
    this.upiId,
    this.bankAccountNo,
    this.bankIfsc,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.jobsCompleted = 0,
    this.proScore = 50,
  });

  final String? fullName;
  final String? phoneE164;
  final int? cityId;
  final int workRadiusKm;
  final int visitFeePaise;
  final List<ProSkill> skills;
  final bool isAvailable;
  final KycStatus kycStatus;
  final String? aadhaarLast4;
  final String? upiId;
  final String? bankAccountNo;
  final String? bankIfsc;
  final double ratingAvg;
  final int ratingCount;
  final int jobsCompleted;
  final int proScore;

  bool get isComplete =>
      fullName != null &&
      cityId != null &&
      skills.isNotEmpty &&
      visitFeePaise > 0;

  ProProfile copyWith({
    String? fullName,
    String? phoneE164,
    int? cityId,
    int? workRadiusKm,
    int? visitFeePaise,
    List<ProSkill>? skills,
    bool? isAvailable,
    KycStatus? kycStatus,
    String? aadhaarLast4,
    String? upiId,
    String? bankAccountNo,
    String? bankIfsc,
    double? ratingAvg,
    int? ratingCount,
    int? jobsCompleted,
    int? proScore,
  }) {
    return ProProfile(
      fullName: fullName ?? this.fullName,
      phoneE164: phoneE164 ?? this.phoneE164,
      cityId: cityId ?? this.cityId,
      workRadiusKm: workRadiusKm ?? this.workRadiusKm,
      visitFeePaise: visitFeePaise ?? this.visitFeePaise,
      skills: skills ?? this.skills,
      isAvailable: isAvailable ?? this.isAvailable,
      kycStatus: kycStatus ?? this.kycStatus,
      aadhaarLast4: aadhaarLast4 ?? this.aadhaarLast4,
      upiId: upiId ?? this.upiId,
      bankAccountNo: bankAccountNo ?? this.bankAccountNo,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      jobsCompleted: jobsCompleted ?? this.jobsCompleted,
      proScore: proScore ?? this.proScore,
    );
  }
}

class JobOffer {
  JobOffer({
    required this.id,
    required this.code,
    required this.categoryCode,
    required this.problem,
    required this.customerName,
    required this.customerAreaName,
    required this.distanceKm,
    required this.visitFeePaise,
    required this.preferredTime,
    required this.expiresAt,
  });

  final String id;
  final String code;
  final String categoryCode;
  final String problem;
  final String customerName;
  final String customerAreaName;
  final double distanceKm;
  final int visitFeePaise;
  final DateTime preferredTime;
  final DateTime expiresAt;
}

class ActiveJob {
  ActiveJob({
    required this.id,
    required this.code,
    required this.categoryCode,
    required this.problem,
    required this.customerName,
    required this.customerPhoneMasked,
    this.customerPhoneE164,
    required this.customerAddress,
    required this.customerAreaName,
    required this.distanceKm,
    required this.visitFeePaise,
    this.status = BookingStatus.accepted,
    this.finalAmountPaise,
    this.customerLat,
    this.customerLng,
  });

  final String id;
  final String code;
  final String categoryCode;
  final String problem;
  final String customerName;
  final String customerPhoneMasked;
  final String? customerPhoneE164;
  final String customerAddress;
  final String customerAreaName;
  final double distanceKm;
  final int visitFeePaise;
  final BookingStatus status;
  final int? finalAmountPaise;
  final double? customerLat;
  final double? customerLng;

  ActiveJob copyWith({
    BookingStatus? status,
    int? finalAmountPaise,
  }) {
    return ActiveJob(
      id: id,
      code: code,
      categoryCode: categoryCode,
      problem: problem,
      customerName: customerName,
      customerPhoneMasked: customerPhoneMasked,
      customerPhoneE164: customerPhoneE164,
      customerAddress: customerAddress,
      customerAreaName: customerAreaName,
      distanceKm: distanceKm,
      visitFeePaise: visitFeePaise,
      status: status ?? this.status,
      finalAmountPaise: finalAmountPaise ?? this.finalAmountPaise,
    );
  }
}

class EarningsSummary {
  EarningsSummary({
    required this.todayPaise,
    required this.weekPaise,
    required this.monthPaise,
    required this.payoutsThisMonthPaise,
    required this.pendingPayoutPaise,
    required this.jobsToday,
    this.ratingAvg,
    this.ratingCount,
    this.jobsCompleted,
  });

  final int todayPaise;
  final int weekPaise;
  final int monthPaise;
  final int payoutsThisMonthPaise;
  final int pendingPayoutPaise;
  final int jobsToday;
  final double? ratingAvg;
  final int? ratingCount;
  final int? jobsCompleted;
}

/// ─── Customer-side models ──────────────────────────────────────────────

enum AppRole { professional, customer }

class CustomerProfile {
  CustomerProfile({this.fullName, this.phoneE164, this.cityId, this.profilePhotoUrl});
  final String? fullName;
  final String? phoneE164;
  final int? cityId;
  final String? profilePhotoUrl;

  CustomerProfile copyWith({String? fullName, String? phoneE164, int? cityId, String? profilePhotoUrl}) {
    return CustomerProfile(
      fullName: fullName ?? this.fullName,
      phoneE164: phoneE164 ?? this.phoneE164,
      cityId: cityId ?? this.cityId,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    );
  }

  bool get isProfileComplete {
    final name = fullName?.trim() ?? '';
    return name.isNotEmpty && cityId != null;
  }
}

class ProSearchResult {
  ProSearchResult({
    required this.id,
    required this.fullName,
    required this.categoryCode,
    required this.cityId,
    required this.visitFeePaise,
    required this.ratingAvg,
    required this.ratingCount,
    required this.jobsCompleted,
    this.distanceKm,
  });
  final int id;
  final String fullName;
  final String categoryCode;
  final int cityId;
  final int visitFeePaise;
  final double ratingAvg;
  final int ratingCount;
  final int jobsCompleted;
  final double? distanceKm;
}

class BookingRating {
  BookingRating({required this.stars, this.reviewText});
  final int stars;
  final String? reviewText;
}

class BookingTrackingStep {
  BookingTrackingStep({
    required this.key,
    required this.label,
    required this.state,
  });

  final String key;
  final String label;
  final String state;
}

class CustomerBooking {
  CustomerBooking({
    required this.id,
    required this.professionalId,
    required this.professionalName,
    required this.categoryCode,
    required this.problemDescription,
    required this.addressText,
    required this.cityId,
    required this.visitFeePaise,
    required this.status,
    required this.createdAt,
    this.scheduledAt,
    this.rating,
    this.addressLat,
    this.addressLng,
    this.bookingCode,
    this.categoryName,
    this.cityName,
    this.finalAmountPaise,
    this.statusLabel,
    this.trackingSteps = const [],
    this.professionalPhoneE164,
    this.professionalPhoneMasked,
  });
  final int id;
  final int professionalId;
  final String professionalName;
  final String categoryCode;
  final String problemDescription;
  final String addressText;
  final int cityId;
  final int visitFeePaise;
  final String status;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final BookingRating? rating;
  final double? addressLat;
  final double? addressLng;
  final String? bookingCode;
  final String? categoryName;
  final String? cityName;
  final int? finalAmountPaise;
  final String? statusLabel;
  final List<BookingTrackingStep> trackingSteps;
  final String? professionalPhoneE164;
  final String? professionalPhoneMasked;

  bool get canComplete => const [
        'confirmed',
        'en_route',
        'arrived',
        'in_progress',
        'awaiting_payment',
      ].contains(status);
  bool get canRate => status == 'completed' && rating == null;
  bool get hasFinalAmount => finalAmountPaise != null && finalAmountPaise! >= 100;
  int get displayAmountPaise => hasFinalAmount ? finalAmountPaise! : visitFeePaise;
  String get displayStatusLabel => statusLabel ?? customerStatusLabel(status);
  bool get canContactProfessional =>
      status != 'cancelled' &&
      professionalPhoneE164 != null &&
      professionalPhoneE164!.trim().isNotEmpty;
}

String customerStatusLabel(String status) {
  return switch (status) {
    'confirmed' => 'Booking confirmed',
    'en_route' => 'Technician en route',
    'arrived' => 'Arrived',
    'in_progress' => 'Repair in progress',
    'awaiting_payment' => 'Awaiting payment',
    'completed' => 'Completed',
    'cancelled' => 'Cancelled',
    _ => status.replaceAll('_', ' '),
  };
}
