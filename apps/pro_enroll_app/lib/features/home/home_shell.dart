import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
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
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final pages = const [
      JobsTab(),
      EarningsTab(),
      ProfileTab(),
      HelpTab(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
    );
  }
}
