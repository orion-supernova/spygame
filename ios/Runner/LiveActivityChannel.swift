import Flutter
import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Bridges the Flutter `LiveTimerController` Dart class to ActivityKit.
///
/// Methods exposed on the channel `com.walhallaa.spygame/live_activity`:
///   - `start(roomCode:String, roundIndex:Int, totalRounds:Int,
///            endsAtMs:Int64, title:String, body:String)` — requests a
///     new Live Activity. If one is already active for a stale round, it
///     is ended first.
///   - `end()` — ends any active activities.
///
/// Reverse calls (Swift → Dart) on the same channel:
///   - `onLiveActivityPushToken(roomCode:String, token:String)` — emitted
///     each time ActivityKit produces a push token for the running
///     activity. Sent on every emission of `pushTokenUpdates` (iOS may
///     rotate tokens mid-activity); the Dart side forwards to Convex.
///
/// Failures are surfaced as FlutterError; the Dart side fails silently and
/// keeps the in-app countdown as the source of truth.
public final class LiveActivityChannel {
    public static let channelName = "com.walhallaa.spygame/live_activity"

    private let channel: FlutterMethodChannel
    private var pushTokenStreamTask: Task<Void, Never>?

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
        case "update":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "bad_args", message: "Expected map", details: nil))
                return
            }
            updateActivity(args: args, result: result)
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

        // Cancel any prior token stream — it belongs to a stale activity.
        pushTokenStreamTask?.cancel()
        pushTokenStreamTask = nil

        Task { [weak self] in
            // End any stale activities first so we don't pile up.
            for activity in Activity<RoundActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
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

            // Require `pushType: .token` — the server-driven round-end update
            // path depends on it. We deliberately do NOT silently fall back
            // to `pushType: nil` here: that path leaves the activity visible
            // but un-updatable, and the failure was previously invisible to
            // both the user and our telemetry. Surface the error to Dart
            // (`no_push_token`) so it can be logged via Convex diagnostics
            // and we can fix the entitlement / APNs misconfiguration.
            do {
                let activity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: .token
                )
                self?.observePushTokenUpdates(for: activity, roomCode: roomCode)
                result(nil)
            } catch {
                NSLog("[LiveActivity] .token request failed: %@", "\(error)")
                result(FlutterError(code: "no_push_token",
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

    #if canImport(ActivityKit)
    @available(iOS 16.2, *)
    private func observePushTokenUpdates(
        for activity: Activity<RoundActivityAttributes>,
        roomCode: String
    ) {
        pushTokenStreamTask?.cancel()
        // `pushTokenUpdates` is an async sequence — iOS may rotate the
        // token mid-activity (rare but documented). Forward every emission
        // to Dart so the server always has the freshest token.
        pushTokenStreamTask = Task { [weak self] in
            for await tokenData in activity.pushTokenUpdates {
                if Task.isCancelled { return }
                let hex = tokenData.map { String(format: "%02x", $0) }.joined()
                await MainActor.run { [weak self] in
                    self?.channel.invokeMethod(
                        "onLiveActivityPushToken",
                        arguments: [
                            "roomCode": roomCode,
                            "token": hex,
                        ]
                    )
                }
            }
        }
    }
    #endif

    private func updateActivity(args: [String: Any], result: @escaping FlutterResult) {
        #if canImport(ActivityKit)
        guard #available(iOS 16.2, *) else {
            result(nil)
            return
        }
        guard let endsAtMs = (args["endsAtMs"] as? NSNumber)?.int64Value,
              let title = args["title"] as? String,
              let body = args["body"] as? String else {
            result(FlutterError(code: "bad_args",
                                message: "Missing required fields",
                                details: args))
            return
        }
        let endedLabel = (args["endedLabel"] as? String) ?? ""
        Task {
            for activity in Activity<RoundActivityAttributes>.activities {
                let newState = RoundActivityAttributes.ContentState(
                    endsAtMs: endsAtMs,
                    title: title,
                    subtitle: body,
                    endedLabel: endedLabel
                )
                let staleDate = Date(timeIntervalSince1970: TimeInterval(endsAtMs) / 1000.0)
                    .addingTimeInterval(60)
                let content = ActivityContent(state: newState, staleDate: staleDate)
                await activity.update(content)
            }
            result(nil)
        }
        #else
        result(nil)
        #endif
    }

    private func endAllActivities(result: @escaping FlutterResult) {
        #if canImport(ActivityKit)
        guard #available(iOS 16.2, *) else {
            result(nil)
            return
        }
        pushTokenStreamTask?.cancel()
        pushTokenStreamTask = nil
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
