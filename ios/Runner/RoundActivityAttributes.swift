import Foundation
#if canImport(ActivityKit)
import ActivityKit

/// Shared attributes for the round-timer Live Activity.
///
/// This file is compiled into BOTH the Runner target (so the main app can
/// call `Activity<RoundActivityAttributes>.request(...)`) and the
/// SpygameLiveActivity widget extension target (so the widget can render
/// the activity). Keep the type and field names byte-identical between
/// targets — `ActivityAttributes` matches across the IPC boundary by
/// fully-qualified type name.
@available(iOS 16.2, *)
public struct RoundActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Server-aligned wall-clock time the round ends, in epoch
        /// milliseconds (already adjusted for client/server clock skew on
        /// the Dart side before the Activity is requested).
        public var endsAtMs: Int64
        /// Localized title, e.g. "Round 2 of 5".
        public var title: String
        /// Localized subtitle, e.g. "Where am I? · ABCD".
        public var subtitle: String
        /// Localized "round ended" string, swapped in for the final 30s
        /// before dismissal. Empty while the round is in progress.
        public var endedLabel: String

        public init(
            endsAtMs: Int64,
            title: String,
            subtitle: String,
            endedLabel: String
        ) {
            self.endsAtMs = endsAtMs
            self.title = title
            self.subtitle = subtitle
            self.endedLabel = endedLabel
        }

        public var endsAt: Date {
            Date(timeIntervalSince1970: TimeInterval(endsAtMs) / 1000.0)
        }
    }

    public var roomCode: String

    public init(roomCode: String) {
        self.roomCode = roomCode
    }
}
#endif
