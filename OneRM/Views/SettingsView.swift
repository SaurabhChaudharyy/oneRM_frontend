//
//  SettingsView.swift
//  OneRM
//

import SwiftUI

/// Settings screen for user preferences
struct SettingsView: View {
    @EnvironmentObject var userPreferences: UserPreferences
    @EnvironmentObject var workoutRepository: WorkoutRepository
    
    @State private var showingResetAlert = false
    
    var body: some View {
        List {
            // Units Section
            Section {
                Picker(selection: $userPreferences.defaultWeightUnit) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                } label: {
                    Label("Default Weight Unit", systemImage: "scalemass.fill")
                }
            } header: {
                Text("Units")
            } footer: {
                Text("Changes the display unit for all weights in the app. Existing data will be converted.")
            }
            
            // Data Section
            Section {
                Button {
                    showingResetAlert = true
                } label: {
                    Label("Reset All Data", systemImage: "trash.fill")
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Data")
            } footer: {
                Text("This will clear all local preferences and cached data.")
            }
            
            // About Section
            Section {
                HStack {
                    Label("Version", systemImage: "info.circle.fill")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                
                Link(destination: URL(string: "https://github.com")!) {
                    Label("Report an Issue", systemImage: "ladybug.fill")
                }
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Settings")
        .alert("Reset All Data?", isPresented: $showingResetAlert) {
            Button("Reset", role: .destructive) {
                userPreferences.reset()
                workoutRepository.clearAllData()
                HapticManager.shared.warning()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. All your preferences will be reset to defaults.")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(UserPreferences.shared)
    .environmentObject(WorkoutRepository.shared)
}
