//
//  WorkoutHistoryChartView.swift
//  Arc
//
//  Created by Khi Kidman on 7/24/25.
//

import SwiftUI
import Charts
import SwiftData

struct WorkoutHistoryChartView: View {
    @Query(sort: \Workout.timestamp) private var workouts: [Workout]

    private var calendar: Calendar { .current }

    private var endDate: Date { Date() }

    private var startDate: Date {
        calendar.date(byAdding: .month, value: -3, to: endDate) ?? endDate
    }

    private var recentWorkouts: [Workout] {
        workouts.filter { workout in
            workout.timestamp >= startDate && workout.timestamp <= endDate
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Volume")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)

            if recentWorkouts.isEmpty {
                ContentUnavailableView(
                    "No Recent Workouts",
                    systemImage: "chart.xyaxis.line",
                    description: Text("Add a workout to see the last 3 months of volume in lbs.")
                )
                .frame(maxWidth: .infinity)
                .frame(height: 220)
            } else {
                Chart(recentWorkouts) { workout in
                    if let volume = workout.volume {
                        LineMark(
                            x: .value("Date", workout.timestamp),
                            y: .value("Volume (lbs)", volume)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.cyan)

                        AreaMark(
                            x: .value("Date", workout.timestamp),
                            y: .value("Volume (lbs)", volume)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.cyan.opacity(0.3), .cyan.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        PointMark(
                            x: .value("Date", workout.timestamp),
                            y: .value("Volume (lbs)", volume)
                        )
                        .foregroundStyle(.cyan)
                    }
                }
                .chartXScale(domain: startDate...endDate)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartYAxisLabel("Volume (lbs)", position: .leading)
                .frame(height: 220)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    WorkoutHistoryChartView()
        .modelContainer(for: Workout.self, inMemory: true)
}
