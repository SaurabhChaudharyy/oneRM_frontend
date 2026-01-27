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
    
    private let repository = WorkoutRepository.shared
    
    var canContinue: Bool {
        !selectedBodyParts.isEmpty
    }
    
    var selectedBodyPartsList: [BodyPart] {
        availableBodyParts.filter { selectedBodyParts.contains($0.id) }
    }
    
    init() {
        Task { await loadBodyParts() }
    }
    
    func loadBodyParts() async {
        isLoading = true
        availableBodyParts = await repository.fetchBodyParts()
        isLoading = false
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
