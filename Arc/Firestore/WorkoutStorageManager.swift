//
//  WorkoutStorageManager.swift
//  Arc
//
//  Created by Codex on 5/3/26.
//

import Foundation
import FirebaseFirestore

struct DBWorkout: Codable, Identifiable {
    let id: String
    let userId: String
    let title: String
    let startedAt: Date
    let completedAt: Date
    let totalVolume: Int
    let totalSets: Int
    let strengthExerciseNames: [String]
    let cardioExerciseNames: [String]
    let exerciseNames: [String]
    let hasStrength: Bool
    let hasCardio: Bool
    let exercises: [DBWorkoutExercise]
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case totalVolume = "total_volume"
        case totalSets = "total_sets"
        case strengthExerciseNames = "strength_exercise_names"
        case cardioExerciseNames = "cardio_exercise_names"
        case exerciseNames = "exercise_names"
        case hasStrength = "has_strength"
        case hasCardio = "has_cardio"
        case exercises
        case updatedAt = "updated_at"
    }

    init(workout: Workout, userId: String, completedAt: Date = Date()) {
        let exercises = workout.exercises.map(DBWorkoutExercise.init(exercise:))
        let strengthExercises = exercises.filter { $0.kind == .strength }
        let cardioExercises = exercises.filter { $0.kind == .cardio }
        let strengthNames = Array(Set(strengthExercises.map(\.name))).sorted()
        let cardioNames = Array(Set(cardioExercises.map(\.name))).sorted()
        let exerciseNames = Array(Set(exercises.map(\.name))).sorted()

        self.id = workout.id.uuidString
        self.userId = userId
        self.title = workout.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Workout" : workout.title
        self.startedAt = workout.timestamp
        self.completedAt = completedAt
        self.totalVolume = workout.strengthVolume
        self.totalSets = strengthExercises.reduce(0) { $0 + $1.strengthSets.count }
        self.strengthExerciseNames = strengthNames
        self.cardioExerciseNames = cardioNames
        self.exerciseNames = exerciseNames
        self.hasStrength = !strengthExercises.isEmpty
        self.hasCardio = !cardioExercises.isEmpty
        self.exercises = exercises
        self.updatedAt = Date()
    }
}

struct DBWorkoutExercise: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let kind: ExerciseKind
    let muscleGroup: String?
    let strengthSets: [DBWorkoutSet]
    let cardio: DBCardioWorkout?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case kind
        case muscleGroup = "muscle_group"
        case strengthSets = "strength_sets"
        case cardio
    }

    init(exercise: Exercise) {
        self.id = exercise.id.uuidString
        self.name = exercise.name
        self.kind = exercise.kind
        self.muscleGroup = exercise.muscleGroup

        switch exercise.kind {
        case .strength:
            self.strengthSets = exercise.sets.map(DBWorkoutSet.init(workoutSet:))
            self.cardio = nil
        case .cardio:
            self.strengthSets = []
            self.cardio = DBCardioWorkout(exercise: exercise)
        }
    }
}

struct DBWorkoutSet: Codable, Hashable {
    let reps: Int
    let weight: Int?
    let isCompleted: Bool
    let volume: Int

    enum CodingKeys: String, CodingKey {
        case reps
        case weight
        case isCompleted = "is_completed"
        case volume
    }

    init(workoutSet: WorkoutSet) {
        self.reps = workoutSet.reps
        self.weight = workoutSet.weight
        self.isCompleted = workoutSet.isCompleted
        self.volume = workoutSet.volume
    }
}

struct DBCardioWorkout: Codable, Hashable {
    let durationSeconds: Int?
    let distance: Double?
    let calories: Int?

    enum CodingKeys: String, CodingKey {
        case durationSeconds = "duration_seconds"
        case distance
        case calories
    }

    init(exercise: Exercise) {
        self.durationSeconds = exercise.cardioDurationSeconds
        self.distance = exercise.cardioDistance
        self.calories = exercise.cardioCalories
    }
}

struct StrengthRecord: Identifiable, Hashable {
    let id: String
    let exerciseName: String
    let muscleGroup: String?
    let weight: Int
    let reps: Int
    let volume: Int
    let date: Date
    let workoutTitle: String
}

struct CardioRecord: Identifiable, Hashable {
    let id: String
    let exerciseName: String
    let muscleGroup: String?
    let durationSeconds: Int?
    let distance: Double?
    let calories: Int?
    let date: Date
    let workoutTitle: String
}

struct WorkoutRecordBook: Hashable {
    let strengthRecords: [StrengthRecord]
    let cardioRecords: [CardioRecord]
}

struct ExerciseRecordEntry: Identifiable, Hashable {
    let id: String
    let exerciseName: String
    let kind: ExerciseKind
    let workoutTitle: String
    let date: Date
    let weight: Int?
    let reps: Int?
    let volume: Int
    let durationSeconds: Int?
    let distance: Double?
    let calories: Int?
}

final class WorkoutStorageManager {
    static let shared = WorkoutStorageManager()

    private init() { }

    private let userCollection = Firestore.firestore().collection("users")

    private func workoutCollection(userId: String) -> CollectionReference {
        userCollection.document(userId).collection("workouts")
    }

    private func workoutDocument(userId: String, workoutId: String) -> DocumentReference {
        workoutCollection(userId: userId).document(workoutId)
    }

    func saveWorkout(_ workout: Workout) async throws {
        let userId = try AuthenticationManager.shared.getAuthenticatedUser().uid
        try await saveWorkout(workout, userId: userId)
    }

    func saveWorkout(_ workout: Workout, userId: String) async throws {
        let dbWorkout = DBWorkout(workout: workout, userId: userId)
        try workoutDocument(userId: userId, workoutId: dbWorkout.id).setData(from: dbWorkout, merge: true)
        workout.volume = dbWorkout.totalVolume
        workout.lastSyncedAt = dbWorkout.updatedAt
    }

    func deleteWorkout(_ workout: Workout) async throws {
        try await deleteWorkout(workoutId: workout.id.uuidString)
    }

    func deleteWorkout(workoutId: String) async throws {
        let userId = try AuthenticationManager.shared.getAuthenticatedUser().uid
        try await deleteWorkout(workoutId: workoutId, userId: userId)
    }

    func deleteWorkout(workoutId: String, userId: String) async throws {
        try await workoutDocument(userId: userId, workoutId: workoutId).delete()
    }

    func getRecentWorkouts(limit: Int = 50) async throws -> [DBWorkout] {
        let userId = try AuthenticationManager.shared.getAuthenticatedUser().uid
        return try await getRecentWorkouts(userId: userId, limit: limit)
    }

    func getRecentWorkouts(userId: String, limit: Int = 50) async throws -> [DBWorkout] {
        let snapshot = try await workoutCollection(userId: userId)
            .order(by: DBWorkout.CodingKeys.completedAt.rawValue, descending: true)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.map { try $0.data(as: DBWorkout.self) }
    }

    func getWorkouts(
        userId: String,
        from startDate: Date,
        through endDate: Date,
        limit: Int = 100
    ) async throws -> [DBWorkout] {
        let snapshot = try await workoutCollection(userId: userId)
            .whereField(DBWorkout.CodingKeys.completedAt.rawValue, isGreaterThanOrEqualTo: startDate)
            .whereField(DBWorkout.CodingKeys.completedAt.rawValue, isLessThan: endDate)
            .order(by: DBWorkout.CodingKeys.completedAt.rawValue, descending: true)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.map { try $0.data(as: DBWorkout.self) }
    }

    func getWorkouts(userId: String, exerciseName: String, limit: Int = 50) async throws -> [DBWorkout] {
        let snapshot = try await workoutCollection(userId: userId)
            .whereField(DBWorkout.CodingKeys.exerciseNames.rawValue, arrayContains: exerciseName)
            .order(by: DBWorkout.CodingKeys.completedAt.rawValue, descending: true)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.map { try $0.data(as: DBWorkout.self) }
    }

    func getRecordBook(limit: Int = 200) async throws -> WorkoutRecordBook {
        let workouts = try await getRecentWorkouts(limit: limit)
        return WorkoutRecordBook(workouts: workouts)
    }
}

extension WorkoutRecordBook {
    init(workouts: [DBWorkout]) {
        var strengthByExercise: [String: StrengthRecord] = [:]
        var cardioByExercise: [String: CardioRecord] = [:]

        for workout in workouts {
            for exercise in workout.exercises {
                switch exercise.kind {
                case .strength:
                    for set in exercise.strengthSets {
                        guard let weight = set.weight else { continue }

                        let candidate = StrengthRecord(
                            id: "\(exercise.name)-\(workout.id)-\(weight)-\(set.reps)",
                            exerciseName: exercise.name,
                            muscleGroup: exercise.muscleGroup,
                            weight: weight,
                            reps: set.reps,
                            volume: set.volume,
                            date: workout.completedAt,
                            workoutTitle: workout.title
                        )

                        if let current = strengthByExercise[exercise.name] {
                            if candidate.weight > current.weight ||
                                (candidate.weight == current.weight && candidate.reps > current.reps) {
                                strengthByExercise[exercise.name] = candidate
                            }
                        } else {
                            strengthByExercise[exercise.name] = candidate
                        }
                    }
                case .cardio:
                    guard let cardio = exercise.cardio else { continue }

                    let candidate = CardioRecord(
                        id: "\(exercise.name)-\(workout.id)",
                        exerciseName: exercise.name,
                        muscleGroup: exercise.muscleGroup,
                        durationSeconds: cardio.durationSeconds,
                        distance: cardio.distance,
                        calories: cardio.calories,
                        date: workout.completedAt,
                        workoutTitle: workout.title
                    )

                    if let current = cardioByExercise[exercise.name] {
                        let candidateScore = cardio.recordScore
                        let currentScore = current.recordScore

                        if candidateScore > currentScore {
                            cardioByExercise[exercise.name] = candidate
                        }
                    } else {
                        cardioByExercise[exercise.name] = candidate
                    }
                }
            }
        }

        self.strengthRecords = strengthByExercise.values.sorted { $0.exerciseName < $1.exerciseName }
        self.cardioRecords = cardioByExercise.values.sorted { $0.exerciseName < $1.exerciseName }
    }
}

private extension DBCardioWorkout {
    var recordScore: Double {
        if let distance {
            return distance
        }

        if let durationSeconds {
            return Double(durationSeconds)
        }

        return Double(calories ?? 0)
    }
}

private extension CardioRecord {
    var recordScore: Double {
        if let distance {
            return distance
        }

        if let durationSeconds {
            return Double(durationSeconds)
        }

        return Double(calories ?? 0)
    }
}

extension Workout {
    var strengthVolume: Int {
        exercises
            .filter { $0.kind == .strength }
            .reduce(0) { total, exercise in
                total + exercise.sets.reduce(0) { $0 + $1.volume }
            }
    }
}

extension WorkoutSet {
    var volume: Int {
        reps * (weight ?? 0)
    }
}

extension DBWorkout {
    func makeLocalWorkout() -> Workout {
        Workout(
            id: UUID(uuidString: id) ?? UUID(),
            timestamp: startedAt,
            title: title,
            volume: totalVolume,
            isCompleted: true,
            lastSyncedAt: updatedAt,
            exercises: exercises.map { $0.makeLocalExercise() }
        )
    }
}

extension DBWorkoutExercise {
    func makeLocalExercise() -> Exercise {
        Exercise(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            kind: kind,
            muscleGroup: muscleGroup,
            cardioDurationSeconds: cardio?.durationSeconds,
            cardioDistance: cardio?.distance,
            cardioCalories: cardio?.calories,
            sets: strengthSets.map { $0.makeLocalSet() }
        )
    }
}

extension DBWorkoutSet {
    func makeLocalSet() -> WorkoutSet {
        WorkoutSet(reps: reps, weight: weight, isCompleted: isCompleted)
    }
}
