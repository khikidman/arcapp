//
//  AddExerciseView.swift
//  Arc
//
//  Created by Khi Kidman on 8/11/25.
//

import SwiftUI

struct AddExerciseView: View {
    let onAddExercise: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(exerciseGroups) { group in
                Section(group.name) {
                    ForEach(group.exercises, id: \.self) { exercise in
                        Button {
                            onAddExercise(exercise)
                            dismiss()
                        } label: {
                            HStack {
                                Text(exercise)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.cyan)
                            }
                            .contentShape(Rectangle())
                        }
                    }
                }
            }
        }
    }
}

private struct ExerciseGroup: Identifiable {
    let name: String
    let exercises: [String]

    var id: String { name }
}

private let exerciseGroups: [ExerciseGroup] = [
    ExerciseGroup(
        name: "Chest",
        exercises: [
            "Bench Press",
            "Incline Dumbbell Press",
            "Chest Fly",
            "Push-Up",
            "Cable Crossover"
        ]
    ),
    ExerciseGroup(
        name: "Back",
        exercises: [
            "Pull-Up",
            "Lat Pulldown",
            "Barbell Row",
            "Seated Cable Row",
            "Single-Arm Dumbbell Row"
        ]
    ),
    ExerciseGroup(
        name: "Shoulders",
        exercises: [
            "Overhead Press",
            "Dumbbell Shoulder Press",
            "Lateral Raise",
            "Rear Delt Fly",
            "Face Pull"
        ]
    ),
    ExerciseGroup(
        name: "Biceps",
        exercises: [
            "Barbell Curl",
            "Dumbbell Curl",
            "Hammer Curl",
            "Preacher Curl",
            "Cable Curl"
        ]
    ),
    ExerciseGroup(
        name: "Triceps",
        exercises: [
            "Triceps Pushdown",
            "Skull Crusher",
            "Overhead Triceps Extension",
            "Close-Grip Bench Press",
            "Bench Dip"
        ]
    ),
    ExerciseGroup(
        name: "Legs",
        exercises: [
            "Back Squat",
            "Leg Press",
            "Romanian Deadlift",
            "Walking Lunge",
            "Leg Extension"
        ]
    ),
    ExerciseGroup(
        name: "Core",
        exercises: [
            "Plank",
            "Hanging Leg Raise",
            "Cable Crunch",
            "Russian Twist",
            "Dead Bug"
        ]
    )
]

#Preview {
    NavigationStack {
        AddExerciseView(onAddExercise: { _ in })
            .navigationTitle("Add Exercise")
    }
}
