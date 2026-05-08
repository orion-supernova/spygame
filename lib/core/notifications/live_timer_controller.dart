import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../convex/convex_bootstrap.dart';
import 'push_token_service.dart';
import 'round_end_notifier.dart';

/// Cross-platform façade over the OS-native "live" round timer.
///
/// On iOS we drive a Live Activity (Lock Screen + Dynamic Island) via a
/// MethodChannel into the Widget Extension. On Android we post an ongoing
/// notification with a system chronometer counting down.
///
/// The countdown ticks autonomously on both platforms — we call [start] once
/// when the round becomes active and [end] once when it ends. No per-second
/// pushes.
class LiveTimerController {
  LiveTimerController._() {
    if (!kIsWeb && Platform.isIOS) {
      _iosChannel.setMethodCallHandler(_handleNativeCall);
    }
  }
  static final LiveTimerController instance = LiveTimerController._();

  static const _iosChannel = MethodChannel('com.walhallaa.spygame/live_activity');

  String? _activeRoundId;

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onLiveActivityPushToken') {
      final args = call.arguments;
      if (args is Map) {
        final roomCode = args['roomCode'] as String?;
        final token = args['token'] as String?;
        if (roomCode != null && token != null && token.isNotEmpty) {
          await PushTokenService.instance.onIosLiveActivityToken(
            roomCode: roomCode,
            token: token,
          );
        }
      }
      return null;
    }
    return null;
  }

  Future<void> start({
    required String roundId,
    required String roomCode,
    required int roundIndex,
    required int totalRounds,
    required int endsAtLocalMs,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    if (_activeRoundId == roundId) return;
    await _endNative();
    _activeRoundId = roundId;

    if (Platform.isAndroid) {
      await RoundEndNotifier.instance.showOngoingChronometer(
        endsAtLocalMs: endsAtLocalMs,
        title: title,
        body: body,
      );
    } else if (Platform.isIOS) {
      try {
        await _iosChannel.invokeMethod<void>('start', {
          'roomCode': roomCode,
          'roundIndex': roundIndex,
          'totalRounds': totalRounds,
          'endsAtMs': endsAtLocalMs,
          'title': title,
          'body': body,
        });
      } on PlatformException catch (e) {
        // iOS < 16.2, user disabled Live Activities, or APNs token issuance
        // failed (`no_push_token`). The in-app timer remains the source of
        // truth in all cases. For `no_push_token` specifically we report to
        // Convex so we can spot entitlement/APNs-config issues in production
        // — a silent fallback (the previous behavior) shipped Live
        // Activities the server could never update.
        debugPrint('Live Activity start failed: ${e.code} ${e.message}');
        if (e.code == 'no_push_token') {
          unawaited(_logLiveActivityFailure(
            code: e.code,
            message: e.message ?? '',
            roomCode: roomCode,
          ));
        }
      } on MissingPluginException {
        // Channel not registered (older build). Ignore.
      }
    }
  }

  Future<void> _logLiveActivityFailure({
    required String code,
    required String message,
    required String roomCode,
  }) async {
    if (!ConvexBootstrap.isInitialized) return;
    try {
      await ConvexBootstrap.client.mutation(
        name: 'diagnostics:logLiveActivityFailure',
        args: {
          'code': code,
          'message': message,
          'roomCode': roomCode,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[diagnostics] logLiveActivityFailure failed: $e');
      }
    }
  }

  Future<void> end() async {
    if (kIsWeb) return;
    if (_activeRoundId == null) return;
    _activeRoundId = null;
    await _endNative();
  }

  Future<void> _endNative() async {
    if (Platform.isAndroid) {
      await RoundEndNotifier.instance.cancelOngoingChronometer();
    } else if (Platform.isIOS) {
      try {
        await _iosChannel.invokeMethod<void>('end');
      } on PlatformException catch (e) {
        debugPrint('Live Activity end failed: ${e.code} ${e.message}');
      } on MissingPluginException {
        // Ignore.
      }
    }
  }
}

final liveTimerControllerProvider = Provider<LiveTimerController>(
  (_) => LiveTimerController.instance,
);
