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
| Splash & language pick    | `SplashScreen`, `LanguageSelectScreen` (Tamil / English)             |
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
- **i18n:** lightweight in-app map under `lib/core/i18n.dart` (Tamil
  + English). For production, switch to ARB + `flutter gen-l10n`.
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

## Next steps

1. Replace `MockRepository` with a generated API client (Dio + retrofit
   from the OpenAPI spec).
2. Add Firebase (FCM push, Crashlytics) and real OTP via MSG91.
3. Integrate Google Maps for the location and active-job screens.
4. Wire up Razorpay Payouts for the daily wallet → UPI flow.
5. Move i18n strings to ARB and add French for the Pondicherry expat
   segment.

See `docs/03-backend-architecture.md` for the full picture.
