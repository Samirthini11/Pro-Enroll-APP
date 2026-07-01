import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/documents/document_detail_screen.dart';
import '../features/documents/document_queue_screen.dart';
import '../features/kyc/kyc_detail_screen.dart';
import '../features/kyc/kyc_queue_screen.dart';
import '../features/shell/admin_shell.dart';
import '../features/splash/splash_screen.dart';
import '../state/admin_state.dart';

class Routes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const kycDetail = '/kyc/:proId';
  static const docDetail = '/docs/:documentId';

  static String kycDetailPath(int proId) => '/kyc/$proId';
  static String docDetailPath(int documentId) => '/docs/$documentId';
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    redirect: (context, state) {
      final loggedIn = auth.valueOrNull != null;
      final onLogin = state.matchedLocation == Routes.login;
      final onSplash = state.matchedLocation == Routes.splash;

      if (onSplash) return null;
      if (!loggedIn && !onLogin) return Routes.login;
      if (loggedIn && onLogin) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (_, __) => const AdminShell(),
      ),
      GoRoute(
        path: Routes.kycDetail,
        builder: (ctx, st) {
          final proId = int.parse(st.pathParameters['proId']!);
          return KycDetailScreen(proId: proId);
        },
      ),
      GoRoute(
        path: Routes.docDetail,
        builder: (ctx, st) {
          final docId = int.parse(st.pathParameters['documentId']!);
          return DocumentDetailScreen(documentId: docId);
        },
      ),
    ],
  );
});
