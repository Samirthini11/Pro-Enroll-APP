import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_otp_service.dart';
import '../data/mock_repository.dart';
import '../data/models.dart';

final repositoryProvider = Provider<MockRepository>((ref) => MockRepository());

final firebaseOtpServiceProvider =
    Provider<FirebaseOtpService>((ref) => FirebaseOtpService());

/// ─── Auth ──────────────────────────────────────────────────────────────
@immutable
class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.phoneE164,
    this.otpRequestId,
    this.errorMessage,
    this.autoVerified = false,
  });

  final bool isAuthenticated;
  final String? phoneE164;
  final String? otpRequestId;
  final String? errorMessage;

  /// True when Firebase auto-verified the SMS on Android and we should
  /// skip the OTP entry screen entirely.
  final bool autoVerified;

  AuthState copyWith({
    bool? isAuthenticated,
    String? phoneE164,
    String? otpRequestId,
    String? errorMessage,
    bool? autoVerified,
    bool clearError = false,
  }) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        phoneE164: phoneE164 ?? this.phoneE164,
        otpRequestId: otpRequestId ?? this.otpRequestId,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        autoVerified: autoVerified ?? this.autoVerified,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo, this._firebase) : super(const AuthState());
  final MockRepository _repo;
  final FirebaseOtpService _firebase;

  bool get _useFirebase => FirebaseOtpService.isAvailable;

  Future<void> startPhone(String phoneE164) async {
    state = state.copyWith(
      phoneE164: phoneE164,
      autoVerified: false,
      clearError: true,
    );

    if (_useFirebase) {
      final r = await _firebase.sendOtp(phoneE164);
      if (r.isAutoVerified) {
        state = state.copyWith(isAuthenticated: true, autoVerified: true);
      } else if (r.isFailed) {
        state = state.copyWith(errorMessage: r.errorMessage);
      } else {
        // OTP sent; nothing else to do until the user types the code.
        state = state.copyWith(otpRequestId: 'firebase');
      }
    } else {
      final reqId = await _repo.sendOtp(phoneE164);
      state = state.copyWith(otpRequestId: reqId);
    }
  }

  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(clearError: true);

    if (state.autoVerified) {
      // Already signed in by Firebase instant verification.
      state = state.copyWith(isAuthenticated: true);
      return true;
    }

    if (_useFirebase) {
      final err = await _firebase.verifyOtp(otp);
      if (err == null) {
        state = state.copyWith(isAuthenticated: true);
        return true;
      }
      state = state.copyWith(errorMessage: err);
      return false;
    }

    final id = state.otpRequestId;
    if (id == null) return false;
    final ok = await _repo.verifyOtp(requestId: id, otp: otp);
    if (ok) {
      state = state.copyWith(isAuthenticated: true);
    } else {
      state = state.copyWith(errorMessage: 'Invalid OTP. Try again.');
    }
    return ok;
  }

  void signOut() {
    if (_useFirebase) {
      // Fire-and-forget; we don't need to wait.
      _firebase.signOut();
    }
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(repositoryProvider),
    ref.read(firebaseOtpServiceProvider),
  );
});

/// ─── Profile ────────────────────────────────────────────────────────────
class ProfileNotifier extends StateNotifier<ProProfile> {
  ProfileNotifier(this._repo) : super(ProProfile());
  // ignore: unused_field
  final MockRepository _repo;

  void setPhone(String phone) => state = state.copyWith(phoneE164: phone);
  void setName(String name) => state = state.copyWith(fullName: name);
  void setCity(int id) => state = state.copyWith(cityId: id);
  void setSkills(List<ProSkill> skills) =>
      state = state.copyWith(skills: skills);
  void setRadius(int km) => state = state.copyWith(workRadiusKm: km);
  void setVisitFeeRupees(int rupees) =>
      state = state.copyWith(visitFeePaise: rupees * 100);
  void setAvailability(bool on) => state = state.copyWith(isAvailable: on);
  void setKyc(KycStatus s, {String? aadhaarLast4}) =>
      state = state.copyWith(kycStatus: s, aadhaarLast4: aadhaarLast4);
  void setUpi(String upi) => state = state.copyWith(upiId: upi);
  void setBank(String acct, String ifsc) =>
      state = state.copyWith(bankAccountNo: acct, bankIfsc: ifsc);

  /// Seeded sample stats for the demo so the Earnings / Profile screens
  /// don't show empty zeros.
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
  final MockRepository _repo;

  Future<void> refresh(List<String> categoryCodes) async {
    state = state.copyWith(loading: true);
    final offers = await _repo.fetchOffers(categoryCodes);
    state = state.copyWith(offers: offers, loading: false);
  }

  void accept(JobOffer offer) {
    state = state.copyWith(
      offers: state.offers.where((o) => o.id != offer.id).toList(),
      activeJob: ActiveJob(
        id: offer.id,
        code: offer.code,
        categoryCode: offer.categoryCode,
        problem: offer.problem,
        customerName: offer.customerName,
        customerPhoneMasked: '+91 78xxx xx${(1000 + offer.id.hashCode.abs() % 900).toString()}',
        customerAddress: offer.customerAreaName,
        customerAreaName: offer.customerAreaName,
        distanceKm: offer.distanceKm,
        visitFeePaise: offer.visitFeePaise,
      ),
    );
  }

  void reject(JobOffer offer) {
    state = state.copyWith(
      offers: state.offers.where((o) => o.id != offer.id).toList(),
    );
  }

  void updateStatus(BookingStatus s) {
    final j = state.activeJob;
    if (j == null) return;
    state = state.copyWith(activeJob: j.copyWith(status: s));
  }

  void complete(int finalAmountRupees) {
    final j = state.activeJob;
    if (j == null) return;
    state = state.copyWith(
      activeJob: j.copyWith(
        status: BookingStatus.completed,
        finalAmountPaise: finalAmountRupees * 100,
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
