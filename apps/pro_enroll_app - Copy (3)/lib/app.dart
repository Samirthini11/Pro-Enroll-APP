import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import 'core/theme.dart';

import 'routing/router.dart';

import 'services/push_notification_service.dart';

import 'state/app_state.dart';

import 'state/locale_state.dart';



class ProEnrollApp extends ConsumerStatefulWidget {

  const ProEnrollApp({super.key});



  @override

  ConsumerState<ProEnrollApp> createState() => _ProEnrollAppState();

}



class _ProEnrollAppState extends ConsumerState<ProEnrollApp> {

  @override

  void initState() {

    super.initState();

    PushNotificationService.onNavigate = (route, {extra}) {

      if (!mounted) return;

      ref.read(routerProvider).go(route, extra: extra);

    };

    Future.microtask(() async {
      await ref.read(pushNotificationServiceProvider).init();
      if (await ref.read(jwtTokenServiceProvider).hasTokenAsync()) {
        await ref.read(pushNotificationServiceProvider).syncTokenWithServer();
      }
    });

  }



  @override

  void dispose() {

    PushNotificationService.onNavigate = null;

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    final router = ref.watch(routerProvider);

    final locale = ref.watch(localeProvider);



    return MaterialApp.router(

      title: 'ProConnect',

      debugShowCheckedModeBanner: false,

      theme: AppTheme.light(),

      darkTheme: AppTheme.light(),

      themeMode: ThemeMode.light,

      routerConfig: router,

      locale: locale,

      supportedLocales: const [

        Locale('en'),

        Locale('ta'),

      ],

      localizationsDelegates: const [

        GlobalMaterialLocalizations.delegate,

        GlobalWidgetsLocalizations.delegate,

        GlobalCupertinoLocalizations.delegate,

      ],

    );

  }

}

