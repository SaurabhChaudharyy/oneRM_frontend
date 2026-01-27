//
//  ContentView.swift
//  OneRM
//
//  Created by OneRM on 2024-01-23.
//

import SwiftUI

/// Main content view with tab-based navigation
struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var userPreferences: UserPreferences
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // New Workout Tab
            NavigationStack {
                WorkoutSetupView()
            }
            .tabItem {
                Label("Workout", systemImage: "dumbbell.fill")
            }
            .tag(0)
            
            // History Tab
            NavigationStack {
                WorkoutHistoryView()
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            .tag(1)
            
            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(2)
        }
        .tint(Color.accentColor)
    }
}

#Preview {
    ContentView()
        .environmentObject(UserPreferences.shared)
        .environmentObject(WorkoutRepository.shared)
}
