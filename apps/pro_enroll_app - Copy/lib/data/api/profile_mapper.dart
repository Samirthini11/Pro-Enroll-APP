import '../models.dart';

KycStatus kycStatusFromApi(String? raw) {
  switch (raw) {
    case 'aadhaar_pending':
      return KycStatus.aadhaarPending;
    case 'selfie_pending':
      return KycStatus.selfiePending;
    case 'in_review':
      return KycStatus.inReview;
    case 'verified':
      return KycStatus.verified;
    case 'rejected':
      return KycStatus.rejected;
    default:
      return KycStatus.notStarted;
  }
}

String kycStatusToApi(KycStatus s) {
  switch (s) {
    case KycStatus.aadhaarPending:
      return 'aadhaar_pending';
    case KycStatus.selfiePending:
      return 'selfie_pending';
    case KycStatus.inReview:
      return 'in_review';
    case KycStatus.verified:
      return 'verified';
    case KycStatus.rejected:
      return 'rejected';
    case KycStatus.notStarted:
      return 'not_started';
  }
}

BookingStatus bookingStatusFromApi(String? raw) {
  switch (raw) {
    case 'on_the_way':
      return BookingStatus.onTheWay;
    case 'in_progress':
      return BookingStatus.inProgress;
    case 'completed':
      return BookingStatus.completed;
    case 'cancelled':
      return BookingStatus.cancelled;
    default:
      return BookingStatus.accepted;
  }
}

String bookingStatusToApi(BookingStatus s) {
  switch (s) {
    case BookingStatus.onTheWay:
      return 'on_the_way';
    case BookingStatus.inProgress:
      return 'in_progress';
    case BookingStatus.completed:
      return 'completed';
    case BookingStatus.cancelled:
      return 'cancelled';
    case BookingStatus.pendingAcceptance:
    case BookingStatus.accepted:
      return 'accepted';
  }
}

ProProfile? profileFromApiMap(Map<String, dynamic>? map) {
  if (map == null || map['registered'] == false) return null;

  final skillsRaw = map['skills'];
  final skills = <ProSkill>[];
  if (skillsRaw is List) {
    for (final s in skillsRaw) {
      if (s is! Map) continue;
      skills.add(ProSkill(
        categoryCode: s['category_code'] as String,
        experienceYears: (s['experience_years'] as num?)?.toInt() ?? 0,
        isPrimary: s['is_primary'] == true,
      ));
    }
  }

  return ProProfile(
    fullName: map['full_name'] as String?,
    phoneE164: map['phone_e164'] as String?,
    cityId: (map['city_id'] as num?)?.toInt(),
    workRadiusKm: (map['work_radius_km'] as num?)?.toInt() ?? 5,
    visitFeePaise: (map['visit_fee_paise'] as num?)?.toInt() ?? 15000,
    skills: skills,
    isAvailable: map['is_available'] == true,
    kycStatus: kycStatusFromApi(map['kyc_status'] as String?),
    aadhaarLast4: map['aadhaar_last4'] as String?,
    upiId: map['upi_id'] as String?,
    bankAccountNo: map['bank_account_no'] as String?,
    bankIfsc: map['bank_ifsc'] as String?,
    ratingAvg: (map['rating_avg'] as num?)?.toDouble() ?? 0,
    ratingCount: (map['rating_count'] as num?)?.toInt() ?? 0,
    jobsCompleted: (map['jobs_completed'] as num?)?.toInt() ?? 0,
    proScore: (map['pro_score'] as num?)?.toInt() ?? 50,
  );
}

JobOffer jobOfferFromApi(Map<String, dynamic> m) {
  return JobOffer(
    id: m['id'] as String,
    code: m['code'] as String,
    categoryCode: m['category_code'] as String,
    problem: m['problem'] as String,
    customerName: m['customer_name'] as String,
    customerAreaName: m['customer_area_name'] as String,
    distanceKm: (m['distance_km'] as num).toDouble(),
    visitFeePaise: (m['visit_fee_paise'] as num).toInt(),
    preferredTime: DateTime.parse(m['preferred_time'] as String),
    expiresAt: DateTime.parse(m['expires_at'] as String),
  );
}

ActiveJob activeJobFromApi(Map<String, dynamic> m) {
  return ActiveJob(
    id: m['id'] as String,
    code: m['code'] as String,
    categoryCode: m['category_code'] as String,
    problem: m['problem'] as String,
    customerName: m['customer_name'] as String,
    customerPhoneMasked: m['customer_phone_masked'] as String,
    customerAddress: m['customer_address'] as String,
    customerAreaName: m['customer_area_name'] as String,
    distanceKm: (m['distance_km'] as num).toDouble(),
    visitFeePaise: (m['visit_fee_paise'] as num).toInt(),
    status: bookingStatusFromApi(m['status'] as String?),
    finalAmountPaise: (m['final_amount_paise'] as num?)?.toInt(),
    customerLat: (m['customer_lat'] as num?)?.toDouble(),
    customerLng: (m['customer_lng'] as num?)?.toDouble(),
  );
}

EarningsSummary earningsFromApi(Map<String, dynamic> m) {
  return EarningsSummary(
    todayPaise: (m['today_paise'] as num).toInt(),
    weekPaise: (m['week_paise'] as num).toInt(),
    monthPaise: (m['month_paise'] as num).toInt(),
    payoutsThisMonthPaise: (m['payouts_this_month_paise'] as num).toInt(),
    pendingPayoutPaise: (m['pending_payout_paise'] as num).toInt(),
    jobsToday: (m['jobs_today'] as num).toInt(),
  );
}

// ─── Customer-side mappers ──────────────────────────────────────────────

ProSearchResult proSearchResultFromApi(Map<String, dynamic> m) {
  final rawId = m['id'];
  final id = rawId is num ? rawId.toInt() : int.tryParse(rawId.toString()) ?? 0;
  return ProSearchResult(
    id: id,
    fullName: m['full_name'] as String? ?? '',
    categoryCode: m['primary_category_code'] as String? ?? m['category_code'] as String? ?? '',
    cityId: (m['city_id'] as num?)?.toInt() ?? 0,
    visitFeePaise: (m['visit_fee_paise'] as num?)?.toInt() ?? 0,
    ratingAvg: (m['rating_avg'] as num?)?.toDouble() ?? 0,
    ratingCount: (m['rating_count'] as num?)?.toInt() ?? 0,
    jobsCompleted: (m['jobs_completed'] as num?)?.toInt() ?? 0,
    distanceKm: (m['distance_km'] as num?)?.toDouble(),
  );
}

CustomerBooking customerBookingFromApi(Map<String, dynamic> m) {
  final ratingRaw = m['rating'];
  BookingRating? rating;
  if (ratingRaw is Map<String, dynamic> && ratingRaw['stars'] != null) {
    rating = BookingRating(
      stars: (ratingRaw['stars'] as num).toInt(),
      reviewText: ratingRaw['review_text'] as String?,
    );
  }

  final rawId = m['id'];
  final id = rawId is num ? rawId.toInt() : int.tryParse(rawId.toString()) ?? 0;

  final proMap = m['professional'] as Map<String, dynamic>?;
  final rawProId = proMap?['id'] ?? m['professional_id'];
  final proId = rawProId is num ? rawProId.toInt() : int.tryParse(rawProId.toString()) ?? 0;
  final proName = proMap?['full_name'] as String? ?? m['professional_name'] as String? ?? m['pro_name'] as String? ?? '';

  return CustomerBooking(
    id: id,
    professionalId: proId,
    professionalName: proName,
    categoryCode: m['category_code'] as String? ?? '',
    problemDescription: m['problem_description'] as String? ?? '',
    addressText: m['address_text'] as String? ?? '',
    addressLat: (m['address_lat'] as num?)?.toDouble(),
    addressLng: (m['address_lng'] as num?)?.toDouble(),
    cityId: (m['city_id'] as num?)?.toInt() ?? 0,
    visitFeePaise: (m['visit_fee_paise'] as num?)?.toInt() ?? 0,
    status: m['status'] as String? ?? 'pending',
    createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
    scheduledAt: m['scheduled_at'] != null ? DateTime.tryParse(m['scheduled_at'] as String) : null,
    rating: rating,
  );
}

CustomerProfile? customerProfileFromApi(Map<String, dynamic>? map) {
  if (map == null) return null;
  return CustomerProfile(
    fullName: map['full_name'] as String?,
    phoneE164: map['phone_e164'] as String?,
    cityId: (map['city_id'] as num?)?.toInt(),
    profilePhotoUrl: map['profile_photo_url'] as String?,
  );
}
