//
//  CurrentWorkoutToolbarLabel.swift
//  Arc
//
//  Created by Codex on 8/2/25.
//

import SwiftUI

struct CurrentWorkoutToolbarLabel: View {
    let startDate: Date
    let viewID: UUID
    let isActive: Bool
    @Binding var expandsToFullWidth: Bool

    var body: some View {
        ZStack {
            Text("Resume")
                .lineLimit(1)
            HStack(spacing: 8) {
                Image(systemName: "figure.strengthtraining.traditional")
                
                Spacer()
                
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(elapsedTimeString(at: context.date))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: expandsToFullWidth ? .infinity : nil, alignment: .center)
        .background(.thinMaterial, in: Capsule())
        .overlay {
            if isActive {
                Capsule()
                    .strokeBorder(.cyan.opacity(0.7), lineWidth: 1.5)
                    .blur(radius: 0.2)
                    .padding(-1)
                    .allowsHitTesting(false)
            }
        }
        .shadow(color: isActive ? .cyan.opacity(0.45) : .clear, radius: 10)
        .id(viewID)
    }

    private func elapsedTimeString(at currentDate: Date) -> String {
        let elapsed = max(Int(currentDate.timeIntervalSince(startDate)), 0)
        let hours = elapsed / 3600
        let minutes = (elapsed % 3600) / 60
        let seconds = elapsed % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    CurrentWorkoutToolbarLabel(
        startDate: .now.addingTimeInterval(-755),
        viewID: UUID(),
        isActive: true,
        expandsToFullWidth: .constant(true)
    )
}
