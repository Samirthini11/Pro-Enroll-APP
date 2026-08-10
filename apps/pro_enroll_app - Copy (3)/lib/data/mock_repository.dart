import 'dart:async';
import 'dart:math';

import '../core/constants.dart';
import 'models.dart';
import 'repository.dart';

/// A purely in-memory mock backend for the Pro-Enroll app scaffold.
class MockRepository implements ProRepository {
  MockRepository();

  final _rand = Random();
  static final Map<String, String> _otpByRequestId = {};

  /// Max value that is safe for `Random.nextInt` across both Dart VM and
  /// JavaScript. On the web, ints are JS numbers, so any expression like
  /// `1 << 32` overflows to 0 and `nextInt(0)` throws. Stick to a fixed
  /// 31-bit positive int instead.
  static const int _maxRandom = 0x7FFFFFFF;

  // ── Auth ────────────────────────────────────────────────────────────
  @override
  Future<OtpSendResult> sendOtp(String phone, {required String mode}) async {
    await _delay();
    final requestId = 'req_${_rand.nextInt(_maxRandom)}';
    // Fixed demo OTP (shown on screen); must match on verify.
    const otp = '123456';
    _otpByRequestId[requestId] = otp;
    return OtpSendResult(requestId: requestId, debugOtp: otp);
  }

  @override
  Future<bool> validateSession() async {
    await _delay();
    return false;
  }

  @override
  Future<void> logout() async {
    await _delay();
  }

  @override
  Future<AuthSyncResult?> verifyOtp({
    required String requestId,
    required String otp,
    required String mode,
    String app = 'pro_enroll',
    AppRole role = AppRole.professional,
  }) async {
    await _delay();
    final expected = _otpByRequestId[requestId];
    if (otp.length != 6 || expected == null || otp.trim() != expected) {
      return null;
    }
    return AuthSyncResult(
      nextRoute: role == AppRole.customer
          ? '/customer/home'
          : (mode == 'sign_in' ? '/home' : '/onboard/category'),
      role: role,
    );
  }

  @override
  Future<AuthSyncResult?> switchRole(AppRole role) async {
    await _delay();
    return AuthSyncResult(
      nextRoute: role == AppRole.customer ? '/customer/home' : '/home',
      role: role,
    );
  }

  @override
  Future<AuthSyncResult?> exchangeFirebaseSession({
    required String idToken,
    required String mode,
    String app = 'pro_enroll',
    AppRole role = AppRole.professional,
  }) async =>
      null;

  @override
  Future<AuthSyncResult> syncAuthSession({required String mode}) async {
    await _delay();
    return AuthSyncResult(
      nextRoute: mode == 'sign_in' ? '/home' : '/onboard/category',
    );
  }

  @override
  Future<ProProfile?> fetchProfile() async {
    await _delay();
    return null;
  }

  @override
  Future<List<CategoryRef>> fetchCategories() async => supportedCategories;

  @override
  Future<void> saveCategories(
    List<String> categoryCodes, {
    Map<String, int>? experienceByCategory,
  }) async =>
      _delay();

  @override
  Future<void> saveExperience({
    required String fullName,
    required Map<String, int> experienceByCategory,
  }) async =>
      _delay();

  @override
  Future<void> saveLocation({
    required int cityId,
    required int workRadiusKm,
    double? homeLat,
    double? homeLng,
  }) async =>
      _delay();

  @override
  Future<void> saveVisitFeePaise(int visitFeePaise) async => _delay();

  @override
  Future<void> uploadKycDocuments(List<String> documentTypes) async => _delay();

  @override
  Future<KycStatus> fetchKycStatus() async {
    await _delay();
    return KycStatus.inReview;
  }

  @override
  Future<void> simulateKycApproval() async => _delay();

  @override
  Future<ActiveJob?> fetchActiveJob() async => null;

  @override
  Future<JobOffer?> fetchOffer(String offerId) async {
    final offers = await fetchOffers(const ['ac', 'plumber', 'ro']);
    for (final o in offers) {
      if (o.id == offerId) return o;
    }
    return null;
  }

  @override
  Future<ActiveJob> acceptOffer(String offerId) async {
    final offer = await fetchOffer(offerId);
    if (offer == null) throw StateError('offer not found');
    return ActiveJob(
      id: offer.id,
      code: offer.code,
      categoryCode: offer.categoryCode,
      problem: offer.problem,
      customerName: offer.customerName,
      customerPhoneMasked: '+91 78xxx xx00',
      customerAddress: offer.customerAreaName,
      customerAreaName: offer.customerAreaName,
      distanceKm: offer.distanceKm,
      visitFeePaise: offer.visitFeePaise,
    );
  }

  @override
  Future<void> rejectOffer(String offerId) async => _delay();

  @override
  Future<void> updateActiveJobStatus(BookingStatus status) async => _delay();

  @override
  Future<void> completeActiveJob(int finalAmountPaise) async => _delay();

  @override
  Future<void> updateAvailability(bool isAvailable) async => _delay();

  // ── KYC ────────────────────────────────────────────────────────────
  @override
  Future<String> initiateAadhaar(String last4) async {
    await _delay();
    return 'kyc_${_rand.nextInt(_maxRandom)}';
  }

  @override
  Future<bool> verifyAadhaarOtp({required String kycRefId, required String otp}) async {
    await _delay();
    return otp.length >= 4 && otp != '0000';
  }

  @override
  Future<double> uploadSelfie() async {
    await _delay(seconds: 2);
    // Mock face-match score.
    return 0.85 + _rand.nextDouble() * 0.15;
  }

  // ── Jobs ──────────────────────────────────────────────────────────
  @override
  Future<List<JobOffer>> fetchOffers(List<String> categoryCodes) async {
    await _delay();
    if (categoryCodes.isEmpty) return const [];
    return _demoOffers(categoryCodes);
  }

  @override
  Future<EarningsSummary> fetchEarnings() async {
    await _delay();
    return EarningsSummary(
      todayPaise: 65000,
      weekPaise: 420000,
      monthPaise: 1850000,
      payoutsThisMonthPaise: 1620000,
      pendingPayoutPaise: 23000,
      jobsToday: 3,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────
  Future<void> _delay({int seconds = 1}) =>
      Future<void>.delayed(Duration(milliseconds: 400 * seconds));

  // ── Customer-side ─────────────────────────────────────────────────
  @override
  Future<List<ProSearchResult>> searchPros({required int cityId, String? categoryCode, String? query, double? lat, double? lng}) async {
    await _delay();
    return [
      ProSearchResult(id: 1, fullName: 'Ravi Kumar', categoryCode: categoryCode ?? 'ac', cityId: cityId, visitFeePaise: 20000, ratingAvg: 4.8, ratingCount: 156, jobsCompleted: 342, distanceKm: 0.8),
      ProSearchResult(id: 2, fullName: 'Senthil Murugan', categoryCode: categoryCode ?? 'plumber', cityId: cityId, visitFeePaise: 15000, ratingAvg: 4.5, ratingCount: 89, jobsCompleted: 198, distanceKm: 1.5),
      ProSearchResult(id: 3, fullName: 'Karthik R', categoryCode: categoryCode ?? 'electrician', cityId: cityId, visitFeePaise: 15000, ratingAvg: 4.6, ratingCount: 72, jobsCompleted: 156, distanceKm: 3.2),
    ];
  }

  @override
  Future<Map<String, dynamic>> fetchProDetail(
    int proId, {
    String? categoryCode,
    double? lat,
    double? lng,
  }) async {
    await _delay();
    return {
      'id': proId,
      'full_name': 'Ravi Kumar',
      'phone_masked': '+91 98***43210',
      'city_id': 1,
      'visit_fee_paise': 20000,
      'rating_avg': 4.8,
      'rating_count': 156,
      'jobs_completed': 342,
      'skills': [
        {'category_code': categoryCode ?? 'ac', 'experience_years': 8},
      ],
      'is_available': true,
      'distance_km': 0.8,
    };
  }

  @override
  Future<List<CustomerBooking>> fetchCustomerBookings() async {
    await _delay();
    return [];
  }

  @override
  Future<CustomerBooking> createBooking({
    required int professionalId,
    required String categoryCode,
    required String problemDescription,
    required String addressText,
    required int cityId,
    DateTime? scheduledAt,
    double? addressLat,
    double? addressLng,
    int? visitFeePaise,
    bool visitFeePaid = true,
    String visitFeePaymentMethod = 'upi',
  }) async {
    await _delay(seconds: 2);
    return CustomerBooking(
      id: DateTime.now().millisecondsSinceEpoch,
      professionalId: professionalId,
      professionalName: 'Ravi Kumar',
      categoryCode: categoryCode,
      problemDescription: problemDescription,
      addressText: addressText,
      cityId: cityId,
      visitFeePaise: visitFeePaise ?? 20000,
      visitFeePaid: visitFeePaid,
      visitFeePaymentMethod: visitFeePaymentMethod,
      status: 'confirmed',
      createdAt: DateTime.now(),
      scheduledAt: scheduledAt,
    );
  }

  @override
  Future<CustomerBooking> fetchBookingDetail(int bookingId) async {
    await _delay();
    return CustomerBooking(
      id: bookingId,
      professionalId: 1,
      professionalName: 'Ravi Kumar',
      categoryCode: 'ac',
      problemDescription: 'AC not cooling',
      addressText: '12, MG Road, White Town, Pondicherry',
      cityId: 1,
      visitFeePaise: 20000,
      visitFeePaid: true,
      visitFeePaymentMethod: 'upi',
      status: 'confirmed',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    );
  }

  @override
  Future<void> cancelBooking(int bookingId) async {
    await _delay();
  }

  @override
  Future<void> completeBooking(int bookingId) async {
    await _delay();
  }

  @override
  Future<void> rateBooking(int bookingId, {required int stars, String? reviewText}) async {
    await _delay();
  }

  @override
  Future<CustomerProfile?> fetchCustomerProfile() async {
    await _delay();
    return CustomerProfile(fullName: 'Demo Customer', phoneE164: '+919876543210', cityId: 1);
  }

  @override
  Future<CustomerProfile?> updateCustomerProfile({
    required String fullName,
    required int cityId,
  }) async {
    await _delay();
    return CustomerProfile(
      fullName: fullName,
      phoneE164: '+919876543210',
      cityId: cityId,
    );
  }

  @override
  Future<void> registerPushToken({
    required String fcmToken,
    String platform = 'android',
    AppRole? role,
  }) async {
    await _delay();
  }

  List<JobOffer> _demoOffers(List<String> categories) {
    final now = DateTime.now();
    final pool = <Map<String, Object>>[
      {
        'cat': 'ac',
        'problem': 'AC not cooling — bedroom split AC, 1.5T',
        'customer': 'Saraswathi',
        'area': 'Mission Street, Pondicherry',
        'distance': 1.2,
        'fee': 20000,
      },
      {
        'cat': 'plumber',
        'problem': 'Kitchen tap is leaking continuously',
        'customer': 'Anjali',
        'area': 'Lawspet, Pondicherry',
        'distance': 2.8,
        'fee': 15000,
      },
      {
        'cat': 'ro',
        'problem': 'RO not producing water — filter change needed',
        'customer': 'Murugan R.',
        'area': 'Bharathiar Road, Karaikal',
        'distance': 0.9,
        'fee': 15000,
      },
      {
        'cat': 'fridge',
        'problem': 'Fridge not cooling, water dripping inside',
        'customer': 'Selvi',
        'area': 'Reddiarpalayam, Pondicherry',
        'distance': 3.5,
        'fee': 20000,
      },
      {
        'cat': 'bike',
        'problem': 'Bike not starting — TVS Apache 160',
        'customer': 'Ravi',
        'area': 'Mudaliarpet, Pondicherry',
        'distance': 1.7,
        'fee': 15000,
      },
      {
        'cat': 'wash',
        'problem': 'Washing machine drum not spinning',
        'customer': 'Lakshmi',
        'area': 'Villianur, Pondicherry',
        'distance': 4.1,
        'fee': 20000,
      },
    ];

    final filtered = pool.where((e) => categories.contains(e['cat']));
    return [
      for (final (i, m) in filtered.indexed)
        JobOffer(
          id: 'off_${i + 1}',
          code: 'PE-2026-${(900 + i).toString().padLeft(6, '0')}',
          categoryCode: m['cat'] as String,
          problem: m['problem'] as String,
          customerName: m['customer'] as String,
          customerAreaName: m['area'] as String,
          distanceKm: m['distance'] as double,
          visitFeePaise: m['fee'] as int,
          preferredTime: now.add(Duration(hours: 1 + i)),
          expiresAt: now.add(const Duration(seconds: 60)),
        ),
    ];
  }
}
