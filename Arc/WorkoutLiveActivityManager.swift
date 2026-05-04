//
//  WorkoutLiveActivityManager.swift
//  Arc
//
//  Created by Codex on 5/3/26.
//

import ActivityKit
import Foundation

@MainActor
enum WorkoutLiveActivityManager {
    static func start(workoutID: String, startedAt: Date, indicator: WorkoutLiveActivityIndicator) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        Task {
            let attributes = WorkoutLiveActivityAttributes(workoutID: workoutID)
            let state = WorkoutLiveActivityAttributes.ContentState(
                indicator: indicator,
                startedAt: startedAt
            )

            if let activity = activity(for: workoutID) {
                await activity.update(ActivityContent(state: state, staleDate: nil))
                return
            }

            do {
                _ = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: nil
                )
            } catch {
                #if DEBUG
                print("Failed to start workout live activity: \(error.localizedDescription)")
                #endif
            }
        }
    }

    static func update(workoutID: String, startedAt: Date, indicator: WorkoutLiveActivityIndicator) {
        guard let activity = activity(for: workoutID) else {
            start(workoutID: workoutID, startedAt: startedAt, indicator: indicator)
            return
        }

        Task {
            let state = WorkoutLiveActivityAttributes.ContentState(
                indicator: indicator,
                startedAt: startedAt
            )
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    static func end(workoutID: String?) {
        let activities = Activity<WorkoutLiveActivityAttributes>.activities.filter { activity in
            guard let workoutID else { return true }
            return activity.attributes.workoutID == workoutID
        }

        for activity in activities {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    private static func activity(for workoutID: String) -> Activity<WorkoutLiveActivityAttributes>? {
        Activity<WorkoutLiveActivityAttributes>.activities.first {
            $0.attributes.workoutID == workoutID
        }
    }
}

extension WorkoutLiveActivityIndicator {
    init(exerciseKind: ExerciseKind) {
        switch exerciseKind {
        case .strength:
            self = .strength
        case .cardio:
            self = .cardio
        }
    }
}
