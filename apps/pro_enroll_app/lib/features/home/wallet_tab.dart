import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ist_time.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/api/api_exception.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../shared/widgets.dart';

class WalletTab extends ConsumerStatefulWidget {
  const WalletTab({super.key});

  @override
  ConsumerState<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends ConsumerState<WalletTab> {
  final _utrController = TextEditingController();
  final _customAmountController = TextEditingController();
  bool _submitting = false;
  int? _selectedAmountPaise;

  @override
  void dispose() {
    _utrController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(earningsProvider);
    ref.invalidate(creditHistoryProvider);
    ref.invalidate(rechargeRequestsProvider);
    await Future.wait([
      ref.read(profileProvider.notifier).loadFromApi(),
      ref.read(earningsProvider.future),
      ref.read(creditHistoryProvider.future),
      ref.read(rechargeRequestsProvider.future),
    ]);
  }

  int _amountPaise(EarningsSummary e) {
    if (_selectedAmountPaise != null) return _selectedAmountPaise!;
    final custom = int.tryParse(_customAmountController.text.trim());
    if (custom != null && custom > 0) return custom * 100;
    return e.suggestedRechargePaise > 0
        ? e.suggestedRechargePaise
        : e.walletRechargeMinPaise;
  }

  String _payUri(EarningsSummary e, int amountPaise) {
    final upiId = e.companyUpiId ?? 'sami050699@okaxis';
    final upiName = e.companyUpiName ?? 'Pro Enroll';
    final am = (amountPaise / 100).toStringAsFixed(2);
    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': upiId,
        'pn': upiName,
        'am': am,
        'cu': 'INR',
        'tn': 'Pro Enroll wallet recharge',
      },
    ).toString();
  }

  Future<void> _openUpi(String payUri) async {
    final ok = await launchUrl(
      Uri.parse(payUri),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open UPI app. Scan the QR instead.'),
        ),
      );
    }
  }

  Future<void> _recharge(EarningsSummary earnings) async {
    final amount = _amountPaise(earnings);
    final min = earnings.walletRechargeMinPaise;
    if (amount < min) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum recharge is ${formatPaise(min)}'),
        ),
      );
      return;
    }
    final utr = _utrController.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (utr.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter UTR from your UPI payment (min 8 characters)'),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(repositoryProvider).rechargeWallet(
            amountPaise: amount,
            utr: utr,
          );
      _utrController.clear();
      ref.invalidate(earningsProvider);
      ref.invalidate(creditHistoryProvider);
      ref.invalidate(rechargeRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sent ${formatPaise(amount)} for admin approval. '
              'Wallet is credited once approved.',
            ),
            backgroundColor: AppTheme.brandSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : 'Could not recharge'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncEarnings = ref.watch(earningsProvider);
    final asyncHistory = ref.watch(creditHistoryProvider);

    return asyncEarnings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.textMuted, size: 40),
              const SizedBox(height: 12),
              Text(
                err is ApiException ? err.message : 'Could not load wallet.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  ref.invalidate(earningsProvider);
                  ref.invalidate(creditHistoryProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (earnings) {
        final amount = _amountPaise(earnings);
        final payUri = _payUri(earnings, amount);
        final upiId = earnings.companyUpiId ?? 'sami050699@okaxis';
        final minRupees = (earnings.walletMinAcceptPaise / 100).round();

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ContentMaxWidth(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                context.pageHPadding,
                16,
                context.pageHPadding,
                28,
              ),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                Text('Wallet', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'First ${earnings.freeBookingLimit} jobs free. Then keep min ₹$minRupees — '
                  '${earnings.visitCommissionPercent}% of visit fee deducted per job.',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13.5),
                ),
                const SizedBox(height: 16),
                _WalletBalanceCard(
                  balancePaise: earnings.walletBalancePaise,
                  minPaise: earnings.walletMinAcceptPaise,
                  freeLeft: earnings.freeBookingsRemaining,
                  canAccept: earnings.canAcceptJobs,
                  pendingRechargePaise: earnings.pendingRechargePaise,
                ),
                ref.watch(rechargeRequestsProvider).maybeWhen(
                      data: (requests) {
                        final visible = requests.take(3).toList();
                        if (visible.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            children: [
                              for (final r in visible) ...[
                                _RechargeStatusTile(request: r),
                                const SizedBox(height: 8),
                              ],
                            ],
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                if (earnings.commissionNote != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    earnings.commissionNote!,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _RechargeCard(
                  upiId: upiId,
                  amountPaise: amount,
                  minPaise: earnings.walletRechargeMinPaise,
                  payUri: payUri,
                  selectedPaise: _selectedAmountPaise,
                  customController: _customAmountController,
                  utrController: _utrController,
                  submitting: _submitting,
                  onSelectPreset: (p) => setState(() {
                    _selectedAmountPaise = p;
                    _customAmountController.clear();
                  }),
                  onCustomChanged: (_) => setState(() => _selectedAmountPaise = null),
                  onOpenUpi: () => _openUpi(payUri),
                  onConfirm: () => _recharge(earnings),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Wallet history',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                asyncHistory.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text(
                    e is ApiException ? e.message : 'Could not load history',
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Text(
                          'No wallet activity yet. Recharges and job fee deductions appear here.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13.5),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final item in items) ...[
                          _WalletHistoryTile(item: item),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  const _WalletBalanceCard({
    required this.balancePaise,
    required this.minPaise,
    required this.freeLeft,
    required this.canAccept,
    this.pendingRechargePaise = 0,
  });

  final int balancePaise;
  final int minPaise;
  final int freeLeft;
  final bool canAccept;
  final int pendingRechargePaise;

  @override
  Widget build(BuildContext context) {
    final low = freeLeft <= 0 && balancePaise < minPaise;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: low
              ? const [Color(0xFFB45309), Color(0xFF92400E)]
              : const [Color(0xFF0F766E), Color(0xFF115E59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (low ? const Color(0xFFB45309) : const Color(0xFF0F766E))
                .withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prepaid wallet',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatPaise(balancePaise),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            freeLeft > 0
                ? '$freeLeft free job${freeLeft == 1 ? '' : 's'} left · then min ${formatPaise(minPaise)}'
                : low
                    ? 'Below minimum ${formatPaise(minPaise)} — recharge to accept jobs'
                    : canAccept
                        ? 'Ready to accept jobs · min ${formatPaise(minPaise)}'
                        : 'Recharge to accept jobs',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (pendingRechargePaise > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${formatPaise(pendingRechargePaise)} awaiting admin approval',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RechargeStatusTile extends StatelessWidget {
  const _RechargeStatusTile({required this.request});

  final WalletRechargeRequest request;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = request.isApproved
        ? (AppTheme.brandSuccess, Icons.check_circle_outline)
        : request.isRejected
            ? (AppTheme.brandDanger, Icons.cancel_outlined)
            : (AppTheme.brandAccentDark, Icons.hourglass_top);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatPaise(request.amountPaise)} · ${request.statusLabel}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'UTR ${request.utr}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (request.rejectedReason != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    request.rejectedReason!,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RechargeCard extends StatelessWidget {
  const _RechargeCard({
    required this.upiId,
    required this.amountPaise,
    required this.minPaise,
    required this.payUri,
    required this.selectedPaise,
    required this.customController,
    required this.utrController,
    required this.submitting,
    required this.onSelectPreset,
    required this.onCustomChanged,
    required this.onOpenUpi,
    required this.onConfirm,
  });

  final String upiId;
  final int amountPaise;
  final int minPaise;
  final String payUri;
  final int? selectedPaise;
  final TextEditingController customController;
  final TextEditingController utrController;
  final bool submitting;
  final ValueChanged<int> onSelectPreset;
  final ValueChanged<String> onCustomChanged;
  final VoidCallback onOpenUpi;
  final VoidCallback onConfirm;

  static const _presets = [5000, 10000, 20000, 50000]; // ₹50, 100, 200, 500

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.qr_code_2, color: AppTheme.brandPrimary, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recharge via company UPI',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pay to company UPI, enter UTR, then submit. Status stays Pending until admin verifies UTR and amount — only then wallet balance updates. Min ${formatPaise(minPaise)}.',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _presets)
                ChoiceChip(
                  label: Text(formatPaise(p)),
                  selected: selectedPaise == p,
                  onSelected: (_) => onSelectPreset(p),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: customController,
            keyboardType: TextInputType.number,
            onChanged: onCustomChanged,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              labelText: 'Custom amount (₹)',
              hintText: 'e.g. 150',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: QrImageView(
                data: payUri,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  upiId,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppTheme.brandPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copy UPI ID',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: upiId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('UPI ID copied')),
                    );
                  }
                },
                icon: const Icon(Icons.copy, size: 18),
              ),
            ],
          ),
          Text(
            'Pay: ${formatPaise(amountPaise)}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpenUpi,
              icon: const Icon(Icons.payment),
              label: Text('Pay ${formatPaise(amountPaise)} via UPI'),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Enter UTR Number',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: utrController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(64),
            ],
            decoration: const InputDecoration(
              hintText: 'e.g. 123456789012',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: submitting ? null : onConfirm,
              child: submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit for admin approval'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletHistoryTile extends StatelessWidget {
  const _WalletHistoryTile({required this.item});

  final CreditHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final when = item.completedAt;
    final whenLabel = when != null ? IstTime.formatDateTime(when) : '';
    final isDebit = item.isDebit || item.creditPaise < 0;
    final amount = item.creditPaise;
    final title = item.label ??
        (item.entryType == 'recharge'
            ? 'Wallet recharge'
            : item.entryType == 'commission_debit'
                ? 'Platform fee deducted'
                : (item.bookingCode.isNotEmpty
                    ? item.bookingCode
                    : 'Wallet entry'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDebit ? Icons.arrow_outward : Icons.add_circle_outline,
            size: 20,
            color: isDebit ? AppTheme.brandDanger : AppTheme.brandSuccess,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (item.utr != null && item.utr!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'UTR ${item.utr}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (whenLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    whenLabel,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${isDebit && amount > 0 ? '-' : (amount > 0 ? '+' : '')}${formatPaise(amount.abs())}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDebit ? AppTheme.brandDanger : AppTheme.brandSuccess,
            ),
          ),
        ],
      ),
    );
  }
}
