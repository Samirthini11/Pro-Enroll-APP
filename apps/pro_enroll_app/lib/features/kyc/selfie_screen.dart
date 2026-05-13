import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../shared/widgets.dart';

class SelfieScreen extends ConsumerStatefulWidget {
  const SelfieScreen({super.key});

  @override
  ConsumerState<SelfieScreen> createState() => _SelfieScreenState();
}

class _SelfieScreenState extends ConsumerState<SelfieScreen> {
  bool _busy = false;
  double? _matchScore;

  Future<void> _capture() async {
    setState(() => _busy = true);
    final s = await ref.read(repositoryProvider).uploadSelfie();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _matchScore = s;
    });
  }

  void _continue() {
    context.push(Routes.kycDocs);
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    return AppPage(
      title: l.t('kyc.selfie.title'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.t('kyc.selfie.body'),
              style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 220,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(140),
                border: Border.all(
                  color: _matchScore != null
                      ? Colors.green
                      : const Color(0xFFE2E8F0),
                  width: 3,
                ),
              ),
              child: _busy
                  ? const Center(child: CircularProgressIndicator())
                  : Icon(
                      _matchScore != null
                          ? Icons.check_circle
                          : Icons.face_outlined,
                      size: 120,
                      color: _matchScore != null
                          ? Colors.green
                          : const Color(0xFF94A3B8),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          if (_matchScore != null)
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Face matched (${(_matchScore! * 100).toStringAsFixed(0)}%)',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          const Spacer(),
          if (_matchScore == null)
            OutlinedButton.icon(
              onPressed: _busy ? null : _capture,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Take selfie'),
            ),
        ],
      ),
      bottom: FilledButton(
        onPressed: _matchScore == null ? null : _continue,
        child: Text(l.t('common.continue')),
      ),
    );
  }
}
