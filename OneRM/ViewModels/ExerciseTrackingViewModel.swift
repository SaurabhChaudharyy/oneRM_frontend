//
//  ExerciseTrackingViewModel.swift
//  OneRM
//

import Foundation
import SwiftUI

/// ViewModel for exercise tracking screen
@MainActor
class ExerciseTrackingViewModel: ObservableObject {
    @Published var workoutSession: WorkoutSession
    @Published var exerciseRows: [ExerciseRow]
    @Published var isSaving = false
    @Published var saveError: String?
    @Published var saveSuccess = false
    @Published var hasUnsavedChanges = false
    @Published var exerciseSuggestions: [String] = []
    @Published var showingSuggestions = false
    @Published var activeRowId: UUID?
    
    private let repository = WorkoutRepository.shared
    private let userPreferences = UserPreferences.shared
    private let initialRowCount = 5
    
    var defaultUnit: WeightUnit {
        userPreferences.defaultWeightUnit
    }
    
    var validExerciseCount: Int {
        exerciseRows.filter { $0.isValid }.count
    }
    
    var totalVolume: Double {
        exerciseRows.reduce(0) { $0 + $1.totalVolume }
    }
    
    var canSave: Bool {
        validExerciseCount > 0 && !isSaving
    }
    
    init(workoutSession: WorkoutSession) {
        self.workoutSession = workoutSession
        self.exerciseRows = workoutSession.exercises.isEmpty
            ? (0..<5).map { _ in ExerciseRow(unit: UserPreferences.shared.defaultWeightUnit) }
            : workoutSession.exercises
    }
    
    // MARK: - Row Management
    
    func addRow() {
        let newRow = ExerciseRow(unit: defaultUnit)
        exerciseRows.append(newRow)
        hasUnsavedChanges = true
        HapticManager.shared.light()
    }
    
    func deleteRow(at offsets: IndexSet) {
        exerciseRows.remove(atOffsets: offsets)
        hasUnsavedChanges = true
        HapticManager.shared.light()
        
        if exerciseRows.isEmpty {
            addRow()
        }
    }
    
    func deleteRow(_ row: ExerciseRow) {
        exerciseRows.removeAll { $0.id == row.id }
        hasUnsavedChanges = true
        HapticManager.shared.light()
        
        if exerciseRows.isEmpty {
            addRow()
        }
    }
    
    // MARK: - Field Updates
    
    func updateExerciseName(for rowId: UUID, name: String) {
        guard let index = exerciseRows.firstIndex(where: { $0.id == rowId }) else { return }
        exerciseRows[index].exerciseName = name
        hasUnsavedChanges = true
    }
    
    func updateWeight(for rowId: UUID, weight: Double) {
        guard let index = exerciseRows.firstIndex(where: { $0.id == rowId }) else { return }
        exerciseRows[index].weight = max(0, weight)
        hasUnsavedChanges = true
    }
    
    func updateReps(for rowId: UUID, reps: Int) {
        guard let index = exerciseRows.firstIndex(where: { $0.id == rowId }) else { return }
        exerciseRows[index].reps = max(0, reps)
        hasUnsavedChanges = true
    }
    
    func updateUnit(for rowId: UUID, unit: WeightUnit) {
        guard let index = exerciseRows.firstIndex(where: { $0.id == rowId }) else { return }
        exerciseRows[index].unit = unit
        hasUnsavedChanges = true
    }
    
    func toggleUnit(for rowId: UUID) {
        guard let index = exerciseRows.firstIndex(where: { $0.id == rowId }) else { return }
        exerciseRows[index].unit = exerciseRows[index].unit == .lbs ? .kg : .lbs
        hasUnsavedChanges = true
        HapticManager.shared.selection()
    }
    
    // MARK: - Suggestions
    
    func fetchSuggestions(for query: String) async {
        guard !query.isEmpty else {
            exerciseSuggestions = []
            showingSuggestions = false
            return
        }
        
        let suggestions = await repository.fetchExerciseSuggestions(query: query)
        exerciseSuggestions = suggestions
        showingSuggestions = !suggestions.isEmpty
    }
    
    func selectSuggestion(_ suggestion: String, for rowId: UUID) {
        updateExerciseName(for: rowId, name: suggestion)
        exerciseSuggestions = []
        showingSuggestions = false
    }
    
    // MARK: - Save
    
    func saveWorkout() async {
        guard canSave else { return }
        
        isSaving = true
        saveError = nil
        HapticManager.shared.light()
        
        var session = workoutSession
        session.exercises = exerciseRows.filter { $0.isValid }
        session.updatedAt = Date()
        
        let result = await repository.saveWorkout(session)
        
        switch result {
        case .success(let saved):
            workoutSession = saved
            hasUnsavedChanges = false
            saveSuccess = true
            HapticManager.shared.success()
        case .failure(let error):
            saveError = error.localizedDescription
            HapticManager.shared.error()
        }
        
        isSaving = false
    }
    
    func clearSaveStatus() {
        saveError = nil
        saveSuccess = false
    }
}
