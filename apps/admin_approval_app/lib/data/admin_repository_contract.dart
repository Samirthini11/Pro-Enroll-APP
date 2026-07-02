import 'models.dart';

/// Contract shared by mock and API repositories.
abstract class AdminRepositoryContract {
  AdminUser? get currentAdmin;

  Future<bool> login({required String email, required String password});
  Future<void> logout();
  Future<void> restoreSession();

  Future<AdminDashboardStats> fetchDashboardStats();
  Future<List<PendingProApplication>> fetchKycQueue({ReviewStatus? status});
  Future<PendingProApplication?> fetchKycDetail(int proId);
  Future<bool> approveKyc(int proId);
  Future<bool> rejectKyc(int proId, String reason);

  Future<List<DocumentReviewItem>> fetchDocumentQueue({
    DocumentKind? kind,
    DocumentStatus? status,
  });
  Future<bool> approveDocument(int documentId);
  Future<bool> rejectDocument(int documentId, String reason);
}
