import 'package:flutter/foundation.dart';

import '../../core/constants.dart';
import '../jwt_token_service.dart';
import '../models.dart';
import '../repository.dart';
import 'api_client.dart';
import 'auth_api.dart';
import 'profile_mapper.dart';

/// PHP backend (`pro_enroll_api`) — auth + screen endpoints.
class ApiRepository implements ProRepository {
  ApiRepository(this._client, {required this.tokens})
      : _auth = AuthApi(_client, tokens);

  final ApiClient _client;
  final JwtTokenService tokens;
  final AuthApi _auth;

  @override
  Future<OtpSendResult> sendOtp(String phone, {required String mode}) =>
      _auth.sendOtp(phone, mode: mode);

  @override
  Future<AuthSyncResult?> verifyOtp({
    required String requestId,
    required String otp,
    required String mode,
    String app = 'pro_enroll',
    AppRole role = AppRole.professional,
  }) =>
      _auth.verifyOtp(
        requestId: requestId,
        otp: otp,
        mode: mode,
        app: app,
        role: role,
      );

  @override
  Future<AuthSyncResult?> exchangeFirebaseSession({
    required String idToken,
    required String mode,
    String app = 'pro_enroll',
    AppRole role = AppRole.professional,
  }) =>
      _auth.exchangeFirebaseSession(
        idToken: idToken,
        mode: mode,
        app: app,
        role: role,
      );

  @override
  Future<AuthSyncResult?> switchRole(AppRole role) => _auth.switchRole(role);

  @override
  Future<bool> validateSession() => _auth.validateSession();

  @override
  Future<void> logout() => _auth.logout();

  @override
  Future<AuthSyncResult> syncAuthSession({required String mode}) async {
    final data = await _client.post(
      '/v1/screens/auth-otp',
      body: {'mode': mode},
    );
    return AuthSyncResult(
      nextRoute: data['next_route'] as String? ?? '/onboard/category',
      profile: profileFromApiMap(
        data['profile'] as Map<String, dynamic>?,
      ),
    );
  }

  @override
  Future<ProProfile?> fetchProfile() async {
    if (await tokens.getActiveRole() == AppRole.customer) {
      return null;
    }
    final fromMe = await _auth.fetchMe();
    if (fromMe != null) return fromMe;
    final data = await _client.get('/v1/screens/home-profile');
    return profileFromApiMap(data['profile'] as Map<String, dynamic>?);
  }

  @override
  Future<List<CategoryRef>> fetchCategories() async {
    final data = await _client.get('/v1/categories', auth: false);
    final list = data['categories'];
    if (list is! List) return [];
    final out = <CategoryRef>[];
    for (final item in list) {
      if (item is Map) {
        out.add(CategoryRef.fromApi(Map<String, dynamic>.from(item)));
      }
    }
    return out;
  }

  @override
  Future<void> saveCategories(
    List<String> categoryCodes, {
    Map<String, int>? experienceByCategory,
  }) async {
    await _client.put(
      '/v1/screens/onboard-category',
      body: {
        'category_codes': categoryCodes,
        if (experienceByCategory != null)
          'experience_by_category': experienceByCategory,
      },
    );
  }

  @override
  Future<void> saveExperience({
    required String fullName,
    required Map<String, int> experienceByCategory,
  }) async {
    await _client.put(
      '/v1/screens/onboard-experience',
      body: {
        'full_name': fullName,
        'experience_by_category': experienceByCategory,
      },
    );
  }

  @override
  Future<void> saveLocation({
    required int cityId,
    required int workRadiusKm,
    double? homeLat,
    double? homeLng,
  }) async {
    await _client.put(
      '/v1/screens/onboard-location',
      body: {
        'city_id': cityId,
        'work_radius_km': workRadiusKm,
        if (homeLat != null) 'home_lat': homeLat,
        if (homeLng != null) 'home_lng': homeLng,
      },
    );
  }

  @override
  Future<void> saveVisitFeePaise(int visitFeePaise) async {
    await _client.put(
      '/v1/screens/onboard-fee',
      body: {'visit_fee_paise': visitFeePaise},
    );
  }

  @override
  Future<String> initiateAadhaar(String last4) async {
    final data = await _client.post(
      '/v1/screens/kyc-aadhaar',
      body: {'action': 'initiate', 'aadhaar_last4': last4},
    );
    return data['kyc_ref_id'] as String;
  }

  @override
  Future<bool> verifyAadhaarOtp({required String kycRefId, required String otp}) async {
    await _client.post(
      '/v1/screens/kyc-aadhaar',
      body: {
        'action': 'verify',
        'kyc_ref_id': kycRefId,
        'otp': otp,
      },
    );
    return true;
  }

  @override
  Future<double> uploadSelfie() async {
    final data = await _client.post('/v1/screens/kyc-selfie');
    return (data['face_match_score'] as num).toDouble();
  }

  @override
  Future<void> uploadKycDocuments(List<String> documentTypes) async {
    await _client.post(
      '/v1/screens/kyc-docs',
      body: {'documents': documentTypes},
    );
  }

  @override
  Future<KycStatus> fetchKycStatus() async {
    final data = await _client.get('/v1/screens/kyc-pending');
    return kycStatusFromApi(data['kyc_status'] as String?);
  }

  @override
  Future<void> simulateKycApproval() async {
    await _client.post('/v1/screens/kyc-pending/simulate-approval');
  }

  @override
  Future<List<JobOffer>> fetchOffers(List<String> categoryCodes) async {
    final data = await _client.get('/v1/screens/home-jobs');
    final list = data['offers'];
    if (list is! List) return [];
    final offers = <JobOffer>[];
    for (final o in list) {
      if (o is! Map<String, dynamic>) continue;
      try {
        offers.add(jobOfferFromApi(o));
      } catch (e) {
        debugPrint('jobOfferFromApi skip: $e');
      }
    }
    return offers;
  }

  @override
  Future<ActiveJob?> fetchActiveJob() async {
    final data = await _client.get('/v1/screens/job-active');
    final job = data['active_job'];
    if (job is Map<String, dynamic>) return activeJobFromApi(job);
    return null;
  }

  @override
  Future<JobOffer?> fetchOffer(String offerId) async {
    final data = await _client.get('/v1/screens/job-offer/$offerId');
    final offer = data['offer'];
    if (offer is Map<String, dynamic>) return jobOfferFromApi(offer);
    return null;
  }

  @override
  Future<ActiveJob> acceptOffer(String offerId) async {
    final data = await _client.post('/v1/screens/job-offer/$offerId/accept');
    final job = data['active_job'];
    if (job is Map<String, dynamic>) return activeJobFromApi(job);
    throw StateError('acceptOffer: missing active_job');
  }

  @override
  Future<void> rejectOffer(String offerId) async {
    await _client.post('/v1/screens/job-offer/$offerId/reject');
  }

  @override
  Future<void> updateActiveJobStatus(BookingStatus status) async {
    await _client.put(
      '/v1/screens/job-active',
      body: {'status': bookingStatusToApi(status)},
    );
  }

  @override
  Future<void> completeActiveJob(int finalAmountPaise) async {
    await _client.post(
      '/v1/screens/job-active',
      body: {'final_amount_paise': finalAmountPaise},
    );
  }

  @override
  Future<EarningsSummary> fetchEarnings() async {
    final data = await _client.get('/v1/screens/home-earnings');
    final summary = data['summary'];
    if (summary is! Map<String, dynamic>) {
      throw StateError('fetchEarnings: missing summary');
    }
    final merged = Map<String, dynamic>.from(summary);
    if (data['rating_avg'] != null) merged['rating_avg'] = data['rating_avg'];
    if (data['rating_count'] != null) merged['rating_count'] = data['rating_count'];
    if (data['jobs_completed'] != null) merged['jobs_completed'] = data['jobs_completed'];
    return earningsFromApi(merged);
  }

  @override
  Future<void> updateAvailability(bool isAvailable) async {
    await _client.put(
      '/v1/screens/home-profile',
      body: {'is_available': isAvailable},
    );
  }

  // ─── Customer-side ─────────────────────────────────────────────────

  @override
  Future<List<ProSearchResult>> searchPros({
    required int cityId,
    String? categoryCode,
    String? query,
    double? lat,
    double? lng,
  }) async {
    final q = <String, String>{'city_id': cityId.toString()};
    if (categoryCode != null) q['category_code'] = categoryCode;
    if (query != null && query.isNotEmpty) q['q'] = query;
    if (lat != null) q['lat'] = lat.toString();
    if (lng != null) q['lng'] = lng.toString();

    final data = await _client.get('/v1/customer/pros/search', auth: false, query: q);
    final list = data['pros'] ?? data['professionals'] ?? data['value'];
    if (list is! List) return [];
    return [
      for (final p in list)
        if (p is Map<String, dynamic>) proSearchResultFromApi(p),
    ];
  }

  @override
  Future<Map<String, dynamic>> fetchProDetail(
    int proId, {
    String? categoryCode,
    double? lat,
    double? lng,
  }) async {
    final q = <String, String>{};
    if (categoryCode != null) q['category_code'] = categoryCode;
    if (lat != null) q['lat'] = lat.toString();
    if (lng != null) q['lng'] = lng.toString();
    final data = await _client.get(
      '/v1/customer/pros/$proId',
      auth: false,
      query: q.isNotEmpty ? q : null,
    );
    final pro = data['pro'] as Map<String, dynamic>?;
    return pro ?? data;
  }

  @override
  Future<List<CustomerBooking>> fetchCustomerBookings() async {
    final data = await _client.get('/v1/customer/bookings');
    final list = data['bookings'] ?? data['value'];
    if (list is! List) return [];
    return [
      for (final b in list)
        if (b is Map<String, dynamic>) customerBookingFromApi(b),
    ];
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
  }) async {
    final scheduled = scheduledAt ?? DateTime.now().add(const Duration(hours: 1));
    final local = scheduled.toLocal();
    final scheduledStr =
        '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
    final body = <String, dynamic>{
      'professional_id': professionalId,
      'category_code': categoryCode,
      'problem_description': problemDescription,
      'address_text': addressText,
      'city_id': cityId,
      'scheduled_at': scheduledStr,
      if (addressLat != null) 'address_lat': addressLat,
      if (addressLng != null) 'address_lng': addressLng,
    };

    final data = await _client.post('/v1/customer/bookings', body: body);
    final booking = data['booking'] ?? data;
    if (booking is Map<String, dynamic>) return customerBookingFromApi(booking);
    throw StateError('createBooking: unexpected response');
  }

  @override
  Future<CustomerBooking> fetchBookingDetail(int bookingId) async {
    final data = await _client.get('/v1/customer/bookings/$bookingId');
    final booking = data['booking'] ?? data;
    if (booking is Map<String, dynamic>) return customerBookingFromApi(booking);
    throw StateError('fetchBookingDetail: unexpected response');
  }

  @override
  Future<void> completeBooking(int bookingId) async {
    await _client.post('/v1/customer/bookings/$bookingId/complete');
  }

  @override
  Future<void> rateBooking(int bookingId, {required int stars, String? reviewText}) async {
    await _client.post(
      '/v1/customer/bookings/$bookingId/rating',
      body: {
        'stars': stars,
        if (reviewText != null && reviewText.isNotEmpty) 'review_text': reviewText,
      },
    );
  }

  @override
  Future<CustomerProfile?> fetchCustomerProfile() async {
    final data = await _client.get('/v1/customer/profile');
    return customerProfileFromApi(data['profile'] as Map<String, dynamic>? ?? data);
  }

  @override
  Future<void> updateCustomerProfile({required String fullName}) async {
    await _client.put('/v1/customer/profile', body: {'full_name': fullName});
  }
}
