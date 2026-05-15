import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around `FirebaseAuth.verifyPhoneNumber` that adapts the
/// callback-style API to the simple `Future<bool>` interface our state
/// notifiers want.
///
/// Lifecycle:
///   1. `sendOtp(phone)` triggers `verifyPhoneNumber`. The call either
///      auto-resolves on the device (Android instant verification) and
///      we sign in immediately, or we receive a `verificationId` and
///      surface it back to the caller as a `String`.
///   2. `verifyOtp(otp)` builds a `PhoneAuthCredential` with the stored
///      `verificationId` + user-entered SMS code and calls
///      `signInWithCredential`.
class FirebaseOtpService {
  FirebaseOtpService([FirebaseAuth? auth]) : _injected = auth;

  /// Resolved lazily so the service can be constructed even on
  /// platforms where Firebase has not been initialised (tests, web).
  FirebaseAuth get _auth => _injected ?? FirebaseAuth.instance;
  final FirebaseAuth? _injected;

  String? _verificationId;
  int? _resendToken;

  /// True if a Firebase app has been initialised. We use this from the
  /// notifier layer to decide whether to talk to Firebase or fall back
  /// to the in-memory mock (web / iOS demo builds).
  static bool get isAvailable {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Sends an OTP to [phoneE164] (must include country code, e.g.
  /// `+919812345678`). Returns:
  ///   • `OtpSendResult.codeSent` — the SMS was dispatched and we are
  ///     ready for the user to enter the code.
  ///   • `OtpSendResult.autoVerified` — Android auto-detected the SMS
  ///     and we are already signed in. The caller should skip the
  ///     OTP entry screen.
  ///   • `OtpSendResult.failed` — surface `errorMessage` to the user.
  Future<OtpSendResult> sendOtp(String phoneE164) async {
    if (!isAvailable) {
      return OtpSendResult.failed('Firebase is not initialised on this platform.');
    }

    _verificationId = null;
    final completer = Completer<_SendResult>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneE164,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android instant verification — sign in right away.
          try {
            await _auth.signInWithCredential(credential);
            if (!completer.isCompleted) {
              completer.complete(_SendResult(kind: _Kind.auto));
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.complete(
                  _SendResult(kind: _Kind.failed, error: e.toString()));
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('verifyPhoneNumber failed: ${e.code} ${e.message}');
          if (!completer.isCompleted) {
            completer.complete(_SendResult(
                kind: _Kind.failed, error: _humanise(e)));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          if (!completer.isCompleted) {
            completer.complete(_SendResult(kind: _Kind.sent));
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (!completer.isCompleted) {
        completer.complete(_SendResult(kind: _Kind.failed, error: '$e'));
      }
    }

    final r = await completer.future;
    switch (r.kind) {
      case _Kind.auto:
        return OtpSendResult.autoVerified;
      case _Kind.sent:
        return OtpSendResult.codeSent;
      case _Kind.failed:
        return OtpSendResult.failed(r.error ?? 'Failed to send OTP.');
    }
  }

  /// Verifies the [otp] against the verificationId from the last
  /// `sendOtp`. Returns `null` on success or a user-facing error
  /// message string on failure.
  Future<String?> verifyOtp(String otp) async {
    final vid = _verificationId;
    if (vid == null) {
      return 'OTP session expired. Tap "Resend OTP".';
    }
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: vid,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      return null;
    } on FirebaseAuthException catch (e) {
      return _humanise(e);
    } catch (e) {
      return '$e';
    }
  }

  Future<void> signOut() => _auth.signOut();

  String? get currentUserPhone => _auth.currentUser?.phoneNumber;

  static String _humanise(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'That phone number doesn\'t look right.';
      case 'invalid-verification-code':
        return 'Invalid OTP. Please try again.';
      case 'session-expired':
        return 'OTP expired. Tap Resend OTP.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'missing-client-identifier':
      case 'app-not-authorized':
        return 'App not authorised for phone auth. Add the SHA-1 fingerprint in the Firebase console.';
      default:
        return e.message ?? 'OTP verification failed (${e.code}).';
    }
  }
}

enum _Kind { sent, auto, failed }

class _SendResult {
  _SendResult({required this.kind, this.error});
  final _Kind kind;
  final String? error;
}

/// Public, app-facing result of `sendOtp`.
sealed class OtpSendResult {
  const OtpSendResult();
  static const OtpSendResult codeSent = _CodeSent();
  static const OtpSendResult autoVerified = _AutoVerified();
  static OtpSendResult failed(String message) => _Failed(message);
}

class _CodeSent extends OtpSendResult {
  const _CodeSent();
}

class _AutoVerified extends OtpSendResult {
  const _AutoVerified();
}

class _Failed extends OtpSendResult {
  const _Failed(this.message);
  final String message;
}

extension OtpSendResultMatch on OtpSendResult {
  bool get isCodeSent => this is _CodeSent;
  bool get isAutoVerified => this is _AutoVerified;
  bool get isFailed => this is _Failed;
  String? get errorMessage =>
      this is _Failed ? (this as _Failed).message : null;
}
