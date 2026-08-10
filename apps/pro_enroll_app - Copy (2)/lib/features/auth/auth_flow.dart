import '../../data/models.dart';

enum AuthMode { signIn, signUp }

class AuthFlow {
  const AuthFlow({required this.mode, this.role});
  final AuthMode mode;
  final AppRole? role;

  bool get isSignUp => mode == AuthMode.signUp;
  bool get isSignIn => mode == AuthMode.signIn;
}
