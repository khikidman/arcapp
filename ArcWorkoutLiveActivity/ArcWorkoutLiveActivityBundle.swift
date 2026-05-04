//
//  ArcWorkoutLiveActivityBundle.swift
//  ArcWorkoutLiveActivity
//
//  Created by Codex on 5/3/26.
//

import ActivityKit
import SwiftUI
import WidgetKit

@main
struct ArcWorkoutLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivityWidget()
    }
}

private struct WorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutLiveActivityAttributes.self) { context in
            WorkoutLiveActivityLockScreenView(context: context)
                .activityBackgroundTint(.black.opacity(0.86))
                .activitySystemActionForegroundColor(.cyan)
                .widgetURL(URL(string: "arc://workout"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    WorkoutActivityIcon(indicator: context.state.indicator)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    WorkoutActivityTimer(startedAt: context.state.startedAt)
                }
            } compactLeading: {
                WorkoutActivityIcon(indicator: context.state.indicator, size: .compact)
            } compactTrailing: {
                WorkoutActivityTimer(startedAt: context.state.startedAt, size: .compact)
            } minimal: {
                WorkoutActivityIcon(indicator: context.state.indicator, size: .minimal)
            }
            .widgetURL(URL(string: "arc://workout"))
        }
    }
}

private struct WorkoutLiveActivityLockScreenView: View {
    let context: ActivityViewContext<WorkoutLiveActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            WorkoutActivityIcon(indicator: context.state.indicator)

            Text("Workout Active")
                .font(.headline.weight(.semibold))

            Spacer()

            WorkoutActivityTimer(startedAt: context.state.startedAt)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct WorkoutActivityIcon: View {
    enum Size {
        case regular
        case compact
        case minimal
    }

    let indicator: WorkoutLiveActivityIndicator
    var size: Size = .regular

    var body: some View {
        Image(systemName: indicator.systemImage)
            .font(font)
            .foregroundStyle(.cyan)
            .frame(width: frameSize, height: frameSize)
    }

    private var font: Font {
        switch size {
        case .regular:
            .title3.weight(.semibold)
        case .compact:
            .caption.weight(.bold)
        case .minimal:
            .caption2.weight(.bold)
        }
    }

    private var frameSize: CGFloat {
        switch size {
        case .regular:
            28
        case .compact:
            18
        case .minimal:
            14
        }
    }
}

private struct WorkoutActivityTimer: View {
    enum Size {
        case regular
        case compact
    }

    let startedAt: Date
    var size: Size = .regular

    var body: some View {
        Group {
            switch size {
            case .regular:
                Text(timerInterval: startedAt...Date.distantFuture, countsDown: false)
            case .compact:
                Text(
                    timerInterval: startedAt...Date.distantFuture,
                    pauseTime: nil,
                    countsDown: false,
                    showsHours: false
                )
            }
        }
        .font(font.monospacedDigit())
        .foregroundStyle(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: maxWidth, alignment: .trailing)
        .multilineTextAlignment(.trailing)
    }

    private var font: Font {
        switch size {
        case .regular:
            .headline.weight(.semibold)
        case .compact:
            .caption2.weight(.bold)
        }
    }

    private var maxWidth: CGFloat? {
        switch size {
        case .regular:
            nil
        case .compact:
            34
        }
    }
}
