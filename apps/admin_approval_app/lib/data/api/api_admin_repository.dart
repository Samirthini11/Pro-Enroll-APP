import 'admin_mapper.dart';
import 'api_client.dart';
import 'api_exception.dart';
import '../admin_repository_contract.dart';
import '../admin_token_service.dart';
import '../models.dart';

/// PHP backend (`pro_enroll_api`) — admin auth + KYC/document endpoints.
class ApiAdminRepository implements AdminRepositoryContract {
  ApiAdminRepository(this._client, {required this.tokens});

  final ApiClient _client;
  final AdminTokenService tokens;

  AdminUser? _session;

  @override
  AdminUser? get currentAdmin => _session;

  @override
  Future<bool> login({required String email, required String password}) async {
    final data = await _client.post(
      '/v1/auth/admin/login',
      auth: false,
      body: {'email': email, 'password': password},
    );

    final access = data['access_token'] as String?;
    final adminMap = data['admin'];
    if (access == null || access.isEmpty || adminMap is! Map) {
      return false;
    }

    final admin = adminUserFromApi(Map<String, dynamic>.from(adminMap));
    await tokens.saveSession(accessToken: access, admin: admin);
    _session = admin;
    return true;
  }

  @override
  Future<void> logout() async {
    try {
      if (await tokens.getAccessToken() != null) {
        await _client.post('/v1/auth/logout');
      }
    } on ApiException catch (e) {
      if (e.code != 'invalid_token' && e.code != 'missing_token') rethrow;
    } finally {
      await tokens.signOut();
      _session = null;
    }
  }

  @override
  Future<void> restoreSession() async {
    final admin = await tokens.getStoredAdmin();
    final token = await tokens.getAccessToken();
    if (admin != null && token != null && token.isNotEmpty) {
      _session = admin;
    }
  }

  @override
  Future<AdminDashboardStats> fetchDashboardStats() async {
    final data = await _client.get('/v1/admin/dashboard');
    return dashboardStatsFromApi(data);
  }

  @override
  Future<List<PendingProApplication>> fetchKycQueue({
    ReviewStatus? status,
  }) async {
    final query = <String, String>{};
    if (status != null) {
      query['status'] = reviewStatusToApi(status);
    }
    final data = await _client.get(
      '/v1/admin/kyc',
      query: query.isEmpty ? null : query,
    );
    final list = data['items'];
    if (list is! List) return [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic>)
          pendingProFromApi(item)
        else if (item is Map)
          pendingProFromApi(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<PendingProApplication?> fetchKycDetail(int proId) async {
    final data = await _client.get('/v1/admin/kyc/$proId');
    final item = data['item'];
    if (item is Map<String, dynamic>) return pendingProFromApi(item);
    if (item is Map) return pendingProFromApi(Map<String, dynamic>.from(item));
    return null;
  }

  @override
  Future<bool> approveKyc(int proId) async {
    await _client.post('/v1/admin/kyc/$proId/approve');
    return true;
  }

  @override
  Future<bool> rejectKyc(int proId, String reason) async {
    await _client.post(
      '/v1/admin/kyc/$proId/reject',
      body: {'reason': reason},
    );
    return true;
  }

  @override
  Future<List<DocumentReviewItem>> fetchDocumentQueue({
    DocumentKind? kind,
    DocumentStatus? status,
  }) async {
    final query = <String, String>{};
    if (kind != null) query['kind'] = documentKindToApi(kind);
    if (status != null) {
      query['status'] = switch (status) {
        DocumentStatus.approved => 'approved',
        DocumentStatus.rejected => 'rejected',
        DocumentStatus.pending => 'pending',
      };
    }
    final data = await _client.get(
      '/v1/admin/documents',
      query: query.isEmpty ? null : query,
    );
    final list = data['items'];
    if (list is! List) return [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic>)
          documentReviewFromApi(item)
        else if (item is Map)
          documentReviewFromApi(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<bool> approveDocument(int documentId) async {
    await _client.post('/v1/admin/documents/$documentId/approve');
    return true;
  }

  @override
  Future<bool> rejectDocument(int documentId, String reason) async {
    await _client.post(
      '/v1/admin/documents/$documentId/reject',
      body: {'reason': reason},
    );
    return true;
  }
}
