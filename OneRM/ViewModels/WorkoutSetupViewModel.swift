//
//  WorkoutSetupViewModel.swift
//  OneRM
//

import Foundation
import SwiftUI

/// ViewModel for workout setup screen
@MainActor
class WorkoutSetupViewModel: ObservableObject {
    @Published var workoutName: String = ""
    @Published var workoutDate: Date = Date()
    @Published var availableBodyParts: [BodyPart] = BodyPart.defaults
    @Published var selectedBodyParts: Set<UUID> = []
    @Published var customBodyPartName: String = ""
    @Published var isLoading = false
    @Published var showingAddCustom = false
    @Published var workoutDates: [Date: [WorkoutSession]] = [:]  // Dates with workouts
    
    private let repository = WorkoutRepository.shared
    
    var canContinue: Bool {
        !selectedBodyParts.isEmpty
    }
    
    var selectedBodyPartsList: [BodyPart] {
        availableBodyParts.filter { selectedBodyParts.contains($0.id) }
    }
    
    init() {
        Task {
            await loadBodyParts()
            await loadWorkoutDates()
        }
    }
    
    func loadBodyParts() async {
        isLoading = true
        availableBodyParts = await repository.fetchBodyParts()
        isLoading = false
    }
    
    func loadWorkoutDates() async {
        workoutDates = await repository.fetchWorkoutDates()
    }
    
    /// Get workouts for a specific date (for calendar display)
    func getWorkoutsForDate(_ date: Date) -> [WorkoutSession] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return workoutDates[startOfDay] ?? []
    }
    
    /// Check if a date has workouts
    func hasWorkoutsOnDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return workoutDates[startOfDay] != nil && !(workoutDates[startOfDay]?.isEmpty ?? true)
    }
    
    func toggleBodyPart(_ bodyPart: BodyPart) {
        HapticManager.shared.selection()
        if selectedBodyParts.contains(bodyPart.id) {
            selectedBodyParts.remove(bodyPart.id)
        } else {
            selectedBodyParts.insert(bodyPart.id)
        }
    }
    
    func isSelected(_ bodyPart: BodyPart) -> Bool {
        selectedBodyParts.contains(bodyPart.id)
    }
    
    func addCustomBodyPart() {
        let trimmed = customBodyPartName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard !availableBodyParts.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) else { return }
        
        let newBodyPart = BodyPart(name: trimmed, isCustom: true)
        availableBodyParts.append(newBodyPart)
        selectedBodyParts.insert(newBodyPart.id)
        customBodyPartName = ""
        showingAddCustom = false
        HapticManager.shared.success()
    }
    
    func deleteCustomBodyPart(_ bodyPart: BodyPart) {
        guard bodyPart.isCustom else { return }  // Only allow deleting custom body parts
        
        // Remove from selected if it was selected
        selectedBodyParts.remove(bodyPart.id)
        
        // Remove from available list
        availableBodyParts.removeAll { $0.id == bodyPart.id }
        
        HapticManager.shared.light()
    }
    
    func createWorkoutSession() -> WorkoutSession {
        WorkoutSession(
            name: workoutName.isEmpty ? nil : workoutName,
            date: workoutDate,
            bodyParts: selectedBodyPartsList,
            exercises: []
        )
    }
    
    func reset() {
        workoutName = ""
        workoutDate = Date()
        selectedBodyParts = []
        customBodyPartName = ""
    }
}
