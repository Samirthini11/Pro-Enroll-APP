import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
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
    final amountSize = context.responsive<double>(xs: 44, sm: 52, md: 60);

    return AppPage(
      title: l.t('onboarding.fee.title'),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            l.t('onboarding.fee.helper'),
            style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.brandPrimary,
                    AppTheme.brandPrimaryDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.brandPrimary.withValues(alpha: 0.22),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Visit fee',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹$_fee',
                    style: TextStyle(
                      fontSize: amountSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(44),
                  shape: const CircleBorder(),
                ),
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
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(44),
                  shape: const CircleBorder(),
                ),
                onPressed:
                    _fee >= 500 ? null : () => setState(() => _fee += 25),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const TrustBanner(
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
