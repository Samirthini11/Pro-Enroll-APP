import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
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

  Future<void> _sendOtp() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final last4 = _aadhaarCtrl.text.trim().substring(8);
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
    final last4 = _aadhaarCtrl.text.trim().substring(8);
    ref.read(profileProvider.notifier).setKyc(KycStatus.selfiePending,
        aadhaarLast4: last4);
    if (!mounted) return;
    context.push(Routes.kycSelfie);
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final valid = _aadhaarCtrl.text.trim().length == 12;
    return AppPage(
      title: l.t('kyc.aadhaar.title'),
      child: ListView(
        children: [
          Text(l.t('kyc.aadhaar.helper'),
              style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          TextField(
            controller: _aadhaarCtrl,
            enabled: !_otpStage,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 4),
            decoration: const InputDecoration(
              labelText: 'Aadhaar number',
              hintText: 'xxxx xxxx xxxx',
              prefixIcon: Icon(Icons.credit_card),
            ),
          ),
          if (_otpStage) ...[
            const SizedBox(height: 20),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (_) => setState(() => _error = null),
              style: const TextStyle(
                  fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                labelText: 'Aadhaar OTP',
                hintText: '••••••',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(color: Colors.redAccent)),
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
