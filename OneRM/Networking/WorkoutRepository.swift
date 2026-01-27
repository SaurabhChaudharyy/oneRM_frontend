//
//  WorkoutRepository.swift
//  OneRM
//
//  Local-first data repository for workout operations.
//  This implementation uses MockDataProvider for local storage.
//  Future: Will be migrated to SwiftData for persistent local storage.
//

import Foundation

/// Repository for workout data operations using Repository pattern
/// Uses local-first approach with MockDataProvider for data storage
@MainActor
class WorkoutRepository: ObservableObject {
    static let shared = WorkoutRepository()
    
    private let dataProvider = MockDataProvider.shared
    
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {}
    
    // MARK: - Body Parts
    
    func fetchBodyParts() async -> [BodyPart] {
        return dataProvider.getBodyParts()
    }
    
    // MARK: - Workouts
    
    func saveWorkout(_ workout: WorkoutSession) async -> Result<WorkoutSession, Error> {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate brief processing delay for UI feedback
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        let savedWorkout = dataProvider.saveWorkout(workout)
        return .success(savedWorkout)
    }
    
    func fetchWorkouts() async -> [WorkoutSession] {
        return dataProvider.getWorkouts()
    }
    
    // MARK: - Exercise Suggestions
    
    func fetchExerciseSuggestions(query: String) async -> [String] {
        guard !query.isEmpty else { return [] }
        return dataProvider.getExerciseSuggestions(query: query)
    }
    
    // MARK: - Personal Records
    
    func fetchPersonalRecords() async -> [PersonalRecord] {
        return dataProvider.getPersonalRecords()
    }
    
    func clearError() {
        error = nil
    }
    
    // MARK: - Clear All Data
    
    /// Clears all workout data from local storage
    func clearAllData() {
        dataProvider.clearAllWorkouts()
    }
}

