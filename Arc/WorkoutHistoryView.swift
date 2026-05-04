//
//  WorkoutHistoryView.swift
//  Arc
//
//  Created by Khi Kidman on 8/1/25.
//

import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Query(sort: \Workout.timestamp, order: .reverse) private var workouts: [Workout]

    var body: some View {
        List {
            if completedWorkouts.isEmpty {
                ContentUnavailableView(
                    "No Workout History",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Completed workouts will appear here after they are saved.")
                )
                .listRowBackground(Color.clear)
            } else {
                Section("Summary") {
                    HistorySummaryRow(
                        title: "Workouts",
                        value: "\(completedWorkouts.count)",
                        systemImage: "dumbbell"
                    )

                    HistorySummaryRow(
                        title: "Strength Volume",
                        value: totalVolume.formatted(),
                        systemImage: "scalemass"
                    )

                    HistorySummaryRow(
                        title: "Cardio Sessions",
                        value: "\(cardioSessionCount)",
                        systemImage: "figure.run"
                    )
                }

                Section("Recent") {
                    ForEach(completedWorkouts) { workout in
                        NavigationLink {
                            WorkoutView(workout: workout)
                        } label: {
                            WorkoutHistoryRow(workout: workout)
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var totalVolume: Int {
        completedWorkouts.reduce(0) { $0 + $1.strengthVolume }
    }

    private var cardioSessionCount: Int {
        completedWorkouts.reduce(0) { count, workout in
            count + workout.exercises.filter { $0.kind == .cardio }.count
        }
    }

    private var completedWorkouts: [Workout] {
        workouts.filter(\.isCompleted)
    }
}

#Preview {
    NavigationStack {
        WorkoutHistoryView()
    }
    .modelContainer(for: [Workout.self, Exercise.self, WorkoutSet.self], inMemory: true)
}

private struct HistorySummaryRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        Label {
            HStack {
                Text(title)
                Spacer()
                Text(value)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.cyan)
        }
    }
}

private struct WorkoutHistoryRow: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.title)
                    .font(.headline)

                Spacer()

                Text(workout.timestamp, format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Label("\(workout.exercises.count)", systemImage: "list.bullet")

                if workout.strengthVolume > 0 {
                    Label(workout.strengthVolume.formatted(), systemImage: "scalemass")
                }

                if workout.exercises.contains(where: { $0.kind == .cardio }) {
                    Label("Cardio", systemImage: "figure.run")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
