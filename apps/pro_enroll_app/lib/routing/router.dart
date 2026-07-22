import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_config.dart';
import '../data/models.dart';
import '../features/auth/auth_flow.dart';
import '../features/auth/auth_landing_screen.dart';
import '../features/auth/otp_verify_screen.dart';
import '../features/auth/phone_input_screen.dart';
import '../features/customer/customer_profile_setup_screen.dart';
import '../features/customer/customer_home_screen.dart';
import '../features/customer/pro_search_screen.dart';
import '../features/customer/pro_detail_screen.dart';
import '../features/customer/booking_create_screen.dart';
import '../features/customer/bookings_list_screen.dart';
import '../features/customer/booking_detail_screen.dart';
import '../features/customer/customer_route_params.dart';
import '../features/home/edit_skills_screen.dart';
import '../features/home/edit_work_area_screen.dart';
import '../features/home/edit_visit_fee_screen.dart';
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
import '../features/legal/terms_acceptance_screen.dart';
import '../features/splash/splash_screen.dart';
import '../state/app_state.dart';

/// Centralised list of route paths so screens never hard-code strings.
class Routes {
  static const splash = '/';
  static const termsAcceptance = '/legal/terms';
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
  static const editSkills = '/home/edit-skills';
  static const editWorkArea = '/home/edit-work-area';
  static const editVisitFee = '/home/edit-visit-fee';
  static const offer = '/job/offer';
  static const activeJob = '/job/active';

  // Customer routes
  static const customerHome = '/customer/home';
  static const customerProfileSetup = '/customer/profile-setup';
  static const customerSearch = '/customer/search';
  static const customerProDetail = '/customer/pro';
  static const customerBook = '/customer/book';
  static const customerBookings = '/customer/bookings';
  static const customerBookingDetail = '/customer/booking';

  static const _public = {
    splash,
    termsAcceptance,
    authLanding,
    phone,
    otp,
    customerSearch,
    customerProDetail,
  };

  static bool isPublic(String path) => _public.contains(path);
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  ref.keepAlive();

  // Only re-run redirect when login status changes — not on otpRequestId /
  // debugOtp updates (avoids splash flash when leaving the phone screen).
  final refresh = ValueNotifier(0);
  ref.onDispose(refresh.dispose);
  ref.listen<AuthState>(authProvider, (prev, next) {
    if (prev?.isAuthenticated != next.isAuthenticated) {
      refresh.value++;
    }
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      if (!AppConfig.hasApi) return null;

      final path = state.matchedLocation;
      if (Routes.isPublic(path)) return null;

      final authed = ref.read(authProvider).isAuthenticated;
      if (!authed) {
        return Routes.authLanding;
      }

      final role = ref.read(roleProvider);
      if (role == AppRole.customer) {
        final profile = ref.read(customerProvider).profile;
        if (profile != null &&
            !profile.isProfileComplete &&
            path != Routes.customerProfileSetup) {
          return Routes.customerProfileSetup;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.termsAcceptance,
        builder: (ctx, st) => TermsAcceptanceScreen(
          viewOnly: st.extra == true,
        ),
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
        path: Routes.editSkills,
        builder: (_, __) => const EditSkillsScreen(),
      ),
      GoRoute(
        path: Routes.editWorkArea,
        builder: (_, __) => const EditWorkAreaScreen(),
      ),
      GoRoute(
        path: Routes.editVisitFee,
        builder: (_, __) => const EditVisitFeeScreen(),
      ),
      GoRoute(
        path: Routes.offer,
        builder: (ctx, st) => OfferDetailScreen(offerId: st.extra as String?),
      ),
      GoRoute(
        path: Routes.activeJob,
        builder: (_, __) => const ActiveJobScreen(),
      ),
      // ─── Customer routes ──────────────────────────────────────────
      GoRoute(
        path: Routes.customerProfileSetup,
        builder: (_, __) => const CustomerProfileSetupScreen(),
      ),
      GoRoute(
        path: Routes.customerHome,
        builder: (_, __) => const CustomerHomeScreen(),
      ),
      GoRoute(
        path: Routes.customerSearch,
        builder: (_, st) => ProSearchScreen(
          params: st.extra is Map<String, dynamic>
              ? st.extra! as Map<String, dynamic>
              : const {},
        ),
      ),
      GoRoute(
        path: Routes.customerProDetail,
        builder: (_, st) => ProDetailScreen(
          params: st.extra is Map<String, dynamic>
              ? st.extra! as Map<String, dynamic>
              : const {},
        ),
      ),
      GoRoute(
        path: Routes.customerBook,
        builder: (_, st) => BookingCreateScreen(
          params: st.extra is Map<String, dynamic>
              ? st.extra! as Map<String, dynamic>
              : const {},
        ),
      ),
      GoRoute(
        path: Routes.customerBookings,
        builder: (_, __) => const BookingsListScreen(),
      ),
      GoRoute(
        path: Routes.customerBookingDetail,
        builder: (_, st) => BookingDetailScreen(
          bookingId: parseRouteInt(st.extra),
        ),
      ),
    ],
  );
});
