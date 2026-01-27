//
//  WorkoutHistoryView.swift
//  OneRM
//

import SwiftUI

/// Workout history view with search, filter, and export functionality
struct WorkoutHistoryView: View {
    @StateObject private var viewModel = WorkoutHistoryViewModel()
    @EnvironmentObject var userPreferences: UserPreferences
    @State private var showingExportSheet = false
    @State private var exportData = ""
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.workouts.isEmpty {
                loadingView
            } else if viewModel.isEmpty {
                emptyStateView
            } else {
                workoutListView
            }
        }
        .navigationTitle("History")
        .searchable(text: $viewModel.searchText, prompt: "Search workouts")
        .refreshable {
            await viewModel.refresh()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    exportData = viewModel.exportWorkouts()
                    showingExportSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(viewModel.isEmpty)
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            exportSheet
        }
        .onAppear {
            Task {
                await viewModel.refresh()
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { _ in
                SkeletonWorkoutCard()
            }
        }
        .padding()
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "calendar.badge.plus",
            title: "No Workouts Yet",
            subtitle: "Start tracking your workouts to see your history here.",
            actionTitle: "Start First Workout"
        )
    }
    
    // MARK: - Workout List
    
    private var workoutListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Personal Records Section
                if !viewModel.personalRecords.isEmpty && viewModel.searchText.isEmpty {
                    personalRecordsSection
                }
                
                // Workouts Section
                if !viewModel.filteredWorkouts.isEmpty {
                    ForEach(viewModel.filteredWorkouts) { workout in
                        WorkoutCardView(workout: workout)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteWorkout(workout)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } else if !viewModel.searchText.isEmpty {
                    noSearchResultsView
                }
            }
            .padding()
        }
    }
    
    // MARK: - Personal Records Section
    
    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.primary)
                Text("Personal Records")
                    .font(.headline)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.personalRecords) { pr in
                        PRCard(record: pr)
                    }
                }
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.2), lineWidth: 1))
    }
    
    // MARK: - No Search Results
    
    private var noSearchResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No Results")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("No workouts match \"\(viewModel.searchText)\"")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Export Sheet
    
    private var exportSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                
                Text("Export Workouts")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Your workout data is ready to export as CSV.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                ShareLink(item: exportData) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share CSV")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        showingExportSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - PR Card

struct PRCard: View {
    let record: PersonalRecord
    @EnvironmentObject var userPreferences: UserPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.exerciseName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(record.formattedWeight(in: userPreferences.defaultWeightUnit))
                    .font(.title2)
                    .fontWeight(.bold)
                Text(userPreferences.defaultWeightUnit.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("\(record.reps) reps")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(minWidth: 120)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Skeleton Workout Card

struct SkeletonWorkoutCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 20)
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 16)
            }
            
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 24)
                }
            }
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 16)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(isAnimating ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
    }
}

#Preview {
    NavigationStack {
        WorkoutHistoryView()
    }
    .environmentObject(UserPreferences.shared)
    .environmentObject(WorkoutRepository.shared)
}
