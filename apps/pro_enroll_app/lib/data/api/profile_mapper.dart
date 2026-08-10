import '../../core/ist_time.dart';
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
    case 'arrived':
      return BookingStatus.arrived;
    case 'in_progress':
      return BookingStatus.inProgress;
    case 'awaiting_payment':
    case 'payment_due':
      return BookingStatus.awaitingPayment;
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
    case BookingStatus.arrived:
      return 'arrived';
    case BookingStatus.inProgress:
      return 'in_progress';
    case BookingStatus.awaitingPayment:
      return 'awaiting_payment';
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
        experienceStartYear: (s['experience_start_year'] as num?)?.toInt(),
        isPrimary: s['is_primary'] == true,
        visitFeePaise: (s['visit_fee_paise'] as num?)?.toInt() ??
            (map['visit_fee_paise'] as num?)?.toInt() ??
            15000,
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
    listingHeld: map['listing_held'] == true || map['listing_held'] == 1,
    freeBookingsUsed: (map['free_bookings_used'] as num?)?.toInt() ?? 0,
    canEditExperience: map['can_edit_experience'] == true ||
        map['can_edit_experience'] == 1 ||
        !map.containsKey('can_edit_experience'),
    experienceEditRequestStatus:
        map['experience_edit_request_status'] as String?,
  );
}

CommissionPreview? commissionPreviewFromApi(dynamic raw) {
  if (raw is! Map) return null;
  final m = Map<String, dynamic>.from(raw);
  return CommissionPreview(
    isFreeBooking: m['is_free_booking'] == true,
    freeBookingsRemaining: (m['free_bookings_remaining'] as num?)?.toInt() ?? 0,
    visitCommissionPercent: (m['visit_commission_percent'] as num?)?.toInt() ?? 0,
    commissionPaise: (m['commission_paise'] as num?)?.toInt() ?? 0,
    proCreditPaise: (m['pro_credit_paise'] as num?)?.toInt() ?? 0,
    label: m['label'] as String?,
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
    preferredTime: IstTime.parse(m['preferred_time'] as String?),
    expiresAt: IstTime.parse(m['expires_at'] as String?),
    commissionPreview: commissionPreviewFromApi(m['commission_preview']),
    customerLat: (m['customer_lat'] as num?)?.toDouble(),
    customerLng: (m['customer_lng'] as num?)?.toDouble(),
    canReject: m.containsKey('can_reject')
        ? (m['can_reject'] == true || m['can_reject'] == 1)
        : true,
    cancelsRemainingToday: (m['cancels_remaining_today'] as num?)?.toInt(),
    dailyCancelLimit: (m['daily_cancel_limit'] as num?)?.toInt() ?? 5,
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
    customerPhoneE164: m['customer_phone_e164'] as String?,
    customerAddress: m['customer_address'] as String,
    customerAreaName: m['customer_area_name'] as String,
    distanceKm: (m['distance_km'] as num).toDouble(),
    visitFeePaise: (m['visit_fee_paise'] as num).toInt(),
    status: bookingStatusFromApi(m['status'] as String?),
    finalAmountPaise: (m['final_amount_paise'] as num?)?.toInt(),
    customerLat: (m['customer_lat'] as num?)?.toDouble(),
    customerLng: (m['customer_lng'] as num?)?.toDouble(),
    commissionPreview: commissionPreviewFromApi(m['commission_preview']),
    proCreditPaise: (m['pro_credit_paise'] as num?)?.toInt(),
    scheduledAt: IstTime.parse(m['scheduled_at'] as String?),
    canCancel: m['can_cancel'] == true || m['can_cancel'] == 1,
    rejectRequiresReason:
        m['reject_requires_reason'] == true || m['reject_requires_reason'] == 1,
    rejectPenaltyPaise: (m['reject_penalty_paise'] as num?)?.toInt() ?? 0,
    cancelsRemainingToday: (m['cancels_remaining_today'] as num?)?.toInt(),
    dailyCancelLimit: (m['daily_cancel_limit'] as num?)?.toInt() ?? 5,
  );
}

ProJobHistoryItem proJobHistoryFromApi(Map<String, dynamic> m) {
  DateTime? optDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return IstTime.parse(raw);
  }

  return ProJobHistoryItem(
    id: '${m['id']}',
    code: (m['code'] as String?) ?? '',
    categoryCode: (m['category_code'] as String?) ?? '',
    categoryName: m['category_name'] as String?,
    problem: (m['problem'] as String?) ?? '',
    customerName: (m['customer_name'] as String?) ?? 'Customer',
    customerAreaName: (m['customer_area_name'] as String?) ?? '',
    customerPhoneE164: m['customer_phone_e164'] as String?,
    customerPhoneMasked: m['customer_phone_masked'] as String?,
    visitFeePaise: (m['visit_fee_paise'] as num?)?.toInt() ?? 0,
    proCreditPaise: (m['pro_credit_paise'] as num?)?.toInt(),
    commissionPaise: (m['commission_paise'] as num?)?.toInt(),
    commissionWaived:
        m['commission_waived'] == true || m['commission_waived'] == 1,
    status: (m['status'] as String?) ?? '',
    statusLabel: (m['status_label'] as String?) ??
        ((m['status'] as String?) ?? '').replaceAll('_', ' '),
    visitFeePaid: m['visit_fee_paid'] == true || m['visit_fee_paid'] == 1,
    visitFeePaymentMethod: m['visit_fee_payment_method'] as String?,
    ratingStars: (m['rating_stars'] as num?)?.toInt(),
    ratingReview: m['rating_review'] as String?,
    createdAt: optDate(m['created_at'] as String?),
    completedAt: optDate(m['completed_at'] as String?),
    updatedAt: optDate(m['updated_at'] as String?),
  );
}

EarningsSummary earningsFromApi(Map<String, dynamic> m) {
  final wallet = (m['wallet_balance_paise'] as num?)?.toInt()
      ?? (m['wallet_net_paise'] as num?)?.toInt()
      ?? 0;
  return EarningsSummary(
    todayPaise: (m['today_paise'] as num?)?.toInt() ?? 0,
    weekPaise: (m['week_paise'] as num?)?.toInt() ?? 0,
    monthPaise: (m['month_paise'] as num?)?.toInt() ?? 0,
    payoutsThisMonthPaise: (m['payouts_this_month_paise'] as num?)?.toInt() ?? 0,
    pendingPayoutPaise: (m['pending_payout_paise'] as num?)?.toInt()
        ?? (m['earnings_balance_paise'] as num?)?.toInt()
        ?? 0,
    jobsToday: (m['jobs_today'] as num?)?.toInt() ?? 0,
    walletBalancePaise: wallet,
    ratingAvg: (m['rating_avg'] as num?)?.toDouble(),
    ratingCount: (m['rating_count'] as num?)?.toInt(),
    jobsCompleted: (m['jobs_completed'] as num?)?.toInt(),
    visitCommissionPercent: (m['visit_commission_percent'] as num?)?.toInt() ?? 10,
    freeBookingLimit: (m['free_booking_limit'] as num?)?.toInt() ?? 5,
    freeBookingsUsed: (m['free_bookings_used'] as num?)?.toInt() ?? 0,
    freeBookingsRemaining: (m['free_bookings_remaining'] as num?)?.toInt() ?? 0,
    listingHeld: m['listing_held'] == true || m['listing_held'] == 1,
    commissionTodayPaise: (m['commission_today_paise'] as num?)?.toInt() ?? 0,
    commissionNote: m['commission_note'] as String?,
    platformFeeDuePaise: (m['platform_fee_due_paise'] as num?)?.toInt() ?? 0,
    walletMinAcceptPaise: (m['wallet_min_accept_paise'] as num?)?.toInt() ?? 5000,
    walletRechargeMinPaise: (m['wallet_recharge_min_paise'] as num?)?.toInt() ?? 5000,
    suggestedRechargePaise: (m['suggested_recharge_paise'] as num?)?.toInt() ?? 5000,
    canAcceptJobs: m['can_accept_jobs'] != false && m['can_accept_jobs'] != 0,
    companyUpiId: m['company_upi_id'] as String?,
    companyUpiName: m['company_upi_name'] as String?,
    companyUpiPayUri: m['company_upi_pay_uri'] as String?,
    pendingRechargePaise: (m['pending_recharge_paise'] as num?)?.toInt() ?? 0,
  );
}

WalletRechargeRequest walletRechargeRequestFromApi(Map<String, dynamic> m) {
  DateTime? optDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return IstTime.parse(raw);
  }

  final status = (m['status'] as String?) ?? 'pending';
  return WalletRechargeRequest(
    id: '${m['id'] ?? ''}',
    amountPaise: (m['amount_paise'] as num?)?.toInt() ?? 0,
    utr: (m['utr'] as String?) ?? '',
    status: status,
    statusLabel: (m['status_label'] as String?) ??
        status.replaceAll('_', ' '),
    rejectedReason: m['rejected_reason'] as String?,
    createdAt: optDate(m['created_at'] as String?),
    reviewedAt: optDate(m['reviewed_at'] as String?),
  );
}

List<WalletRechargeRequest> walletRechargeRequestsFromApi(dynamic raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map<String, dynamic>) walletRechargeRequestFromApi(item),
  ];
}

CreditHistoryItem creditHistoryItemFromApi(Map<String, dynamic> m) {
  // Prepaid wallet ledger rows (recharge / commission_debit).
  if (m['entry_type'] != null || m.containsKey('amount_paise')) {
    final amount = (m['amount_paise'] as num?)?.toInt() ?? 0;
    final type = m['entry_type'] as String?;
    return CreditHistoryItem(
      id: '${m['id'] ?? ''}',
      bookingCode: m['booking_code'] as String? ?? '',
      categoryCode: '',
      creditPaise: amount,
      visitFeePaise: 0,
      commissionPaise: amount < 0 ? -amount : 0,
      commissionWaived: false,
      platformFeePaid: type == 'commission_debit',
      utr: m['utr'] as String?,
      completedAt: m['created_at'] != null
          ? IstTime.parse(m['created_at'] as String)
          : (m['completed_at'] != null
              ? IstTime.parse(m['completed_at'] as String)
              : null),
      label: m['label'] as String? ?? m['note'] as String?,
      entryType: type,
    );
  }

  return CreditHistoryItem(
    id: '${m['id'] ?? ''}',
    bookingCode: m['booking_code'] as String? ?? '',
    categoryCode: m['category_code'] as String? ?? '',
    creditPaise: (m['credit_paise'] as num?)?.toInt() ?? 0,
    visitFeePaise: (m['visit_fee_paise'] as num?)?.toInt() ?? 0,
    commissionPaise: (m['commission_paise'] as num?)?.toInt() ?? 0,
    commissionWaived: m['commission_waived'] == true || m['commission_waived'] == 1,
    platformFeePaid: m['platform_fee_paid'] == true || m['platform_fee_paid'] == 1,
    finalAmountPaise: (m['final_amount_paise'] as num?)?.toInt(),
    utr: m['commission_upi_utr'] as String?,
    completedAt: m['completed_at'] != null
        ? IstTime.parse(m['completed_at'] as String)
        : null,
    label: m['label'] as String?,
  );
}

List<CreditHistoryItem> creditHistoryFromApi(dynamic raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map<String, dynamic>) creditHistoryItemFromApi(item),
  ];
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

List<BookingTrackingStep> trackingStepsFromApi(dynamic raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map<String, dynamic>)
        BookingTrackingStep(
          key: item['key'] as String? ?? '',
          label: item['label'] as String? ?? '',
          state: item['state'] as String? ?? 'upcoming',
        ),
  ];
}

BookingLiveTracking? trackingFromApi(dynamic raw) {
  if (raw is! Map<String, dynamic>) return null;
  final lat = (raw['pro_lat'] as num?)?.toDouble();
  final lng = (raw['pro_lng'] as num?)?.toDouble();
  if (lat == null || lng == null) return null;
  return BookingLiveTracking(
    proLat: lat,
    proLng: lng,
    distanceKm: (raw['distance_km'] as num?)?.toDouble() ?? 0,
    etaMinutes: (raw['eta_minutes'] as num?)?.toInt() ?? 0,
    updatedAt: raw['updated_at'] != null
        ? IstTime.parse(raw['updated_at'] as String)
        : null,
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
    categoryName: m['category_name'] as String?,
    bookingCode: m['booking_code'] as String?,
    problemDescription: m['problem_description'] as String? ?? '',
    addressText: m['address_text'] as String? ?? '',
    addressLat: (m['address_lat'] as num?)?.toDouble(),
    addressLng: (m['address_lng'] as num?)?.toDouble(),
    cityId: (m['city_id'] as num?)?.toInt() ?? 0,
    cityName: m['city_name'] as String?,
    visitFeePaise: (m['visit_fee_paise'] as num?)?.toInt() ?? 0,
    finalAmountPaise: (m['final_amount_paise'] as num?)?.toInt(),
    status: m['status'] as String? ?? 'pending',
    statusLabel: m['status_label'] as String?,
    trackingSteps: trackingStepsFromApi(m['tracking_steps']),
    professionalPhoneE164: proMap?['phone_e164'] as String?,
    professionalPhoneMasked: proMap?['phone_masked'] as String?,
    visitFeePaid: m['visit_fee_paid'] == true || m['visit_fee_paid'] == 1,
    visitFeePaymentMethod: m['visit_fee_payment_method'] as String?,
    createdAt: IstTime.parse(m['created_at'] as String?),
    scheduledAt: m['scheduled_at'] != null
        ? IstTime.parse(m['scheduled_at'] as String)
        : null,
    acceptedAt: m['accepted_at'] != null
        ? IstTime.parse(m['accepted_at'] as String)
        : null,
    rating: rating,
    tracking: trackingFromApi(m['tracking']),
    apiCanCancel: m.containsKey('can_cancel')
        ? (m['can_cancel'] == true || m['can_cancel'] == 1)
        : null,
    cancelHint: m['cancel_hint'] as String?,
    cancelUnlockAt: m['cancel_unlock_at'] != null
        ? IstTime.parse(m['cancel_unlock_at'] as String)
        : null,
    cancelsRemainingToday: (m['cancels_remaining_today'] as num?)?.toInt(),
    dailyCancelLimit: (m['daily_cancel_limit'] as num?)?.toInt() ?? 5,
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
