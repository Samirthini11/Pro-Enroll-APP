import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../shared/widgets.dart';

class HelpTab extends ConsumerWidget {
  const HelpTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(lProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text(l.t('help.title'),
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
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
              'Free Tamil video courses to upskill — AC, RO, plumbing, customer service',
          onTap: () {},
        ),
        const SizedBox(height: 24),
        const TrustBanner(
          text: 'In emergency, use the SOS button on an active job.',
          icon: Icons.warning_amber_rounded,
        ),
      ],
    );
  }
}
