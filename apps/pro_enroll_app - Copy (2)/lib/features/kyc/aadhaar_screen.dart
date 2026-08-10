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

class AadhaarScreen extends ConsumerStatefulWidget {
  const AadhaarScreen({super.key});

  @override
  ConsumerState<AadhaarScreen> createState() => _AadhaarScreenState();
}

class _AadhaarScreenState extends ConsumerState<AadhaarScreen> {
  final _aadhaarCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpStage = false;
  bool _busy = false;
  String? _kycRef;
  String? _error;

  @override
  void dispose() {
    _aadhaarCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  String get _digits => _aadhaarCtrl.text.replaceAll(' ', '');

  Future<void> _sendOtp() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final last4 = _digits.substring(8);
    final ref0 = await ref.read(repositoryProvider).initiateAadhaar(last4);
    if (!mounted) return;
    setState(() {
      _kycRef = ref0;
      _otpStage = true;
      _busy = false;
    });
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref.read(repositoryProvider).verifyAadhaarOtp(
          kycRefId: _kycRef!,
          otp: _otpCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      setState(() => _error = 'Invalid Aadhaar OTP.');
      return;
    }
    final last4 = _digits.substring(8);
    ref
        .read(profileProvider.notifier)
        .setKyc(KycStatus.selfiePending, aadhaarLast4: last4);
    if (!mounted) return;
    context.push(Routes.kycSelfie);
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final valid = _digits.length == 12;
    return AppPage(
      title: l.t('kyc.aadhaar.title'),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            l.t('kyc.aadhaar.helper'),
            style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _aadhaarCtrl,
            enabled: !_otpStage,
            keyboardType: TextInputType.number,
            inputFormatters: [
              _AadhaarFormatter(),
            ],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            decoration: const InputDecoration(
              labelText: 'Aadhaar number',
              hintText: 'xxxx xxxx xxxx',
              prefixIcon: Icon(Icons.credit_card),
            ),
          ),
          if (_otpStage) ...[
            const SizedBox(height: 18),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (_) => setState(() => _error = null),
              style: const TextStyle(
                fontSize: 26,
                letterSpacing: 8,
                fontWeight: FontWeight.w800,
              ),
              decoration: const InputDecoration(
                labelText: 'Aadhaar OTP',
                hintText: '• • • • • •',
              ),
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
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ],
        ],
      ),
      bottom: FilledButton(
        onPressed: _busy
            ? null
            : (_otpStage
                ? (_otpCtrl.text.length >= 4 ? _verifyOtp : null)
                : (valid ? _sendOtp : null)),
        child: _busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : Text(_otpStage ? l.t('common.submit') : 'Send Aadhaar OTP'),
      ),
    );
  }
}

/// Strips non-digits, caps at 12 digits, and inserts a space after every
/// 4 digits ("1234 5678 9012") while keeping the caret at the end.
class _AadhaarFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 12) digits = digits.substring(0, 12);
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
