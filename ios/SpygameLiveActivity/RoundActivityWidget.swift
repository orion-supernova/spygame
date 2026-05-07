import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
struct RoundActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RoundActivityAttributes.self) { context in
            // Lock Screen / banner UI.
            LockScreenView(context: context)
                .activityBackgroundTint(Color(.sRGB, red: 0.12, green: 0.12, blue: 0.13, opacity: 1.0))
                .activitySystemActionForegroundColor(Color(.sRGB, red: 0.78, green: 1.0, blue: 0.30, opacity: 1.0))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI — appears when the user long-presses the island
                // or the system promotes the activity.
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.attributes.roomCode)
                            .font(.system(.headline, design: .monospaced).weight(.semibold))
                    } icon: {
                        Image(systemName: "eye.trianglebadge.exclamationmark")
                            .foregroundStyle(Color(.sRGB, red: 0.78, green: 1.0, blue: 0.30, opacity: 1.0))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.endedLabel.isEmpty {
                        Text(timerInterval: Date()...context.state.endsAt,
                             countsDown: true,
                             showsHours: false)
                            .multilineTextAlignment(.trailing)
                            .font(.system(.title2, design: .monospaced).weight(.bold))
                            .foregroundStyle(Color(.sRGB, red: 0.78, green: 1.0, blue: 0.30, opacity: 1.0))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    } else {
                        Text(context.state.endedLabel)
                            .font(.system(.callout, design: .monospaced).weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.title)
                            .font(.system(.subheadline).weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(context.state.subtitle)
                            .font(.system(.caption))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: "eye.trianglebadge.exclamationmark")
                    .foregroundStyle(Color(.sRGB, red: 0.78, green: 1.0, blue: 0.30, opacity: 1.0))
            } compactTrailing: {
                if context.state.endedLabel.isEmpty {
                    Text(timerInterval: Date()...context.state.endsAt,
                         countsDown: true,
                         showsHours: false)
                        .monospacedDigit()
                        .frame(maxWidth: 56, alignment: .trailing)
                } else {
                    Text(verbatim: "—")
                        .monospaced()
                        .foregroundStyle(.secondary)
                }
            } minimal: {
                if context.state.endedLabel.isEmpty {
                    Text(timerInterval: Date()...context.state.endsAt,
                         countsDown: true,
                         showsHours: false)
                        .monospacedDigit()
                        .font(.caption2)
                } else {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.secondary)
                }
            }
            .keylineTint(Color(.sRGB, red: 0.78, green: 1.0, blue: 0.30, opacity: 1.0))
        }
    }
}

@available(iOS 16.2, *)
private struct LockScreenView: View {
    let context: ActivityViewContext<RoundActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "eye.trianglebadge.exclamationmark")
                        .font(.caption)
                        .foregroundStyle(Color(.sRGB, red: 0.78, green: 1.0, blue: 0.30, opacity: 1.0))
                    Text(context.attributes.roomCode)
                        .font(.system(.caption, design: .monospaced).weight(.semibold))
                        .tracking(2)
                        .foregroundStyle(.secondary)
                }
                Text(context.state.title)
                    .font(.system(.title3).weight(.semibold))
                    .foregroundStyle(.primary)
                Text(context.state.subtitle)
                    .font(.system(.caption))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 2) {
                if context.state.endedLabel.isEmpty {
                    Text(timerInterval: Date()...context.state.endsAt,
                         countsDown: true,
                         showsHours: false)
                        .font(.system(.largeTitle, design: .monospaced).weight(.bold))
                        .foregroundStyle(Color(.sRGB, red: 0.78, green: 1.0, blue: 0.30, opacity: 1.0))
                        .multilineTextAlignment(.trailing)
                        .monospacedDigit()
                } else {
                    Text(context.state.endedLabel)
                        .font(.system(.title3, design: .monospaced).weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
    }
}
