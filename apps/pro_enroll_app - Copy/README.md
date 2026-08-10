# Pro-Enroll (Flutter app)

Mobile application used by service **professionals** to self-enroll,
complete KYC, set their service area, and receive jobs from nearby
customers (AC, plumbing, RO, fridge, washing machine, car/bike
mechanic, electrician). It targets Pondicherry, Karaikal and nearby
Tamil Nadu.

This folder contains only the **Pro-Enroll** app (the professional
side). The customer-side **Pro-User** app is a separate Flutter app
that will share a sibling folder under `apps/`.

> For the full product, business and backend documents see
> [`../../docs/`](../../docs/).

---

## Requirements

- Flutter SDK **3.41+** (channel: `stable`)
- Dart **3.11+**
- Android SDK / Xcode (to actually run on a device or emulator)

The project does not depend on any private package; `flutter pub get`
fetches everything from pub.dev.

## Run locally

```bash
cd apps/pro_enroll_app
flutter pub get
flutter run            # picks the first available device
# or for a specific device:
flutter run -d emulator-5554
flutter run -d chrome  # web works too — useful for quick UI review
```

## Test & analyze

```bash
flutter analyze
flutter test
```

Both should report zero issues / all tests passing.

## What this scaffold ships

The app implements the **full professional-onboarding journey** end to
end in UI, backed by a mocked in-memory repository (no real network
calls). This makes it easy to demo the flow, get visual feedback, and
later swap the mock for a real backend client.

| Flow                      | Screens included                                                     |
| ------------------------- | -------------------------------------------------------------------- |
| Splash & language pick    | `SplashScreen`, `LanguageSelectScreen` (English first; Tamil available) |
| Welcome                   | `WelcomeScreen` with value props (KYC, payouts, training)            |
| Phone auth                | `PhoneInputScreen`, `OtpVerifyScreen` (6-digit OTP, demo: any code)  |
| Onboarding                | Category multi-select, experience + name, city + work radius, visit fee |
| KYC                       | Intro, Aadhaar OTP, selfie liveness, supporting docs, pending review |
| Home shell (bottom nav)   | Jobs, Earnings, Profile, Help                                        |
| Job flow                  | Offer detail with 60s timer, accept/reject, active job state machine |

Money is stored in **paise** (₹ × 100) throughout, matching the backend
schema in `docs/05-database-schema.md`.

## Tech choices

- **State management:** `flutter_riverpod` 2.x via plain
  `StateNotifierProvider` and `FutureProvider` — no codegen needed.
- **Routing:** `go_router` 14.x. All routes live in `lib/routing/router.dart`.
- **i18n:** lightweight in-app map under `lib/core/i18n.dart`.
  **English is the v1 default**; Tamil is shipped as a one-tap toggle
  and will be promoted to default once translations are reviewed by
  native speakers. For production, migrate to ARB + `flutter gen-l10n`.
- **Networking:** stubbed `MockRepository` in `lib/data/`. Replace with
  a Dio + retrofit client generated from the OpenAPI spec described in
  `docs/06-api-specification.md`.

## Folder layout

```
lib/
├── app.dart                 # MaterialApp.router + theme + locale
├── main.dart                # ProviderScope + runApp
├── core/                    # theme, constants, i18n helpers
├── data/                    # models + mock repository (in-memory)
├── routing/                 # go_router config
├── state/                   # Riverpod notifiers (auth, profile, jobs, locale)
└── features/
    ├── splash/
    ├── onboarding/          # language, welcome, category, experience, location, fee
    ├── auth/                # phone, OTP
    ├── kyc/                 # intro, Aadhaar, selfie, docs, pending review
    ├── home/                # bottom-nav shell + 4 tabs
    ├── job/                 # offer detail + active job
    └── shared/              # reusable widgets (AppPage, InfoCard, TrustBanner)
```

## Demo shortcuts

To keep the scaffold easy to demo without a real backend, the following
shortcuts are baked in:

- **OTP:** any 6-digit code works, except `000000` which fails so you
  can see the error UX. Same idea for the Aadhaar OTP (any 4–6 digits,
  except `0000`).
- **Pending review screen** has a *“Continue (demo: simulate
  approval)”* button that flips the profile to `verified` immediately
  and lands you on the home shell with seeded sample stats.
- **Mock job offers** are generated for whatever categories you picked,
  with realistic Pondicherry / Karaikal addresses.

## PHP API + JWT auth (Firebase SMS OTP)

| Environment | API base URL | When |
| ----------- | ------------ | ---- |
| **Local** (default in debug) | `http://localhost:8080` | `flutter run` until VPS is fixed |
| **Live** (default in release APK) | `http://98.93.105.128/pro_enroll_api` | After server CORS + rewrite deploy |

**Local API folder:** `D:\krishna\pro_enroll_api`

**MySQL / phpMyAdmin (live):** [http://98.93.105.128/phpmyadmin/](http://98.93.105.128/phpmyadmin/) — import `database/schema.sql` into `pro_enroll`.

**VPS deploy / fix 404 & CORS:** see [`pro_enroll_api/DEPLOY_VPS.md`](../../../pro_enroll_api/DEPLOY_VPS.md) (Apache + `composer install` + `.env`).

1. **Send OTP** — Firebase Phone Auth in the Flutter app sends a 6-digit SMS (project `proenroll-4ff13`).
2. **Verify OTP** — App verifies with Firebase, then `POST /v1/auth/firebase/session` with `{ "id_token", "mode" }`. Returns `access_token` (JWT) and `next_route`.
3. **Legacy mail OTP** — `POST /v1/auth/otp/send` + `/verify` still work when `USE_FIREBASE_SMS_OTP=false` in the app.
4. **Authenticated API** — all `/v1/screens/*` calls use `Authorization: Bearer <jwt>`.

### Local API (XAMPP)

```powershell
cd D:\krishna\pro_enroll_api
copy .env.example .env
composer install
php -S localhost:8080 -t public
```

Apply schema:

```powershell
mysql -u root -p < database\schema.sql
```

Run against **local** API (default in debug — start PHP first):

```bash
flutter run -d chrome
flutter run -d android
```

Physical Android on same Wi‑Fi (replace with your PC IP):

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
```

### Live API (after server fix is committed & deployed)

Test live from Chrome before APK:

```bash
flutter run -d chrome --dart-define=USE_LIVE_API=true
```

Release APK (uses live API automatically):

```bash
flutter build apk --release
```

Without `USE_API=true`, the app uses the in-memory mock (any 6-digit OTP except `000000`).

## Runtime configuration (`--dart-define`)

| Flag | Default | Purpose |
| ---- | ------- | ------- |
| `GOOGLE_MAPS_API_KEY` | *(empty)* | Optional Static Maps key; without it, OpenStreetMap tiles are used. |
| `USE_LOCAL_API` | `false` | Force local API even in release builds. |
| `USE_LIVE_API` | `false` | Force live API in debug (test VPS from Chrome). |
| `API_BASE_URL` | *(see above)* | Override either environment explicitly. Debug → local; release → live. |
| `USE_API` | `true` | Set `false` to use in-memory mock instead of real API. |
| `USE_FIREBASE_SMS_OTP` | `false` | Set `true` for real SMS via Firebase Phone Auth (Android device/emulator). |

### Firebase SMS OTP (real text message)

1. Firebase Console → **Authentication** → **Sign-in method** → enable **Phone**.
2. Firebase Console → **Project settings** → **Your apps** → Android app `pro.enroll` → add **SHA-1** (debug: run `cd android && ./gradlew signingReport`).
3. Upload `config/firebase-service-account.json` on the PHP API and run `composer install`.
4. Run on **Android** (SMS does not work on PHP dev OTP path the same way on web):

```bash
flutter run -d android --dart-define=USE_API=true --dart-define=USE_FIREBASE_SMS_OTP=true
```

Without `USE_FIREBASE_SMS_OTP=true`, the API returns a **Dev OTP** on screen (local testing).

Examples:

```bash
# Local API (debug default)
flutter run -d chrome

# Live API (test after server deploy)
flutter run -d chrome --dart-define=USE_LIVE_API=true

# Sharper map tiles (enable Static Maps API in Google Cloud)
flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_key_here
```

## Next steps

1. Replace `MockRepository` with a generated API client (Dio + retrofit
   from the OpenAPI spec).
2. Add FCM push + Crashlytics.
3. Integrate Google Maps for the location and active-job screens.
4. Wire up Razorpay Payouts for the daily wallet → UPI flow.
5. Move i18n strings to ARB and add French for the Pondicherry expat
   segment.

See `docs/03-backend-architecture.md` for the full picture.
