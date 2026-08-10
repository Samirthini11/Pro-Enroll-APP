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
  });
  Future<void> saveExperience({
    required String fullName,
    required Map<String, int> experienceByCategory,
  });
  Future<void> saveLocation({
    required int cityId,
    required int workRadiusKm,
    double? homeLat,
    double? homeLng,
  });
  Future<void> saveVisitFeePaise(int visitFeePaise);

  Future<String> initiateAadhaar(String last4);
  Future<bool> verifyAadhaarOtp({required String kycRefId, required String otp});
  Future<double> uploadSelfie();
  Future<void> uploadKycDocuments(List<String> documentTypes);
  Future<KycStatus> fetchKycStatus();
  Future<void> simulateKycApproval();

  Future<List<JobOffer>> fetchOffers(List<String> categoryCodes);
  Future<ActiveJob?> fetchActiveJob();
  Future<JobOffer?> fetchOffer(String offerId);
  Future<ActiveJob> acceptOffer(String offerId);
  Future<void> rejectOffer(String offerId);
  Future<void> updateActiveJobStatus(BookingStatus status);
  Future<void> completeActiveJob(int finalAmountPaise);

  Future<EarningsSummary> fetchEarnings();
  Future<void> updateAvailability(bool isAvailable);

  // ─── Customer-side ──────────────────────────────────────────────────
  Future<List<ProSearchResult>> searchPros({required int cityId, String? categoryCode, String? query, double? lat, double? lng});
  Future<Map<String, dynamic>> fetchProDetail(int proId, {String? categoryCode});
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
  });
  Future<CustomerBooking> fetchBookingDetail(int bookingId);
  Future<void> completeBooking(int bookingId);
  Future<void> rateBooking(int bookingId, {required int stars, String? reviewText});
  Future<CustomerProfile?> fetchCustomerProfile();
  Future<void> updateCustomerProfile({required String fullName});
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
