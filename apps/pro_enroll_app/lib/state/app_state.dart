import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_repository.dart';
import '../data/models.dart';

final repositoryProvider = Provider<MockRepository>((ref) => MockRepository());

/// ─── Auth ──────────────────────────────────────────────────────────────
@immutable
class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.phoneE164,
    this.otpRequestId,
  });

  final bool isAuthenticated;
  final String? phoneE164;
  final String? otpRequestId;

  AuthState copyWith({
    bool? isAuthenticated,
    String? phoneE164,
    String? otpRequestId,
  }) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        phoneE164: phoneE164 ?? this.phoneE164,
        otpRequestId: otpRequestId ?? this.otpRequestId,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState());
  final MockRepository _repo;

  Future<void> startPhone(String phoneE164) async {
    final reqId = await _repo.sendOtp(phoneE164);
    state = state.copyWith(phoneE164: phoneE164, otpRequestId: reqId);
  }

  Future<bool> verifyOtp(String otp) async {
    final id = state.otpRequestId;
    if (id == null) return false;
    final ok = await _repo.verifyOtp(requestId: id, otp: otp);
    if (ok) state = state.copyWith(isAuthenticated: true);
    return ok;
  }

  void signOut() => state = const AuthState();
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(repositoryProvider));
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
