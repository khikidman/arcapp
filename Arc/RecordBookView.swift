//
//  RecordBookView.swift
//  Arc
//
//  Created by Codex on 5/3/26.
//

import SwiftUI
import SwiftData

struct RecordBookView: View {
    @Query(sort: \Workout.timestamp, order: .reverse) private var workouts: [Workout]
    @AppStorage("settings.weightUnit") private var weightUnit = "lb"
    @State private var searchText = ""

    var body: some View {
        List {
            if filteredStrengthRecords.isEmpty && filteredCardioRecords.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "No Records Yet" : "No Matching Records",
                    systemImage: "trophy",
                    description: Text(searchText.isEmpty ? "Strength PRs and cardio bests will appear after workouts are saved." : "Try a different exercise name.")
                )
                .listRowBackground(Color.clear)
            } else {
                if !filteredStrengthRecords.isEmpty {
                    Section("Strength") {
                        ForEach(filteredStrengthRecords) { record in
                            NavigationLink {
                                ExerciseRecordHistoryView(
                                    exerciseName: record.exerciseName,
                                    kind: .strength,
                                    entries: entries(for: record.exerciseName, kind: .strength),
                                    weightUnit: weightUnit
                                )
                            } label: {
                                StrengthRecordRow(record: record, weightUnit: weightUnit)
                            }
                        }
                    }
                }

                if !filteredCardioRecords.isEmpty {
                    Section("Cardio") {
                        ForEach(filteredCardioRecords) { record in
                            NavigationLink {
                                ExerciseRecordHistoryView(
                                    exerciseName: record.exerciseName,
                                    kind: .cardio,
                                    entries: entries(for: record.exerciseName, kind: .cardio),
                                    weightUnit: weightUnit
                                )
                            } label: {
                                CardioRecordRow(record: record)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Record Book")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search records")
    }

    private var recordBook: LocalRecordBook {
        LocalRecordBook(workouts: workouts.filter(\.isCompleted))
    }

    private var strengthRecords: [StrengthRecord] {
        recordBook.strengthRecords
    }

    private var cardioRecords: [CardioRecord] {
        recordBook.cardioRecords
    }

    private var filteredStrengthRecords: [StrengthRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return strengthRecords }
        return strengthRecords.filter { $0.exerciseName.localizedStandardContains(query) }
    }

    private var filteredCardioRecords: [CardioRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return cardioRecords }
        return cardioRecords.filter { $0.exerciseName.localizedStandardContains(query) }
    }

    private func entries(for exerciseName: String, kind: ExerciseKind) -> [ExerciseRecordEntry] {
        allEntries
            .filter { $0.exerciseName == exerciseName && $0.kind == kind }
            .sorted { lhs, rhs in
                if lhs.volume != rhs.volume {
                    return lhs.volume > rhs.volume
                }

                if lhs.cardioScore != rhs.cardioScore {
                    return lhs.cardioScore > rhs.cardioScore
                }

                return lhs.date > rhs.date
            }
    }

    private var allEntries: [ExerciseRecordEntry] {
        workouts
            .filter(\.isCompleted)
            .flatMap { workout in
                workout.exercises.flatMap { exercise in
                    switch exercise.kind {
                    case .strength:
                        return exercise.sets.enumerated().map { index, set in
                            ExerciseRecordEntry(
                                id: "\(workout.id.uuidString)-\(exercise.id.uuidString)-\(index)",
                                exerciseName: exercise.name,
                                kind: .strength,
                                workoutTitle: workout.title,
                                date: workout.timestamp,
                                weight: set.weight,
                                reps: set.reps,
                                volume: set.volume,
                                durationSeconds: nil,
                                distance: nil,
                                calories: nil
                            )
                        }
                    case .cardio:
                        return [
                            ExerciseRecordEntry(
                                id: "\(workout.id.uuidString)-\(exercise.id.uuidString)",
                                exerciseName: exercise.name,
                                kind: .cardio,
                                workoutTitle: workout.title,
                                date: workout.timestamp,
                                weight: nil,
                                reps: nil,
                                volume: 0,
                                durationSeconds: exercise.cardioDurationSeconds,
                                distance: exercise.cardioDistance,
                                calories: exercise.cardioCalories
                            )
                        ]
                    }
                }
            }
    }
}

private struct StrengthRecordRow: View {
    let record: StrengthRecord
    let weightUnit: String

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(record.exerciseName)
                    .font(.headline)

                Text(record.muscleGroup ?? "Strength")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(record.weight) \(weightUnit) x \(record.reps)")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.cyan)

                Text(record.date, format: .dateTime.month(.abbreviated).day().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct CardioRecordRow: View {
    let record: CardioRecord

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(record.exerciseName)
                    .font(.headline)

                Text(record.muscleGroup ?? "Cardio")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(record.primaryValue)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.cyan)

                Text(record.date, format: .dateTime.month(.abbreviated).day().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ExerciseRecordHistoryView: View {
    let exerciseName: String
    let kind: ExerciseKind
    let entries: [ExerciseRecordEntry]
    let weightUnit: String
    @State private var strengthSort = StrengthRecordSort.volume

    var body: some View {
        List {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No Entries",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Past entries for this exercise will appear here.")
                )
                .listRowBackground(Color.clear)
            } else {
                if kind == .strength {
                    Section("Analytics") {
                        StrengthRecordSummaryView(entries: entries, weightUnit: weightUnit)
                    }
                }

                Section(sectionTitle) {
                    if kind == .strength {
                        Picker("Sort", selection: $strengthSort) {
                            ForEach(StrengthRecordSort.allCases) { sort in
                                Text(sort.title).tag(sort)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    ForEach(sortedEntries) { entry in
                        ExerciseRecordEntryRow(entry: entry, weightUnit: weightUnit)
                    }
                }
            }
        }
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sectionTitle: String {
        switch kind {
        case .strength:
            "Sorted By \(strengthSort.title)"
        case .cardio:
            "Sorted By Best Effort"
        }
    }

    private var sortedEntries: [ExerciseRecordEntry] {
        switch kind {
        case .strength:
            entries.sorted { lhs, rhs in
                switch strengthSort {
                case .recent:
                    if lhs.date != rhs.date {
                        return lhs.date > rhs.date
                    }
                case .weight:
                    if (lhs.weight ?? 0) != (rhs.weight ?? 0) {
                        return (lhs.weight ?? 0) > (rhs.weight ?? 0)
                    }
                case .volume:
                    if lhs.volume != rhs.volume {
                        return lhs.volume > rhs.volume
                    }
                }

                if lhs.volume != rhs.volume {
                    return lhs.volume > rhs.volume
                }

                if (lhs.weight ?? 0) != (rhs.weight ?? 0) {
                    return (lhs.weight ?? 0) > (rhs.weight ?? 0)
                }

                return lhs.date > rhs.date
            }
        case .cardio:
            entries.sorted { lhs, rhs in
                if lhs.cardioScore != rhs.cardioScore {
                    return lhs.cardioScore > rhs.cardioScore
                }

                return lhs.date > rhs.date
            }
        }
    }
}

private enum StrengthRecordSort: String, CaseIterable, Identifiable {
    case recent
    case weight
    case volume

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recent:
            "Recent"
        case .weight:
            "Highest Weight"
        case .volume:
            "Highest Volume"
        }
    }
}

private struct StrengthRecordSummaryView: View {
    let entries: [ExerciseRecordEntry]
    let weightUnit: String

    var body: some View {
        HStack(spacing: 12) {
            RecordMetricView(icon: "chart.line.uptrend.xyaxis", title: "Predicted 1RM", value: predictedOneRepMaxText)
            RecordMetricView(icon: "dumbbell.fill", title: "Highest Weight", value: highestWeightText)
            RecordMetricView(icon: "sum", title: "Max Volume", value: maxVolumeText)
        }
        .padding(.vertical, 4)
    }

    private var predictedOneRepMaxText: String {
        guard let predictedOneRepMax = entries.compactMap(\.estimatedOneRepMax).max() else {
            return "--"
        }

        return "\(Int(predictedOneRepMax.rounded()).formatted()) \(weightUnit)"
    }

    private var highestWeightText: String {
        guard let highestWeight = entries.compactMap(\.weight).max() else {
            return "--"
        }

        return "\(highestWeight) \(weightUnit)"
    }

    private var maxVolumeText: String {
        guard let maxVolume = entries.map(\.volume).max() else {
            return "--"
        }

        return "\(maxVolume.formatted()) \(weightUnit)"
    }
}

private struct RecordMetricView: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.cyan)
                .frame(height: 26)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct ExerciseRecordEntryRow: View {
    let entry: ExerciseRecordEntry
    let weightUnit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(primaryValue)
                    .font(.headline.weight(.semibold))

                Spacer()

                Text(entry.date, format: .dateTime.month(.abbreviated).day().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let secondaryValue {
                Text(secondaryValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var primaryValue: String {
        switch entry.kind {
        case .strength:
            let weight = entry.weight ?? 0
            let reps = entry.reps ?? 0
            return "\(weight) \(weightUnit) x \(reps)"
        case .cardio:
            if let distance = entry.distance {
                return distance.formatted(.number.precision(.fractionLength(0...2))) + " mi"
            }

            if let durationSeconds = entry.durationSeconds {
                return "\(durationSeconds / 60) min"
            }

            if let calories = entry.calories {
                return "\(calories) cal"
            }

            return "--"
        }
    }

    private var secondaryValue: String? {
        switch entry.kind {
        case .strength:
            "\(entry.volume.formatted()) \(weightUnit) volume"
        case .cardio:
            nil
        }
    }
}

private struct LocalRecordBook {
    let strengthRecords: [StrengthRecord]
    let cardioRecords: [CardioRecord]

    init(workouts: [Workout]) {
        var dbWorkouts: [DBWorkout] = []

        for workout in workouts {
            dbWorkouts.append(DBWorkout(workout: workout, userId: "local", completedAt: workout.timestamp))
        }

        let recordBook = WorkoutRecordBook(workouts: dbWorkouts)
        self.strengthRecords = recordBook.strengthRecords
        self.cardioRecords = recordBook.cardioRecords
    }
}

private extension CardioRecord {
    var primaryValue: String {
        if let distance {
            return distance.formatted(.number.precision(.fractionLength(0...2))) + " mi"
        }

        if let durationSeconds {
            return "\(durationSeconds / 60) min"
        }

        if let calories {
            return "\(calories) cal"
        }

        return "--"
    }
}

private extension ExerciseRecordEntry {
    var estimatedOneRepMax: Double? {
        guard kind == .strength,
              let weight,
              let reps,
              weight > 0,
              reps > 0 else {
            return nil
        }

        guard reps > 1 else {
            return Double(weight)
        }

        return Double(weight) * (1 + Double(reps) / 30)
    }

    var cardioScore: Double {
        if let distance {
            return distance
        }

        if let durationSeconds {
            return Double(durationSeconds)
        }

        return Double(calories ?? 0)
    }
}

#Preview {
    NavigationStack {
        RecordBookView()
    }
    .modelContainer(for: [Workout.self, Exercise.self, WorkoutSet.self], inMemory: true)
}
