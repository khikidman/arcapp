//
//  Exercise.swift
//  Arc
//
//  Created by Khi Kidman on 7/29/25.
//

import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet]

    init(
        id: UUID = UUID(),
        name: String,
        sets: [WorkoutSet] = []
    ) {
        self.id = id
        self.name = name
        self.sets = sets
    }
}
