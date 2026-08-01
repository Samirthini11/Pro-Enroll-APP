library;

/// Admin roles matching `admin_user.role` in the database schema.
enum AdminRole { support, ops, finance, superadmin }

extension AdminRoleX on AdminRole {
  String get label => switch (this) {
        AdminRole.support => 'Support',
        AdminRole.ops => 'Operations',
        AdminRole.finance => 'Finance',
        AdminRole.superadmin => 'Super Admin',
      };
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  final int id;
  final String email;
  final String name;
  final AdminRole role;
}

/// KYC review status for a professional awaiting admin action.
enum ReviewStatus { inReview, verified, rejected }

extension ReviewStatusX on ReviewStatus {
  String get label => switch (this) {
        ReviewStatus.inReview => 'In Review',
        ReviewStatus.verified => 'Verified',
        ReviewStatus.rejected => 'Rejected',
      };
}

/// Document kinds from `pro_document.kind` in the schema.
enum DocumentKind { aadhaar, pan, selfie, shopPhoto, cert, other }

extension DocumentKindX on DocumentKind {
  String get label => switch (this) {
        DocumentKind.aadhaar => 'Aadhaar',
        DocumentKind.pan => 'PAN',
        DocumentKind.selfie => 'Selfie',
        DocumentKind.shopPhoto => 'Shop Photo',
        DocumentKind.cert => 'Certificate',
        DocumentKind.other => 'Other',
      };

  String get code => switch (this) {
        DocumentKind.aadhaar => 'aadhaar',
        DocumentKind.pan => 'pan',
        DocumentKind.selfie => 'selfie',
        DocumentKind.shopPhoto => 'shop_photo',
        DocumentKind.cert => 'cert',
        DocumentKind.other => 'other',
      };
}

enum DocumentStatus { pending, approved, rejected }

class ProDocument {
  const ProDocument({
    required this.id,
    required this.kind,
    required this.label,
    required this.status,
    this.thumbnailUrl,
    this.uploadedAt,
    this.rejectedReason,
  });

  final int id;
  final DocumentKind kind;
  final String label;
  final DocumentStatus status;
  final String? thumbnailUrl;
  final DateTime? uploadedAt;
  final String? rejectedReason;

  ProDocument copyWith({DocumentStatus? status, String? rejectedReason}) {
    return ProDocument(
      id: id,
      kind: kind,
      label: label,
      status: status ?? this.status,
      thumbnailUrl: thumbnailUrl,
      uploadedAt: uploadedAt,
      rejectedReason: rejectedReason ?? this.rejectedReason,
    );
  }
}

class ProSkill {
  const ProSkill({
    required this.categoryCode,
    required this.experienceYears,
    this.isPrimary = false,
  });

  final String categoryCode;
  final int experienceYears;
  final bool isPrimary;
}

/// A professional application waiting for admin KYC approval.
class PendingProApplication {
  const PendingProApplication({
    required this.proId,
    required this.fullName,
    required this.displayName,
    required this.phoneE164,
    required this.city,
    required this.skills,
    required this.workRadiusKm,
    required this.visitFeePaise,
    required this.aadhaarLast4,
    required this.faceMatchScore,
    required this.submittedAt,
    required this.documents,
    this.status = ReviewStatus.inReview,
    this.rejectedReason,
    this.address,
  });

  final int proId;
  final String fullName;
  final String displayName;
  final String phoneE164;
  final String city;
  final List<ProSkill> skills;
  final int workRadiusKm;
  final int visitFeePaise;
  final String aadhaarLast4;
  final double faceMatchScore;
  final DateTime submittedAt;
  final List<ProDocument> documents;
  final ReviewStatus status;
  final String? rejectedReason;
  final String? address;

  String get primaryCategory =>
      skills.where((s) => s.isPrimary).firstOrNull?.categoryCode ??
      (skills.isNotEmpty ? skills.first.categoryCode : '—');

  int get pendingDocCount =>
      documents.where((d) => d.status == DocumentStatus.pending).length;

  PendingProApplication copyWith({
    ReviewStatus? status,
    String? rejectedReason,
    List<ProDocument>? documents,
  }) {
    return PendingProApplication(
      proId: proId,
      fullName: fullName,
      displayName: displayName,
      phoneE164: phoneE164,
      city: city,
      skills: skills,
      workRadiusKm: workRadiusKm,
      visitFeePaise: visitFeePaise,
      aadhaarLast4: aadhaarLast4,
      faceMatchScore: faceMatchScore,
      submittedAt: submittedAt,
      documents: documents ?? this.documents,
      status: status ?? this.status,
      rejectedReason: rejectedReason ?? this.rejectedReason,
      address: address,
    );
  }
}

/// Shop photo or training certificate pending document-level review.
class DocumentReviewItem {
  const DocumentReviewItem({
    required this.documentId,
    required this.proId,
    required this.proName,
    required this.city,
    required this.kind,
    required this.label,
    required this.submittedAt,
    this.status = DocumentStatus.pending,
    this.thumbnailUrl,
    this.rejectedReason,
    this.notes,
  });

  final int documentId;
  final int proId;
  final String proName;
  final String city;
  final DocumentKind kind;
  final String label;
  final DateTime submittedAt;
  final DocumentStatus status;
  final String? thumbnailUrl;
  final String? rejectedReason;
  final String? notes;

  DocumentReviewItem copyWith({
    DocumentStatus? status,
    String? rejectedReason,
  }) {
    return DocumentReviewItem(
      documentId: documentId,
      proId: proId,
      proName: proName,
      city: city,
      kind: kind,
      label: label,
      submittedAt: submittedAt,
      status: status ?? this.status,
      thumbnailUrl: thumbnailUrl,
      rejectedReason: rejectedReason ?? this.rejectedReason,
      notes: notes,
    );
  }
}

class AdminDashboardStats {
  const AdminDashboardStats({
    required this.kycPending,
    required this.docsPending,
    required this.approvedToday,
    required this.rejectedToday,
    required this.totalVerifiedPros,
    required this.totalRegisteredPros,
    required this.totalRegisteredCustomers,
  });

  final int kycPending;
  final int docsPending;
  final int approvedToday;
  final int rejectedToday;
  final int totalVerifiedPros;
  final int totalRegisteredPros;
  final int totalRegisteredCustomers;
}
