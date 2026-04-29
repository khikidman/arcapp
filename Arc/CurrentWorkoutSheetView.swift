//
//  CurrentWorkoutSheetView.swift
//  Arc
//
//  Created by Codex on 8/2/25.
//

import SwiftUI
import SwiftData

struct CurrentWorkoutSheetView: View {
    @Bindable var workout: Workout
    let onClose: () -> Void
    let onOpenWorkout: () -> Void
    @State private var showAddExerciseSheet = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay {
                    Color.black.opacity(0.75)
                }
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                ZStack {
                    WorkoutSheetTimer(startDate: workout.timestamp)

                    HStack {
                        Button() {
                            onClose()
                        } label: {
                            Text("Cancel")
                                .padding(6)
                        }
                        .font(.body.weight(.medium))
                        .foregroundStyle(.red)
                        .buttonStyle(.glass)

                        Spacer()

                        Button {
                            onOpenWorkout()
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(6)
                        }
                        .tint(.cyan)
                        .clipShape(.circle)
                        .buttonStyle(.glassProminent)
                    }
                }

                VStack(spacing: 8) {
                    Text(workout.title)
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Label(
                        workout.timestamp.formatted(.dateTime.month().day().year().hour().minute()),
                        systemImage: "calendar"
                    )
                    .foregroundStyle(.secondary)

                    if let volume = workout.volume {
                        Label("\(volume) lbs", systemImage: "scalemass")
                            .font(.headline)
                    }
                }

                if workout.exercises.isEmpty {
                    ContentUnavailableView(
                        "No Exercises Yet",
                        systemImage: "dumbbell",
                        description: Text("Tap the plus button to add an exercise.")
                    )
                } else {
                    List {
                        ForEach(workout.exercises, id: \.persistentModelID) { exercise in
                            ExerciseListItemView(
                                exercise: exercise,
                                onDelete: {
                                    if let index = workout.exercises.firstIndex(where: {
                                        $0.persistentModelID == exercise.persistentModelID
                                    }) {
                                        workout.exercises.remove(at: index)
                                    }
                                }
                            )
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .deleteDisabled(true)
                            .padding(.vertical, 6)
                            .ignoresSafeArea()
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .frame(maxHeight: .infinity)
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showAddExerciseSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.bold))
                        .padding(10)
                        .foregroundStyle(.white)
                }
                .tint(.cyan)
                .clipShape(.circle)
                .buttonStyle(.glassProminent)
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showAddExerciseSheet) {
            NavigationStack {
                AddExerciseView()
                    .navigationTitle("Add Exercise")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            seedTestExerciseIfNeeded()
        }
    }

    private func seedTestExerciseIfNeeded() {
        guard workout.exercises.isEmpty else { return }

        workout.exercises.append(
            Exercise(
                name: "Incline Dumbbell Press",
                sets: [
                    WorkoutSet(reps: 10, weight: 60),
                    WorkoutSet(reps: 8, weight: 65),
                    WorkoutSet(reps: 8, weight: 65)
                ]
            )
        )
    }
}

private struct WorkoutSheetTimer: View {
    let startDate: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(elapsedTimeString(at: context.date))
                .frame(maxWidth: .infinity)
        }
    }

    private func elapsedTimeString(at currentDate: Date) -> String {
        let elapsed = max(Int(currentDate.timeIntervalSince(startDate)), 0)
        let hours = elapsed / 3600
        let minutes = (elapsed % 3600) / 60
        let seconds = elapsed % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

#Preview {
    CurrentWorkoutSheetView(
        workout: Workout(),
        onClose: {},
        onOpenWorkout: {}
    )
}
