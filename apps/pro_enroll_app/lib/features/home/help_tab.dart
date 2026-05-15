import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/responsive.dart';
import '../shared/widgets.dart';

class HelpTab extends ConsumerWidget {
  const HelpTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(lProvider);
    return ContentMaxWidth(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
            context.pageHPadding, 16, context.pageHPadding, 28),
        physics: const BouncingScrollPhysics(),
        children: [
          Text(l.t('help.title'),
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
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
