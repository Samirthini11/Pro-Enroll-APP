import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_token_service.dart';
import '../data/app_admin_repository.dart';
import '../data/admin_repository_contract.dart';
import '../data/api/api_exception.dart';
import '../data/models.dart';

final adminTokenServiceProvider =
    Provider<AdminTokenService>((ref) => AdminTokenService());

final repositoryProvider = Provider<AdminRepositoryContract>((ref) {
  final tokens = ref.watch(adminTokenServiceProvider);
  return AppAdminRepository(tokens: tokens);
});

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AdminUser?>>((ref) {
  return AuthNotifier(ref.watch(repositoryProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<AdminUser?>> {
  AuthNotifier(this._repo) : super(const AsyncData(null)) {
    _restore();
  }

  final AdminRepositoryContract _repo;

  Future<void> _restore() async {
    await _repo.restoreSession();
    final existing = _repo.currentAdmin;
    if (existing != null) state = AsyncData(existing);
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final ok = await _repo.login(email: email, password: password);
      if (ok) {
        state = AsyncData(_repo.currentAdmin);
        return true;
      }
      state = const AsyncData(null);
      return false;
    } on ApiException catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(null);
  }
}

final dashboardStatsProvider =
    FutureProvider.autoDispose<AdminDashboardStats>((ref) async {
  return ref.watch(repositoryProvider).fetchDashboardStats();
});

final kycQueueProvider = FutureProvider.autoDispose
    .family<List<PendingProApplication>, ReviewStatus?>((ref, status) async {
  return ref.watch(repositoryProvider).fetchKycQueue(status: status);
});

final kycDetailProvider = FutureProvider.autoDispose
    .family<PendingProApplication?, int>((ref, proId) async {
  return ref.watch(repositoryProvider).fetchKycDetail(proId);
});

final documentQueueProvider = FutureProvider.autoDispose
    .family<List<DocumentReviewItem>, DocumentQueueFilter>((ref, filter) async {
  return ref.watch(repositoryProvider).fetchDocumentQueue(
        kind: filter.kind,
        status: filter.status,
      );
});

class DocumentQueueFilter {
  const DocumentQueueFilter({this.kind, this.status});

  final DocumentKind? kind;
  final DocumentStatus? status;

  @override
  bool operator ==(Object other) =>
      other is DocumentQueueFilter &&
      other.kind == kind &&
      other.status == status;

  @override
  int get hashCode => Object.hash(kind, status);
}
