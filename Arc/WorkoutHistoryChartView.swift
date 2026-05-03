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
    private struct VolumeChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let volume: Int
        let isSample: Bool
    }

    @Query(sort: \Workout.timestamp) private var workouts: [Workout]
    @AppStorage("settings.weightUnit") private var weightUnit = "lb"

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

    private var workoutChartPoints: [VolumeChartPoint] {
        recentWorkouts.compactMap { workout in
            guard let volume = workout.volume else { return nil }

            return VolumeChartPoint(
                date: workout.timestamp,
                volume: volume,
                isSample: false
            )
        }
    }

    private var sampleChartPoints: [VolumeChartPoint] {
        #if DEBUG
        let weeklyVolumes = [8_400, 12_250, 10_900, 15_700, 14_200, 18_450, 17_600, 21_300, 23_100]

        return weeklyVolumes.enumerated().compactMap { index, volume in
            guard let date = calendar.date(byAdding: .weekOfYear, value: index - weeklyVolumes.count + 1, to: endDate) else {
                return nil
            }

            return VolumeChartPoint(date: date, volume: volume, isSample: true)
        }
        #else
        return []
        #endif
    }

    private var chartPoints: [VolumeChartPoint] {
        workoutChartPoints.isEmpty ? sampleChartPoints : workoutChartPoints
    }

    private var isShowingSampleData: Bool {
        !chartPoints.isEmpty && chartPoints.allSatisfy(\.isSample)
    }

    private var volumeTitle: String {
        "Volume (\(weightUnit))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                HStack {
                    Spacer()

                    if isShowingSampleData {
                        Text("Sample")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                Text(volumeTitle)
                    .font(.headline)
                    .frame(alignment: .center)
            }
            .padding(.bottom, 4)

            if chartPoints.isEmpty {
                ContentUnavailableView(
                    "No Recent Workouts",
                    systemImage: "chart.xyaxis.line",
                    description: Text("Add a workout to see the last 3 months of volume in \(weightUnit).")
                )
                .frame(maxWidth: .infinity)
                .frame(height: 220)
            } else {
                Chart(chartPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(volumeTitle, point.volume)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.cyan)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value(volumeTitle, point.volume)
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
                        x: .value("Date", point.date),
                        y: .value(volumeTitle, point.volume)
                    )
                    .foregroundStyle(.cyan)
                }
                .chartXScale(domain: startDate...endDate)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(
                            format: .dateTime.month(.abbreviated),
                            centered: false,
                            anchor: .topTrailing
                        )
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
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
