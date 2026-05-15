import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../shared/widgets.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

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
    await ref.read(authProvider.notifier).startPhone(phone);
    ref.read(profileProvider.notifier).setPhone(phone);
    if (!mounted) return;
    setState(() => _busy = false);
    context.push(Routes.otp);
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    return AppPage(
      title: l.t('auth.phone.title'),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 4),
          Text(
            l.t('auth.phone.helper'),
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
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
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
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 80, minHeight: 0),
              hintText: '98xxxxxxxx',
            ),
          ),
          const SizedBox(height: 16),
          const TrustBanner(
            icon: Icons.shield_outlined,
            text: 'Verified pros only. We use OTP, never store your password.',
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
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(l.t('common.continue')),
      ),
    );
  }
}
