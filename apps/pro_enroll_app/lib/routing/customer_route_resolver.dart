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
    if (AppConfig.hasApi &&
        serverNextRoute != null &&
        serverNextRoute.isNotEmpty) {
      final mapped = _fromServerRoute(serverNextRoute);
      if (mapped != null) return mapped;
    }

    if (profile?.isProfileComplete ?? false) {
      return Routes.customerHome;
    }
    return Routes.customerProfileSetup;
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
