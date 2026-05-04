//
//  ArcApp.swift
//  Arc
//
//  Created by Khi Kidman on 7/23/25.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct ArcApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Workout.self, Exercise.self, WorkoutSet.self])
    }
}
