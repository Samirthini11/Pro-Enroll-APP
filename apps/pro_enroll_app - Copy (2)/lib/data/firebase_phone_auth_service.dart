import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Sends and verifies OTP via Firebase Phone Auth (SMS delivered by Firebase).
class FirebasePhoneAuthService {
  FirebasePhoneAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  String? _verificationId;
  int? _resendToken;
  ConfirmationResult? _webConfirmation;

  bool get hasPendingVerification => kIsWeb
      ? _webConfirmation != null
      : _verificationId != null && _verificationId!.isNotEmpty;

  Future<void> sendOtp(String phoneE164) async {
    if (kIsWeb) {
      _webConfirmation = await _auth.signInWithPhoneNumber(phoneE164);
      return;
    }

    final completer = Completer<void>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.completeError(
            Exception(e.message ?? 'Could not send SMS OTP'),
          );
        }
      },
      codeSent: (verificationId, forceResendingToken) {
        _verificationId = verificationId;
        _resendToken = forceResendingToken;
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );

    return completer.future;
  }

  Future<String> verifyOtpAndGetIdToken(String smsCode) async {
    final UserCredential result;
    if (kIsWeb) {
      final confirmation = _webConfirmation;
      if (confirmation == null) {
        throw StateError('No pending Firebase verification. Request a new OTP.');
      }
      result = await confirmation.confirm(smsCode.trim());
      _webConfirmation = null;
    } else {
      final verificationId = _verificationId;
      if (verificationId == null || verificationId.isEmpty) {
        throw StateError('No pending Firebase verification. Request a new OTP.');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      result = await _auth.signInWithCredential(credential);
      _verificationId = null;
    }

    final token = await result.user?.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Firebase sign-in succeeded but no ID token was issued');
    }

    return token;
  }

  Future<void> signOut() => _auth.signOut();
}
