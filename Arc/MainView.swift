//
//  ContentView.swift
//  Arc
//
//  Created by Khi Kidman on 7/23/25.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workouts: [Workout]
    @State private var selectedWorkout: Workout?
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAddingToolbar: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                if colorScheme == .dark {
                    LinearGradient(colors: [.white.opacity(0.2), .gray.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                } else {
                    Color.white.ignoresSafeArea()
                }
                List {
                    WorkoutHistoryChartView(workouts: workouts)
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
                .scrollContentBackground(.hidden)
                .background(.clear)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button {
                            
                        } label: {
                            Label("History", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                                
                        }
                        .tint(.primary)
                        Spacer()
                        Menu {
                            Button {
                                addItem()
                            } label: {
                                Label("Workout", systemImage: "dumbbell")
                            }
                            Button {
                                
                            } label: {
                                Label("Food", systemImage: "carrot")
                            }
                        } label: {
                            Button {
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
            }
            
            
        }
        .tint(.cyan)
        
    }

    private func addItem() {
        withAnimation {
            let newItem = Workout(timestamp: Date(), title: "Unnamed Workout", volume: Int.random(in: 10000...14000))
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(workouts[index])
            }
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: Workout.self, inMemory: true)
}
