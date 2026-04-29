//
//  Set.swift
//  Arc
//
//  Created by Khi Kidman on 8/2/25.
//

import Foundation
import SwiftData

@Model
final class WorkoutSet {
    var reps: Int
    var weight: Int?
    var isCompleted: Bool

    init(
        reps: Int,
        weight: Int? = nil,
        isCompleted: Bool = false
    ) {
        self.reps = reps
        self.weight = weight
        self.isCompleted = isCompleted
    }
}
