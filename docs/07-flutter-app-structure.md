# 07 · Flutter App Structure

Both apps share a common **core** package and differ only in the
feature modules they ship and their app theme/branding. They are kept as
two separate Flutter apps in a single monorepo so the team can release
them independently but reuse 70 %+ of the code.

```
proenroll-flutter/
├── apps/
│   ├── pro_enroll_app/         # for the professional (the Pro)
│   │   ├── lib/main.dart
│   │   ├── lib/app.dart
│   │   ├── pubspec.yaml
│   │   └── android/  ios/
│   └── pro_user_app/           # for the customer
│       ├── lib/main.dart
│       ├── lib/app.dart
│       ├── pubspec.yaml
│       └── android/  ios/
├── packages/
│   ├── core/                   # shared: theme, l10n, widgets, errors
│   ├── api_client/             # generated Dart client from OpenAPI
│   ├── auth/                   # OTP, JWT, session storage
│   ├── location/               # geolocator + background service
│   ├── payments/               # Razorpay wrapper
│   ├── chat/                   # Socket.IO chat widgets
│   └── analytics/              # event tracking
├── melos.yaml                  # monorepo orchestration
└── pubspec.yaml                # workspace
```

Use **Melos** to run, build and test the whole workspace.

---

## 1. Common packages (`packages/`)

| Package      | Purpose                                                             | Key deps                                          |
| ------------ | ------------------------------------------------------------------- | ------------------------------------------------- |
| `core`       | Theme, typography, ColorScheme, common widgets (`PrimaryButton`, `AppScaffold`), error/exception types, env config. | `flutter_localizations`, `intl`, `flex_color_scheme` |
| `api_client` | Auto‑generated Dart client (Dio‑based) from `openapi.yaml`.         | `dio`, `retrofit`, `json_serializable`            |
| `auth`       | `signInWithPhone()`, OTP verify, token storage in secure storage, auto refresh, auth interceptor for Dio. | `flutter_secure_storage`, `dio` |
| `location`   | Foreground + background location service with battery‑safe profiles (idle, on_trip). | `geolocator`, `flutter_background_service` |
| `payments`   | Razorpay Flutter wrapper, returns a normalised `PaymentResult`.     | `razorpay_flutter`                                |
| `chat`       | Socket.IO connection with auto‑reconnect, chat UI widgets.          | `socket_io_client`                                |
| `analytics`  | Logs events to Firebase + custom backend.                           | `firebase_analytics`                              |

---

## 2. State management & navigation

- **State**: [`riverpod`](https://pub.dev/packages/flutter_riverpod) 2.x
  with code‑generation. Clean dependency injection, testable, no
  boilerplate of BLoC.
- **Routing**: [`go_router`](https://pub.dev/packages/go_router) with
  type‑safe routes; deep links from FCM and WhatsApp use the same
  routing.
- **Forms**: `flutter_hooks` + `reactive_forms`.
- **Networking**: `dio` with logging + retry + auth interceptors.
- **Caching**: `hive` for offline cache (categories, last bookings).
- **i18n**: `flutter_localizations` + `intl` ARB files (`ta`, `en`,
  `fr`). All user‑facing strings are keyed.

---

## 3. `pro_user_app` (Customer)

### 3.1 Screens

```
splash
onboarding (3 slides)
auth/
  phone_input
  otp_verify
home/
  shell                     // bottom nav: Home, Bookings, Wallet, Profile
  home_tab                  // categories grid, banners, "Re-book" carousel
  bookings_tab              // active + past bookings
  wallet_tab                // cashback wallet
  profile_tab               // profile, addresses, language, help
search/
  pro_list                  // map + list toggle, filters
  pro_detail
booking/
  create_step1_problem      // category, sub-category, photos, description
  create_step2_slot         // pick date+time
  create_step3_address      // saved or new address
  create_step4_review       // summary + visit fee
  confirmation
  detail                    // live status, chat, track on map
  rating
  dispute
addresses/
  list
  edit
help/
  faq
  contact_support
```

### 3.2 Key UX rules (recap)

- Tamil first, English secondary.
- Big bottom CTA buttons (`56 dp`).
- “Verified” badge prominently next to every pro.
- Persistent live status banner once a booking is active.
- “Pay only after work is done” shown on the booking review screen.

### 3.3 `pubspec.yaml` (excerpt)

```yaml
name: pro_user_app
environment:
  sdk: ">=3.4.0 <4.0.0"
  flutter: ">=3.22.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  core: { path: ../../packages/core }
  api_client: { path: ../../packages/api_client }
  auth: { path: ../../packages/auth }
  location: { path: ../../packages/location }
  payments: { path: ../../packages/payments }
  chat: { path: ../../packages/chat }
  analytics: { path: ../../packages/analytics }

  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  go_router: ^14.0.0
  dio: ^5.4.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  intl: ^0.19.0
  google_maps_flutter: ^2.6.0
  geolocator: ^11.0.0
  image_picker: ^1.0.0
  flutter_image_compress: ^2.0.0
  cached_network_image: ^3.3.0
  firebase_core: ^2.27.0
  firebase_messaging: ^14.7.0
  firebase_crashlytics: ^3.4.0
  firebase_analytics: ^10.8.0
  permission_handler: ^11.3.0
  url_launcher: ^6.2.0
  speech_to_text: ^6.6.0
  flutter_secure_storage: ^9.0.0

dev_dependencies:
  build_runner: ^2.4.0
  riverpod_generator: ^2.4.0
  json_serializable: ^6.7.0
  flutter_test:
    sdk: flutter
```

---

## 4. `pro_enroll_app` (Professional)

### 4.1 Screens

```
splash
auth/
  phone_input
  otp_verify
onboarding/
  language_select
  category_select         // multi
  sub_skills_select
  experience              // years per category
  home_location           // map pin + address
  work_radius
  visit_fee
kyc/
  intro
  aadhaar_input
  aadhaar_otp
  selfie_capture          // with liveness check
  documents_upload
  pending_review          // waiting state
  rejected
home/
  shell                   // bottom nav: Jobs, Earnings, Profile, Help
  jobs_tab                // offers + active job
  earnings_tab            // today/week/month, payouts
  profile_tab
  help_tab
job/
  offer_detail            // 60-sec accept timer
  active_job              // status machine: on_the_way, arrived, in_progress
  job_complete            // enter final amount, before/after photos
  rating_received
bank/
  add_bank
  payout_history
subscription/
  plans                   // free / basic / plus
  payment
```

### 4.2 Background services

- **Foreground location** while a job is `accepted`, `on_the_way`,
  `in_progress`. Notification: "Pro‑Enroll is sharing your location for
  job #PE‑2026‑000901".
- **Periodic location** (every 2 min) while `is_available = true` and no
  active job. Stops when `is_available = false`.
- **FCM background handler** to show offer banner even when app is
  killed.

### 4.3 `pubspec.yaml` (delta vs user app)

Add:
```yaml
flutter_background_service: ^5.0.0
mlkit_face_detection: ^0.10.0       # optional on-device liveness pre-check
mobile_scanner: ^5.0.0              # scan customer payment QR
```

---

## 5. Permissions

| App         | Android permissions                                                    | iOS keys                                          |
| ----------- | ---------------------------------------------------------------------- | ------------------------------------------------- |
| User app    | INTERNET, ACCESS_FINE_LOCATION (for "near me"), READ_MEDIA_IMAGES, CAMERA, POST_NOTIFICATIONS, RECORD_AUDIO (voice search) | NSLocationWhenInUseUsageDescription, NSCameraUsageDescription, NSMicrophoneUsageDescription |
| Pro app     | All above + ACCESS_BACKGROUND_LOCATION, FOREGROUND_SERVICE, FOREGROUND_SERVICE_LOCATION | NSLocationAlwaysAndWhenInUseUsageDescription      |

Explain permissions inside the app **before** triggering the system
dialog — improves grant rate dramatically.

---

## 6. Theming & branding

- Primary colour for Pro‑User: **#2563EB** (trust blue).
- Primary colour for Pro‑Enroll: **#16A34A** (growth green).
- Font family: `Inter` (English/French), `Noto Sans Tamil` (Tamil).
- Both built with `flex_color_scheme` so dark mode is one toggle away.

---

## 7. Build & release

- Flavours: `dev`, `staging`, `prod` — different bundle ids and APIs.
- Use **Codemagic** or **GitHub Actions + Fastlane** for CI/CD.
- Each app is signed independently (separate keystore + App Store
  Connect entry).
- Min Android SDK 23 (covers >97 % of Indian devices), target SDK 34.
- iOS 13+.

---

## 8. Offline behaviour

- App boot reads cached categories from Hive so the home screen renders
  even with no network.
- The user’s last 5 bookings are cached for offline read.
- Mutations (create booking, send chat) are queued and replayed when
  the connection comes back, with idempotency keys generated on the
  device.

---

## 9. Accessibility

- All tap targets ≥ 48 dp.
- Colour contrast ≥ 4.5:1.
- Voice‑over labels on every icon button.
- Tamil voice search alternative for visually impaired users.

---

## 10. Testing strategy

- **Unit tests** for use cases (Riverpod providers).
- **Widget tests** for critical flows (auth, booking, KYC).
- **Integration tests** with `integration_test` package on emulator and a
  real low‑end device (Redmi 9A) for performance baselines.
- **Golden tests** for theming and Tamil typography rendering.
