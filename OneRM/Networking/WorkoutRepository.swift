//
//  WorkoutRepository.swift
//  OneRM
//
//  Local-first data repository for workout operations.
//  Uses SwiftData for persistent local storage with optional cloud sync.
//

import Foundation

/// Repository for workout data operations using Repository pattern
/// Uses local-first approach with SwiftData for persistent storage
@MainActor
class WorkoutRepository: ObservableObject {
    static let shared = WorkoutRepository()
    
    /// SwiftData storage manager for persistent data
    private let storageManager = StorageManager.shared
    
    /// Mock data provider for exercise suggestions and default body parts
    private let mockDataProvider = MockDataProvider.shared
    
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {}
    
    // MARK: - Body Parts
    
    /// Fetch available body parts (uses static defaults)
    func fetchBodyParts() async -> [BodyPart] {
        return mockDataProvider.getBodyParts()
    }
    
    // MARK: - Workouts
    
    /// Save a workout session to persistent storage
    func saveWorkout(_ workout: WorkoutSession) async -> Result<WorkoutSession, Error> {
        isLoading = true
        defer { isLoading = false }
        
        // Brief delay for UI feedback
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        let savedWorkout = storageManager.saveWorkout(workout)
        return .success(savedWorkout)
    }
    
    /// Fetch all workout sessions from persistent storage
    func fetchWorkouts() async -> [WorkoutSession] {
        return storageManager.fetchWorkouts()
    }
    
    /// Delete a workout session
    func deleteWorkout(_ workout: WorkoutSession) async {
        storageManager.deleteWorkout(workout)
    }
    
    /// Delete a workout by ID
    func deleteWorkout(id: UUID) async {
        storageManager.deleteWorkout(id: id)
    }
    
    // MARK: - Exercise Suggestions
    
    /// Fetch exercise name suggestions based on query
    func fetchExerciseSuggestions(query: String) async -> [String] {
        guard !query.isEmpty else { return [] }
        return mockDataProvider.getExerciseSuggestions(query: query)
    }
    
    // MARK: - Personal Records
    
    /// Fetch all personal records from persistent storage
    func fetchPersonalRecords() async -> [PersonalRecord] {
        return storageManager.fetchBestPersonalRecords()
    }
    
    func clearError() {
        error = nil
    }
    
    // MARK: - Clear All Data
    
    /// Clears all workout data from persistent storage
    func clearAllData() {
        storageManager.clearAllData()
    }
    
    // MARK: - Calendar & History Features
    
    /// Fetch workouts for a specific date
    func fetchWorkoutsForDate(_ date: Date) async -> [WorkoutSession] {
        return storageManager.fetchWorkoutsForDate(date)
    }
    
    /// Fetch all dates that have workouts (for calendar markers)
    func fetchWorkoutDates() async -> [Date: [WorkoutSession]] {
        return storageManager.fetchWorkoutDates()
    }
    
    /// Fetch previous exercise data for showing history/PRs
    func fetchPreviousExerciseData(exerciseName: String, bodyPartNames: [String]) async -> [ExerciseRow] {
        return storageManager.fetchPreviousExerciseData(exerciseName: exerciseName, bodyPartNames: bodyPartNames)
    }
    
    /// Get best PR for a specific exercise
    func fetchBestPRForExercise(exerciseName: String) async -> PersonalRecord? {
        return storageManager.fetchBestPRForExercise(exerciseName: exerciseName)
    }
}

