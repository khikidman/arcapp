//
//  WorkoutView.swift
//  Arc
//
//  Created by Khi Kidman on 7/24/25.
//

import SwiftUI

struct WorkoutView: View {
    let workout: Workout

    var body: some View {
        List {
            Section("Details") {
                Text(workout.title)
                Text(workout.timestamp, format: .dateTime.month().day().year().hour().minute())

                if let volume = workout.volume {
                    Text("Volume: \(volume)")
                }
            }
        }
        .navigationTitle(workout.title)
    }
}

#Preview {
    NavigationStack {
        WorkoutView(workout: Workout())
    }
}
