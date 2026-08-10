import '../core/app_config.dart';
import '../data/models.dart';
import 'router.dart';

/// Chooses the correct customer screen after login / session restore.
class CustomerRouteResolver {
  const CustomerRouteResolver._();

  static String resolve({
    CustomerProfile? profile,
    String? serverNextRoute,
  }) {
    // Name + city are required before home — never skip setup when incomplete,
    // even if a stale next_route says /customer/home.
    if (!(profile?.isProfileComplete ?? false)) {
      return Routes.customerProfileSetup;
    }

    if (AppConfig.hasApi &&
        serverNextRoute != null &&
        serverNextRoute.isNotEmpty) {
      final mapped = _fromServerRoute(serverNextRoute);
      if (mapped != null) return mapped;
    }

    return Routes.customerHome;
  }

  static String? _fromServerRoute(String route) {
    switch (route) {
      case '/customer/home':
        return Routes.customerHome;
      case '/customer/profile-setup':
        return Routes.customerProfileSetup;
      default:
        return null;
    }
  }
}
