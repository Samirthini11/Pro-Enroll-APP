/// Distinguishes the two entry points into the phone/OTP screens.
///
///   • [AuthMode.signIn] — existing pro returning to the app. After OTP
///     verification we route them straight to the home shell with
///     seeded demo stats (since there is no real backend yet).
///   • [AuthMode.signUp] — new pro enrolling. After OTP we kick off
///     the onboarding wizard: category → experience → location →
///     visit fee → KYC.
enum AuthMode { signIn, signUp }

class AuthFlow {
  const AuthFlow({required this.mode});
  final AuthMode mode;

  bool get isSignUp => mode == AuthMode.signUp;
  bool get isSignIn => mode == AuthMode.signIn;
}
