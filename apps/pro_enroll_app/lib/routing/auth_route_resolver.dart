import '../core/app_config.dart';
import '../data/models.dart';
import 'router.dart';

/// Chooses the correct screen after login / session restore (API-aware).
class AuthRouteResolver {
  const AuthRouteResolver._();

  static String resolve({
    required ProProfile profile,
    String? serverNextRoute,
    required bool isSignIn,
    /// When true, in-review pros may open home to explore the app
    /// before admin KYC approval.
    bool allowKycPreview = false,
  }) {
    if (AppConfig.hasApi) {
      if (_onboardingComplete(profile) &&
          (profile.kycStatus == KycStatus.verified ||
              (allowKycPreview && profile.kycStatus == KycStatus.inReview))) {
        return Routes.home;
      }
      if (serverNextRoute != null && serverNextRoute.isNotEmpty) {
        final mapped = _fromServerRoute(
          serverNextRoute,
          allowKycPreview: allowKycPreview,
        );
        if (mapped != null) return mapped;
      }
      return _fromProfile(profile, allowKycPreview: allowKycPreview);
    }

    if (serverNextRoute == '/home' || (isSignIn && serverNextRoute == null)) {
      return Routes.home;
    }
    if (serverNextRoute == '/onboard/category' || !isSignIn) {
      return Routes.onboardCategory;
    }
    return Routes.home;
  }

  static String? _fromServerRoute(
    String route, {
    bool allowKycPreview = false,
  }) {
    switch (route) {
      case '/home':
        return Routes.home;
      case '/onboard/category':
        return Routes.onboardCategory;
      case '/onboard/experience':
        return Routes.onboardExperience;
      case '/onboard/location':
        return Routes.onboardLocation;
      case '/onboard/fee':
        return Routes.onboardFee;
      case '/kyc':
        return Routes.kycIntro;
      case '/kyc/aadhaar':
        return Routes.kycAadhaar;
      case '/kyc/selfie':
        return Routes.kycSelfie;
      case '/kyc/docs':
        return Routes.kycDocs;
      case '/kyc/pending':
        return allowKycPreview ? Routes.home : Routes.kycPending;
      case '/job/active':
        return Routes.activeJob;
      case '/customer/home':
        return Routes.customerHome;
      default:
        return null;
    }
  }

  static bool _onboardingComplete(ProProfile profile) {
    return profile.skills.isNotEmpty &&
        profile.fullName != null &&
        profile.fullName!.trim().isNotEmpty &&
        profile.cityId != null;
  }

  static String _fromProfile(
    ProProfile profile, {
    bool allowKycPreview = false,
  }) {
    if (profile.skills.isEmpty) {
      return Routes.onboardCategory;
    }
    if (profile.fullName == null || profile.fullName!.trim().isEmpty) {
      return Routes.onboardExperience;
    }
    if (profile.cityId == null) {
      return Routes.onboardLocation;
    }

    switch (profile.kycStatus) {
      case KycStatus.verified:
        return Routes.home;
      case KycStatus.inReview:
        return allowKycPreview ? Routes.home : Routes.kycPending;
      case KycStatus.aadhaarPending:
        return Routes.kycAadhaar;
      case KycStatus.selfiePending:
        return Routes.kycSelfie;
      case KycStatus.rejected:
      case KycStatus.notStarted:
        return Routes.kycIntro;
    }
  }
}
