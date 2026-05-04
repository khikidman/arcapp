//
//  WorkoutView.swift
//  Arc
//
//  Created by Khi Kidman on 7/24/25.
//

import SwiftUI

struct WorkoutView: View {
    @Bindable var workout: Workout

    var body: some View {
        List {
            Section("Details") {
                TextField("Workout title", text: $workout.title)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)

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
