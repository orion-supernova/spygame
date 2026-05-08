import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/lifecycle/app_lifecycle_observer.dart';
import 'core/providers/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';

class WhereAmIApp extends ConsumerStatefulWidget {
  const WhereAmIApp({super.key});

  @override
  ConsumerState<WhereAmIApp> createState() => _WhereAmIAppState();
}

class _WhereAmIAppState extends ConsumerState<WhereAmIApp> {
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    // app_links is a no-op on web (the URL is already the route), but on
    // iOS/Android we need to forward incoming Universal/App Links into the
    // router so the app navigates to the join screen.
    if (kIsWeb) return;
    _appLinks = AppLinks();
    // ignore: discarded_futures
    _appLinks!.getInitialLink().then(_handle);
    _linkSub = _appLinks!.uriLinkStream.listen(_handle);
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  void _handle(Uri? uri) {
    if (uri == null) return;
    final segs = uri.pathSegments;
    if (segs.length < 2) return;
    final code = segs[1].toUpperCase();
    if (code.isEmpty) return;
    // Both /join/CODE and /lobby/CODE links route through /join so the
    // user always confirms their codename before being added to the room.
    if (segs[0] == 'join' || segs[0] == 'lobby') {
      ref.read(routerProvider).go(AppRoute.joinFor(code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    return AppLifecycleHost(
      child: MaterialApp.router(
        title: 'Where am I?',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    );
  }
}
