import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../../state/locale_state.dart';
import '../shared/api_errors.dart';
import '../shared/book_service_action.dart';
import '../shared/language_picker.dart';
import '../shared/widgets.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(lProvider);
    final profile = ref.watch(profileProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final city = supportedCities.firstWhere(
      (c) => c.id == profile.cityId,
      orElse: () => supportedCities.first,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(profileProvider.notifier).loadFromApi(),
      child: ContentMaxWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              context.pageHPadding, 16, context.pageHPadding, 28),
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          children: [
            Text(l.t('profile.title'),
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                gradient: const LinearGradient(
                  colors: [AppTheme.brandPrimary, AppTheme.brandPrimaryDark],
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
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    profile.fullName ?? 'Pro',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (profile.kycStatus.isVerified) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified,
                                      color: Colors.white, size: 18),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.phoneE164 ?? '',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${city.name}, ${city.state}',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      BookServiceAvatar(
                        name: profile.fullName,
                        onTap: () => switchToCustomerMode(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _stat(
                            label: l.t('profile.rating'),
                            value: profile.ratingCount > 0
                                ? profile.ratingAvg.toStringAsFixed(1)
                                : '—',
                            icon: Icons.star),
                        _statDivider(),
                        _stat(
                            label: l.t('profile.jobs'),
                            value: '${profile.jobsCompleted}',
                            icon: Icons.work_outline),
                        _statDivider(),
                        _stat(
                            label: l.t('profile.proScore'),
                            value: '${profile.proScore}',
                            icon: Icons.trending_up),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const _MyServicesCard(),
            const SizedBox(height: 10),
            InfoCard(
              icon: Icons.radar,
              title: 'Work area & distance',
              subtitle: '${city.name} · ${profile.workRadiusKm} km radius',
              onTap: () => context.push(Routes.editWorkArea),
            ),
            const SizedBox(height: 10),
            InfoCard(
              icon: Icons.currency_rupee,
              title: 'Visiting charges',
              subtitle: profile.hasVaryingVisitFees
                  ? 'From ${formatPaise(profile.minVisitFeePaise)} · by service'
                  : '${formatPaise(profile.visitFeePaise)} per visit',
              onTap: () => context.push(Routes.editVisitFee),
            ),
            const SizedBox(height: 14),

            InfoCard(
              icon: Icons.account_balance,
              title: l.t('profile.bank.title'),
              subtitle:
                  profile.upiId ?? profile.bankAccountNo ?? l.t('profile.bank.empty'),
              onTap: () => _showBankSheet(context, ref),
            ),
            const SizedBox(height: 10),
            InfoCard(
              icon: Icons.translate,
              title: l.t('profile.language'),
              subtitle: languageNativeLabel(lang),
              onTap: () => showLanguagePicker(context, ref),
            ),
            const SizedBox(height: 10),
            InfoCard(
              icon: Icons.workspace_premium,
              title: 'Subscription',
              subtitle: 'Free plan • upgrade to ₹99/mo for unlimited leads',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              ),
            ),
            const SizedBox(height: 10),
            InfoCard(
              icon: Icons.home_repair_service,
              title: l.t('profile.bookService'),
              subtitle: l.t('profile.bookService.subtitle'),
              onTap: () => switchToCustomerMode(context, ref),
            ),
            const SizedBox(height: 10),
            InfoCard(
              icon: Icons.logout,
              title: l.t('profile.signout'),
              danger: true,
              onTap: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go(Routes.authLanding);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              )),
          Text(label,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.white.withValues(alpha: 0.85),
              )),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 28,
        color: Colors.white.withValues(alpha: 0.18),
      );

  void _showBankSheet(BuildContext context, WidgetRef ref) {
    final upiCtrl = TextEditingController(
        text: ref.read(profileProvider).upiId ?? '');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add UPI for daily payouts',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              const Text(
                'Payouts run every day at 7 PM IST.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: upiCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'UPI ID',
                  hintText: 'name@upi',
                  prefixIcon:
                      Icon(Icons.account_balance_wallet_outlined),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  ref
                      .read(profileProvider.notifier)
                      .setUpi(upiCtrl.text.trim());
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MyServicesCard extends ConsumerStatefulWidget {
  const _MyServicesCard();

  @override
  ConsumerState<_MyServicesCard> createState() => _MyServicesCardState();
}

class _MyServicesCardState extends ConsumerState<_MyServicesCard> {
  Map<String, int> _startYears = {};
  bool _busy = false;
  bool _initialized = false;
  final int _currentYear = DateTime.now().year;

  void _ensureInitialized(List<ProSkill> skills) {
    if (_initialized || skills.isEmpty) return;
    _startYears = {
      for (final s in skills)
        s.categoryCode:
            s.effectiveStartYear.clamp(_currentYear - 50, _currentYear),
    };
    _initialized = true;
  }

  bool get _dirty {
    final skills = ref.read(profileProvider).skills;
    if (skills.length != _startYears.length) return true;
    for (final s in skills) {
      if (_startYears[s.categoryCode] != s.effectiveStartYear) return true;
    }
    return false;
  }

  int _yearsFor(String code) =>
      (_currentYear - (_startYears[code] ?? _currentYear)).clamp(0, 50);

  Future<void> _save() async {
    if (_startYears.isEmpty || _busy) return;
    setState(() => _busy = true);
    final codes = _startYears.keys.toList();
    final existing = {
      for (final s in ref.read(profileProvider).skills) s.categoryCode: s,
    };
    final skills = codes
        .map(
          (code) => ProSkill(
            categoryCode: code,
            experienceStartYear: _startYears[code] ?? _currentYear,
            experienceYears: _yearsFor(code),
            isPrimary: codes.first == code,
            visitFeePaise: existing[code]?.visitFeePaise ?? 15000,
          ),
        )
        .toList();
    try {
      await ref.read(profileProvider.notifier).persistCategories(
            codes,
            experienceStartYearByCategory: Map<String, int>.from(_startYears),
          );
      ref.read(profileProvider.notifier).setSkills(skills);
      await ref.read(profileProvider.notifier).loadFromApi();
      if (mounted) {
        setState(() => _initialized = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Services updated'),
            backgroundColor: AppTheme.brandSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showApiError(context, e, fallback: 'Could not update services.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final profile = ref.watch(profileProvider);
    final skills = profile.skills;
    final canEdit = profile.canEditExperience;
    _ensureInitialized(skills);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('My services',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                TextButton.icon(
                  onPressed: () => context.push(Routes.editSkills),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit services'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              canEdit
                  ? 'Set the year you started each service. Experience updates automatically.'
                  : 'Experience year is locked after enrollment. Raise a request from Help for admin approval.',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            if (canEdit &&
                profile.experienceEditRequestStatus == 'approved') ...[
              const SizedBox(height: 8),
              const Text(
                'Admin unlocked editing — update the year and save.',
                style: TextStyle(
                  color: AppTheme.brandSuccess,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (skills.isEmpty)
              const Text('No services yet. Tap Edit services to add.',
                  style: TextStyle(color: AppTheme.textMuted))
            else
              for (final s in skills)
                _ServiceExperienceRow(
                  categoryCode: s.categoryCode,
                  lang: lang,
                  startYear: _startYears[s.categoryCode] ?? s.effectiveStartYear,
                  years: _yearsFor(s.categoryCode),
                  minYear: _currentYear - 50,
                  maxYear: _currentYear,
                  enabled: canEdit,
                  onChanged: (y) =>
                      setState(() => _startYears[s.categoryCode] = y),
                ),
            if (_dirty && canEdit) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save experience'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ServiceExperienceRow extends StatelessWidget {
  const _ServiceExperienceRow({
    required this.categoryCode,
    required this.lang,
    required this.startYear,
    required this.years,
    required this.minYear,
    required this.maxYear,
    required this.onChanged,
    this.enabled = true,
  });

  final String categoryCode;
  final String lang;
  final int startYear;
  final int years;
  final int minYear;
  final int maxYear;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cat = supportedCategories.firstWhere(
      (c) => c.code == categoryCode,
      orElse: () => supportedCategories.first,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(cat.icon, color: AppTheme.brandPrimary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name(lang),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  'Since $startYear · $years yr${years == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: !enabled || startYear <= minYear
                ? null
                : () => onChanged(startYear - 1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('$startYear', style: const TextStyle(fontWeight: FontWeight.w800)),
          IconButton(
            onPressed: !enabled || startYear >= maxYear
                ? null
                : () => onChanged(startYear + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
