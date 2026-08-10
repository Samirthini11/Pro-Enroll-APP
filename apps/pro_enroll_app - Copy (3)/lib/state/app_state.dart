import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../core/app_config.dart';
import '../core/i18n.dart';

import '../data/api/api_exception.dart';
import '../data/app_repository.dart';
import '../data/firebase_phone_auth_service.dart';
import '../data/jwt_token_service.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../routing/auth_route_resolver.dart';
import '../routing/customer_route_resolver.dart';
import '../routing/router.dart';
import '../services/push_notification_service.dart';



final jwtTokenServiceProvider =

    Provider<JwtTokenService>((ref) => JwtTokenService());



final repositoryProvider = Provider<ProRepository>((ref) {

  final tokens = ref.read(jwtTokenServiceProvider);

  return AppRepository(tokens: tokens);

});

final roleProvider = StateProvider<AppRole>((ref) => AppRole.professional);



/// ─── Auth ──────────────────────────────────────────────────────────────

@immutable

class AuthState {

  const AuthState({

    this.isAuthenticated = false,

    this.phoneE164,

    this.otpRequestId,

    this.errorMessage,
    this.otpErrorCode,

    this.mockOtpMode = false,

    this.nextRoute,

    this.debugOtp,
    this.signUpFlow = true,
    this.role,
    this.firebaseSmsMode = false,

  });

  final bool isAuthenticated;
  final String? phoneE164;
  final String? otpRequestId;
  final String? errorMessage;
  /// e.g. `invalid_otp` from API — UI must not navigate while this is set.
  final String? otpErrorCode;
  final bool mockOtpMode;
  final String? nextRoute;
  /// Shown on OTP screen when API returns `debug_otp` (local dev).
  final String? debugOtp;
  /// `true` = create account, `false` = sign in (survives router refresh).
  final bool signUpFlow;
  final AppRole? role;
  /// OTP was sent via Firebase Phone Auth (SMS), not PHP mail OTP.
  final bool firebaseSmsMode;

  AuthState copyWith({

    bool? isAuthenticated,

    String? phoneE164,

    String? otpRequestId,

    String? errorMessage,
    String? otpErrorCode,

    bool? mockOtpMode,

    String? nextRoute,
    String? debugOtp,
    bool? signUpFlow,
    AppRole? role,
    bool? firebaseSmsMode,
    bool clearError = false,
    bool clearOtpErrorCode = false,
    bool clearDebugOtp = false,
  }) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        phoneE164: phoneE164 ?? this.phoneE164,
        otpRequestId: otpRequestId ?? this.otpRequestId,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        otpErrorCode:
            clearOtpErrorCode ? null : (otpErrorCode ?? this.otpErrorCode),
        mockOtpMode: mockOtpMode ?? this.mockOtpMode,
        nextRoute: nextRoute ?? this.nextRoute,
        debugOtp: clearDebugOtp ? null : (debugOtp ?? this.debugOtp),
        signUpFlow: signUpFlow ?? this.signUpFlow,
        role: role ?? this.role,
        firebaseSmsMode: firebaseSmsMode ?? this.firebaseSmsMode,
      );

}



class AuthNotifier extends StateNotifier<AuthState> {

  AuthNotifier(this._repo, this._tokens, this._ref) : super(const AuthState());



  final ProRepository _repo;

  final JwtTokenService _tokens;

  final Ref _ref;

  FirebasePhoneAuthService? _firebasePhoneAuth;



  /// Start a fresh sign-up (clears any old JWT so user is not sent to home).
  Future<void> beginSignUp() async {
    await _tokens.signOut();
    _ref.read(profileProvider.notifier).reset();
    state = const AuthState(signUpFlow: true);
  }

  void beginSignIn() {
    state = const AuthState(signUpFlow: false);
  }

  Future<void> startPhone(String phoneE164, {required bool isSignIn}) async {
    final signUp = !isSignIn;
    if (signUp) {
      await _tokens.signOut();
    }

    if (AppConfig.usesFirebaseSmsOtp) {
      try {
        await (_firebasePhoneAuth ??= FirebasePhoneAuthService()).sendOtp(phoneE164);
        state = AuthState(
          phoneE164: phoneE164,
          mockOtpMode: false,
          firebaseSmsMode: true,
          signUpFlow: signUp,
          otpRequestId: 'firebase',
          isAuthenticated: false,
        );
      } catch (e) {
        state = AuthState(
          phoneE164: phoneE164,
          mockOtpMode: false,
          firebaseSmsMode: true,
          signUpFlow: signUp,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
          isAuthenticated: false,
        );
      }
      return;
    }

    try {
      final mode = isSignIn ? 'sign_in' : 'sign_up';
      final sent = await _repo.sendOtp(phoneE164, mode: mode);
      state = AuthState(
        phoneE164: phoneE164,
        mockOtpMode: !AppConfig.hasApi,
        signUpFlow: signUp,
        otpRequestId: sent.requestId,
        debugOtp: sent.debugOtp,
        isAuthenticated: false,
      );
    } on ApiException catch (e) {
      state = AuthState(
        phoneE164: phoneE164,
        mockOtpMode: !AppConfig.hasApi,
        signUpFlow: signUp,
        errorMessage: e.message,
        isAuthenticated: false,
      );
    } catch (e) {
      final detail = e is ApiException
          ? e.message
          : e.toString().replaceFirst('Exception: ', '');
      state = AuthState(
        phoneE164: phoneE164,
        mockOtpMode: !AppConfig.hasApi,
        signUpFlow: signUp,
        errorMessage: detail.isNotEmpty
            ? detail
            : 'Could not send OTP. Check API connection and try again.',
        isAuthenticated: false,
      );
    }
  }

  void clearError() {
    if (state.errorMessage != null || state.otpErrorCode != null) {
      state = state.copyWith(clearError: true, clearOtpErrorCode: true);
    }
  }

  bool _isInvalidOtpError(ApiException e) =>
      e.code == 'invalid_otp' || e.statusCode == 401;

  String _otpVerifyErrorMessage(ApiException e, L l) {
    if (_isInvalidOtpError(e)) {
      return l.t('auth.otp.invalid');
    }
    return e.message;
  }

  Future<void> _rejectOtpVerification(L l, {required String message}) async {
    if (AppConfig.hasApi) {
      await _tokens.signOut();
    }
    state = state.copyWith(
      isAuthenticated: false,
      errorMessage: message,
      otpErrorCode: 'invalid_otp',
    );
  }

  Future<void> _syncPushToken() async {
    if (!AppConfig.usesFirebase) return;
    try {
      await _ref.read(pushNotificationServiceProvider).syncTokenWithServer();
    } catch (e) {
      debugPrint('Push token sync: $e');
    }
  }

  Future<bool> verifyOtp(String otp, {required bool isSignIn, String app = 'pro_enroll'}) async {

    state = state.copyWith(
      clearError: true,
      clearOtpErrorCode: true,
      isAuthenticated: false,
    );



    final id = state.otpRequestId;
    final l = _ref.read(lProvider);

    if (id == null) {
      state = state.copyWith(
        isAuthenticated: false,
        errorMessage: l.t('auth.otp.session_expired'),
      );
      return false;
    }



    final mode = isSignIn ? 'sign_in' : 'sign_up';

    final role = _ref.read(roleProvider);

    try {
      final AuthSyncResult? sync;
      if (state.firebaseSmsMode && AppConfig.usesFirebaseSmsOtp) {
        final idToken = await (_firebasePhoneAuth ??= FirebasePhoneAuthService())
            .verifyOtpAndGetIdToken(otp);
        sync = await _repo.exchangeFirebaseSession(
          idToken: idToken,
          mode: mode,
          app: app,
          role: role,
        );
      } else {
        sync = await _repo.verifyOtp(
          requestId: id,
          otp: otp,
          mode: mode,
          app: app,
          role: role,
        );
      }
      if (sync == null) {
        await _rejectOtpVerification(l, message: l.t('auth.otp.invalid'));
        return false;
      }

      if (!await _tokens.hasTokenAsync() && AppConfig.hasApi) {
        await _tokens.signOut();
        state = state.copyWith(
          isAuthenticated: false,
          errorMessage: 'Sign-in succeeded but no token was saved. Retry.',
        );
        return false;
      }

      state = state.copyWith(
        isAuthenticated: true,
        nextRoute: sync.nextRoute,
        role: sync.role ?? role,
        clearDebugOtp: true,
        clearOtpErrorCode: true,
      );
      if (sync.role != null) {
        _ref.read(roleProvider.notifier).state = sync.role!;
      }
      if (sync.profile != null) {
        _ref.read(profileProvider.notifier).applyFromServer(sync.profile!);
      }
      final activeRole = sync.role ?? role;
      if (activeRole == AppRole.customer) {
        await _ref.read(customerProvider.notifier).loadProfile();
      }
      await _syncPushToken();
      return true;
    } on ApiException catch (e) {
      if (_isInvalidOtpError(e)) {
        await _rejectOtpVerification(
          l,
          message: _otpVerifyErrorMessage(e, l),
        );
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          errorMessage: e.message,
        );
      }
      return false;
    } catch (_) {
      state = state.copyWith(
        isAuthenticated: false,
        errorMessage: 'Verification failed. Try again.',
      );
      return false;
    }
  }



  /// Optional refresh after OTP when API did not return full profile.

  Future<void> completeAuthAndSync({required bool isSignIn}) async {

    if (!AppConfig.hasApi || !await _tokens.hasTokenAsync()) {

      state = state.copyWith(

        nextRoute: isSignIn ? '/home' : '/onboard/category',

      );

      return;

    }

    if (await _tokens.getActiveRole() == AppRole.customer) {
      try {
        final mode = isSignIn ? 'sign_in' : 'sign_up';
        final sync = await _repo.syncAuthSession(mode: mode);
        state = state.copyWith(nextRoute: sync.nextRoute);
      } catch (e) {
        debugPrint('Customer auth sync failed: $e');
      }
      return;
    }

    try {

      final mode = isSignIn ? 'sign_in' : 'sign_up';

      final sync = await _repo.syncAuthSession(mode: mode);

      state = state.copyWith(nextRoute: sync.nextRoute);

      if (sync.profile != null) {

        _ref.read(profileProvider.notifier).applyFromServer(sync.profile!);

      }

    } catch (e) {

      debugPrint('Auth API sync failed: $e');

    }

  }



  void navigateAfterAuth(GoRouter router, {required bool isSignIn}) {
    if (!state.isAuthenticated || state.otpErrorCode == 'invalid_otp') {
      return;
    }

    final profile = _ref.read(profileProvider);
    final path = AuthRouteResolver.resolve(
      profile: profile,
      serverNextRoute: state.nextRoute,
      isSignIn: isSignIn,
    );

    if (!AppConfig.hasApi) {
      final pn = _ref.read(profileProvider.notifier);
      if (path == Routes.home) {
        if (profile.fullName == null || profile.fullName!.isEmpty) {
          pn.setName('Pro user');
        }
        if (!profile.kycStatus.isVerified) {
          pn.setKyc(KycStatus.verified);
          pn.seedDemoStats();
        }
        pn.setAvailability(true);
      }
    }

    router.go(path);
  }

  void navigateAfterCustomerAuth(GoRouter router) {
    if (!state.isAuthenticated || state.otpErrorCode == 'invalid_otp') {
      return;
    }

    final profile = _ref.read(customerProvider).profile;
    router.go(CustomerRouteResolver.resolve(
      profile: profile,
      serverNextRoute: state.nextRoute,
    ));
  }

  /// After session restore — where the user should land.
  String routeAfterSessionRestore() {
    final role = _ref.read(roleProvider);
    if (role == AppRole.customer) {
      final profile = _ref.read(customerProvider).profile;
      return CustomerRouteResolver.resolve(
        profile: profile,
        serverNextRoute: state.nextRoute,
      );
    }
    final profile = _ref.read(profileProvider);
    return AuthRouteResolver.resolve(
      profile: profile,
      serverNextRoute: state.nextRoute,
      isSignIn: true,
    );
  }



  Future<bool> tryRestoreSession() async {
    if (!AppConfig.hasApi || !await _tokens.hasTokenAsync()) {
      return false;
    }

    final activeRole = await _tokens.getActiveRole();
    await _tokens.setActiveRole(activeRole);
    _ref.read(roleProvider.notifier).state = activeRole;

    var valid = await _repo.validateSession();
    if (!valid) {
      await _tokens.signOut();
      return false;
    }

    state = state.copyWith(
      isAuthenticated: true,
      role: activeRole,
      nextRoute: activeRole == AppRole.customer ? '/customer/home' : state.nextRoute,
    );

    try {
      if (activeRole == AppRole.customer) {
        await _ref.read(customerProvider.notifier).loadProfile();
      } else {
        final profile = await _repo.fetchProfile();
        if (profile != null) {
          _ref.read(profileProvider.notifier).applyFromServer(profile);
        }
      }
    } catch (e) {
      debugPrint('Session restore profile sync: $e');
    }

    await _syncPushToken();
    return true;
  }

  Future<void> signOut() async {
    try {
      await (_firebasePhoneAuth ?? FirebasePhoneAuthService()).signOut();
    } catch (_) {
      // Local JWT logout still proceeds if Firebase is unavailable.
    }
    _firebasePhoneAuth = null;
    await _repo.logout();
    state = const AuthState();
    _ref.read(profileProvider.notifier).reset();
    _ref.read(roleProvider.notifier).state = AppRole.professional;
  }

  /// Switch between Pro (enrolled) and Customer (book services) without OTP.
  Future<bool> switchRole(AppRole target) async {
    if (!AppConfig.hasApi || !await _tokens.hasTokenAsync()) {
      _ref.read(roleProvider.notifier).state = target;
      return false;
    }
    try {
      final sync = await _repo.switchRole(target);
      if (sync == null) return false;
      _ref.read(roleProvider.notifier).state = sync.role ?? target;
      state = state.copyWith(
        isAuthenticated: true,
        nextRoute: sync.nextRoute,
        role: sync.role ?? target,
        clearError: true,
      );
      if (target == AppRole.professional && sync.profile != null) {
        _ref.read(profileProvider.notifier).applyFromServer(sync.profile!);
      } else if (target == AppRole.professional) {
        final profile = await _repo.fetchProfile();
        if (profile != null) {
          _ref.read(profileProvider.notifier).applyFromServer(profile);
        }
      } else if (target == AppRole.customer) {
        await _ref.read(customerProvider.notifier).loadProfile();
      }
      await _syncPushToken();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    } catch (_) {
      return false;
    }
  }
}



final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {

  return AuthNotifier(

    ref.read(repositoryProvider),

    ref.read(jwtTokenServiceProvider),

    ref,

  );

});



/// ─── Profile ────────────────────────────────────────────────────────────

class ProfileNotifier extends StateNotifier<ProProfile> {

  ProfileNotifier(this._repo) : super(ProProfile());



  final ProRepository _repo;



  void applyFromServer(ProProfile profile) => state = profile;



  void reset() => state = ProProfile();



  Future<void> loadFromApi() async {

    final p = await _repo.fetchProfile();

    if (p != null) applyFromServer(p);

  }



  void setPhone(String phone) => state = state.copyWith(phoneE164: phone);



  void setName(String name) => state = state.copyWith(fullName: name);



  void setCity(int id) => state = state.copyWith(cityId: id);



  void setSkills(List<ProSkill> skills) =>

      state = state.copyWith(skills: skills);



  void setRadius(int km) => state = state.copyWith(workRadiusKm: km);



  void setVisitFeeRupees(int rupees) =>

      state = state.copyWith(visitFeePaise: rupees * 100);



  Future<void> setAvailability(bool on) async {

    state = state.copyWith(isAvailable: on);

    await _repo.updateAvailability(on);

  }



  void setKyc(KycStatus s, {String? aadhaarLast4}) =>

      state = state.copyWith(kycStatus: s, aadhaarLast4: aadhaarLast4);



  void setUpi(String upi) => state = state.copyWith(upiId: upi);



  void setBank(String acct, String ifsc) =>

      state = state.copyWith(bankAccountNo: acct, bankIfsc: ifsc);



  Future<void> persistCategories(
    List<String> codes, {
    Map<String, int>? experienceByCategory,
  }) async {
    await _repo.saveCategories(
      codes,
      experienceByCategory: experienceByCategory,
    );
  }



  Future<void> persistExperience({

    required String fullName,

    required Map<String, int> yearsByCategory,

  }) async {

    await _repo.saveExperience(

      fullName: fullName,

      experienceByCategory: yearsByCategory,

    );

  }



  Future<void> persistLocation({
    required int cityId,
    required int radiusKm,
    double? homeLat,
    double? homeLng,
  }) async {
    await _repo.saveLocation(
      cityId: cityId,
      workRadiusKm: radiusKm,
      homeLat: homeLat,
      homeLng: homeLng,
    );
  }



  Future<void> persistVisitFee() async {

    await _repo.saveVisitFeePaise(state.visitFeePaise);

  }



  void seedDemoStats() {

    state = state.copyWith(

      ratingAvg: 4.7,

      ratingCount: 142,

      jobsCompleted: 384,

      proScore: 82,

    );

  }

}



final profileProvider =

    StateNotifierProvider<ProfileNotifier, ProProfile>((ref) {

  return ProfileNotifier(ref.read(repositoryProvider));

});



/// ─── Jobs ──────────────────────────────────────────────────────────────

class JobsState {

  const JobsState({this.offers = const [], this.activeJob, this.loading = false});

  final List<JobOffer> offers;

  final ActiveJob? activeJob;

  final bool loading;



  JobsState copyWith({

    List<JobOffer>? offers,

    ActiveJob? activeJob,

    bool? loading,

    bool clearActive = false,

  }) =>

      JobsState(

        offers: offers ?? this.offers,

        activeJob: clearActive ? null : (activeJob ?? this.activeJob),

        loading: loading ?? this.loading,

      );

}



class JobsNotifier extends StateNotifier<JobsState> {

  JobsNotifier(this._repo) : super(const JobsState());



  final ProRepository _repo;



  Future<void> refresh(List<String> categoryCodes) async {
    state = state.copyWith(loading: true);
    try {
      final offers = await _repo.fetchOffers(categoryCodes);
      final active = await _repo.fetchActiveJob();
      state = state.copyWith(offers: offers, activeJob: active, loading: false);
    } catch (e) {
      debugPrint('fetchOffers error: $e');
      state = state.copyWith(offers: const [], loading: false);
    }
  }



  Future<void> accept(JobOffer offer) async {

    final job = await _repo.acceptOffer(offer.id);

    state = state.copyWith(

      offers: state.offers.where((o) => o.id != offer.id).toList(),

      activeJob: job,

    );

  }



  Future<void> reject(JobOffer offer) async {

    await _repo.rejectOffer(offer.id);

    state = state.copyWith(

      offers: state.offers.where((o) => o.id != offer.id).toList(),

    );

  }



  Future<void> updateStatus(BookingStatus s) async {

    final j = state.activeJob;

    if (j == null) return;

    await _repo.updateActiveJobStatus(s);

    state = state.copyWith(activeJob: j.copyWith(status: s));

  }



  Future<void> complete(int finalAmountRupees) async {

    final j = state.activeJob;

    if (j == null) return;

    final paise = finalAmountRupees * 100;

    await _repo.completeActiveJob(paise);

    state = state.copyWith(

      activeJob: j.copyWith(

        status: BookingStatus.completed,

        finalAmountPaise: paise,

      ),

    );

  }



  void clearActive() => state = state.copyWith(clearActive: true);

}



final jobsProvider =

    StateNotifierProvider<JobsNotifier, JobsState>((ref) {

  return JobsNotifier(ref.read(repositoryProvider));

});



/// ─── Earnings ──────────────────────────────────────────────────────────

final earningsProvider = FutureProvider<EarningsSummary>((ref) {

  return ref.read(repositoryProvider).fetchEarnings();

});

/// ─── Customer ──────────────────────────────────────────────────────────

class CustomerState {
  const CustomerState({
    this.profile,
    this.searchResults = const [],
    this.bookings = const [],
    this.loading = false,
  });
  final CustomerProfile? profile;
  final List<ProSearchResult> searchResults;
  final List<CustomerBooking> bookings;
  final bool loading;

  CustomerState copyWith({
    CustomerProfile? profile,
    List<ProSearchResult>? searchResults,
    List<CustomerBooking>? bookings,
    bool? loading,
  }) => CustomerState(
    profile: profile ?? this.profile,
    searchResults: searchResults ?? this.searchResults,
    bookings: bookings ?? this.bookings,
    loading: loading ?? this.loading,
  );
}

class CustomerNotifier extends StateNotifier<CustomerState> {
  CustomerNotifier(this._repo) : super(const CustomerState());
  final ProRepository _repo;

  Future<void> searchPros({required int cityId, String? categoryCode, String? query, double? lat, double? lng}) async {
    state = state.copyWith(loading: true);
    try {
      final results = await _repo.searchPros(cityId: cityId, categoryCode: categoryCode, query: query, lat: lat, lng: lng);
      state = state.copyWith(searchResults: results, loading: false);
    } catch (e) {
      debugPrint('searchPros error: $e');
      state = state.copyWith(loading: false);
    }
  }

  Future<void> loadBookings() async {
    state = state.copyWith(loading: true);
    try {
      final bookings = await _repo.fetchCustomerBookings();
      state = state.copyWith(bookings: bookings, loading: false);
    } catch (e) {
      debugPrint('loadBookings error: $e');
      state = state.copyWith(loading: false);
    }
  }

  Future<void> loadProfile() async {
    try {
      final p = await _repo.fetchCustomerProfile();
      if (p != null) state = state.copyWith(profile: p);
    } catch (e) {
      debugPrint('loadProfile error: $e');
    }
  }

  Future<void> saveProfile({
    required String fullName,
    required int cityId,
  }) async {
    final p = await _repo.updateCustomerProfile(
      fullName: fullName,
      cityId: cityId,
    );
    if (p != null) state = state.copyWith(profile: p);
  }

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
    final b = await _repo.createBooking(
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
    );
    await loadBookings();
    return b;
  }

  Future<void> cancelBooking(int bookingId) async {
    await _repo.cancelBooking(bookingId);
    await loadBookings();
  }

  Future<void> completeBooking(int bookingId) async {
    await _repo.completeBooking(bookingId);
    await loadBookings();
  }

  Future<void> rateBooking(int bookingId, {required int stars, String? reviewText}) async {
    await _repo.rateBooking(bookingId, stars: stars, reviewText: reviewText);
    await loadBookings();
  }

  void reset() => state = const CustomerState();
}

final customerProvider = StateNotifierProvider<CustomerNotifier, CustomerState>((ref) {
  return CustomerNotifier(ref.read(repositoryProvider));
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref.read(repositoryProvider));
});

