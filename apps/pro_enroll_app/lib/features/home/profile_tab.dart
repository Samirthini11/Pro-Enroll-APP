import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/i18n.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../../state/locale_state.dart';
import '../shared/widgets.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(lProvider);
    final profile = ref.watch(profileProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final theme = Theme.of(context);
    final city = supportedCities.firstWhere(
      (c) => c.id == profile.cityId,
      orElse: () => supportedCities.first,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text(l.t('profile.title'), style: theme.textTheme.headlineMedium),
        const SizedBox(height: 16),

        // Header.
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      (profile.fullName ?? 'P').characters.first.toUpperCase(),
                      style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 22),
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
                                style: theme.textTheme.titleLarge,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (profile.kycStatus.isVerified) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.verified,
                                  color: theme.colorScheme.primary,
                                  size: 20),
                            ],
                          ],
                        ),
                        Text(profile.phoneE164 ?? '',
                            style:
                                const TextStyle(color: Color(0xFF64748B))),
                        Text('${city.name}, ${city.state}',
                            style:
                                const TextStyle(color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _stat(
                      label: l.t('profile.rating'),
                      value: profile.ratingAvg.toStringAsFixed(1),
                      icon: Icons.star,
                      color: Colors.amber),
                  _stat(
                      label: l.t('profile.jobs'),
                      value: '${profile.jobsCompleted}',
                      icon: Icons.work_outline,
                      color: theme.colorScheme.primary),
                  _stat(
                      label: l.t('profile.proScore'),
                      value: '${profile.proScore}',
                      icon: Icons.trending_up,
                      color: Colors.deepPurple),
                ],
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
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in profile.skills)
                      Chip(
                        avatar: Icon(
                          supportedCategories
                              .firstWhere((c) => c.code == s.categoryCode,
                                  orElse: () => supportedCategories.first)
                              .icon,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        label: Text(
                          '${supportedCategories.firstWhere((c) => c.code == s.categoryCode, orElse: () => supportedCategories.first).name(lang)}  •  ${s.experienceYears}y',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.radar,
                        color: Color(0xFF64748B), size: 18),
                    const SizedBox(width: 6),
                    Text('${profile.workRadiusKm} km work radius',
                        style: const TextStyle(color: Color(0xFF64748B))),
                    const Spacer(),
                    Text('Visit fee ${formatPaise(profile.visitFeePaise)}',
                        style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Bank.
        InfoCard(
          icon: Icons.account_balance,
          title: l.t('profile.bank.title'),
          subtitle: profile.upiId ?? profile.bankAccountNo ??
              l.t('profile.bank.empty'),
          onTap: () => _showBankSheet(context, ref),
        ),
        const SizedBox(height: 10),

        // Language.
        InfoCard(
          icon: Icons.translate,
          title: l.t('profile.language'),
          subtitle: lang == 'ta' ? 'தமிழ்' : 'English',
          onTap: () {
            ref.read(localeProvider.notifier)
                .setLanguage(lang == 'ta' ? 'en' : 'ta');
          },
        ),
        const SizedBox(height: 10),

        InfoCard(
          icon: Icons.workspace_premium,
          title: 'Subscription',
          subtitle: 'Free plan — upgrade to ₹99/mo for unlimited leads',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming soon')),
          ),
        ),
        const SizedBox(height: 10),

        InfoCard(
          icon: Icons.logout,
          title: l.t('profile.signout'),
          onTap: () {
            ref.read(authProvider.notifier).signOut();
            context.go(Routes.welcome);
          },
        ),
      ],
    );
  }

  Widget _stat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

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
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add UPI for daily payouts',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: upiCtrl,
                decoration: const InputDecoration(
                  labelText: 'UPI ID',
                  hintText: 'name@upi',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  ref.read(profileProvider.notifier).setUpi(upiCtrl.text.trim());
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
