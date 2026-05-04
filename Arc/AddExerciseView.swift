//
//  AddExerciseView.swift
//  Arc
//
//  Created by Khi Kidman on 8/11/25.
//

import SwiftUI

struct AddExerciseView: View {
    let onAddExercise: (ExerciseTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedExercise: ExerciseTemplate?

    var body: some View {
        List {
            ForEach(filteredExerciseGroups) { group in
                Section(group.name) {
                    ForEach(group.exercises) { exercise in
                        HStack(spacing: 12) {
                            Button {
                                selectedExercise = exercise
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.cyan)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)

                            Button {
                                onAddExercise(exercise)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(exercise.name)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.white)

                                    Spacer()

                                    Image(systemName: "plus")
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(.cyan)
                                        .frame(width: 44, height: 44)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .contentShape(Rectangle())
                        .listRowBackground(Color.clear)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search exercises")
        .sheet(item: $selectedExercise) { exercise in
            ExerciseInfoCard(exercise: exercise)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var filteredExerciseGroups: [ExerciseGroup] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return exerciseGroups
        }

        return exerciseGroups.compactMap { group in
            let matchingExercises = group.exercises.filter {
                $0.name.localizedStandardContains(query)
            }

            guard !matchingExercises.isEmpty else {
                return nil
            }

            return ExerciseGroup(name: group.name, exercises: matchingExercises)
        }
    }
}

private struct ExerciseInfoCard: View {
    let exercise: ExerciseTemplate
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(exercise.groupName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.cyan)

                        Text(exercise.name)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Instructions")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(exercise.instructions)
                        .font(.body)
                        .lineSpacing(5)
                        .foregroundStyle(.white.opacity(0.82))
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(.white.opacity(0.14), lineWidth: 1)
                        )
                )

                Spacer(minLength: 0)
            }
            .padding(22)
        }
    }
}

struct ExerciseTemplate: Identifiable, Hashable {
    let name: String
    let groupName: String
    let kind: ExerciseKind
    let instructions: String

    var id: String { name }
}

extension ExerciseTemplate {
    init(_ name: String, groupName: String) {
        self.name = name
        self.groupName = groupName
        self.kind = groupName == "Cardio" ? .cardio : .strength
        self.instructions = Self.exerciseInstructions(for: name, groupName: groupName)
    }

    private static func exerciseInstructions(for name: String, groupName: String) -> String {
        switch groupName {
        case "Cardio":
            return "Start at an easy pace for a few minutes, then settle into a steady rhythm you can maintain. Keep your posture tall, breathe consistently, and slow down gradually before stopping."
        case "Core":
            return "Brace your midsection before each rep and move with control. Keep your ribs stacked over your hips, avoid pulling with your neck, and stop the set when your form starts to shift."
        default:
            return "Set up with a stable stance and brace before the first rep. Move through a controlled range of motion, keep tension on the target muscle, and finish each rep without bouncing or rushing."
        }
    }
}

private struct ExerciseGroup: Identifiable {
    let name: String
    let exercises: [ExerciseTemplate]

    var id: String { name }

    init(name: String, exercises: [ExerciseTemplate]) {
        self.name = name
        self.exercises = exercises
    }

    init(name: String, exerciseNames: [String]) {
        self.name = name
        self.exercises = exerciseNames.map { ExerciseTemplate($0, groupName: name) }
    }
}

private let exerciseGroups: [ExerciseGroup] = [
    ExerciseGroup(
        name: "Chest",
        exerciseNames: [
            "Bench Press",
            "Incline Dumbbell Press",
            "Chest Fly",
            "Push-Up",
            "Cable Crossover"
        ]
    ),
    ExerciseGroup(
        name: "Back",
        exerciseNames: [
            "Pull-Up",
            "Lat Pulldown",
            "Barbell Row",
            "Seated Cable Row",
            "Single-Arm Dumbbell Row"
        ]
    ),
    ExerciseGroup(
        name: "Shoulders",
        exerciseNames: [
            "Overhead Press",
            "Dumbbell Shoulder Press",
            "Lateral Raise",
            "Rear Delt Fly",
            "Face Pull"
        ]
    ),
    ExerciseGroup(
        name: "Biceps",
        exerciseNames: [
            "Barbell Curl",
            "Dumbbell Curl",
            "Hammer Curl",
            "Preacher Curl",
            "Cable Curl"
        ]
    ),
    ExerciseGroup(
        name: "Triceps",
        exerciseNames: [
            "Triceps Pushdown",
            "Skull Crusher",
            "Overhead Triceps Extension",
            "Close-Grip Bench Press",
            "Bench Dip"
        ]
    ),
    ExerciseGroup(
        name: "Legs",
        exerciseNames: [
            "Back Squat",
            "Leg Press",
            "Romanian Deadlift",
            "Walking Lunge",
            "Leg Extension"
        ]
    ),
    ExerciseGroup(
        name: "Core",
        exerciseNames: [
            "Plank",
            "Hanging Leg Raise",
            "Cable Crunch",
            "Russian Twist",
            "Dead Bug"
        ]
    ),
    ExerciseGroup(
        name: "Cardio",
        exerciseNames: [
            "Treadmill Run",
            "Stationary Bike",
            "Elliptical",
            "Rowing Machine",
            "Stair Climber"
        ]
    )
]

#Preview {
    NavigationStack {
        AddExerciseView(onAddExercise: { _ in })
            .navigationTitle("Add Exercise")
    }
}
