//
//  WorkoutHistoryViewModel.swift
//  OneRM
//

import Foundation
import SwiftUI

/// ViewModel for workout history screen
@MainActor
class WorkoutHistoryViewModel: ObservableObject {
    @Published var workouts: [WorkoutSession] = []
    @Published var filteredWorkouts: [WorkoutSession] = []
    @Published var searchText: String = "" {
        didSet { filterWorkouts() }
    }
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: String?
    @Published var personalRecords: [PersonalRecord] = []
    
    private let repository = WorkoutRepository.shared
    
    var isEmpty: Bool {
        workouts.isEmpty
    }
    
    var hasSearchResults: Bool {
        !filteredWorkouts.isEmpty || searchText.isEmpty
    }
    
    init() {
        Task { await loadWorkouts() }
    }
    
    func loadWorkouts() async {
        isLoading = true
        error = nil
        
        async let workoutsTask = repository.fetchWorkouts()
        async let prsTask = repository.fetchPersonalRecords()
        
        workouts = await workoutsTask
        personalRecords = await prsTask
        filterWorkouts()
        
        isLoading = false
    }
    
    func refresh() async {
        isRefreshing = true
        await loadWorkouts()
        isRefreshing = false
        HapticManager.shared.light()
    }
    
    private func filterWorkouts() {
        if searchText.isEmpty {
            filteredWorkouts = workouts
        } else {
            filteredWorkouts = workouts.filter { workout in
                let nameMatch = workout.name?.lowercased().contains(searchText.lowercased()) ?? false
                let bodyPartMatch = workout.bodyParts.contains { $0.name.lowercased().contains(searchText.lowercased()) }
                let exerciseMatch = workout.exercises.contains { $0.exerciseName.lowercased().contains(searchText.lowercased()) }
                return nameMatch || bodyPartMatch || exerciseMatch
            }
        }
    }
    
    func deleteWorkout(_ workout: WorkoutSession) {
        workouts.removeAll { $0.id == workout.id }
        filterWorkouts()
        HapticManager.shared.light()
    }
    
    func exportWorkouts() -> String {
        var csv = "Date,Name,Body Parts,Exercise,Weight,Reps,Unit,Total\n"
        
        for workout in workouts {
            let bodyParts = workout.bodyParts.map { $0.name }.joined(separator: "; ")
            for exercise in workout.exercises where exercise.isValid {
                csv += "\"\(workout.formattedDate)\","
                csv += "\"\(workout.name ?? "")\","
                csv += "\"\(bodyParts)\","
                csv += "\"\(exercise.exerciseName)\","
                csv += "\(exercise.weight),"
                csv += "\(exercise.reps),"
                csv += "\(exercise.unit.rawValue),"
                csv += "\(exercise.totalVolume)\n"
            }
        }
        
        return csv
    }
}
