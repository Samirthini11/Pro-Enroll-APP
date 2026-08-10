import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../shared/api_errors.dart';
import '../shared/widgets.dart';

class HelpTab extends ConsumerStatefulWidget {
  const HelpTab({super.key});

  @override
  ConsumerState<HelpTab> createState() => _HelpTabState();
}

class _HelpTabState extends ConsumerState<HelpTab> {
  bool _requestBusy = false;

  Future<void> _requestExperienceEdit() async {
    if (_requestBusy) return;
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.read(lProvider).t('help.experience_edit.title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ref.read(lProvider).t('help.experience_edit.dialog_body'),
              style: const TextStyle(height: 1.35, fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: ref.read(lProvider).t('help.experience_edit.reason'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ref.read(lProvider).t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ref.read(lProvider).t('help.experience_edit.submit')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _requestBusy = true);
    try {
      final profile = await ref
          .read(repositoryProvider)
          .requestExperienceEdit(reason: reasonCtrl.text.trim());
      if (profile != null) {
        ref.read(profileProvider.notifier).applyFromServer(profile);
      } else {
        await ref.read(profileProvider.notifier).loadFromApi();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(lProvider).t('help.experience_edit.sent')),
          backgroundColor: AppTheme.brandSuccess,
        ),
      );
    } catch (e) {
      if (mounted) {
        showApiError(context, e, fallback: 'Could not submit request.');
      }
    } finally {
      reasonCtrl.dispose();
      if (mounted) setState(() => _requestBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final profile = ref.watch(profileProvider);
    final enrolled = profile.cityId != null &&
        (profile.fullName?.trim().isNotEmpty ?? false);
    final locked = enrolled && !profile.canEditExperience;
    final pending = profile.experienceEditRequestStatus == 'pending';
    final unlocked = enrolled && profile.canEditExperience;

    return ContentMaxWidth(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
            context.pageHPadding, 16, context.pageHPadding, 28),
        physics: const BouncingScrollPhysics(),
        children: [
          Text(l.t('help.title'),
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          if (enrolled) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timeline, color: AppTheme.brandPrimary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.t('help.experience_edit.title'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locked
                        ? l.t('help.experience_edit.locked_body')
                        : unlocked
                            ? l.t('help.experience_edit.unlocked_body')
                            : l.t('help.experience_edit.locked_body'),
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      height: 1.35,
                      fontSize: 13,
                    ),
                  ),
                  if (pending) ...[
                    const SizedBox(height: 10),
                    Text(
                      l.t('help.experience_edit.pending'),
                      style: const TextStyle(
                        color: Color(0xFFB86E00),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (locked && !pending) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _requestBusy ? null : _requestExperienceEdit,
                        child: _requestBusy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l.t('help.experience_edit.request')),
                      ),
                    ),
                  ],
                  if (unlocked) ...[
                    const SizedBox(height: 10),
                    Text(
                      l.t('help.experience_edit.go_profile'),
                      style: const TextStyle(
                        color: AppTheme.brandSuccess,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ],
          InfoCard(
            icon: Icons.call,
            title: l.t('help.call'),
            subtitle: '+91 80000 00000 (9 AM – 9 PM, all days)',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          InfoCard(
            icon: Icons.message,
            title: l.t('help.whatsapp'),
            subtitle: 'Quick chat with our support team',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          InfoCard(
            icon: Icons.book_outlined,
            title: l.t('help.faq'),
            subtitle: 'How payouts work, KYC, ratings, disputes',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          InfoCard(
            icon: Icons.school_outlined,
            title: 'Pro Academy',
            subtitle:
                'Free Tamil video courses — AC, RO, plumbing, customer service',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          InfoCard(
            icon: Icons.gavel_outlined,
            title: l.t('legal.terms.title'),
            subtitle: l.t('legal.terms.subtitle'),
            onTap: () => context.push(Routes.termsAcceptance, extra: true),
          ),
          const SizedBox(height: 18),
          const TrustBanner(
            tone: TrustBannerTone.warning,
            text: 'In emergency, use the SOS button on an active job.',
            icon: Icons.warning_amber_rounded,
          ),
        ],
      ),
    );
  }
}
