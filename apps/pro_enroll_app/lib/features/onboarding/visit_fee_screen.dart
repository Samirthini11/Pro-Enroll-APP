import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../shared/widgets.dart';

class VisitFeeScreen extends ConsumerStatefulWidget {
  const VisitFeeScreen({super.key});

  @override
  ConsumerState<VisitFeeScreen> createState() => _VisitFeeScreenState();
}

class _VisitFeeScreenState extends ConsumerState<VisitFeeScreen> {
  int _fee = 150;

  @override
  void initState() {
    super.initState();
    _fee = (ref.read(profileProvider).visitFeePaise / 100).round();
    if (_fee < 100) _fee = 150;
  }

  void _continue() {
    ref.read(profileProvider.notifier).setVisitFeeRupees(_fee);
    context.push(Routes.kycIntro);
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final c = Theme.of(context).colorScheme;
    return AppPage(
      title: l.t('onboarding.fee.title'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(l.t('onboarding.fee.helper'),
              style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 32),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: c.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('Visit fee',
                      style: TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Text(
                    '₹$_fee',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      color: c.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: _fee <= 50 ? null : () => setState(() => _fee -= 25),
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Slider(
                  value: _fee.toDouble().clamp(50, 500),
                  min: 50,
                  max: 500,
                  divisions: 18,
                  label: '₹$_fee',
                  onChanged: (v) => setState(() => _fee = v.round()),
                ),
              ),
              IconButton.filledTonal(
                onPressed: _fee >= 500 ? null : () => setState(() => _fee += 25),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TrustBanner(
            icon: Icons.info_outline,
            text:
                'Customers see this fee before booking. Most pros in Pondy charge ₹100–₹250.',
          ),
        ],
      ),
      bottom: FilledButton(
        onPressed: _continue,
        child: Text(l.t('common.continue')),
      ),
    );
  }
}
