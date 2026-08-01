import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
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
    // Make the selfie circle responsive — never larger than the
    // smaller of (300, 60% of viewport width / 45% of viewport height).
    final cap = (context.screenW * 0.6).clamp(180.0, 300.0);
    final capH = (context.screenH * 0.42).clamp(180.0, 320.0);
    final circle = cap < capH ? cap : capH;

    return AppPage(
      title: l.t('kyc.selfie.title'),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            l.t('kyc.selfie.body'),
            style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 22),
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: circle,
              height: circle * 1.1,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(circle),
                border: Border.all(
                  color: _matchScore != null
                      ? AppTheme.brandSuccess
                      : AppTheme.border,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _busy
                  ? const Center(child: CircularProgressIndicator())
                  : Icon(
                      _matchScore != null
                          ? Icons.check_circle
                          : Icons.face_outlined,
                      size: circle * 0.55,
                      color: _matchScore != null
                          ? AppTheme.brandSuccess
                          : AppTheme.textFaint,
                    ),
            ),
          ),
          const SizedBox(height: 18),
          if (_matchScore != null)
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified,
                        size: 16, color: AppTheme.brandSuccess),
                    const SizedBox(width: 6),
                    Text(
                      'Face matched (${(_matchScore! * 100).toStringAsFixed(0)}%)',
                      style: const TextStyle(
                        color: AppTheme.brandSuccess,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 18),
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
