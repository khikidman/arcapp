//
//  WorkoutLiveActivityAttributes.swift
//  ArcWorkoutLiveActivity
//
//  Created by Codex on 5/3/26.
//

import ActivityKit
import Foundation

struct WorkoutLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var indicator: WorkoutLiveActivityIndicator
        var startedAt: Date
    }

    let workoutID: String
}

enum WorkoutLiveActivityIndicator: String, Codable, Hashable {
    case strength
    case cardio

    var systemImage: String {
        switch self {
        case .strength:
            "dumbbell.fill"
        case .cardio:
            "figure.run"
        }
    }
}
