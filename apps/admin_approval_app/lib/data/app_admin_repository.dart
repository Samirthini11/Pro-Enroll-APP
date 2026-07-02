import '../core/app_config.dart';
import 'admin_repository_contract.dart';
import 'admin_token_service.dart';
import 'api/api_admin_repository.dart';
import 'api/api_client.dart';
import 'mock_admin_repository.dart';
import 'models.dart';

/// Routes to [ApiAdminRepository] when [AppConfig.hasApi] is on.
class AppAdminRepository implements AdminRepositoryContract {
  AppAdminRepository({
    MockAdminRepository? mock,
    ApiAdminRepository? api,
    AdminTokenService? tokens,
  })  : _mock = mock ?? MockAdminRepository(),
        _api = api ??
            ApiAdminRepository(
              ApiClient(tokens ?? AdminTokenService()),
              tokens: tokens ?? AdminTokenService(),
            );

  final MockAdminRepository _mock;
  final ApiAdminRepository _api;

  bool get _useApi => AppConfig.hasApi;

  AdminRepositoryContract get _active => _useApi ? _api : _mock;

  @override
  AdminUser? get currentAdmin => _active.currentAdmin;

  @override
  Future<bool> login({required String email, required String password}) =>
      _active.login(email: email, password: password);

  @override
  Future<void> logout() => _active.logout();

  @override
  Future<void> restoreSession() async {
    if (_useApi) {
      await _api.restoreSession();
    }
  }

  @override
  Future<AdminDashboardStats> fetchDashboardStats() =>
      _active.fetchDashboardStats();

  @override
  Future<List<PendingProApplication>> fetchKycQueue({ReviewStatus? status}) =>
      _active.fetchKycQueue(status: status);

  @override
  Future<PendingProApplication?> fetchKycDetail(int proId) =>
      _active.fetchKycDetail(proId);

  @override
  Future<bool> approveKyc(int proId) => _active.approveKyc(proId);

  @override
  Future<bool> rejectKyc(int proId, String reason) =>
      _active.rejectKyc(proId, reason);

  @override
  Future<List<DocumentReviewItem>> fetchDocumentQueue({
    DocumentKind? kind,
    DocumentStatus? status,
  }) =>
      _active.fetchDocumentQueue(kind: kind, status: status);

  @override
  Future<bool> approveDocument(int documentId) =>
      _active.approveDocument(documentId);

  @override
  Future<bool> rejectDocument(int documentId, String reason) =>
      _active.rejectDocument(documentId, reason);
}
