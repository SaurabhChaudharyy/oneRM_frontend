//
//  SettingsView.swift
//  OneRM
//

import SwiftUI

/// Settings screen for user preferences
struct SettingsView: View {
    @EnvironmentObject var userPreferences: UserPreferences
    @EnvironmentObject var workoutRepository: WorkoutRepository
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var showingResetAlert = false
    @State private var showingSignOutAlert = false
    @State private var showingLoginView = false
    
    var body: some View {
        List {
            // Account Section
            accountSection
            
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
            
            // Sync Section (only show when signed in)
            if authManager.isSignedIn {
                syncSection
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
        .sheet(isPresented: $showingLoginView) {
            LoginView()
                .environmentObject(authManager)
        }
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
        .alert("Sign Out?", isPresented: $showingSignOutAlert) {
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You can sign back in anytime to sync your workouts across devices.")
        }
    }
    
    // MARK: - Account Section
    
    @ViewBuilder
    private var accountSection: some View {
        Section {
            if let user = authManager.currentUser {
                // Signed in state
                signedInView(user: user)
            } else {
                // Signed out state
                signedOutView
            }
        } header: {
            Text("Account")
        } footer: {
            if authManager.isSignedIn {
                Text("Signed in workouts will sync across all your devices.")
            } else {
                Text("Sign in to backup and sync your workouts across devices.")
            }
        }
    }
    
    private func signedInView(user: User) -> some View {
        VStack(spacing: 0) {
            // User profile row
            HStack(spacing: 14) {
                // Avatar
                if let photoURL = user.photoURL {
                    AsyncImage(url: photoURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        initialsAvatar(user: user)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    initialsAvatar(user: user)
                }
                
                // User info
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(.headline)
                    
                    if let email = user.email {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: user.provider == .apple ? "apple.logo" : "g.circle.fill")
                            .font(.caption2)
                        Text(user.provider == .apple ? "Apple" : "Google")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Sync status indicator
                Image(systemName: "checkmark.icloud.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            .padding(.vertical, 4)
            
            Divider()
                .padding(.top, 12)
            
            // Sign out button
            Button {
                showingSignOutAlert = true
            } label: {
                Text("Sign Out")
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
    }
    
    private var signedOutView: some View {
        Button {
            showingLoginView = true
        } label: {
            HStack(spacing: 14) {
                // Avatar placeholder
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sign In")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Backup & sync your workouts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    private func initialsAvatar(user: User) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
            
            Text(user.initials)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Sync Section
    
    @ViewBuilder
    private var syncSection: some View {
        Section {
            HStack {
                Label("Last Synced", systemImage: "arrow.triangle.2.circlepath")
                Spacer()
                if let lastSync = authManager.currentUser?.lastSyncedAt {
                    Text(lastSync, style: .relative)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Not yet")
                        .foregroundStyle(.secondary)
                }
            }
            
            Button {
                // TODO: Implement manual sync
                HapticManager.shared.light()
            } label: {
                Label("Sync Now", systemImage: "arrow.clockwise")
            }
        } header: {
            Text("Sync")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(UserPreferences.shared)
    .environmentObject(WorkoutRepository.shared)
    .environmentObject(AuthenticationManager.shared)
}

