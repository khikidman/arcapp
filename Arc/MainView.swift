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
        case recentWorkouts
        case weeklyWorkouts
        case weeklyVolume
        case workoutStreak
        case lastWorkout

        var id: Self { self }

        var title: String {
            switch self {
            case .volumeChart:
                "Volume Chart"
            case .recentWorkouts:
                "Recent Workouts"
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
            case .recentWorkouts:
                "clock.arrow.circlepath"
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
            switch self {
            case .volumeChart, .recentWorkouts:
                false
            default:
                true
            }
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
    @State private var workoutSyncError: String?
    @State private var didHydrateWorkouts = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var showCurrentWorkoutCard = false
    @State private var currentWorkoutLabelExpanded = false
    @State private var currentWorkoutToolbarLabelID = UUID()
    @AppStorage("settings.weightUnit") private var weightUnit = "lb"
    @AppStorage("home.isVolumeChartHidden") private var isVolumeChartHidden = false
    @AppStorage("home.isRecentWorkoutsHidden") private var isRecentWorkoutsHidden = false
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

                    if !isHomeWidgetHidden(.recentWorkouts) {
                        recentWorkoutsWidget
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
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.cyan.opacity(0.18), lineWidth: 1)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
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
        .task {
            await hydrateLocalWorkoutsFromFirestoreIfNeeded()
        }
        .sheet(isPresented: $showCurrentWorkoutCard) {
            if let workout = currentWorkout {
                CurrentWorkoutSheetView(
                    workout: workout,
                    onClose: closeCurrentWorkoutCard,
                    onCancelWorkout: cancelCurrentWorkout,
                    onOpenWorkout: {
                        completeCurrentWorkout(workout)
                    },
                    onActivityChanged: { kind in
                        updateWorkoutLiveActivity(for: kind)
                    }
                )
                    .navigationTransition(.zoom(sourceID: currentWorkoutTransitionID, in: currentWorkoutTransitionNamespace))
                    .presentationDetents([.large], selection: $currentWorkoutSheetDetent)
                    .presentationDragIndicator(.visible)
                    .presentationContentInteraction(.resizes)
                    .presentationBackground(.ultraThinMaterial)
            }
        }
        .alert("Sync Delayed", isPresented: Binding(
            get: { workoutSyncError != nil },
            set: { if !$0 { workoutSyncError = nil } }
        )) {
            Button("OK", role: .cancel) { workoutSyncError = nil }
        } message: {
            Text("Your workout is saved locally. Firebase sync can retry later. \(workoutSyncError ?? "Try again later.")")
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
            let newItem = Workout(timestamp: Date(), title: "Current Workout", volume: 0, isCompleted: false)
            modelContext.insert(newItem)
            activeWorkout = newItem
            startWorkoutLiveActivity(for: newItem)
            currentWorkoutSheetDetent = .large
            showCurrentWorkoutCard = true
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let workout = completedWorkouts[index]
                let workoutId = workout.id.uuidString
                if activeWorkout === workout {
                    WorkoutLiveActivityManager.end(workoutID: workoutId)
                    activeWorkout = nil
                    showCurrentWorkoutCard = false
                }
                modelContext.delete(workout)
                Task {
                    try? await WorkoutStorageManager.shared.deleteWorkout(workoutId: workoutId)
                }
            }
        }
    }

    private func cancelCurrentWorkout() {
        guard let workout = activeWorkout else {
            closeCurrentWorkoutCard()
            return
        }

        withAnimation {
            activeWorkout = nil
            showCurrentWorkoutCard = false
            currentWorkoutLabelExpanded = false
            modelContext.delete(workout)
        }

        let workoutId = workout.id.uuidString
        WorkoutLiveActivityManager.end(workoutID: workoutId)

        Task {
            try? await WorkoutStorageManager.shared.deleteWorkout(workoutId: workoutId)
        }
    }

    private func completeCurrentWorkout(_ workout: Workout) {
        workout.volume = workout.strengthVolume
        workout.isCompleted = true
        let workoutId = workout.id.uuidString

        withAnimation {
            if activeWorkout === workout {
                activeWorkout = nil
            }

            WorkoutLiveActivityManager.end(workoutID: workoutId)
            showCurrentWorkoutCard = false
            currentWorkoutLabelExpanded = false
            selectedWorkout = workout
        }

        Task {
            do {
                try await WorkoutStorageManager.shared.saveWorkout(workout)
            } catch {
                await MainActor.run {
                    workoutSyncError = error.localizedDescription
                }
            }
        }
    }

    private func startWorkoutLiveActivity(for workout: Workout) {
        WorkoutLiveActivityManager.start(
            workoutID: workout.id.uuidString,
            startedAt: workout.timestamp,
            indicator: mostRecentLiveActivityIndicator(for: workout)
        )
    }

    private func updateWorkoutLiveActivity(for kind: ExerciseKind) {
        guard let workout = activeWorkout else { return }

        WorkoutLiveActivityManager.update(
            workoutID: workout.id.uuidString,
            startedAt: workout.timestamp,
            indicator: WorkoutLiveActivityIndicator(exerciseKind: kind)
        )
    }

    private func mostRecentLiveActivityIndicator(for workout: Workout) -> WorkoutLiveActivityIndicator {
        guard let exercise = workout.exercises.last else {
            return .strength
        }

        return WorkoutLiveActivityIndicator(exerciseKind: exercise.kind)
    }

    @MainActor
    private func hydrateLocalWorkoutsFromFirestoreIfNeeded() async {
        guard !didHydrateWorkouts else { return }
        didHydrateWorkouts = true

        do {
            let remoteWorkouts = try await WorkoutStorageManager.shared.getRecentWorkouts(limit: 200)
            upsert(remoteWorkouts: remoteWorkouts)
        } catch {
            workoutSyncError = error.localizedDescription
        }
    }

    @MainActor
    private func upsert(remoteWorkouts: [DBWorkout]) {
        let localWorkoutsById = workouts.reduce(into: [String: Workout]()) { result, workout in
            result[workout.id.uuidString] = workout
        }

        for remoteWorkout in remoteWorkouts {
            if let localWorkout = localWorkoutsById[remoteWorkout.id] {
                update(localWorkout, from: remoteWorkout)
            } else {
                modelContext.insert(remoteWorkout.makeLocalWorkout())
            }
        }
    }

    @MainActor
    private func update(_ workout: Workout, from remoteWorkout: DBWorkout) {
        workout.title = remoteWorkout.title
        workout.timestamp = remoteWorkout.startedAt
        workout.volume = remoteWorkout.totalVolume
        workout.isCompleted = true
        workout.lastSyncedAt = remoteWorkout.updatedAt

        for exercise in workout.exercises {
            modelContext.delete(exercise)
        }
        workout.exercises = remoteWorkout.exercises.map { $0.makeLocalExercise() }
    }

    private var currentWorkout: Workout? {
        activeWorkout ?? workouts.sorted { $0.timestamp > $1.timestamp }.first
    }

    private var completedWorkouts: [Workout] {
        workouts
            .filter(\.isCompleted)
            .sorted { $0.timestamp > $1.timestamp }
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

        return completedWorkouts.filter { workout in
            workout.timestamp >= week.start && workout.timestamp < week.end
        }
    }

    private var weeklyVolume: Int {
        workoutsThisWeek.reduce(0) { total, workout in
            total + (workout.volume ?? 0)
        }
    }

    private var workoutStreak: Int {
        let workoutDays = Set(completedWorkouts.map { calendar.startOfDay(for: $0.timestamp) })
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
        completedWorkouts.max { $0.timestamp < $1.timestamp }
    }

    private var recentWorkouts: [Workout] {
        Array(completedWorkouts.prefix(3))
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

    private var recentWorkoutsWidget: some View {
        HomeRecentWorkoutsWidget(
            workouts: recentWorkouts,
            isEditing: isEditing,
            onOpenHistory: {
                menuDestination = .history
            },
            onOpenWorkout: { workout in
                selectedWorkout = workout
            },
            onDelete: {
                withAnimation {
                    setHomeWidget(.recentWorkouts, hidden: true)
                }
            }
        )
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
        case .recentWorkouts:
            isRecentWorkoutsHidden
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
        case .recentWorkouts:
            isRecentWorkoutsHidden = hidden
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
        case .recentWorkouts:
            "\(recentWorkouts.count)"
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
        case .recentWorkouts:
            recentWorkouts.count == 1 ? "workout" : "workouts"
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
        .cyan
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
        RecordBookView()
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
        .modelContainer(for: [Workout.self, Exercise.self, WorkoutSet.self], inMemory: true)
}

private struct HomeRecentWorkoutsWidget: View {
    let workouts: [Workout]
    let isEditing: Bool
    let onOpenHistory: () -> Void
    let onOpenWorkout: (Workout) -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    onOpenHistory()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.cyan)
                            .frame(width: 28, height: 28)

                        Text("Recent Workouts")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                if workouts.isEmpty {
                    Text("No workouts yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                } else {
                    VStack(spacing: 8) {
                        ForEach(workouts) { workout in
                            Button {
                                onOpenWorkout(workout)
                            } label: {
                                RecentWorkoutWidgetRow(workout: workout)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.cyan.opacity(0.18), lineWidth: 1)
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
                        .accessibilityLabel("Delete Recent Workouts widget")
                }
                .clipShape(.circle)
                .buttonStyle(.glass)
                .padding(8)
            }
        }
    }
}

private struct RecentWorkoutWidgetRow: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Text(workout.timestamp, format: .dateTime.month(.abbreviated).day())

                    if workout.strengthVolume > 0 {
                        Label(workout.strengthVolume.formatted(), systemImage: "scalemass")
                    }

                    if workout.exercises.contains(where: { $0.kind == .cardio }) {
                        Label("Cardio", systemImage: "figure.run")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
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
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
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
