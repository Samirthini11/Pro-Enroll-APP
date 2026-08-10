import 'dart:async';

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
import '../services/kyc_preview_service.dart';
import '../services/push_notification_service.dart';



final jwtTokenServiceProvider =

    Provider<JwtTokenService>((ref) => JwtTokenService());



final repositoryProvider = Provider<ProRepository>((ref) {

  final tokens = ref.read(jwtTokenServiceProvider);

  return AppRepository(tokens: tokens);

});

final roleProvider = StateProvider<AppRole>((ref) => AppRole.professional);

/// Professional home bottom-nav: 0 Jobs · 1 Wallet · 2 Earnings · 3 Profile · 4 Help
final homeShellTabProvider = StateProvider<int>((ref) => 0);



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
      final activeRole = sync.role ?? role;
      if (activeRole == AppRole.customer) {
        await _ref.read(customerProvider.notifier).loadProfile();
        // Prefer profile-based next route so incomplete customers get name+city setup.
        final customer = _ref.read(customerProvider).profile;
        if (!(customer?.isProfileComplete ?? false)) {
          state = state.copyWith(nextRoute: '/customer/profile-setup');
        }
      } else if (sync.profile != null) {
        _ref.read(profileProvider.notifier).applyFromServer(sync.profile!);
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
        await _ref.read(customerProvider.notifier).loadProfile();
        final customer = _ref.read(customerProvider).profile;
        final next = !(customer?.isProfileComplete ?? false)
            ? '/customer/profile-setup'
            : sync.nextRoute;
        state = state.copyWith(nextRoute: next);
      } catch (e) {
        debugPrint('Customer auth sync failed: $e');
        final customer = _ref.read(customerProvider).profile;
        if (!(customer?.isProfileComplete ?? false)) {
          state = state.copyWith(nextRoute: '/customer/profile-setup');
        }
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
      allowKycPreview: _ref.read(kycPreviewUnlockedProvider),
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

    unawaited(navigateRespectingPush(router, path));
  }

  void navigateAfterCustomerAuth(GoRouter router) {
    if (!state.isAuthenticated || state.otpErrorCode == 'invalid_otp') {
      return;
    }

    final profile = _ref.read(customerProvider).profile;
    final path = CustomerRouteResolver.resolve(
      profile: profile,
      serverNextRoute: state.nextRoute,
    );
    unawaited(navigateRespectingPush(router, path));
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
      allowKycPreview: _ref.read(kycPreviewUnlockedProvider),
    );
  }

  /// Open a notification deep link when queued; otherwise [defaultRoute].
  Future<void> navigateRespectingPush(
    GoRouter router,
    String defaultRoute,
  ) async {
    if (!state.isAuthenticated || state.otpErrorCode == 'invalid_otp') {
      return;
    }

    final push = _ref.read(pushNotificationServiceProvider);
    await push.init();

    final role = _ref.read(roleProvider);
    final hadPending = PushNotificationService.hasPending;
    if (hadPending) {
      final navigated = await push.markReadyAndFlush(authenticated: true);
      // Success, or another flush (auth listener) already consumed the pending.
      if (navigated || !PushNotificationService.hasPending) {
        unawaited(push.finishColdStartAndSyncToken(role: role));
        return;
      }
      // Could not open deep link yet — land on shell, then retry once.
      router.go(defaultRoute);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await push.markReadyAndFlush(authenticated: true);
      unawaited(push.finishColdStartAndSyncToken(role: role));
      return;
    }

    router.go(defaultRoute);
    unawaited(push.finishColdStartAndSyncToken(role: role));
  }

  /// Optimistically mark authenticated from a disk JWT before network validate.
  /// Prevents GoRouter from bouncing a cold-start notification tap to login.
  Future<bool> bootstrapSessionFromDisk({AppRole? preferredRole}) async {
    if (!AppConfig.hasApi) return false;

    final preferred = preferredRole ??
        PushNotificationService.pendingRequiredRole;
    final active = await _tokens.getActiveRole();
    final candidates = <AppRole>[
      if (preferred != null) preferred,
      active,
      ...AppRole.values,
    ];

    for (final role in candidates) {
      if (!await _tokens.hasTokenForRole(role)) continue;
      await _tokens.setActiveRole(role);
      _ref.read(roleProvider.notifier).state = role;
      state = state.copyWith(
        isAuthenticated: true,
        role: role,
      );
      return true;
    }
    return state.isAuthenticated;
  }



  Future<bool> tryRestoreSession({AppRole? preferredRole}) async {
    if (!AppConfig.hasApi) {
      return false;
    }

    final activeRole = await _tokens.getActiveRole();
    final preferred = preferredRole ??
        PushNotificationService.pendingRequiredRole;
    final fromNotification = PushNotificationService.hasPending;

    // Prefer the role needed by a tapped notification, then last-active, then the other.
    final candidates = <AppRole>[];
    void add(AppRole role) {
      if (!candidates.contains(role)) candidates.add(role);
    }

    if (preferred != null) add(preferred);
    add(activeRole);
    for (final role in AppRole.values) {
      add(role);
    }

    ApiException? lastAuthFailure;

    Future<bool> adoptRole(AppRole role, {required bool syncPush}) async {
      await _tokens.setActiveRole(role);
      _ref.read(roleProvider.notifier).state = role;
      state = state.copyWith(
        isAuthenticated: true,
        role: role,
      );

      try {
        if (role == AppRole.customer) {
          await _ref.read(customerProvider.notifier).loadProfile();
          final customer = _ref.read(customerProvider).profile;
          state = state.copyWith(
            nextRoute: !(customer?.isProfileComplete ?? false)
                ? '/customer/profile-setup'
                : '/customer/home',
          );
        } else {
          final profile = await _repo.fetchProfile();
          if (profile != null) {
            _ref.read(profileProvider.notifier).applyFromServer(profile);
          }
        }
      } catch (e) {
        debugPrint('Session restore profile sync: $e');
      }

      if (syncPush) {
        // Do not block notification deep-link on FCM register.
        unawaited(_syncPushToken());
      }
      return true;
    }

    for (final role in candidates) {
      if (!await _tokens.hasTokenForRole(role)) continue;

      await _tokens.setActiveRole(role);
      _ref.read(roleProvider.notifier).state = role;

      try {
        final valid = await _repo.validateSession();
        if (!valid) {
          // Soft fail — fall through to trust on-disk JWT below.
          continue;
        }
      } on ApiException catch (e) {
        lastAuthFailure = e;
        if (e.statusCode == 401) {
          continue;
        }
        // Non-auth error: still restore this role (token present).
      } catch (e) {
        debugPrint('Session restore network for $role: $e');
        // Keep going with this role if a token exists.
      }

      return adoptRole(role, syncPush: !fromNotification);
    }

    // Cold start / soft failure: JWT still on disk → keep session (open app /
    // notification) instead of sending the user to login.
    for (final role in candidates) {
      if (!await _tokens.hasTokenForRole(role)) continue;
      debugPrint(
        'Session restore: trusting local JWT for $role '
        '(server validate soft-failed; fromNotification=$fromNotification)',
      );
      return adoptRole(role, syncPush: !fromNotification);
    }

    // No usable token — nothing to restore (do not wipe empty storage).
    if (lastAuthFailure != null) {
      debugPrint('Session restore failed: $lastAuthFailure');
    }
    return false;
  }

  Future<void> signOut() async {
    try {
      // Go offline before logout so customer search drops this pro immediately.
      if (_ref.read(roleProvider) == AppRole.professional &&
          _ref.read(profileProvider).isAvailable) {
        await _ref.read(profileProvider.notifier).setAvailability(false);
      }
    } catch (_) {
      // Still proceed with logout.
    }
    try {
      await (_firebasePhoneAuth ?? FirebasePhoneAuthService()).signOut();
    } catch (_) {
      // Local JWT logout still proceeds if Firebase is unavailable.
    }
    _firebasePhoneAuth = null;
    await _repo.logout();
    state = const AuthState();
    _ref.read(profileProvider.notifier).reset();
    _ref.read(customerProvider.notifier).reset();
    _ref.read(jobsProvider.notifier).reset();
    _ref.read(roleProvider.notifier).state = AppRole.professional;
    _ref.read(kycPreviewUnlockedProvider.notifier).state = false;
    await KycPreviewService.clear();
    // Drop stale deep-links from this session; a new tap while logged out
    // will queue a fresh destination for after the next login.
    await _ref.read(pushNotificationServiceProvider).clearPendingForLogout();
  }

  /// Switch between Pro (enrolled) and Customer (book services) without OTP.
  Future<bool> switchRole(AppRole target) async {
    if (!AppConfig.hasApi) {
      _ref.read(roleProvider.notifier).state = target;
      return false;
    }

    Future<bool> adoptLocal() async {
      await _tokens.setActiveRole(target);
      _ref.read(roleProvider.notifier).state = target;
      state = state.copyWith(
        isAuthenticated: true,
        role: target,
        clearError: true,
      );
      try {
        if (target == AppRole.customer) {
          if (_ref.read(profileProvider).isAvailable) {
            try {
              await _ref.read(profileProvider.notifier).setAvailability(false);
            } catch (_) {}
          }
          await _ref.read(customerProvider.notifier).loadProfile();
        } else {
          final profile = await _repo.fetchProfile();
          if (profile != null) {
            _ref.read(profileProvider.notifier).applyFromServer(profile);
          }
        }
      } catch (e) {
        debugPrint('switchRole local profile sync: $e');
      }
      return true;
    }

    if (await _tokens.hasTokenForRole(target)) {
      return adoptLocal();
    }

    if (!await _tokens.hasTokenAsync()) {
      _ref.read(roleProvider.notifier).state = target;
      return false;
    }

    try {
      final sync = await _repo.switchRole(target);
      if (sync == null) {
        if (await _tokens.hasTokenForRole(target)) return adoptLocal();
        return false;
      }
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
        if (_ref.read(profileProvider).isAvailable) {
          try {
            await _ref.read(profileProvider.notifier).setAvailability(false);
          } catch (_) {}
        }
        await _ref.read(customerProvider.notifier).loadProfile();
      }
      await _syncPushToken();
      return true;
    } on ApiException catch (e) {
      debugPrint('switchRole API failed: $e');
      if (await _tokens.hasTokenForRole(target)) return adoptLocal();
      return false;
    } catch (e) {
      debugPrint('switchRole failed: $e');
      if (await _tokens.hasTokenForRole(target)) return adoptLocal();
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

  void setSkillVisitFeesRupees(Map<String, int> feesRupees) {
    if (feesRupees.isEmpty) return;
    final skills = [
      for (final s in state.skills)
        s.copyWith(
          visitFeePaise:
              (feesRupees[s.categoryCode] ?? (s.visitFeePaise / 100).round()) *
                  100,
        ),
    ];
    ProSkill? primary;
    for (final s in skills) {
      if (s.isPrimary) {
        primary = s;
        break;
      }
    }
    primary ??= skills.isNotEmpty ? skills.first : null;
    state = state.copyWith(
      skills: skills,
      visitFeePaise: primary?.visitFeePaise ?? state.visitFeePaise,
    );
  }

  Future<void> setAvailability(bool on) async {
    if (state.isAvailable == on) return;
    final previous = state;
    // Optimistic UI — avoid a second full profile reload that jerks the switch.
    state = state.copyWith(isAvailable: on);
    try {
      final updated = await _repo.updateAvailability(on);
      if (updated != null) {
        // Keep the toggle value the user just set if the server echoes it.
        state = updated.copyWith(isAvailable: on);
      }
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  /// Soft ping so customer search keeps listing this pro.
  Future<void> pingPresence() async {
    if (!state.isAvailable) return;
    try {
      await _repo.pingPresence();
    } catch (e) {
      debugPrint('pingPresence: $e');
    }
  }



  void setKyc(KycStatus s, {String? aadhaarLast4}) =>

      state = state.copyWith(kycStatus: s, aadhaarLast4: aadhaarLast4);



  void setUpi(String upi) => state = state.copyWith(upiId: upi);



  void setBank(String acct, String ifsc) =>

      state = state.copyWith(bankAccountNo: acct, bankIfsc: ifsc);



  Future<void> persistCategories(
    List<String> codes, {
    Map<String, int>? experienceByCategory,
    Map<String, int>? experienceStartYearByCategory,
  }) async {
    await _repo.saveCategories(
      codes,
      experienceByCategory: experienceByCategory,
      experienceStartYearByCategory: experienceStartYearByCategory,
    );
  }

  Future<void> persistExperience({
    required String fullName,
    Map<String, int>? yearsByCategory,
    Map<String, int>? startYearByCategory,
  }) async {
    await _repo.saveExperience(
      fullName: fullName,
      experienceByCategory: yearsByCategory,
      experienceStartYearByCategory: startYearByCategory,
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
    final fees = {
      for (final s in state.skills) s.categoryCode: s.visitFeePaise,
    };
    await _repo.saveVisitFeePaise(
      state.visitFeePaise,
      feesByCategoryPaise: fees.isEmpty ? null : fees,
    );
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
  const JobsState({
    this.offers = const [],
    this.history = const [],
    this.activeJob,
    this.loading = false,
  });

  final List<JobOffer> offers;
  final List<ProJobHistoryItem> history;
  final ActiveJob? activeJob;
  final bool loading;

  JobsState copyWith({
    List<JobOffer>? offers,
    List<ProJobHistoryItem>? history,
    Object? activeJob = _unset,
    bool? loading,
    bool clearActive = false,
  }) {
    final ActiveJob? nextActive;
    if (clearActive) {
      nextActive = null;
    } else if (identical(activeJob, _unset)) {
      nextActive = this.activeJob;
    } else {
      nextActive = activeJob as ActiveJob?;
    }

    return JobsState(
      offers: offers ?? this.offers,
      history: history ?? this.history,
      activeJob: nextActive,
      loading: loading ?? this.loading,
    );
  }
}

const Object _unset = Object();

class JobsNotifier extends StateNotifier<JobsState> {
  JobsNotifier(this._repo) : super(const JobsState());

  final ProRepository _repo;

  Future<void> refresh(
    List<String> categoryCodes, {
    bool silent = false,
  }) async {
    // Silent refresh keeps the current list visible (no spinner swap / layout jump).
    if (!silent || (state.offers.isEmpty && state.history.isEmpty)) {
      state = state.copyWith(loading: true);
    }
    try {
      final bundle = await _repo.fetchHomeJobs(categoryCodes);
      state = state.copyWith(
        offers: bundle.offers,
        history: bundle.history,
        activeJob: bundle.activeJob,
        loading: false,
        clearActive: bundle.activeJob == null,
      );
    } catch (e) {
      debugPrint('fetchHomeJobs error: $e');
      if (!silent) {
        state = state.copyWith(
          offers: const [],
          history: const [],
          loading: false,
        );
      } else {
        state = state.copyWith(loading: false);
      }
    }
  }

  Future<void> accept(JobOffer offer) async {
    final existing = state.activeJob;
    if (existing != null && _isOpenJobStatus(existing.status)) {
      throw ApiException(
        'Finish your current job before accepting a new one.',
        code: 'job_in_progress',
        statusCode: 409,
      );
    }
    final result = await _repo.acceptOffer(offer.id);
    state = state.copyWith(
      offers: state.offers.where((o) => o.id != offer.id).toList(),
      activeJob: result.activeJob,
    );
  }

  static bool _isOpenJobStatus(BookingStatus s) =>
      s == BookingStatus.accepted ||
      s == BookingStatus.onTheWay ||
      s == BookingStatus.arrived ||
      s == BookingStatus.inProgress ||
      s == BookingStatus.awaitingPayment;

  Future<void> reject(JobOffer offer) async {
    await _repo.rejectOffer(offer.id);
    state = state.copyWith(
      offers: state.offers.where((o) => o.id != offer.id).toList(),
    );
  }

  Future<void> cancelActive({String? reason}) async {
    await _repo.cancelActiveJob(reason: reason);
    final next = await _repo.fetchActiveJob();
    state = state.copyWith(
      activeJob: next,
      clearActive: next == null,
    );
  }

  Future<void> updateStatus(BookingStatus s) async {
    final j = state.activeJob;
    if (j == null) return;
    if (j.status == s) return;

    // Client-side one-step guard (server also enforces this).
    final allowed = switch (j.status) {
      BookingStatus.accepted => s == BookingStatus.onTheWay,
      BookingStatus.onTheWay => s == BookingStatus.arrived,
      BookingStatus.arrived => s == BookingStatus.inProgress,
      _ => false,
    };
    if (!allowed) {
      throw ApiException(
        'Please use the next step button only once.',
        code: 'invalid_status_transition',
        statusCode: 400,
      );
    }

    await _repo.updateActiveJobStatus(s);
    // Cancel only before work starts, and under daily limit.
    final statusAllowsCancel = s == BookingStatus.accepted ||
        s == BookingStatus.onTheWay ||
        s == BookingStatus.arrived;
    final underDailyLimit = (j.cancelsRemainingToday ?? 1) > 0;
    final canCancel = statusAllowsCancel && underDailyLimit;
    state = state.copyWith(
      activeJob: j.copyWith(status: s, canCancel: canCancel),
    );
  }

  Future<void> pingLocation(double lat, double lng) async {
    final job = state.activeJob;
    if (job == null) return;
    // Stop sharing once work has started (or later).
    if (job.status == BookingStatus.inProgress ||
        job.status == BookingStatus.awaitingPayment ||
        job.status == BookingStatus.completed ||
        job.status == BookingStatus.cancelled) {
      return;
    }
    try {
      await _repo.pingActiveJobLocation(lat: lat, lng: lng);
    } catch (e) {
      debugPrint('pingLocation error: $e');
    }
  }

  Future<void> complete() async {
    final j = state.activeJob;
    if (j == null) return;
    final settled = await _repo.completeActiveJob(0);
    if (settled != null) {
      state = state.copyWith(activeJob: settled);
    } else {
      state = state.copyWith(
        activeJob: j.copyWith(status: BookingStatus.awaitingPayment),
      );
    }
  }

  Future<void> confirmPaymentReceived({String paymentMethod = 'cash'}) async {
    final j = state.activeJob;
    if (j == null) return;
    await _repo.confirmPaymentReceived(
      paymentMethod: paymentMethod,
    );
    // Current job closed — clear so a new offer can be accepted.
    final next = await _repo.fetchActiveJob();
    state = state.copyWith(
      activeJob: next,
      clearActive: next == null,
    );
  }

  void clearActive() => state = state.copyWith(clearActive: true);

  void reset() => state = const JobsState();
}



final jobsProvider =

    StateNotifierProvider<JobsNotifier, JobsState>((ref) {

  return JobsNotifier(ref.read(repositoryProvider));

});



/// ─── Earnings ──────────────────────────────────────────────────────────

final earningsProvider = FutureProvider<EarningsSummary>((ref) {

  return ref.read(repositoryProvider).fetchEarnings();

});

final creditHistoryProvider = FutureProvider<List<CreditHistoryItem>>((ref) {
  return ref.read(repositoryProvider).fetchCreditHistory();
});

final rechargeRequestsProvider =
    FutureProvider<List<WalletRechargeRequest>>((ref) {
  return ref.read(repositoryProvider).fetchRechargeRequests();
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
    state = state.copyWith(loading: true, searchResults: const []);
    try {
      // Keep bookings fresh so we can hide busy pros client-side too.
      try {
        final bookings = await _repo.fetchCustomerBookings();
        state = state.copyWith(bookings: bookings);
      } catch (_) {}

      var results = await _repo.searchPros(
        cityId: cityId,
        categoryCode: categoryCode,
        query: query,
        lat: lat,
        lng: lng,
      );

      // Safety net: hide pros with an in-process booking for this customer.
      // Own professional profile is excluded by the API (same phone / dual role).
      final busyProIds = {
        for (final b in state.bookings)
          if (b.isInProcess) b.professionalId,
      };
      if (busyProIds.isNotEmpty) {
        results = [
          for (final p in results)
            if (!busyProIds.contains(p.id)) p,
        ];
      }

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
    bool visitFeePaid = false,
    String? visitFeePaymentMethod,
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
    // Immediately hide this pro from nearby lists while booking is in process.
    state = state.copyWith(
      searchResults: [
        for (final p in state.searchResults)
          if (p.id != professionalId) p,
      ],
    );
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

  Future<CustomerBooking> payVisitFee(
    int bookingId, {
    String paymentMethod = 'upi',
  }) async {
    final b = await _repo.payVisitFee(bookingId, paymentMethod: paymentMethod);
    await loadBookings();
    return b;
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

