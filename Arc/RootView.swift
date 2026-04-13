//
//  MainView.swift
//  Arc
//
//  Created by Khi Kidman on 7/24/25.
//

import SwiftUI

struct RootView: View {
    @State var selectedTab: NavigationTab = .home
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        
        TabView(selection: $selectedTab) {
            Tab(value: NavigationTab.home) {
                
            } label: {
                Label("Home", systemImage: "house")
            }
            
            Tab(value: NavigationTab.history) {
                
            } label: {
                Label("History", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate")
            }
            
            Tab(value: NavigationTab.food) {
                
            } label: {
                Label("Food", systemImage: "carrot")
            }
            
            Tab(value: NavigationTab.settings) {
                
            } label: {
                Label("Settings", systemImage: "gear")
            }
            
            Tab(value: NavigationTab.workout, role: .search) {
                
            } label: {
                Label("New", systemImage: "plus")
            }
        }
    }
}

enum NavigationTab {
    case home
    case history
    case food
    case settings
    case workout
}

#Preview {
    RootView()
}
