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
  arrived,
  inProgress,
  awaitingPayment,
  completed,
  cancelled,
}

class ProSkill {
  ProSkill({
    required this.categoryCode,
    required this.experienceYears,
    this.experienceStartYear,
    this.isPrimary = false,
    this.visitFeePaise = 15000,
  });

  final String categoryCode;
  /// Calculated years (from API: current IST year − start year).
  final int experienceYears;
  /// Calendar year the pro started this service.
  final int? experienceStartYear;
  final bool isPrimary;
  /// Visiting charge for this service (paise).
  final int visitFeePaise;

  int get effectiveStartYear =>
      experienceStartYear ?? (DateTime.now().year - experienceYears.clamp(0, 50));

  ProSkill copyWith({
    int? experienceYears,
    int? experienceStartYear,
    bool? isPrimary,
    int? visitFeePaise,
  }) {
    return ProSkill(
      categoryCode: categoryCode,
      experienceYears: experienceYears ?? this.experienceYears,
      experienceStartYear: experienceStartYear ?? this.experienceStartYear,
      isPrimary: isPrimary ?? this.isPrimary,
      visitFeePaise: visitFeePaise ?? this.visitFeePaise,
    );
  }
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
    this.listingHeld = false,
    this.freeBookingsUsed = 0,
    this.canEditExperience = true,
    this.experienceEditRequestStatus,
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
  final bool listingHeld;
  final int freeBookingsUsed;
  /// False after enrollment until admin unlocks an experience-year edit.
  final bool canEditExperience;
  /// pending | approved | rejected | used (latest Help request).
  final String? experienceEditRequestStatus;

  bool get isComplete =>
      fullName != null &&
      cityId != null &&
      skills.isNotEmpty &&
      visitFeePaise > 0;

  /// Fee for a service category (skill fee, else profile fallback).
  int visitFeePaiseFor(String categoryCode) {
    for (final s in skills) {
      if (s.categoryCode == categoryCode && s.visitFeePaise > 0) {
        return s.visitFeePaise;
      }
    }
    return visitFeePaise;
  }

  /// Lowest skill fee (for "from ₹X" labels).
  int get minVisitFeePaise {
    if (skills.isEmpty) return visitFeePaise;
    var min = skills.first.visitFeePaise;
    for (final s in skills) {
      if (s.visitFeePaise > 0 && s.visitFeePaise < min) min = s.visitFeePaise;
    }
    return min > 0 ? min : visitFeePaise;
  }

  bool get hasVaryingVisitFees {
    if (skills.length < 2) return false;
    final first = skills.first.visitFeePaise;
    return skills.any((s) => s.visitFeePaise != first);
  }

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
    bool? listingHeld,
    int? freeBookingsUsed,
    bool? canEditExperience,
    String? experienceEditRequestStatus,
    bool clearExperienceEditRequestStatus = false,
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
      listingHeld: listingHeld ?? this.listingHeld,
      freeBookingsUsed: freeBookingsUsed ?? this.freeBookingsUsed,
      canEditExperience: canEditExperience ?? this.canEditExperience,
      experienceEditRequestStatus: clearExperienceEditRequestStatus
          ? null
          : (experienceEditRequestStatus ?? this.experienceEditRequestStatus),
    );
  }
}

class CommissionPreview {
  CommissionPreview({
    required this.isFreeBooking,
    required this.freeBookingsRemaining,
    required this.visitCommissionPercent,
    required this.commissionPaise,
    required this.proCreditPaise,
    this.label,
  });

  final bool isFreeBooking;
  final int freeBookingsRemaining;
  final int visitCommissionPercent;
  final int commissionPaise;
  final int proCreditPaise;
  final String? label;
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
    this.commissionPreview,
    this.customerLat,
    this.customerLng,
    this.canReject = true,
    this.cancelsRemainingToday,
    this.dailyCancelLimit = 5,
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
  final CommissionPreview? commissionPreview;
  final double? customerLat;
  final double? customerLng;
  final bool canReject;
  final int? cancelsRemainingToday;
  final int dailyCancelLimit;

  bool get hasServiceLocation => customerLat != null && customerLng != null;
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
    this.commissionPreview,
    this.proCreditPaise,
    this.scheduledAt,
    this.canCancel = false,
    this.rejectRequiresReason = false,
    this.rejectPenaltyPaise = 0,
    this.cancelsRemainingToday,
    this.dailyCancelLimit = 5,
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
  final CommissionPreview? commissionPreview;
  final int? proCreditPaise;
  final DateTime? scheduledAt;
  final bool canCancel;

  /// Rejecting now (while on the way) needs a reason from the pro.
  final bool rejectRequiresReason;

  /// Wallet penalty (paise) charged if the pro rejects now. 0 = no penalty.
  final int rejectPenaltyPaise;
  final int? cancelsRemainingToday;
  final int dailyCancelLimit;

  ActiveJob copyWith({
    BookingStatus? status,
    int? finalAmountPaise,
    CommissionPreview? commissionPreview,
    int? proCreditPaise,
    DateTime? scheduledAt,
    bool? canCancel,
    bool? rejectRequiresReason,
    int? rejectPenaltyPaise,
    int? cancelsRemainingToday,
    int? dailyCancelLimit,
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
      customerLat: customerLat,
      customerLng: customerLng,
      commissionPreview: commissionPreview ?? this.commissionPreview,
      proCreditPaise: proCreditPaise ?? this.proCreditPaise,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      canCancel: canCancel ?? this.canCancel,
      rejectRequiresReason: rejectRequiresReason ?? this.rejectRequiresReason,
      rejectPenaltyPaise: rejectPenaltyPaise ?? this.rejectPenaltyPaise,
      cancelsRemainingToday: cancelsRemainingToday ?? this.cancelsRemainingToday,
      dailyCancelLimit: dailyCancelLimit ?? this.dailyCancelLimit,
    );
  }
}

/// Past / recent booking row on the professional Jobs tab.
class ProJobHistoryItem {
  ProJobHistoryItem({
    required this.id,
    required this.code,
    required this.categoryCode,
    required this.problem,
    required this.customerName,
    required this.customerAreaName,
    required this.visitFeePaise,
    required this.status,
    required this.statusLabel,
    this.categoryName,
    this.customerPhoneE164,
    this.customerPhoneMasked,
    this.proCreditPaise,
    this.commissionPaise,
    this.commissionWaived = false,
    this.visitFeePaid = false,
    this.visitFeePaymentMethod,
    this.ratingStars,
    this.ratingReview,
    this.createdAt,
    this.completedAt,
    this.updatedAt,
  });

  final String id;
  final String code;
  final String categoryCode;
  final String? categoryName;
  final String problem;
  final String customerName;
  final String customerAreaName;
  final String? customerPhoneE164;
  final String? customerPhoneMasked;
  final int visitFeePaise;
  final int? proCreditPaise;
  final int? commissionPaise;
  final bool commissionWaived;
  final String status;
  final String statusLabel;
  final bool visitFeePaid;
  final String? visitFeePaymentMethod;
  final int? ratingStars;
  final String? ratingReview;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  DateTime? get displayAt => completedAt ?? updatedAt ?? createdAt;

  bool get isLive => const [
        'confirmed',
        'en_route',
        'arrived',
        'in_progress',
        'awaiting_payment',
      ].contains(status);

  bool get canContactCustomer =>
      isLive &&
      customerPhoneE164 != null &&
      customerPhoneE164!.trim().isNotEmpty;
}

class EarningsSummary {
  EarningsSummary({
    required this.todayPaise,
    required this.weekPaise,
    required this.monthPaise,
    required this.payoutsThisMonthPaise,
    required this.pendingPayoutPaise,
    required this.jobsToday,
    this.walletBalancePaise = 0,
    this.ratingAvg,
    this.ratingCount,
    this.jobsCompleted,
    this.visitCommissionPercent = 10,
    this.freeBookingLimit = 5,
    this.freeBookingsUsed = 0,
    this.freeBookingsRemaining = 5,
    this.listingHeld = false,
    this.commissionTodayPaise = 0,
    this.commissionNote,
    this.platformFeeDuePaise = 0,
    this.walletMinAcceptPaise = 5000,
    this.walletRechargeMinPaise = 5000,
    this.suggestedRechargePaise = 5000,
    this.canAcceptJobs = true,
    this.companyUpiId,
    this.companyUpiName,
    this.companyUpiPayUri,
    this.pendingRechargePaise = 0,
  });

  final int todayPaise;
  final int weekPaise;
  final int monthPaise;
  final int payoutsThisMonthPaise;
  final int pendingPayoutPaise;
  final int jobsToday;
  /// Prepaid wallet balance (recharges − platform fee deductions).
  final int walletBalancePaise;
  final double? ratingAvg;
  final int? ratingCount;
  final int? jobsCompleted;
  final int visitCommissionPercent;
  final int freeBookingLimit;
  final int freeBookingsUsed;
  final int freeBookingsRemaining;
  final bool listingHeld;
  final int commissionTodayPaise;
  final String? commissionNote;
  final int platformFeeDuePaise;
  final int walletMinAcceptPaise;
  final int walletRechargeMinPaise;
  final int suggestedRechargePaise;
  final bool canAcceptJobs;
  final String? companyUpiId;
  final String? companyUpiName;
  final String? companyUpiPayUri;
  /// Submitted recharges still waiting for admin approval.
  final int pendingRechargePaise;
}

/// A wallet top-up submitted to admin for approval.
class WalletRechargeRequest {
  WalletRechargeRequest({
    required this.id,
    required this.amountPaise,
    required this.utr,
    required this.status,
    required this.statusLabel,
    this.rejectedReason,
    this.createdAt,
    this.reviewedAt,
  });

  final String id;
  final int amountPaise;
  final String utr;
  final String status;
  final String statusLabel;
  final String? rejectedReason;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

class CreditHistoryItem {
  CreditHistoryItem({
    required this.id,
    required this.bookingCode,
    required this.categoryCode,
    required this.creditPaise,
    required this.visitFeePaise,
    required this.commissionPaise,
    required this.commissionWaived,
    required this.platformFeePaid,
    this.finalAmountPaise,
    this.utr,
    this.completedAt,
    this.label,
    this.entryType,
  });

  final String id;
  final String bookingCode;
  final String categoryCode;
  final int creditPaise;
  final int visitFeePaise;
  final int commissionPaise;
  final bool commissionWaived;
  final bool platformFeePaid;
  final int? finalAmountPaise;
  final String? utr;
  final DateTime? completedAt;
  final String? label;
  /// recharge | commission_debit | null (legacy job credit)
  final String? entryType;

  bool get isRecharge => entryType == 'recharge' || creditPaise > 0 && entryType != null;
  bool get isDebit => entryType == 'commission_debit' || creditPaise < 0;
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

/// Live technician location while en route (from API `tracking` object).
class BookingLiveTracking {
  const BookingLiveTracking({
    required this.proLat,
    required this.proLng,
    required this.distanceKm,
    required this.etaMinutes,
    this.updatedAt,
  });

  final double proLat;
  final double proLng;
  final double distanceKm;
  final int etaMinutes;
  final DateTime? updatedAt;
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
    this.acceptedAt,
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
    this.visitFeePaid = false,
    this.visitFeePaymentMethod,
    this.tracking,
    this.apiCanCancel,
    this.cancelHint,
    this.cancelUnlockAt,
    this.cancelsRemainingToday,
    this.dailyCancelLimit = 5,
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
  final DateTime? acceptedAt;
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
  final bool visitFeePaid;
  final String? visitFeePaymentMethod;
  final BookingLiveTracking? tracking;
  /// Server decision: confirmed, or en_route after 10 min stuck.
  final bool? apiCanCancel;
  final String? cancelHint;
  final DateTime? cancelUnlockAt;
  final int? cancelsRemainingToday;
  final int dailyCancelLimit;

  /// Show live map + ETA only until work starts (not during repair).
  bool get isTrackable => const ['en_route', 'arrived'].contains(status);
  bool get isInProcess => const [
        'confirmed',
        'en_route',
        'arrived',
        'in_progress',
        'awaiting_payment',
      ].contains(status);

  /// Prefer API flag; fall back to confirmed-only for older payloads.
  bool get canCancel => apiCanCancel ?? (status == 'confirmed');
  /// Payment confirms work and closes the booking (no separate Complete step).
  bool get canPayVisitFee => !visitFeePaid && status == 'awaiting_payment';
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
    'awaiting_payment' => 'Confirm & pay visit fee',
    'completed' => 'Completed',
    'cancelled' => 'Cancelled',
    _ => status.replaceAll('_', ' '),
  };
}
