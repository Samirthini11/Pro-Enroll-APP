import 'dart:convert';

import '../models.dart';

ReviewStatus reviewStatusFromApi(String? status) => switch (status) {
      'verified' => ReviewStatus.verified,
      'rejected' => ReviewStatus.rejected,
      _ => ReviewStatus.inReview,
    };

String reviewStatusToApi(ReviewStatus status) => switch (status) {
      ReviewStatus.verified => 'verified',
      ReviewStatus.rejected => 'rejected',
      ReviewStatus.inReview => 'in_review',
    };

DocumentKind documentKindFromApi(String? kind) => switch (kind) {
      'aadhaar' => DocumentKind.aadhaar,
      'pan' => DocumentKind.pan,
      'selfie' => DocumentKind.selfie,
      'shop_photo' => DocumentKind.shopPhoto,
      'cert' => DocumentKind.cert,
      _ => DocumentKind.other,
    };

String documentKindToApi(DocumentKind kind) => kind.code;

DocumentStatus documentStatusFromApi(String? status) => switch (status) {
      'approved' => DocumentStatus.approved,
      'rejected' => DocumentStatus.rejected,
      _ => DocumentStatus.pending,
    };

DateTime? parseApiDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

AdminDashboardStats dashboardStatsFromApi(Map<String, dynamic> map) {
  return AdminDashboardStats(
    kycPending: (map['kyc_pending'] as num?)?.toInt() ?? 0,
    docsPending: (map['docs_pending'] as num?)?.toInt() ?? 0,
    approvedToday: (map['approved_today'] as num?)?.toInt() ?? 0,
    rejectedToday: (map['rejected_today'] as num?)?.toInt() ?? 0,
    totalVerifiedPros: (map['total_verified_pros'] as num?)?.toInt() ?? 0,
  );
}

PendingProApplication pendingProFromApi(Map<String, dynamic> map) {
  final skillsRaw = map['skills'];
  final skills = <ProSkill>[];
  if (skillsRaw is List) {
    for (final item in skillsRaw) {
      if (item is Map) {
        skills.add(ProSkill(
          categoryCode: item['category_code'] as String? ?? '',
          experienceYears: (item['experience_years'] as num?)?.toInt() ?? 0,
          isPrimary: item['is_primary'] == true,
        ));
      }
    }
  }

  final docsRaw = map['documents'];
  final documents = <ProDocument>[];
  if (docsRaw is List) {
    for (final item in docsRaw) {
      if (item is Map) {
        documents.add(proDocumentFromApi(Map<String, dynamic>.from(item)));
      }
    }
  }

  return PendingProApplication(
    proId: (map['pro_id'] as num?)?.toInt() ?? 0,
    fullName: map['full_name'] as String? ?? '',
    displayName: map['display_name'] as String? ?? '',
    phoneE164: map['phone_e164'] as String? ?? '',
    city: map['city'] as String? ?? '—',
    skills: skills,
    workRadiusKm: (map['work_radius_km'] as num?)?.toInt() ?? 5,
    visitFeePaise: (map['visit_fee_paise'] as num?)?.toInt() ?? 15000,
    aadhaarLast4: map['aadhaar_last4'] as String? ?? '',
    faceMatchScore: (map['face_match_score'] as num?)?.toDouble() ?? 0,
    submittedAt: parseApiDateTime(map['submitted_at']) ?? DateTime.now(),
    documents: documents,
    status: reviewStatusFromApi(map['status'] as String?),
    rejectedReason: map['rejected_reason'] as String?,
    address: map['address'] as String?,
  );
}

ProDocument proDocumentFromApi(Map<String, dynamic> map) {
  return ProDocument(
    id: (map['id'] as num?)?.toInt() ?? 0,
    kind: documentKindFromApi(map['kind'] as String?),
    label: map['label'] as String? ?? '',
    status: documentStatusFromApi(map['status'] as String?),
    thumbnailUrl: map['thumbnail_url'] as String?,
    uploadedAt: parseApiDateTime(map['uploaded_at']),
    rejectedReason: map['rejected_reason'] as String?,
  );
}

DocumentReviewItem documentReviewFromApi(Map<String, dynamic> map) {
  return DocumentReviewItem(
    documentId: (map['document_id'] as num?)?.toInt() ?? 0,
    proId: (map['pro_id'] as num?)?.toInt() ?? 0,
    proName: map['pro_name'] as String? ?? '',
    city: map['city'] as String? ?? '—',
    kind: documentKindFromApi(map['kind'] as String?),
    label: map['label'] as String? ?? '',
    submittedAt: parseApiDateTime(map['submitted_at']) ?? DateTime.now(),
    status: documentStatusFromApi(map['status'] as String?),
    thumbnailUrl: map['thumbnail_url'] as String?,
    rejectedReason: map['rejected_reason'] as String?,
    notes: map['notes'] as String?,
  );
}

AdminUser adminUserFromApi(Map<String, dynamic> map) {
  final roleStr = map['role'] as String? ?? 'ops';
  final role = switch (roleStr) {
    'support' => AdminRole.support,
    'finance' => AdminRole.finance,
    'superadmin' => AdminRole.superadmin,
    _ => AdminRole.ops,
  };
  return AdminUser(
    id: (map['id'] as num?)?.toInt() ?? 1,
    email: map['email'] as String? ?? '',
    name: map['name'] as String? ?? 'Admin',
    role: role,
  );
}

String adminUserToJson(AdminUser admin) => jsonEncode({
      'id': admin.id,
      'email': admin.email,
      'name': admin.name,
      'role': switch (admin.role) {
        AdminRole.support => 'support',
        AdminRole.finance => 'finance',
        AdminRole.superadmin => 'superadmin',
        AdminRole.ops => 'ops',
      },
    });

AdminUser? adminUserFromStoredJson(String raw) {
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final roleStr = map['role'] as String? ?? 'ops';
    final role = switch (roleStr) {
      'support' => AdminRole.support,
      'finance' => AdminRole.finance,
      'superadmin' => AdminRole.superadmin,
      _ => AdminRole.ops,
    };
    return AdminUser(
      id: (map['id'] as num?)?.toInt() ?? 1,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? 'Admin',
      role: role,
    );
  } catch (_) {
    return null;
  }
}
