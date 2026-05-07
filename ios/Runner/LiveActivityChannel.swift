import Flutter
import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Bridges the Flutter `LiveTimerController` Dart class to ActivityKit.
///
/// Two methods are exposed on the channel `com.walhallaa.spygame/live_activity`:
///   - `start(roomCode:String, roundIndex:Int, totalRounds:Int,
///            endsAtMs:Int64, title:String, body:String)` — requests a
///     new Live Activity. If one is already active for a stale round, it
///     is ended first.
///   - `end()` — ends any active activities.
///
/// Failures are surfaced as FlutterError; the Dart side fails silently and
/// keeps the in-app countdown as the source of truth.
public final class LiveActivityChannel {
    public static let channelName = "com.walhallaa.spygame/live_activity"

    private let channel: FlutterMethodChannel

    public init(messenger: FlutterBinaryMessenger) {
        self.channel = FlutterMethodChannel(
            name: LiveActivityChannel.channelName,
            binaryMessenger: messenger
        )
        self.channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "start":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "bad_args", message: "Expected map", details: nil))
                return
            }
            startActivity(args: args, result: result)
        case "end":
            endAllActivities(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func startActivity(args: [String: Any], result: @escaping FlutterResult) {
        #if canImport(ActivityKit)
        guard #available(iOS 16.2, *) else {
            result(FlutterError(code: "unsupported_os",
                                message: "Live Activities require iOS 16.2+",
                                details: nil))
            return
        }
        guard let roomCode = args["roomCode"] as? String,
              let endsAtMs = (args["endsAtMs"] as? NSNumber)?.int64Value,
              let title = args["title"] as? String,
              let body = args["body"] as? String else {
            result(FlutterError(code: "bad_args",
                                message: "Missing required fields",
                                details: args))
            return
        }

        // Make sure ActivityKit is enabled by the user / system.
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            result(FlutterError(code: "disabled",
                                message: "Live Activities disabled by user",
                                details: nil))
            return
        }

        // End any stale activities first so we don't pile up.
        Task {
            for activity in Activity<RoundActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            do {
                let attributes = RoundActivityAttributes(roomCode: roomCode)
                let state = RoundActivityAttributes.ContentState(
                    endsAtMs: endsAtMs,
                    title: title,
                    subtitle: body,
                    endedLabel: ""
                )
                let staleDate = Date(timeIntervalSince1970: TimeInterval(endsAtMs) / 1000.0)
                    .addingTimeInterval(60)
                let content = ActivityContent(state: state, staleDate: staleDate)
                _ = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
                result(nil)
            } catch {
                result(FlutterError(code: "request_failed",
                                    message: error.localizedDescription,
                                    details: nil))
            }
        }
        #else
        result(FlutterError(code: "unsupported_platform",
                            message: "ActivityKit unavailable",
                            details: nil))
        #endif
    }

    private func endAllActivities(result: @escaping FlutterResult) {
        #if canImport(ActivityKit)
        guard #available(iOS 16.2, *) else {
            result(nil)
            return
        }
        Task {
            for activity in Activity<RoundActivityAttributes>.activities {
                let endedState = RoundActivityAttributes.ContentState(
                    endsAtMs: Int64(Date().timeIntervalSince1970 * 1000),
                    title: activity.content.state.title,
                    subtitle: activity.content.state.subtitle,
                    endedLabel: "Round ended"
                )
                let endContent = ActivityContent(
                    state: endedState,
                    staleDate: Date().addingTimeInterval(30)
                )
                await activity.end(endContent, dismissalPolicy: .after(.now + 30))
            }
            result(nil)
        }
        #else
        result(nil)
        #endif
    }
}
