import 'dart:async';

import 'admin_repository_contract.dart';
import 'models.dart';

/// In-memory mock backend for the Admin Approval app.
///
/// Used when `USE_API=false`. Mirrors admin endpoints from `pro_enroll_api`.
class MockAdminRepository implements AdminRepositoryContract {
  MockAdminRepository() {
    _seedData();
  }

  AdminUser? _session;
  late List<PendingProApplication> _kycQueue;
  late List<DocumentReviewItem> _docQueue;

  AdminUser? get currentAdmin => _session;

  Future<void> _delay([int ms = 400]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  Future<bool> login({required String email, required String password}) async {
    await _delay();
    if (email.isEmpty || password.length < 4) return false;
    _session = AdminUser(
      id: 1,
      email: email,
      name: 'Admin User',
      role: AdminRole.ops,
    );
    return true;
  }

  Future<void> logout() async {
    await _delay(200);
    _session = null;
  }

  @override
  Future<void> restoreSession() async {}

  Future<AdminDashboardStats> fetchDashboardStats() async {
    await _delay();
    final kycPending =
        _kycQueue.where((p) => p.status == ReviewStatus.inReview).length;
    final docsPending =
        _docQueue.where((d) => d.status == DocumentStatus.pending).length;
    return AdminDashboardStats(
      kycPending: kycPending,
      docsPending: docsPending,
      approvedToday: 7,
      rejectedToday: 2,
      totalVerifiedPros: 1482,
      totalRegisteredPros: 1520,
      totalRegisteredCustomers: 3840,
    );
  }

  Future<List<PendingProApplication>> fetchKycQueue({
    ReviewStatus? status,
  }) async {
    await _delay();
    if (status == null) {
      return List.unmodifiable(_kycQueue);
    }
    return List.unmodifiable(_kycQueue.where((p) => p.status == status));
  }

  Future<PendingProApplication?> fetchKycDetail(int proId) async {
    await _delay();
    try {
      return _kycQueue.firstWhere((p) => p.proId == proId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> approveKyc(int proId) async {
    await _delay(600);
    final idx = _kycQueue.indexWhere((p) => p.proId == proId);
    if (idx < 0) return false;
    _kycQueue[idx] = _kycQueue[idx].copyWith(status: ReviewStatus.verified);
    return true;
  }

  Future<bool> rejectKyc(int proId, String reason) async {
    await _delay(600);
    final idx = _kycQueue.indexWhere((p) => p.proId == proId);
    if (idx < 0) return false;
    _kycQueue[idx] = _kycQueue[idx].copyWith(
      status: ReviewStatus.rejected,
      rejectedReason: reason,
    );
    return true;
  }

  Future<List<DocumentReviewItem>> fetchDocumentQueue({
    DocumentKind? kind,
    DocumentStatus? status,
  }) async {
    await _delay();
    return List.unmodifiable(
      _docQueue.where((d) {
        final kindOk = kind == null || d.kind == kind;
        final statusOk = status == null || d.status == status;
        return kindOk && statusOk;
      }),
    );
  }

  Future<bool> approveDocument(int documentId) async {
    await _delay(500);
    final idx = _docQueue.indexWhere((d) => d.documentId == documentId);
    if (idx < 0) return false;
    _docQueue[idx] =
        _docQueue[idx].copyWith(status: DocumentStatus.approved);
    return true;
  }

  Future<bool> rejectDocument(int documentId, String reason) async {
    await _delay(500);
    final idx = _docQueue.indexWhere((d) => d.documentId == documentId);
    if (idx < 0) return false;
    _docQueue[idx] = _docQueue[idx].copyWith(
      status: DocumentStatus.rejected,
      rejectedReason: reason,
    );
    return true;
  }

  void _seedData() {
    final now = DateTime.now();
    _kycQueue = [
      PendingProApplication(
        proId: 101,
        fullName: 'Murugan S.',
        displayName: 'Murugan AC Service',
        phoneE164: '+919876543210',
        city: 'Pondicherry',
        address: '12, Bharathi Street, Reddiarpalayam',
        skills: const [
          ProSkill(categoryCode: 'ac', experienceYears: 8, isPrimary: true),
          ProSkill(categoryCode: 'fridge', experienceYears: 4),
        ],
        workRadiusKm: 10,
        visitFeePaise: 15000,
        aadhaarLast4: '4521',
        faceMatchScore: 0.94,
        submittedAt: now.subtract(const Duration(hours: 3)),
        documents: [
          ProDocument(
            id: 1,
            kind: DocumentKind.aadhaar,
            label: 'Aadhaar (masked)',
            status: DocumentStatus.approved,
            uploadedAt: now.subtract(const Duration(hours: 4)),
          ),
          ProDocument(
            id: 2,
            kind: DocumentKind.selfie,
            label: 'Selfie + face match',
            status: DocumentStatus.approved,
            uploadedAt: now.subtract(const Duration(hours: 4)),
          ),
          ProDocument(
            id: 3,
            kind: DocumentKind.shopPhoto,
            label: 'Shop front photo',
            status: DocumentStatus.pending,
            uploadedAt: now.subtract(const Duration(hours: 3)),
          ),
          ProDocument(
            id: 4,
            kind: DocumentKind.cert,
            label: 'AC training certificate',
            status: DocumentStatus.pending,
            uploadedAt: now.subtract(const Duration(hours: 3)),
          ),
        ],
      ),
      PendingProApplication(
        proId: 102,
        fullName: 'Selvam R.',
        displayName: 'Selvam Plumbing Works',
        phoneE164: '+919812345678',
        city: 'Karaikal',
        address: '45, Beach Road, Karaikal',
        skills: const [
          ProSkill(categoryCode: 'plumber', experienceYears: 12, isPrimary: true),
        ],
        workRadiusKm: 5,
        visitFeePaise: 15000,
        aadhaarLast4: '7890',
        faceMatchScore: 0.88,
        submittedAt: now.subtract(const Duration(hours: 8)),
        documents: [
          ProDocument(
            id: 5,
            kind: DocumentKind.aadhaar,
            label: 'Aadhaar (masked)',
            status: DocumentStatus.approved,
            uploadedAt: now.subtract(const Duration(hours: 9)),
          ),
          ProDocument(
            id: 6,
            kind: DocumentKind.selfie,
            label: 'Selfie + face match',
            status: DocumentStatus.approved,
            uploadedAt: now.subtract(const Duration(hours: 9)),
          ),
          ProDocument(
            id: 7,
            kind: DocumentKind.shopPhoto,
            label: 'Workshop photo',
            status: DocumentStatus.pending,
            uploadedAt: now.subtract(const Duration(hours: 8)),
          ),
        ],
      ),
      PendingProApplication(
        proId: 103,
        fullName: 'Karthik V.',
        displayName: 'Karthik Bike Care',
        phoneE164: '+919700112233',
        city: 'Cuddalore',
        address: 'NH-45, Near Bus Stand',
        skills: const [
          ProSkill(categoryCode: 'bike', experienceYears: 6, isPrimary: true),
          ProSkill(categoryCode: 'car', experienceYears: 3),
        ],
        workRadiusKm: 15,
        visitFeePaise: 20000,
        aadhaarLast4: '3344',
        faceMatchScore: 0.72,
        submittedAt: now.subtract(const Duration(minutes: 45)),
        documents: [
          ProDocument(
            id: 8,
            kind: DocumentKind.aadhaar,
            label: 'Aadhaar (masked)',
            status: DocumentStatus.approved,
            uploadedAt: now.subtract(const Duration(hours: 1)),
          ),
          ProDocument(
            id: 9,
            kind: DocumentKind.selfie,
            label: 'Selfie + face match',
            status: DocumentStatus.pending,
            uploadedAt: now.subtract(const Duration(minutes: 50)),
          ),
          ProDocument(
            id: 10,
            kind: DocumentKind.cert,
            label: 'Two-wheeler mechanic diploma',
            status: DocumentStatus.pending,
            uploadedAt: now.subtract(const Duration(minutes: 45)),
          ),
        ],
      ),
    ];

    _docQueue = [
      for (final app in _kycQueue)
        for (final doc in app.documents.where(
          (d) =>
              d.status == DocumentStatus.pending &&
              (d.kind == DocumentKind.shopPhoto ||
                  d.kind == DocumentKind.cert),
        ))
          DocumentReviewItem(
            documentId: doc.id,
            proId: app.proId,
            proName: app.displayName,
            city: app.city,
            kind: doc.kind,
            label: doc.label,
            submittedAt: doc.uploadedAt ?? app.submittedAt,
            status: doc.status,
            notes: doc.kind == DocumentKind.shopPhoto
                ? 'Verify shop/workshop matches registered address'
                : 'Verify training certificate authenticity',
          ),
    ];
  }
}
