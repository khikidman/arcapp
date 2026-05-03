//
//  ContentView.swift
//  Arc
//
//  Created by Khi Kidman on 7/23/25.
//

import SwiftUI
import SwiftData

struct MainView: View {
    private enum MenuDestination: Hashable, Identifiable {
        case history
        case recordBook
        case profile

        var id: Self { self }
    }

    private enum HomeWidget: String, CaseIterable, Identifiable {
        case volumeChart
        case weeklyWorkouts
        case weeklyVolume
        case workoutStreak
        case lastWorkout

        var id: Self { self }

        var title: String {
            switch self {
            case .volumeChart:
                "Volume Chart"
            case .weeklyWorkouts:
                "This Week"
            case .weeklyVolume:
                "Week Volume"
            case .workoutStreak:
                "Streak"
            case .lastWorkout:
                "Last Workout"
            }
        }

        var systemImage: String {
            switch self {
            case .volumeChart:
                "chart.xyaxis.line"
            case .weeklyWorkouts:
                "calendar"
            case .weeklyVolume:
                "scalemass"
            case .workoutStreak:
                "flame.fill"
            case .lastWorkout:
                "clock.arrow.circlepath"
            }
        }

        var isSmall: Bool {
            self != .volumeChart
        }
    }

    @Binding var showSignInView: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var workouts: [Workout]
    @State private var selectedWorkout: Workout?
    @State private var menuDestination: MenuDestination?
    @State private var activeWorkout: Workout?
    @State private var editMode: EditMode = .inactive
    @State private var currentWorkoutSheetDetent: PresentationDetent = .large
    @Environment(\.colorScheme) private var colorScheme
    @State private var showCurrentWorkoutCard = false
    @State private var currentWorkoutLabelExpanded = false
    @State private var currentWorkoutToolbarLabelID = UUID()
    @AppStorage("settings.weightUnit") private var weightUnit = "lb"
    @AppStorage("home.isVolumeChartHidden") private var isVolumeChartHidden = false
    @AppStorage("home.isWeeklyWorkoutsHidden") private var isWeeklyWorkoutsHidden = false
    @AppStorage("home.isWeeklyVolumeHidden") private var isWeeklyVolumeHidden = false
    @AppStorage("home.isWorkoutStreakHidden") private var isWorkoutStreakHidden = false
    @AppStorage("home.isLastWorkoutHidden") private var isLastWorkoutHidden = false
    @Namespace private var currentWorkoutTransitionNamespace

    var body: some View {
        ZStack {
                if colorScheme == .dark {
                    LinearGradient(colors: [.white.opacity(0.1), .gray.opacity(0.01)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                } else {
                    Color.white.ignoresSafeArea()
                }
                List {
                    if !visibleSmallWidgets.isEmpty {
                        smallWidgetGrid
                    }

                    if !isHomeWidgetHidden(.volumeChart) {
                        ZStack(alignment: .topTrailing) {
                            WorkoutHistoryChartView()
                                .padding(12)

                            if isEditing {
                                widgetDeleteButton(.volumeChart)
                                    .padding(8)
                            }
                        }
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.cyan.opacity(0.18), lineWidth: 1)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    ForEach(workouts) { workout in
                        WorkoutCardView(workout: workout)
                            .onTapGesture {
                                selectedWorkout = workout
                            }
                    }
                    .onDelete(perform: deleteItems)

                    if isEditing && !hiddenHomeWidgets.isEmpty {
                        addWidgetMenu
                    }
                }
                .navigationDestination(item: $selectedWorkout) { workout in
                    WorkoutView(workout: workout)
                }
                .navigationDestination(item: $menuDestination) { destination in
                    switch destination {
                    case .history:
                        WorkoutHistoryView()
                    case .recordBook:
                        recordBookView
                    case .profile:
                        SettingsView(showSignInView: $showSignInView)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(.clear)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        NavigationLink {
                            SettingsView(showSignInView: $showSignInView)
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem(placement: .bottomBar) {
                        Menu {
                            Button {
                                menuDestination = .history
                            } label: {
                                menuLabel("History", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                                    .tint(.cyan)
                            }

                            Button {
                                menuDestination = .recordBook
                            } label: {
                                menuLabel("Record Book", systemImage: "trophy")
                                    .tint(.cyan)
                            }

                            Button {
                                menuDestination = .profile
                            } label: {
                                menuLabel("Profile", systemImage: "person.crop.circle")
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.headline.weight(.semibold))
                        }
                        .tint(.primary)
                    }
                    if activeWorkout == nil {
                        ToolbarSpacer(.flexible, placement: .bottomBar)
                    }
                    ToolbarItem(placement: .status) {
                        if activeWorkout != nil {
                            Button {
                                currentWorkoutSheetDetent = .large
                                showCurrentWorkoutCard = true
                            } label: {
                                CurrentWorkoutToolbarLabel(
                                    startDate: currentWorkout?.timestamp ?? .now,
                                    viewID: currentWorkoutToolbarLabelID,
                                    isActive: activeWorkout != nil,
                                    expandsToFullWidth: $currentWorkoutLabelExpanded
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .matchedTransitionSource(id: currentWorkoutTransitionID, in: currentWorkoutTransitionNamespace)
                    ToolbarItem(placement: .bottomBar) {
                        Menu {
                            Button {
                                startWorkout()
                            } label: {
                                Label("Workout", systemImage: "dumbbell")
                            }
                            Button {

                            } label: {
                                Label("Food", systemImage: "carrot")
                            }
                        } label: {
                            Label("Add Item", systemImage: "plus")
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())
                        }
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                        .buttonStyle(.glassProminent)
                    }
                }

        }
        .environment(\.editMode, $editMode)
        .tint(.cyan)
        .onAppear {
            currentWorkoutToolbarLabelID = UUID()
            currentWorkoutLabelExpanded = false
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))
                currentWorkoutLabelExpanded = true
            }
        }
        .sheet(isPresented: $showCurrentWorkoutCard) {
            if let workout = currentWorkout {
                CurrentWorkoutSheetView(
                    workout: workout,
                    onClose: closeCurrentWorkoutCard,
                    onOpenWorkout: {
                        selectedWorkout = workout
                        closeCurrentWorkoutCard()
                    }
                )
                    .navigationTransition(.zoom(sourceID: currentWorkoutTransitionID, in: currentWorkoutTransitionNamespace))
                    .presentationDetents([.large], selection: $currentWorkoutSheetDetent)
                    .presentationDragIndicator(.visible)
                    .presentationContentInteraction(.resizes)
                    .presentationBackground(.ultraThinMaterial)
            }
        }
    }

    private func startWorkout() {
        if activeWorkout != nil {
            currentWorkoutSheetDetent = .large
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                showCurrentWorkoutCard = true
            }
            return
        }

        withAnimation {
            let newItem = Workout(timestamp: Date(), title: "Current Workout", volume: 0)
            modelContext.insert(newItem)
            activeWorkout = newItem
            currentWorkoutSheetDetent = .large
            showCurrentWorkoutCard = true
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let workout = workouts[index]
                if activeWorkout === workout {
                    activeWorkout = nil
                    showCurrentWorkoutCard = false
                }
                modelContext.delete(workout)
            }
        }
    }

    private var currentWorkout: Workout? {
        activeWorkout ?? workouts.sorted { $0.timestamp > $1.timestamp }.first
    }

    private var calendar: Calendar {
        .current
    }

    private var isEditing: Bool {
        editMode.isEditing
    }

    private var hiddenHomeWidgets: [HomeWidget] {
        HomeWidget.allCases.filter(isHomeWidgetHidden)
    }

    private var visibleSmallWidgets: [HomeWidget] {
        HomeWidget.allCases.filter { widget in
            widget.isSmall && !isHomeWidgetHidden(widget)
        }
    }

    private var workoutsThisWeek: [Workout] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
            return []
        }

        return workouts.filter { workout in
            workout.timestamp >= week.start && workout.timestamp < week.end
        }
    }

    private var weeklyVolume: Int {
        workoutsThisWeek.reduce(0) { total, workout in
            total + (workout.volume ?? 0)
        }
    }

    private var workoutStreak: Int {
        let workoutDays = Set(workouts.map { calendar.startOfDay(for: $0.timestamp) })
        guard var day = workoutDays.max() else {
            return 0
        }

        var streak = 0
        while workoutDays.contains(day) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else {
                break
            }
            day = previousDay
        }

        return streak
    }

    private var lastWorkout: Workout? {
        workouts.max { $0.timestamp < $1.timestamp }
    }

    private var addWidgetMenu: some View {
        HStack {
            Spacer()

            Menu {
                ForEach(hiddenHomeWidgets) { widget in
                    Button {
                        withAnimation {
                            setHomeWidget(widget, hidden: false)
                        }
                    } label: {
                        Label(widget.title, systemImage: widget.systemImage)
                    }
                }
            } label: {
                Label("Add Widget", systemImage: "plus")
            }
            .buttonStyle(.glass)

            Spacer()
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private var smallWidgetGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(visibleSmallWidgets) { widget in
                smallWidgetView(widget)
            }
        }
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func smallWidgetView(_ widget: HomeWidget) -> some View {
        HomeStatWidget(
            title: widget.title,
            value: value(for: widget),
            caption: caption(for: widget),
            systemImage: widget.systemImage,
            tint: tint(for: widget),
            isEditing: isEditing,
            onDelete: {
                withAnimation {
                    setHomeWidget(widget, hidden: true)
                }
            }
        )
    }

    private func widgetDeleteButton(_ widget: HomeWidget) -> some View {
        Button {
            withAnimation {
                setHomeWidget(widget, hidden: true)
            }
        } label: {
            Image(systemName: "xmark")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.red)
                .frame(width: 20, height: 20)
                .clipShape(.circle)
                .accessibilityLabel("Delete \(widget.title) widget")
        }
        .clipShape(.circle)
        .buttonStyle(.glass)
    }

    private func isHomeWidgetHidden(_ widget: HomeWidget) -> Bool {
        switch widget {
        case .volumeChart:
            isVolumeChartHidden
        case .weeklyWorkouts:
            isWeeklyWorkoutsHidden
        case .weeklyVolume:
            isWeeklyVolumeHidden
        case .workoutStreak:
            isWorkoutStreakHidden
        case .lastWorkout:
            isLastWorkoutHidden
        }
    }

    private func setHomeWidget(_ widget: HomeWidget, hidden: Bool) {
        switch widget {
        case .volumeChart:
            isVolumeChartHidden = hidden
        case .weeklyWorkouts:
            isWeeklyWorkoutsHidden = hidden
        case .weeklyVolume:
            isWeeklyVolumeHidden = hidden
        case .workoutStreak:
            isWorkoutStreakHidden = hidden
        case .lastWorkout:
            isLastWorkoutHidden = hidden
        }
    }

    private func value(for widget: HomeWidget) -> String {
        return switch widget {
        case .volumeChart:
            ""
        case .weeklyWorkouts:
            "\(workoutsThisWeek.count)"
        case .weeklyVolume:
            weeklyVolume.formatted()
        case .workoutStreak:
            "\(workoutStreak)"
        case .lastWorkout:
            lastWorkout.map { shortDateLabel(for: $0.timestamp) } ?? "--"
        }
    }

    private func caption(for widget: HomeWidget) -> String {
        return switch widget {
        case .volumeChart:
            ""
        case .weeklyWorkouts:
            workoutsThisWeek.count == 1 ? "workout" : "workouts"
        case .weeklyVolume:
            weightUnit
        case .workoutStreak:
            workoutStreak == 1 ? "day" : "days"
        case .lastWorkout:
            lastWorkout?.title ?? "No workouts yet"
        }
    }

    private func tint(for widget: HomeWidget) -> Color {
        return switch widget {
        case .volumeChart:
            .cyan
        case .weeklyWorkouts:
            .cyan
        case .weeklyVolume:
            .green
        case .workoutStreak:
            .orange
        case .lastWorkout:
            .red
        }
    }

    private func shortDateLabel(for date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "Today"
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    private var recordBookView: some View {
        Text("Record Book coming soon")
            .navigationTitle("Record Book")
            .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func menuLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .tint(.cyan)

            Text(title)
                .foregroundStyle(.white)
        }
    }

    private var currentWorkoutTransitionID: String {
        if let workout = currentWorkout {
            return "current-workout-\(workout.persistentModelID)"
        }

        return "current-workout"
    }

    private func closeCurrentWorkoutCard() {
        showCurrentWorkoutCard = false
    }
}

#Preview {
    MainView(showSignInView: .constant(false))
        .modelContainer(for: Workout.self, inMemory: true)
}

private struct HomeStatWidget: View {
    let title: String
    let value: String
    let caption: String
    let systemImage: String
    let tint: Color
    let isEditing: Bool
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(value)
                        .font(.title2.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 106, alignment: .leading)
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            }

            if isEditing {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.red)
                        .frame(width: 20, height: 20)
                        .clipShape(.circle)
                        .accessibilityLabel("Delete \(title) widget")
                }
                .clipShape(.circle)
                .buttonStyle(.glass)
                .padding(6)
            }
        }
    }
}
