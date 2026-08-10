import 'package:flutter/foundation.dart';

import '../core/app_config.dart';
import '../core/constants.dart';
import 'api/api_client.dart';
import 'api/api_exception.dart';
import 'api/api_repository.dart';
import 'jwt_token_service.dart';
import 'mock_repository.dart';
import 'models.dart';
import 'repository.dart';

/// Routes to [ApiRepository] when [AppConfig.hasApi] is on.
/// Protected calls require a stored JWT; OTP endpoints do not.
class AppRepository implements ProRepository {
  factory AppRepository({
    MockRepository? mock,
    ApiRepository? api,
    JwtTokenService? tokens,
  }) {
    final t = tokens ?? JwtTokenService();
    return AppRepository._(
      mock: mock ?? MockRepository(),
      tokens: t,
      api: api ?? ApiRepository(ApiClient(t), tokens: t),
    );
  }

  AppRepository._({
    required MockRepository mock,
    required JwtTokenService tokens,
    required ApiRepository api,
  })  : _mock = mock,
        _tokens = tokens,
        _api = api;

  final MockRepository _mock;
  final ApiRepository _api;
  final JwtTokenService _tokens;

  bool get _useApi => AppConfig.hasApi;

  Future<T> _whenApi<T>({
    required Future<T> Function() api,
    required Future<T> Function() mock,
  }) async {
    if (!_useApi) return mock();
    return api();
  }

  Future<T> _whenAuthedApi<T>({
    required Future<T> Function() api,
    required Future<T> Function() mock,
  }) async {
    if (!_useApi) return mock();
    final token = await _tokens.getAccessToken();
    if (token == null || token.isEmpty) {
      throw ApiException('Please sign in again', code: 'no_token');
    }
    return api();
  }

  @override
  Future<OtpSendResult> sendOtp(String phone, {required String mode}) async {
    if (!_useApi) {
      return _mock.sendOtp(phone, mode: mode);
    }
    return _api.sendOtp(phone, mode: mode);
  }

  @override
  Future<AuthSyncResult?> verifyOtp({
    required String requestId,
    required String otp,
    required String mode,
    String app = 'pro_enroll',
    AppRole role = AppRole.professional,
  }) async {
    if (!_useApi) {
      return _mock.verifyOtp(
        requestId: requestId,
        otp: otp,
        mode: mode,
        app: app,
      );
    }
    return _api.verifyOtp(
      requestId: requestId,
      otp: otp,
      mode: mode,
      app: app,
      role: role,
    );
  }

  @override
  Future<AuthSyncResult?> exchangeFirebaseSession({
    required String idToken,
    required String mode,
    String app = 'pro_enroll',
    AppRole role = AppRole.professional,
  }) async {
    if (!_useApi) {
      return null;
    }
    return _api.exchangeFirebaseSession(
      idToken: idToken,
      mode: mode,
      app: app,
      role: role,
    );
  }

  @override
  Future<AuthSyncResult?> switchRole(AppRole role) async {
    if (!_useApi) {
      return AuthSyncResult(
        nextRoute: role == AppRole.customer ? '/customer/home' : '/home',
        role: role,
      );
    }
    return _api.switchRole(role);
  }

  @override
  Future<bool> validateSession() => _whenApi(
        api: _api.validateSession,
        mock: _mock.validateSession,
      );

  @override
  Future<void> logout() async {
    if (_useApi && await _tokens.hasTokenAsync()) {
      try {
        await _api.logout();
      } catch (e) {
        debugPrint('logout API: $e');
      }
    }
    await _tokens.signOut(allRoles: true);
  }

  @override
  Future<AuthSyncResult> syncAuthSession({required String mode}) async {
    if (!_useApi) {
      return AuthSyncResult(
        nextRoute: mode == 'sign_in' ? '/home' : '/onboard/category',
      );
    }
    final token = await _tokens.getAccessToken();
    if (token == null || token.isEmpty) {
      return AuthSyncResult(
        nextRoute: mode == 'sign_in' ? '/home' : '/onboard/category',
      );
    }
    return _api.syncAuthSession(mode: mode);
  }

  @override
  Future<ProProfile?> fetchProfile() => _whenAuthedApi(
        api: _api.fetchProfile,
        mock: () async => null,
      );

  @override
  Future<List<CategoryRef>> fetchCategories() => _whenApi(
        api: _api.fetchCategories,
        mock: _mock.fetchCategories,
      );

  @override
  Future<void> saveCategories(
    List<String> categoryCodes, {
    Map<String, int>? experienceByCategory,
  }) =>
      _whenAuthedApi(
        api: () => _api.saveCategories(
          categoryCodes,
          experienceByCategory: experienceByCategory,
        ),
        mock: () async {},
      );

  @override
  Future<void> saveExperience({
    required String fullName,
    required Map<String, int> experienceByCategory,
  }) =>
      _whenAuthedApi(
        api: () => _api.saveExperience(
          fullName: fullName,
          experienceByCategory: experienceByCategory,
        ),
        mock: () async {},
      );

  @override
  Future<void> saveLocation({
    required int cityId,
    required int workRadiusKm,
    double? homeLat,
    double? homeLng,
  }) =>
      _whenAuthedApi(
        api: () => _api.saveLocation(
          cityId: cityId,
          workRadiusKm: workRadiusKm,
          homeLat: homeLat,
          homeLng: homeLng,
        ),
        mock: () async {},
      );

  @override
  Future<void> saveVisitFeePaise(int visitFeePaise) => _whenAuthedApi(
        api: () => _api.saveVisitFeePaise(visitFeePaise),
        mock: () async {},
      );

  @override
  Future<String> initiateAadhaar(String last4) => _whenAuthedApi(
        api: () => _api.initiateAadhaar(last4),
        mock: () => _mock.initiateAadhaar(last4),
      );

  @override
  Future<bool> verifyAadhaarOtp({required String kycRefId, required String otp}) =>
      _whenAuthedApi(
        api: () => _api.verifyAadhaarOtp(kycRefId: kycRefId, otp: otp),
        mock: () => _mock.verifyAadhaarOtp(kycRefId: kycRefId, otp: otp),
      );

  @override
  Future<double> uploadSelfie() => _whenAuthedApi(
        api: _api.uploadSelfie,
        mock: _mock.uploadSelfie,
      );

  @override
  Future<void> uploadKycDocuments(List<String> documentTypes) => _whenAuthedApi(
        api: () => _api.uploadKycDocuments(documentTypes),
        mock: () async {},
      );

  @override
  Future<KycStatus> fetchKycStatus() => _whenAuthedApi(
        api: _api.fetchKycStatus,
        mock: () async => KycStatus.inReview,
      );

  @override
  Future<void> simulateKycApproval() => _whenAuthedApi(
        api: _api.simulateKycApproval,
        mock: () async {},
      );

  @override
  Future<List<JobOffer>> fetchOffers(List<String> categoryCodes) =>
      _whenAuthedApi(
        api: () => _api.fetchOffers(categoryCodes),
        mock: () => _mock.fetchOffers(categoryCodes),
      );

  @override
  Future<ActiveJob?> fetchActiveJob() => _whenAuthedApi(
        api: _api.fetchActiveJob,
        mock: _mock.fetchActiveJob,
      );

  @override
  Future<JobOffer?> fetchOffer(String offerId) => _whenAuthedApi(
        api: () => _api.fetchOffer(offerId),
        mock: () async {
          final all = await _mock.fetchOffers(const ['ac', 'plumber']);
          for (final o in all) {
            if (o.id == offerId) return o;
          }
          return null;
        },
      );

  @override
  Future<ActiveJob> acceptOffer(String offerId) => _whenAuthedApi(
        api: () => _api.acceptOffer(offerId),
        mock: () async {
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
        },
      );

  @override
  Future<void> rejectOffer(String offerId) => _whenAuthedApi(
        api: () => _api.rejectOffer(offerId),
        mock: () async {},
      );

  @override
  Future<void> updateActiveJobStatus(BookingStatus status) => _whenAuthedApi(
        api: () => _api.updateActiveJobStatus(status),
        mock: () async {},
      );

  @override
  Future<void> completeActiveJob(int finalAmountPaise) => _whenAuthedApi(
        api: () => _api.completeActiveJob(finalAmountPaise),
        mock: () async {},
      );

  @override
  Future<EarningsSummary> fetchEarnings() => _whenAuthedApi(
        api: _api.fetchEarnings,
        mock: _mock.fetchEarnings,
      );

  @override
  Future<void> updateAvailability(bool isAvailable) => _whenAuthedApi(
        api: () => _api.updateAvailability(isAvailable),
        mock: () async {},
      );

  // ─── Customer-side ──────────────────────────────────────────────────

  @override
  Future<List<ProSearchResult>> searchPros({required int cityId, String? categoryCode, String? query, double? lat, double? lng}) =>
      _whenApi(
        api: () => _api.searchPros(cityId: cityId, categoryCode: categoryCode, query: query, lat: lat, lng: lng),
        mock: () => _mock.searchPros(cityId: cityId, categoryCode: categoryCode, query: query, lat: lat, lng: lng),
      );

  @override
  Future<Map<String, dynamic>> fetchProDetail(
    int proId, {
    String? categoryCode,
    double? lat,
    double? lng,
  }) =>
      _whenApi(
        api: () => _api.fetchProDetail(
          proId,
          categoryCode: categoryCode,
          lat: lat,
          lng: lng,
        ),
        mock: () => _mock.fetchProDetail(
          proId,
          categoryCode: categoryCode,
          lat: lat,
          lng: lng,
        ),
      );

  @override
  Future<List<CustomerBooking>> fetchCustomerBookings() => _whenAuthedApi(
        api: _api.fetchCustomerBookings,
        mock: _mock.fetchCustomerBookings,
      );

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
  }) =>
      _whenAuthedApi(
        api: () => _api.createBooking(
          professionalId: professionalId,
          categoryCode: categoryCode,
          problemDescription: problemDescription,
          addressText: addressText,
          cityId: cityId,
          scheduledAt: scheduledAt,
          addressLat: addressLat,
          addressLng: addressLng,
          visitFeePaise: visitFeePaise,
          visitFeePaid: visitFeePaid,
          visitFeePaymentMethod: visitFeePaymentMethod,
        ),
        mock: () => _mock.createBooking(
          professionalId: professionalId,
          categoryCode: categoryCode,
          problemDescription: problemDescription,
          addressText: addressText,
          cityId: cityId,
          scheduledAt: scheduledAt,
          addressLat: addressLat,
          addressLng: addressLng,
          visitFeePaise: visitFeePaise,
          visitFeePaid: visitFeePaid,
          visitFeePaymentMethod: visitFeePaymentMethod,
        ),
      );

  @override
  Future<CustomerBooking> fetchBookingDetail(int bookingId) => _whenAuthedApi(
        api: () => _api.fetchBookingDetail(bookingId),
        mock: () => _mock.fetchBookingDetail(bookingId),
      );

  @override
  Future<void> cancelBooking(int bookingId) => _whenAuthedApi(
        api: () => _api.cancelBooking(bookingId),
        mock: () => _mock.cancelBooking(bookingId),
      );

  @override
  Future<void> completeBooking(int bookingId) => _whenAuthedApi(
        api: () => _api.completeBooking(bookingId),
        mock: () => _mock.completeBooking(bookingId),
      );

  @override
  Future<void> rateBooking(int bookingId, {required int stars, String? reviewText}) =>
      _whenAuthedApi(
        api: () => _api.rateBooking(bookingId, stars: stars, reviewText: reviewText),
        mock: () => _mock.rateBooking(bookingId, stars: stars, reviewText: reviewText),
      );

  @override
  Future<CustomerProfile?> fetchCustomerProfile() => _whenAuthedApi(
        api: _api.fetchCustomerProfile,
        mock: _mock.fetchCustomerProfile,
      );

  @override
  Future<CustomerProfile?> updateCustomerProfile({
    required String fullName,
    required int cityId,
  }) =>
      _whenAuthedApi(
        api: () => _api.updateCustomerProfile(fullName: fullName, cityId: cityId),
        mock: () => _mock.updateCustomerProfile(fullName: fullName, cityId: cityId),
      );

  @override
  Future<void> registerPushToken({
    required String fcmToken,
    String platform = 'android',
    AppRole? role,
  }) =>
      _whenAuthedApi(
        api: () => _api.registerPushToken(
          fcmToken: fcmToken,
          platform: platform,
          role: role,
        ),
        mock: () => _mock.registerPushToken(
          fcmToken: fcmToken,
          platform: platform,
          role: role,
        ),
      );
}
