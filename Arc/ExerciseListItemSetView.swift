//
//  ExerciseListItemSetView.swift
//  Arc
//
//  Created by Khi Kidman on 8/1/25.
//

import SwiftUI
import SwiftData

struct ExerciseListItemSetView: View {
    @Bindable var workoutSet: WorkoutSet
    let setIndex: Int
    var onActivityChanged: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            Text("\(setIndex + 1)")
                .font(.headline.weight(.semibold))
                .frame(width: 12, height: 32)
                .frame(maxWidth: .infinity)

            Menu {
                Text("No history yet")
            } label: {
                HStack (spacing: 2){
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(workoutSet.isCompleted ? .white : .cyan)
                    Text("25")
                        .lineLimit(1)
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                }
                .frame(alignment: .center)
                .padding(.horizontal, 8)
            }
            .frame(width: 70, height: 32)
            .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .frame(maxWidth: .infinity)
            
            

            TextField("lbs", text: weightText)
                .keyboardType(.numberPad)
                .textFieldStyle(.plain)
                .padding(.horizontal, 10)
                .frame(width: 60, height: 32)
                .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .frame(maxWidth: .infinity)
            
            Image(systemName: "xmark")
                .font(.caption)
                .foregroundStyle(.gray)
                
            
            TextField("reps", text: repsText)
                .keyboardType(.numberPad)
                .textFieldStyle(.plain)
                .padding(.horizontal, 10)
                .frame(width: 60, height: 32)
                .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .frame(maxWidth: .infinity)

            Button {
                onActivityChanged()
                workoutSet.isCompleted.toggle()
            } label: {
                Image(systemName: workoutSet.isCompleted ? "checkmark" : "checkmark")
                    .frame(width: 32, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(workoutSet.isCompleted ? .cyan : .black.opacity(0.5))
                    )
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(workoutSet.isCompleted ? .white : .cyan)
            }
            .buttonStyle(.plain)
        }
        .font(.subheadline)
    }

    private var weightText: Binding<String> {
        Binding(
            get: { workoutSet.weight.map(String.init) ?? "" },
            set: { newValue in
                onActivityChanged()
                workoutSet.weight = Int(newValue)
            }
        )
    }

    private var repsText: Binding<String> {
        Binding(
            get: { String(workoutSet.reps) },
            set: { newValue in
                onActivityChanged()
                if let reps = Int(newValue) {
                    workoutSet.reps = reps
                } else if newValue.isEmpty {
                    workoutSet.reps = 0
                }
            }
        )
    }
}

#Preview {
    ExerciseListItemSetView(
        workoutSet: WorkoutSet(reps: 8, weight: 135),
        setIndex: 0,
        onActivityChanged: {}
    )
}
