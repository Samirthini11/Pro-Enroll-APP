import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(l.t('auth.phone.helper'),
              style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              prefixIcon: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('+91',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w600)),
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 60),
              hintText: '98xxxxxxxx',
            ),
          ),
          const SizedBox(height: 16),
          TrustBanner(text: l.t('app.name') + ' • Aadhaar verified pros only'),
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
            : Text(l.t('common.continue')),
      ),
    );
  }
}
