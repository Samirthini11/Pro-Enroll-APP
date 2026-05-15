import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_flow.dart';
import '../features/auth/auth_landing_screen.dart';
import '../features/auth/otp_verify_screen.dart';
import '../features/auth/phone_input_screen.dart';
import '../features/home/home_shell.dart';
import '../features/job/active_job_screen.dart';
import '../features/job/offer_detail_screen.dart';
import '../features/kyc/aadhaar_screen.dart';
import '../features/kyc/documents_screen.dart';
import '../features/kyc/kyc_intro_screen.dart';
import '../features/kyc/pending_review_screen.dart';
import '../features/kyc/selfie_screen.dart';
import '../features/onboarding/category_select_screen.dart';
import '../features/onboarding/experience_screen.dart';
import '../features/onboarding/home_location_screen.dart';
import '../features/onboarding/visit_fee_screen.dart';
import '../features/splash/splash_screen.dart';

/// Centralised list of route paths so screens never hard-code strings.
class Routes {
  static const splash = '/';
  static const authLanding = '/auth/landing';
  static const phone = '/auth/phone';
  static const otp = '/auth/otp';

  static const onboardCategory = '/onboard/category';
  static const onboardExperience = '/onboard/experience';
  static const onboardLocation = '/onboard/location';
  static const onboardFee = '/onboard/fee';

  static const kycIntro = '/kyc';
  static const kycAadhaar = '/kyc/aadhaar';
  static const kycSelfie = '/kyc/selfie';
  static const kycDocs = '/kyc/docs';
  static const kycPending = '/kyc/pending';

  static const home = '/home';
  static const offer = '/job/offer';
  static const activeJob = '/job/active';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.authLanding,
        builder: (_, __) => const AuthLandingScreen(),
      ),
      GoRoute(
        path: Routes.phone,
        builder: (ctx, st) => PhoneInputScreen(
          flow: st.extra is AuthFlow
              ? st.extra! as AuthFlow
              : const AuthFlow(mode: AuthMode.signUp),
        ),
      ),
      GoRoute(
        path: Routes.otp,
        builder: (ctx, st) => OtpVerifyScreen(
          flow: st.extra is AuthFlow
              ? st.extra! as AuthFlow
              : const AuthFlow(mode: AuthMode.signUp),
        ),
      ),
      GoRoute(
        path: Routes.onboardCategory,
        builder: (_, __) => const CategorySelectScreen(),
      ),
      GoRoute(
        path: Routes.onboardExperience,
        builder: (_, __) => const ExperienceScreen(),
      ),
      GoRoute(
        path: Routes.onboardLocation,
        builder: (_, __) => const HomeLocationScreen(),
      ),
      GoRoute(
        path: Routes.onboardFee,
        builder: (_, __) => const VisitFeeScreen(),
      ),
      GoRoute(
        path: Routes.kycIntro,
        builder: (_, __) => const KycIntroScreen(),
      ),
      GoRoute(
        path: Routes.kycAadhaar,
        builder: (_, __) => const AadhaarScreen(),
      ),
      GoRoute(
        path: Routes.kycSelfie,
        builder: (_, __) => const SelfieScreen(),
      ),
      GoRoute(
        path: Routes.kycDocs,
        builder: (_, __) => const DocumentsScreen(),
      ),
      GoRoute(
        path: Routes.kycPending,
        builder: (_, __) => const PendingReviewScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (_, __) => const HomeShell(),
      ),
      GoRoute(
        path: Routes.offer,
        builder: (ctx, st) => OfferDetailScreen(offerId: st.extra as String?),
      ),
      GoRoute(
        path: Routes.activeJob,
        builder: (_, __) => const ActiveJobScreen(),
      ),
    ],
  );
});
