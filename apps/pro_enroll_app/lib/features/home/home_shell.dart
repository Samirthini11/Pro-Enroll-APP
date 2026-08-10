import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_config.dart';
import '../../core/i18n.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../services/kyc_preview_service.dart';
import '../../services/push_notification_service.dart';
import '../../state/app_state.dart';
import 'earnings_tab.dart';
import 'help_tab.dart';
import 'jobs_tab.dart';
import 'profile_tab.dart';
import 'wallet_tab.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> with WidgetsBindingObserver {
  Timer? _presenceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final pendingTab = PushNotificationService.pendingHomeTab;
    if (pendingTab != null && pendingTab >= 0 && pendingTab <= 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(homeShellTabProvider.notifier).state = pendingTab;
      });
      PushNotificationService.pendingHomeTab = null;
    }
    if (AppConfig.hasApi) {
      Future.microtask(() async {
        await ref.read(pushNotificationServiceProvider).markReadyAndFlush(
              authenticated: true,
            );
        unawaited(
          ref.read(pushNotificationServiceProvider).finishColdStartAndSyncToken(
                role: ref.read(roleProvider),
              ),
        );
        await ref.read(profileProvider.notifier).loadFromApi();
        final profile = ref.read(profileProvider);
        if (profile.isAvailable) {
          await ref.read(jobsProvider.notifier).refresh(
                profile.skills.map((s) => s.categoryCode).toList(),
              );
          _syncPresenceHeartbeat(true);
        }
        // Retry notification deep-link after home shell is mounted.
        await ref.read(pushNotificationServiceProvider).markReadyAndFlush(
              authenticated: true,
            );
        // Apply wallet tab after home is up (if push set it after first frame).
        final tab = PushNotificationService.pendingHomeTab;
        if (tab != null && mounted) {
          PushNotificationService.pendingHomeTab = null;
          ref.read(homeShellTabProvider.notifier).state = tab.clamp(0, 4);
          if (tab == 1) {
            ref.invalidate(earningsProvider);
            ref.invalidate(creditHistoryProvider);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presenceTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uninstall can't notify the server; heartbeat TTL hides stale online pros.
    // Resume → refresh presence immediately so they reappear in search.
    if (state == AppLifecycleState.resumed) {
      final available = ref.read(profileProvider).isAvailable;
      if (available) {
        unawaited(ref.read(profileProvider.notifier).pingPresence());
        _syncPresenceHeartbeat(true);
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Keep online while backgrounded briefly; TTL covers uninstall.
      // Still send one last heartbeat so short background doesn't expire early.
      if (ref.read(profileProvider).isAvailable) {
        unawaited(ref.read(profileProvider.notifier).pingPresence());
      }
    }
  }

  void _syncPresenceHeartbeat(bool online) {
    _presenceTimer?.cancel();
    if (!online || !AppConfig.hasApi) return;
    // Server TTL is 15 min; ping every 4 min while Jobs home is open.
    _presenceTimer = Timer.periodic(const Duration(minutes: 4), (_) {
      unawaited(ref.read(profileProvider.notifier).pingPresence());
    });
    unawaited(ref.read(profileProvider.notifier).pingPresence());
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(lProvider);
    final available = ref.watch(profileProvider.select((p) => p.isAvailable));
    final kycStatus = ref.watch(profileProvider.select((p) => p.kycStatus));
    final preview = ref.watch(kycPreviewUnlockedProvider);
    final showPendingBanner =
        preview && kycStatus == KycStatus.inReview;

    if (kycStatus.isVerified && preview) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        ref.read(kycPreviewUnlockedProvider.notifier).state = false;
        await KycPreviewService.clear();
      });
    }

    ref.listen<bool>(
      profileProvider.select((p) => p.isAvailable),
      (prev, next) {
        if (prev != next) _syncPresenceHeartbeat(next);
      },
    );

    // Ensure timer matches current availability on rebuild.
    if (available && _presenceTimer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncPresenceHeartbeat(true);
      });
    } else if (!available && _presenceTimer != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncPresenceHeartbeat(false);
      });
    }

    final pages = const [
      JobsTab(),
      WalletTab(),
      EarningsTab(),
      ProfileTab(),
      HelpTab(),
    ];
    final index = ref.watch(homeShellTabProvider).clamp(0, pages.length - 1);
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: ContentMaxWidth(
          child: Column(
            children: [
              if (showPendingBanner)
                Material(
                  color: const Color(0xFFFFF4E5),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.hourglass_top_rounded,
                          size: 18,
                          color: Color(0xFFB86E00),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.t('kyc.pending.banner'),
                            style: const TextStyle(
                              color: Color(0xFF8A5400),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: IndexedStack(index: index, children: pages),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) {
            ref.read(homeShellTabProvider.notifier).state = i;
            if (i == 1) {
              ref.invalidate(earningsProvider);
              ref.invalidate(creditHistoryProvider);
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.work_outline),
              selectedIcon: const Icon(Icons.work),
              label: l.t('home.tab.jobs'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: const Icon(Icons.account_balance_wallet),
              label: l.t('home.tab.wallet'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.payments_outlined),
              selectedIcon: const Icon(Icons.payments),
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
