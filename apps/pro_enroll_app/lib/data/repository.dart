import '../core/constants.dart';
import 'models.dart';

/// Result of `POST /v1/auth/otp/send`.
class OtpSendResult {
  const OtpSendResult({required this.requestId, this.debugOtp});

  final String requestId;
  /// Present when API runs with `APP_DEBUG` / `OTP_DEBUG_RETURN`.
  final String? debugOtp;
}

/// Contract for Pro-Enroll backend (mock or PHP API).
abstract class ProRepository {
  Future<OtpSendResult> sendOtp(String phone, {required String mode});

  Future<AuthSyncResult?> verifyOtp({
    required String requestId,
    required String otp,
    required String mode,
    String app = 'pro_enroll',
    AppRole role = AppRole.professional,
  });

  /// Exchange Firebase Phone Auth ID token for a JWT session.
  Future<AuthSyncResult?> exchangeFirebaseSession({
    required String idToken,
    required String mode,
    String app = 'pro_enroll',
    AppRole role = AppRole.professional,
  });

  /// Switch session between professional and customer (same phone).
  Future<AuthSyncResult?> switchRole(AppRole role);

  Future<bool> validateSession();

  Future<void> logout();

  /// Refresh profile / next route when JWT already exists.
  Future<AuthSyncResult> syncAuthSession({required String mode});

  Future<ProProfile?> fetchProfile();

  Future<List<CategoryRef>> fetchCategories();

  Future<void> saveCategories(
    List<String> categoryCodes, {
    Map<String, int>? experienceByCategory,
    Map<String, int>? experienceStartYearByCategory,
  });
  Future<void> saveExperience({
    required String fullName,
    Map<String, int>? experienceByCategory,
    Map<String, int>? experienceStartYearByCategory,
  });
  Future<void> saveLocation({
    required int cityId,
    required int workRadiusKm,
    double? homeLat,
    double? homeLng,
  });
  Future<void> saveVisitFeePaise(
    int visitFeePaise, {
    Map<String, int>? feesByCategoryPaise,
  });

  Future<String> initiateAadhaar(String last4);
  Future<bool> verifyAadhaarOtp({required String kycRefId, required String otp});
  Future<double> uploadSelfie();
  Future<void> uploadKycDocuments(List<String> documentTypes);
  Future<KycStatus> fetchKycStatus();
  Future<void> simulateKycApproval();

  Future<List<JobOffer>> fetchOffers(List<String> categoryCodes);
  /// Offers + job history (+ active) from home-jobs screen.
  Future<HomeJobsBundle> fetchHomeJobs(List<String> categoryCodes);
  Future<ActiveJob?> fetchActiveJob();
  Future<JobOffer?> fetchOffer(String offerId);
  /// Accepts an offer. Fails if another job is still active.
  Future<AcceptOfferResult> acceptOffer(String offerId);
  Future<void> rejectOffer(String offerId);
  Future<void> updateActiveJobStatus(BookingStatus status);
  Future<void> pingActiveJobLocation({required double lat, required double lng});
  Future<ActiveJob?> completeActiveJob(int finalAmountPaise);
  /// Pro confirms cash / offline visit fee received → settle job as completed.
  Future<ActiveJob?> confirmPaymentReceived({String paymentMethod = 'cash'});
  /// Reject an accepted job while still on the way (before marking arrived).
  /// [reason] is required when rejecting after heading out (en_route).
  Future<void> cancelActiveJob({String? reason});

  Future<EarningsSummary> fetchEarnings();
  Future<List<CreditHistoryItem>> fetchCreditHistory();
  Future<EarningsSummary> markPlatformFeePaid({required String utr});
  /// Submits a top-up for admin approval; wallet is credited only once approved.
  Future<EarningsSummary> rechargeWallet({
    required int amountPaise,
    required String utr,
  });
  Future<List<WalletRechargeRequest>> fetchRechargeRequests();
  /// Raise a Help request so admin can unlock experience year edits.
  Future<ProProfile?> requestExperienceEdit({String? reason});
  /// Returns the updated profile from the server when available.
  Future<ProProfile?> updateAvailability(bool isAvailable);

  /// Keep online presence alive while the pro app is open.
  Future<void> pingPresence();

  // ─── Customer-side ──────────────────────────────────────────────────
  Future<List<ProSearchResult>> searchPros({required int cityId, String? categoryCode, String? query, double? lat, double? lng});
  Future<Map<String, dynamic>> fetchProDetail(
    int proId, {
    String? categoryCode,
    double? lat,
    double? lng,
  });
  Future<List<CustomerBooking>> fetchCustomerBookings();
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
    bool visitFeePaid = false,
    String? visitFeePaymentMethod,
  });
  Future<CustomerBooking> fetchBookingDetail(int bookingId);
  Future<void> cancelBooking(int bookingId);
  Future<void> completeBooking(int bookingId);
  Future<CustomerBooking> payVisitFee(
    int bookingId, {
    String paymentMethod = 'upi',
  });
  Future<void> rateBooking(int bookingId, {required int stars, String? reviewText});
  Future<CustomerProfile?> fetchCustomerProfile();
  Future<CustomerProfile?> updateCustomerProfile({
    required String fullName,
    required int cityId,
  });

  /// Register this device's FCM token for push alerts.
  Future<void> registerPushToken({
    required String fcmToken,
    String platform = 'android',
    AppRole? role,
  });
}

class AuthSyncResult {
  const AuthSyncResult({
    required this.nextRoute,
    this.profile,
    this.role,
  });

  final String nextRoute;
  final ProProfile? profile;
  final AppRole? role;
}

class HomeJobsBundle {
  const HomeJobsBundle({
    this.offers = const [],
    this.history = const [],
    this.activeJob,
  });

  final List<JobOffer> offers;
  final List<ProJobHistoryItem> history;
  final ActiveJob? activeJob;
}

/// Result of accepting a job offer.
class AcceptOfferResult {
  const AcceptOfferResult({
    required this.activeJob,
  });

  final ActiveJob activeJob;
}
