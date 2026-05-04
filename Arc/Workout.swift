//
//  Workout.swift
//  Arc
//
//  Created by Khi Kidman on 7/23/25.
//

import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID = UUID()
    var timestamp: Date
    var title: String
    var volume: Int?
    var isCompleted: Bool = true
    var lastSyncedAt: Date?
    @Relationship(deleteRule: .cascade) var exercises: [Exercise]
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        title: String = "New Workout",
        volume: Int? = 0,
        isCompleted: Bool = true,
        lastSyncedAt: Date? = nil,
        exercises: [Exercise] = []
    ) {
        self.id = id
        self.timestamp = timestamp
        self.title = title
        self.volume = volume
        self.isCompleted = isCompleted
        self.lastSyncedAt = lastSyncedAt
        self.exercises = exercises
    }
}
