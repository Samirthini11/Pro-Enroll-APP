import 'package:flutter_test/flutter_test.dart';

import 'package:admin_approval_app/data/mock_admin_repository.dart';
import 'package:admin_approval_app/data/models.dart';

void main() {
  group('AdminApprovalApp', () {
    test('login accepts valid credentials', () async {
      final repo = MockAdminRepository();
      final ok = await repo.login(
        email: 'admin@proenroll.in',
        password: 'secret',
      );
      expect(ok, isTrue);
      expect(repo.currentAdmin?.email, 'admin@proenroll.in');
    });

    test('KYC queue has in-review applications', () async {
      final repo = MockAdminRepository();
      final queue = await repo.fetchKycQueue(status: ReviewStatus.inReview);
      expect(queue.length, greaterThanOrEqualTo(1));
    });

    test('approve KYC marks pro as verified', () async {
      final repo = MockAdminRepository();
      final proId = (await repo.fetchKycQueue(status: ReviewStatus.inReview))
          .first
          .proId;
      await repo.approveKyc(proId);
      final detail = await repo.fetchKycDetail(proId);
      expect(detail?.status, ReviewStatus.verified);
    });

    test('document queue includes shop and certificate items', () async {
      final repo = MockAdminRepository();
      final docs =
          await repo.fetchDocumentQueue(status: DocumentStatus.pending);
      expect(docs.any((d) => d.kind == DocumentKind.shopPhoto), isTrue);
      expect(docs.any((d) => d.kind == DocumentKind.cert), isTrue);
    });
  });
}
