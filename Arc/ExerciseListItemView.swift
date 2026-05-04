//
//  ExerciseListItemView.swift
//  Arc
//
//  Created by Khi Kidman on 7/29/25.
//

import SwiftUI
import SwiftData

struct ExerciseListItemView: View {
    @Bindable var exercise: Exercise
    var onActivityChanged: () -> Void = {}
    var onDelete: () -> Void
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    // Chevron (LEFT)
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                isExpanded.toggle()
                            }
                        }
                    
//                    Spacer()

                    // Title (CENTER / FLEX)
                    Text(exercise.name)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    // Menu (RIGHT)
                    Menu {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete Exercise", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.cyan)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.black.opacity(0.5))
                            )
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        isExpanded.toggle()
                    }
                }
            }
            .buttonStyle(.plain)

//            Divider()
//                .overlay(.white.opacity(0.15))

            if isExpanded {
                if exercise.kind == .cardio {
                    CardioExerciseMetricsView(
                        exercise: exercise,
                        onActivityChanged: onActivityChanged
                    )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    VStack(spacing: 12) {
                        List {
                            ForEach(Array(exercise.sets.enumerated()), id: \.element.persistentModelID) { index, workoutSet in
                                ExerciseListItemSetView(
                                    workoutSet: workoutSet,
                                    setIndex: index,
                                    onActivityChanged: onActivityChanged
                                )
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .padding(.bottom, 4)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteSet(workoutSet)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .frame(height: CGFloat(exercise.sets.count) * 50)

                        Button {
                            addSet()
                        } label: {
                            Image(systemName: "plus")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.cyan)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    private func deleteSet(_ set: WorkoutSet) {
        exercise.sets.removeAll {
            $0.persistentModelID == set.persistentModelID
        }
    }

    private func addSet() {
        onActivityChanged()

        if let lastSet = exercise.sets.last {
            exercise.sets.append(
                WorkoutSet(reps: lastSet.reps, weight: lastSet.weight)
            )
            return
        }

        exercise.sets.append(WorkoutSet(reps: 0, weight: nil))
    }
}

private struct CardioExerciseMetricsView: View {
    @Bindable var exercise: Exercise
    let onActivityChanged: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cardio")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                metricField("min", text: durationMinutesText, keyboardType: .numberPad)
                metricField("mi", text: distanceText, keyboardType: .decimalPad)
                metricField("cal", text: caloriesText, keyboardType: .numberPad)
            }
        }
    }

    private func metricField(
        _ placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType
    ) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboardType)
            .textFieldStyle(.plain)
            .padding(.horizontal, 10)
            .frame(height: 38)
            .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var durationMinutesText: Binding<String> {
        Binding(
            get: {
                guard let seconds = exercise.cardioDurationSeconds, seconds > 0 else { return "" }
                return String(seconds / 60)
            },
            set: { newValue in
                onActivityChanged()

                if let minutes = Int(newValue) {
                    exercise.cardioDurationSeconds = minutes * 60
                } else if newValue.isEmpty {
                    exercise.cardioDurationSeconds = nil
                }
            }
        )
    }

    private var distanceText: Binding<String> {
        Binding(
            get: {
                guard let distance = exercise.cardioDistance else { return "" }
                return distance.formatted(.number.precision(.fractionLength(0...2)))
            },
            set: { newValue in
                onActivityChanged()

                if let distance = Double(newValue) {
                    exercise.cardioDistance = distance
                } else if newValue.isEmpty {
                    exercise.cardioDistance = nil
                }
            }
        )
    }

    private var caloriesText: Binding<String> {
        Binding(
            get: { exercise.cardioCalories.map(String.init) ?? "" },
            set: { newValue in
                onActivityChanged()

                if let calories = Int(newValue) {
                    exercise.cardioCalories = calories
                } else if newValue.isEmpty {
                    exercise.cardioCalories = nil
                }
            }
        )
    }
}

#Preview {
    ExerciseListItemView(
        exercise: Exercise(
            name: "Bench Press",
            sets: [
                WorkoutSet(reps: 8, weight: 135),
                WorkoutSet(reps: 6, weight: 155)
            ]
        ),
        onDelete: {}
    )
}
