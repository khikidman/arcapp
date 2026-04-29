//
//  WorkoutCardView.swift
//  Arc
//
//  Created by Khi Kidman on 7/24/25.
//

import SwiftUI

struct WorkoutCardView: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workout.title)
                .font(.headline)

            Text(workout.timestamp, format: .dateTime.month().day().year())
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let volume = workout.volume {
                Text("Volume: \(volume)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    WorkoutCardView(workout: Workout())
}
