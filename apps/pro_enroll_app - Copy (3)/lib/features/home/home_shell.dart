import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_config.dart';
import '../../core/i18n.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../state/app_state.dart';
import 'earnings_tab.dart';
import 'help_tab.dart';
import 'jobs_tab.dart';
import 'profile_tab.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (AppConfig.hasApi) {
      Future.microtask(() async {
        await ref.read(pushNotificationServiceProvider).syncTokenWithServer();
        await ref.read(profileProvider.notifier).loadFromApi();
        final profile = ref.read(profileProvider);
        if (profile.isAvailable) {
          await ref.read(jobsProvider.notifier).refresh(
                profile.skills.map((s) => s.categoryCode).toList(),
              );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final pages = const [
      JobsTab(),
      EarningsTab(),
      ProfileTab(),
      HelpTab(),
    ];
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(child: ContentMaxWidth(child: IndexedStack(index: _index, children: pages))),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) {
            setState(() => _index = i);
            if (i == 1) {
              ref.invalidate(earningsProvider);
              ref.read(profileProvider.notifier).loadFromApi();
            } else if (i == 2) {
              ref.read(profileProvider.notifier).loadFromApi();
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.work_outline),
              selectedIcon: const Icon(Icons.work),
              label: l.t('home.tab.jobs'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.currency_rupee_outlined),
              selectedIcon: const Icon(Icons.currency_rupee),
              label: l.t('home.tab.earnings'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: l.t('home.tab.profile'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.help_outline),
              selectedIcon: const Icon(Icons.help),
              label: l.t('home.tab.help'),
            ),
          ],
        ),
      ),
    );
  }
}
