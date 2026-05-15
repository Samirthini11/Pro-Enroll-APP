import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
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
  String? _error;

  bool get _isValid => _controller.text.trim().length == 6;

  Future<void> _verify() async {
    if (!_isValid || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref
        .read(authProvider.notifier)
        .verifyOtp(_controller.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      final msg = ref.read(authProvider).errorMessage ?? 'Invalid OTP. Try again.';
      setState(() => _error = msg);
      return;
    }

    if (widget.flow.isSignIn) {
      // Returning pro — pretend the backend says they're already
      // verified and seed some sample stats so the Home shell isn't
      // empty in the mock build.
      final pn = ref.read(profileProvider.notifier);
      pn.setName(ref.read(profileProvider).fullName ?? 'Pro user');
      pn.setKyc(KycStatus.verified);
      pn.seedDemoStats();
      pn.setAvailability(true);
      context.go(Routes.home);
    } else {
      context.go(Routes.onboardCategory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final phone = ref.watch(authProvider).phoneE164 ?? '';
    return AppPage(
      title: l.t('auth.otp.title'),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 4),
          Text(
            l.t('auth.otp.helper', {'phone': phone}),
            style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
          ),
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
            onChanged: (_) => setState(() => _error = null),
            style: const TextStyle(
              fontSize: 28,
              letterSpacing: 10,
              fontWeight: FontWeight.w800,
            ),
            decoration: const InputDecoration(hintText: '• • • • • •'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 16, color: AppTheme.brandDanger),
                const SizedBox(width: 6),
                Text(_error!,
                    style: const TextStyle(
                      color: AppTheme.brandDanger,
                      fontWeight: FontWeight.w600,
                    )),
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
                      ref.read(authProvider.notifier).startPhone(phone);
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
            : Text(widget.flow.isSignIn ? 'Sign in' : l.t('common.submit')),
      ),
    );
  }
}
