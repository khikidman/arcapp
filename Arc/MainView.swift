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
    @AppStorage("home.isVolumeChartHidden") private var isVolumeChartHidden = false
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
                    if isVolumeChartHidden {
                        Button {
                            withAnimation {
                                isVolumeChartHidden = false
                            }
                        } label: {
                            Label("Add Widget", systemImage: "plus")
                        }
                    } else {
                        ZStack(alignment: .topTrailing) {
                            WorkoutHistoryChartView()

                            if isEditing {
                                Button {
                                    withAnimation {
                                        isVolumeChartHidden = true
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(.red)
                                        .frame(width: 20, height: 20)
                                        .clipShape(.circle)
                                        .accessibilityLabel("Delete volume chart widget")
                                }
                                .clipShape(.circle)
                                .buttonStyle(.glass)
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    ForEach(workouts) { workout in
                        WorkoutCardView(workout: workout)
                            .onTapGesture {
                                selectedWorkout = workout
                            }
                    }
                    .onDelete(perform: deleteItems)
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

    private var isEditing: Bool {
        editMode.isEditing
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
