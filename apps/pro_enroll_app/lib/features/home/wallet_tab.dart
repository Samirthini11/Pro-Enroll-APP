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
  bool _submitting = false;

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(earningsProvider);
    ref.invalidate(creditHistoryProvider);
    await Future.wait([
      ref.read(earningsProvider.future),
      ref.read(creditHistoryProvider.future),
    ]);
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

  Future<void> _markPaid(EarningsSummary earnings) async {
    final utr = _utrController.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (utr.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter UTR number from your UPI payment (min 8 characters)'),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(repositoryProvider).markPlatformFeePaid(utr: utr);
      _utrController.clear();
      ref.invalidate(earningsProvider);
      ref.invalidate(creditHistoryProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Platform fee marked as paid'),
            backgroundColor: AppTheme.brandSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : 'Could not update'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _payUri(EarningsSummary e) {
    final fromApi = e.companyUpiPayUri;
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    final upiId = e.companyUpiId ?? 'sami050699@okaxis';
    final upiName = e.companyUpiName ?? 'Pro Enroll';
    final am = (e.platformFeeDuePaise / 100).toStringAsFixed(2);
    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': upiId,
        'pn': upiName,
        'am': am,
        'cu': 'INR',
        'tn': 'Pro Enroll platform fee',
      },
    ).toString();
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
        final upiId = earnings.companyUpiId ?? 'sami050699@okaxis';
        final due = earnings.platformFeeDuePaise;
        final payUri = _payUri(earnings);

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
                Text(
                  'Wallet',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Balance, platform fee payment, and credit history',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13.5),
                ),
                const SizedBox(height: 16),
                _WalletBalanceCard(balancePaise: earnings.walletBalancePaise),
                const SizedBox(height: 14),
                _PlatformFeePayCard(
                  upiId: upiId,
                  duePaise: due,
                  payUri: payUri,
                  utrController: _utrController,
                  submitting: _submitting,
                  onOpenUpi: () => _openUpi(payUri),
                  onMarkPaid: due > 0 ? () => _markPaid(earnings) : null,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Credit history',
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
                          'No credits yet. Completed jobs will show here.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13.5),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final item in items) ...[
                          _CreditHistoryTile(item: item),
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
  const _WalletBalanceCard({required this.balancePaise});

  final int balancePaise;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF115E59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
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
                  'Wallet balance',
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
                const SizedBox(height: 2),
                Text(
                  'Available for next payout',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformFeePayCard extends StatelessWidget {
  const _PlatformFeePayCard({
    required this.upiId,
    required this.duePaise,
    required this.payUri,
    required this.utrController,
    required this.submitting,
    required this.onOpenUpi,
    required this.onMarkPaid,
  });

  final String upiId;
  final int duePaise;
  final String payUri;
  final TextEditingController utrController;
  final bool submitting;
  final VoidCallback onOpenUpi;
  final VoidCallback? onMarkPaid;

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
                  'Pay platform fee to company',
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
            duePaise > 0
                ? 'Pay ${formatPaise(duePaise)} via UPI, then enter UTR to mark as paid.'
                : 'No platform fee due. You can still open company UPI if needed.',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              height: 1.35,
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
          if (duePaise > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Amount due: ${formatPaise(duePaise)}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpenUpi,
              icon: const Icon(Icons.payment),
              label: Text(
                duePaise > 0
                    ? 'Pay ${formatPaise(duePaise)} via UPI'
                    : 'Open UPI',
              ),
            ),
          ),
          if (duePaise > 0) ...[
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
                onPressed: submitting || onMarkPaid == null ? null : onMarkPaid,
                child: submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Mark as paid'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreditHistoryTile extends StatelessWidget {
  const _CreditHistoryTile({required this.item});

  final CreditHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final when = item.completedAt;
    final whenLabel = when != null
        ? IstTime.formatDateTime(when)
        : '';
    final feeDue = !item.platformFeePaid &&
        !item.commissionWaived &&
        item.commissionPaise > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.bookingCode.isNotEmpty
                      ? item.bookingCode
                      : 'Booking #${item.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                formatPaise(item.creditPaise),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppTheme.brandSuccess,
                ),
              ),
            ],
          ),
          if (item.label != null && item.label!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.label!,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
            ),
          ],
          if (whenLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              whenLabel,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (item.commissionWaived)
                _chip('Free booking', AppTheme.brandSuccess)
              else if (item.commissionPaise > 0)
                _chip(
                  'Fee ${formatPaise(item.commissionPaise)}',
                  feeDue ? AppTheme.brandDanger : AppTheme.textMuted,
                ),
              if (item.platformFeePaid)
                _chip(
                  item.utr != null && item.utr!.isNotEmpty
                      ? 'Paid · UTR ${item.utr}'
                      : 'Platform fee paid',
                  AppTheme.brandSuccess,
                )
              else if (feeDue)
                _chip('UTR pending', AppTheme.brandDanger),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
      ),
    );
  }
}
