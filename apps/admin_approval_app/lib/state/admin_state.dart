import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_admin_repository.dart';
import '../data/models.dart';

final repositoryProvider = Provider<MockAdminRepository>((ref) {
  return MockAdminRepository();
});

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AdminUser?>>((ref) {
  return AuthNotifier(ref.watch(repositoryProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<AdminUser?>> {
  AuthNotifier(this._repo) : super(const AsyncData(null)) {
    final existing = _repo.currentAdmin;
    if (existing != null) state = AsyncData(existing);
  }

  final MockAdminRepository _repo;

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    final ok = await _repo.login(email: email, password: password);
    if (ok) {
      state = AsyncData(_repo.currentAdmin);
      return true;
    }
    state = const AsyncData(null);
    return false;
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
