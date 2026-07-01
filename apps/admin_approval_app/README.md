# Pro-Enroll Admin Approval App

Flutter mobile app for **internal admin staff** to review and approve Pro-Enroll professional applications.

## Features

- **Admin sign-in** — email + password (maps to `role=admin` JWT in production)
- **Dashboard** — pending KYC count, document queue, approved/rejected today
- **Pro User Approval (KYC Queue)** — review full pro profile, Aadhaar, selfie face-match score, skills, and approve or reject with reason
- **Shop & Certificate Verify** — dedicated queue for `shop_photo` and `cert` documents from `pro_document` table
- **Document detail** — approve/reject individual shop photos and training certificates

## Run locally

```bash
cd apps/admin_approval_app
flutter pub get
flutter run
```

Demo login: any email + password with 4+ characters (e.g. `admin@proenroll.in` / `admin123`).

## API mapping

| Screen | Backend endpoint |
|--------|------------------|
| KYC Queue | `GET /v1/admin/kyc?status=in_review` |
| Approve Pro | `POST /v1/admin/kyc/:pro_id/approve` |
| Reject Pro | `POST /v1/admin/kyc/:pro_id/reject` |
| Shop/Cert queue | Filtered from pro documents pending review |

See `docs/06-api-specification.md` for the full admin API.

## Monorepo

This app lives alongside `apps/pro_enroll_app` (professional app) in the Pro-Enroll monorepo.
