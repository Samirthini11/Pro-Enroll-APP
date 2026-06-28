import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../shared/widgets.dart';
import 'auth_flow.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key, this.flow = const AuthFlow(mode: AuthMode.signUp)});

  final AuthFlow flow;

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _controller = TextEditingController();
  bool _busy = false;

  bool get _isValid => _controller.text.trim().length == 6;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onOtpTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onOtpTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onOtpTextChanged() => setState(() {});

  void _fillDevOtp(String otp) {
    _controller.text = otp;
    _controller.selection = TextSelection.collapsed(offset: otp.length);
  }

  bool _isSignInFrom(AuthState auth) => !auth.signUpFlow;

  Future<void> _showOtpAlert({
    required String title,
    required String message,
  }) async {
    final l = ref.read(lProvider);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: AppTheme.brandDanger, size: 32),
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.t('common.ok')),
          ),
        ],
      ),
    );
  }

  Future<void> _verify() async {
    if (!_isValid || _busy) return;
    setState(() => _busy = true);
    final authNotifier = ref.read(authProvider.notifier);
    final l = ref.read(lProvider);
    final authFlow = ref.read(authProvider);
    final isSignIn = _isSignInFrom(authFlow);
    final role = ref.read(roleProvider);
    final app = role == AppRole.customer ? 'pro_fix_customer' : 'pro_enroll';
    final ok = await authNotifier.verifyOtp(
      _controller.text.trim(),
      isSignIn: isSignIn,
      app: app,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    final authAfterVerify = ref.read(authProvider);
    final blocked = !ok ||
        authAfterVerify.otpErrorCode == 'invalid_otp' ||
        !authAfterVerify.isAuthenticated;

    if (blocked) {
      final message = authAfterVerify.errorMessage ?? l.t('auth.otp.invalid');
      await _showOtpAlert(
        title: l.t('auth.otp.invalid_title'),
        message: message,
      );
      if (mounted) setState(() {});
      return;
    }

    await authNotifier.completeAuthAndSync(isSignIn: isSignIn);
    if (!mounted) return;

    final authBeforeNav = ref.read(authProvider);
    if (!authBeforeNav.isAuthenticated ||
        authBeforeNav.otpErrorCode == 'invalid_otp') {
      return;
    }

    final currentRole = ref.read(roleProvider);
    if (currentRole == AppRole.customer) {
      authNotifier.navigateAfterCustomerAuth(GoRouter.of(context));
    } else {
      authNotifier.navigateAfterAuth(GoRouter.of(context), isSignIn: isSignIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final auth = ref.watch(authProvider);
    final phone = auth.phoneE164 ?? '';
    final otpError = auth.errorMessage;
    final isSignUp = auth.signUpFlow;
    final isSignIn = _isSignInFrom(auth);
    return AppPage(
      title: isSignUp ? l.t('auth.signup.otp.title') : l.t('auth.otp.title'),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 4),
          Text(
            isSignUp
                ? l.t('auth.signup.otp.helper', {'phone': phone})
                : l.t('auth.otp.helper', {'phone': phone}),
            style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
          ),
          if (auth.mockOtpMode && auth.debugOtp != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _fillDevOtp(auth.debugOtp!),
              child: TrustBanner(
                icon: Icons.info_outline,
                text: 'Demo OTP: ${auth.debugOtp} (tap to fill)',
              ),
            ),
          ] else if (auth.debugOtp != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _fillDevOtp(auth.debugOtp!),
              child: TrustBanner(
                icon: Icons.info_outline,
                text: 'Dev OTP: ${auth.debugOtp} (tap to fill)',
              ),
            ),
          ] else if (auth.firebaseSmsMode) ...[
            const SizedBox(height: 12),
            const TrustBanner(
              icon: Icons.sms_outlined,
              text: 'Enter the 6-digit code sent via SMS to your phone.',
            ),
          ] else ...[
            const SizedBox(height: 12),
            const TrustBanner(
              icon: Icons.sms_outlined,
              text: 'Enter the 6-digit code sent to your phone.',
            ),
          ],
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (_) => ref.read(authProvider.notifier).clearError(),
            style: const TextStyle(
              fontSize: 28,
              letterSpacing: 10,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: '• • • • • •',
              errorText: otpError,
              errorMaxLines: 2,
            ),
          ),
          if (otpError != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 16, color: AppTheme.brandDanger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    otpError,
                    style: const TextStyle(
                      color: AppTheme.brandDanger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _busy
                  ? null
                  : () {
                      ref.read(authProvider.notifier).startPhone(
                            phone,
                            isSignIn: isSignIn,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.t('auth.otp.resend'))),
                      );
                    },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l.t('auth.otp.resend')),
            ),
          ),
        ],
      ),
      bottom: FilledButton(
        onPressed: _isValid && !_busy ? _verify : null,
        child: _busy
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(l.t('common.submit')),
      ),
    );
  }
}
