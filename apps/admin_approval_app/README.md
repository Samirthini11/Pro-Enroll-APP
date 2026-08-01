# Pro-Enroll Admin Approval App

Flutter mobile app for **internal admin staff** to review and approve Pro-Enroll professional applications.

## Features

- **Admin sign-in** — email + password via `pro_enroll_api` (`role=admin` JWT)
- **Dashboard** — pending KYC count, document queue, approved/rejected today
- **Pro User Approval (KYC Queue)** — review full pro profile, Aadhaar, selfie face-match score, skills, and approve or reject with reason
- **Shop & Certificate Verify** — dedicated queue for `shop_photo` and `cert` documents
- **Document detail** — approve/reject individual shop photos and training certificates

## Run locally

```bash
cd apps/admin_approval_app
flutter pub get
flutter run
```

Uses the live VPS API by default (`http://98.93.105.128/pro_enroll_api`).

### Local `pro_enroll_api`

```bash
# Terminal 1 — PHP API
cd pro_enroll_api
php -S localhost:8080 -t public

# Terminal 2 — Admin app (Android emulator)
cd apps/admin_approval_app
flutter run --dart-define=USE_LOCAL_API=true
```

### Mock mode (no backend)

```bash
flutter run --dart-define=USE_API=false
```

Demo login in mock mode: any email + password with 4+ characters.

### API credentials

Default admin login (configure in `pro_enroll_api/.env`):

| Email | Password |
|-------|----------|
| `admin@proenroll.in` | `admin123` |

## API mapping

| Screen | Backend endpoint |
|--------|------------------|
| Login | `POST /v1/auth/admin/login` |
| Dashboard | `GET /v1/admin/dashboard` |
| KYC Queue | `GET /v1/admin/kyc?status=in_review` |
| KYC Detail | `GET /v1/admin/kyc/:pro_id` |
| Approve Pro | `POST /v1/admin/kyc/:pro_id/approve` |
| Reject Pro | `POST /v1/admin/kyc/:pro_id/reject` |
| Shop/Cert queue | `GET /v1/admin/documents?status=pending` |
| Approve document | `POST /v1/admin/documents/:id/approve` |
| Reject document | `POST /v1/admin/documents/:id/reject` |

Run migration `pro_enroll_api/database/migrations/011_admin_kyc.sql` before using document review on a fresh database.

## Monorepo

This app lives alongside `apps/pro_enroll_app` (professional app) and shares the same `pro_enroll_api` backend.
