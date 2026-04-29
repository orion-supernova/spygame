import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/lifecycle/app_lifecycle_observer.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class WhereAmIApp extends ConsumerWidget {
  const WhereAmIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return AppLifecycleHost(
      child: MaterialApp.router(
        title: 'Where am I?',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        routerConfig: router,
      ),
    );
  }
}
