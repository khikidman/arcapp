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
    var timestamp: Date
    var title: String
    var volume: Int?
    @Relationship(deleteRule: .cascade) var exercises: [Exercise]
    
    init(
        timestamp: Date = Date(),
        title: String = "New Workout",
        volume: Int? = 0,
        exercises: [Exercise] = []
    ) {
        self.timestamp = timestamp
        self.title = title
        self.volume = volume
        self.exercises = exercises
    }
}
