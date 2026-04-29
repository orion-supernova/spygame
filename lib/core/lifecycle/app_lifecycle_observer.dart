import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../convex/server_time_provider.dart';

/// Wraps the app and translates [AppLifecycleState] into Riverpod state plus
/// side effects (recompute server-time offset on resume, etc).
class AppLifecycleHost extends ConsumerStatefulWidget {
  const AppLifecycleHost({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppLifecycleHost> createState() => _AppLifecycleHostState();
}

class _AppLifecycleHostState extends ConsumerState<AppLifecycleHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLifecycleProvider.notifier).state = state;
    if (state == AppLifecycleState.resumed) {
      // Refresh server-clock offset on every resume so the countdown re-syncs.
      // ignore: discarded_futures
      ref.read(serverTimeOffsetProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

final appLifecycleProvider =
    StateProvider<AppLifecycleState>((_) => AppLifecycleState.resumed);
