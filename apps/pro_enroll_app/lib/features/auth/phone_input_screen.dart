import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../shared/widgets.dart';
import 'auth_flow.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key, this.flow = const AuthFlow(mode: AuthMode.signUp)});

  final AuthFlow flow;

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid => _controller.text.trim().length == 10;

  Future<void> _continue() async {
    if (!_isValid || _busy) return;
    setState(() => _busy = true);
    final phone = '+91${_controller.text.trim()}';
    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.startPhone(
      phone,
      isSignIn: widget.flow.isSignIn,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    final auth = ref.read(authProvider);
    if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!)),
      );
      return;
    }
    if (auth.otpRequestId == null || auth.otpRequestId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send OTP. Check API connection and try again.'),
        ),
      );
      return;
    }

    ref.read(profileProvider.notifier).setPhone(phone);
    if (!mounted) return;

    final flow = widget.flow;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.push(Routes.otp, extra: flow);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final isSignIn = widget.flow.isSignIn;
    final title =
        isSignIn ? l.t('auth.signin.title') : l.t('auth.signup.title');
    final helper =
        isSignIn ? l.t('auth.signin.helper') : l.t('auth.signup.helper');
    return AppPage(
      title: title,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 4),
          Text(
            helper,
            style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (_) {
              ref.read(authProvider.notifier).clearError();
              setState(() {});
            },
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: _CountryPrefix(),
              ),
              prefixIconConstraints:
                  BoxConstraints(minWidth: 80, minHeight: 0),
              hintText: '98xxxxxxxx',
              errorText: ref.watch(authProvider).errorMessage,
              errorMaxLines: 4,
            ),
          ),
          const SizedBox(height: 16),
          TrustBanner(
            icon: Icons.shield_outlined,
            text: l.t('auth.phone.trust'),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              isSignIn
                  ? l.t('auth.signin.new_here')
                  : l.t('auth.signup.agree'),
              style:
                  const TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
            ),
          ),
        ],
      ),
      bottom: FilledButton(
        onPressed: _isValid && !_busy ? _continue : null,
        child: _busy
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                isSignIn ? l.t('auth.signin.send_otp') : l.t('common.continue'),
              ),
      ),
    );
  }
}

class _CountryPrefix extends StatelessWidget {
  const _CountryPrefix();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.brandPrimaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '+91',
            style: TextStyle(
              color: AppTheme.brandPrimaryDark,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
