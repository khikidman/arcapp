//
//  Exercise.swift
//  Arc
//
//  Created by Khi Kidman on 7/29/25.
//

import Foundation
import SwiftData

enum ExerciseKind: String, Codable, CaseIterable {
    case strength
    case cardio
}

@Model
final class Exercise {
    var id: UUID
    var name: String
    var kindRawValue: String = ExerciseKind.strength.rawValue
    var muscleGroup: String?
    var cardioDurationSeconds: Int?
    var cardioDistance: Double?
    var cardioCalories: Int?
    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet]

    var kind: ExerciseKind {
        get { ExerciseKind(rawValue: kindRawValue) ?? .strength }
        set { kindRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        kind: ExerciseKind = .strength,
        muscleGroup: String? = nil,
        cardioDurationSeconds: Int? = nil,
        cardioDistance: Double? = nil,
        cardioCalories: Int? = nil,
        sets: [WorkoutSet] = []
    ) {
        self.id = id
        self.name = name
        self.kindRawValue = kind.rawValue
        self.muscleGroup = muscleGroup
        self.cardioDurationSeconds = cardioDurationSeconds
        self.cardioDistance = cardioDistance
        self.cardioCalories = cardioCalories
        self.sets = sets
    }
}
