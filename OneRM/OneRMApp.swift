//
//  OneRMApp.swift
//  OneRM
//
//  Created by OneRM on 2024-01-23.
//

import SwiftUI
import SwiftData

/// Main application entry point for OneRM workout tracking app
@main
struct OneRMApp: App {
    /// SwiftData model container for persistent storage
    let modelContainer: ModelContainer
    
    /// Shared user preferences instance
    @StateObject private var userPreferences = UserPreferences.shared
    
    /// Shared workout repository for data operations
    @StateObject private var workoutRepository = WorkoutRepository.shared
    
    /// Controls whether the launch screen is shown
    @State private var showLaunchScreen = true
    
    init() {
        // Initialize SwiftData container
        do {
            let schema = Schema([
                PersistedWorkoutSession.self,
                PersistedExerciseRow.self,
                PersistedPersonalRecord.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ OneRMApp: SwiftData initialized successfully")
        } catch {
            fatalError("❌ OneRMApp: Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(userPreferences)
                    .environmentObject(workoutRepository)
                
                // Launch screen overlay
                if showLaunchScreen {
                    LaunchView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                // Dismiss launch screen after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showLaunchScreen = false
                    }
                }
            }
        }
        .modelContainer(modelContainer)
    }
}
