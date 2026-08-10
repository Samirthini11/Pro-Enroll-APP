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
import '../shared/widgets.dart';

String _initial(String? name) {
  if (name == null || name.isEmpty) return 'P';
  return name.trim().substring(0, 1).toUpperCase();
}

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

    return ContentMaxWidth(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
            context.pageHPadding, 16, context.pageHPadding, 28),
        physics: const BouncingScrollPhysics(),
        children: [
          Text(l.t('profile.title'),
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),

          // Pro card.
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
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Text(
                        _initial(profile.fullName),
                        style: const TextStyle(
                          color: AppTheme.brandPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
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
                          value: profile.ratingAvg.toStringAsFixed(1),
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

          // Skills.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Skills',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in profile.skills)
                        Chip(
                          avatar: Icon(
                            supportedCategories
                                .firstWhere(
                                    (c) => c.code == s.categoryCode,
                                    orElse: () =>
                                        supportedCategories.first)
                                .icon,
                            size: 16,
                            color: AppTheme.brandPrimary,
                          ),
                          label: Text(
                            '${supportedCategories.firstWhere((c) => c.code == s.categoryCode, orElse: () => supportedCategories.first).name(lang)} • ${s.experienceYears}y',
                          ),
                          backgroundColor: AppTheme.brandPrimaryLight,
                          side: const BorderSide(
                              color: Color(0xFFDBE5FA)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => context.push(Routes.editSkills),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit services'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.radar,
                          color: AppTheme.textMuted, size: 18),
                      const SizedBox(width: 6),
                      Text('${profile.workRadiusKm} km work radius',
                          style: const TextStyle(color: AppTheme.textMuted)),
                      const Spacer(),
                      Text(
                        formatPaise(profile.visitFeePaise),
                        style: const TextStyle(
                            color: AppTheme.brandPrimary,
                            fontWeight: FontWeight.w800),
                      ),
                      const Text(
                        ' visit',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
            icon: Icons.person_search,
            title: 'Book a service',
            subtitle: 'Switch to customer mode — find a Plumber, AC tech, etc.',
            onTap: () async {
              final ok = await ref.read(authProvider.notifier).switchRole(
                    AppRole.customer,
                  );
              if (!context.mounted) return;
              if (ok) {
                ref.invalidate(earningsProvider);
                context.go(Routes.customerHome);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ref.read(authProvider).errorMessage ??
                          'Could not switch to customer mode.',
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          InfoCard(
            icon: Icons.translate,
            title: l.t('profile.language'),
            subtitle: lang == 'ta' ? 'தமிழ்' : 'English',
            onTap: () {
              ref
                  .read(localeProvider.notifier)
                  .setLanguage(lang == 'ta' ? 'en' : 'ta');
            },
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
