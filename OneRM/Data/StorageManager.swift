//
//  StorageManager.swift
//  OneRM
//
//  Handles all CRUD operations for workout data using SwiftData.
//  This is the data access layer that abstracts SwiftData operations.
//

import Foundation
import SwiftData

/// Manages local data storage operations using SwiftData
@MainActor
final class StorageManager {
    /// Shared singleton instance
    static let shared = StorageManager()
    
    private let dataController = DataController.shared
    
    private var context: ModelContext {
        dataController.context
    }
    
    private init() {}
    
    // MARK: - Workout Sessions
    
    /// Fetch all workout sessions, sorted by date (newest first)
    func fetchWorkouts() -> [WorkoutSession] {
        let descriptor = FetchDescriptor<PersistedWorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let results = try context.fetch(descriptor)
            print("📖 SwiftData: Fetched \(results.count) workouts")
            return results.map { $0.toDomainModel() }
        } catch {
            print("❌ SwiftData: Failed to fetch workouts: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Save a new workout session or update existing one
    func saveWorkout(_ workout: WorkoutSession) -> WorkoutSession {
        // Normalize exercise names before saving (lowercase + trim for consistent matching)
        var normalizedWorkout = workout
        normalizedWorkout.exercises = workout.exercises.map { exercise in
            var normalizedExercise = exercise
            normalizedExercise.exerciseName = normalizeExerciseName(exercise.exerciseName)
            return normalizedExercise
        }
        
        // Check if workout already exists
        let existingDescriptor = FetchDescriptor<PersistedWorkoutSession>(
            predicate: #Predicate { $0.id == normalizedWorkout.id }
        )
        
        do {
            let existing = try context.fetch(existingDescriptor).first
            
            if let existing = existing {
                // Update existing workout
                existing.update(from: normalizedWorkout)
                updateExercises(for: existing, from: normalizedWorkout.exercises)
                print("✏️ SwiftData: Updated existing workout: \(normalizedWorkout.id)")
            } else {
                // Create new workout
                let persisted = PersistedWorkoutSession.from(normalizedWorkout)
                context.insert(persisted)
                
                // Add exercises with order
                for (index, exercise) in normalizedWorkout.exercises.enumerated() where exercise.isValid {
                    let persistedExercise = PersistedExerciseRow.from(exercise, order: index)
                    persistedExercise.workoutSession = persisted
                    context.insert(persistedExercise)
                }
                print("➕ SwiftData: Created new workout: \(normalizedWorkout.id)")
            }
            
            // Update personal records
            updatePersonalRecords(from: normalizedWorkout)
            
            dataController.save()
            
        } catch {
            print("❌ SwiftData: Failed to save workout: \(error.localizedDescription)")
        }
        
        return normalizedWorkout
    }
    
    /// Normalize exercise name: trim whitespace and convert to lowercase for consistent matching
    private func normalizeExerciseName(_ name: String) -> String {
        return name.trimmingCharacters(in: .whitespaces).lowercased()
    }
    
    /// Delete a workout session
    func deleteWorkout(_ workout: WorkoutSession) {
        let descriptor = FetchDescriptor<PersistedWorkoutSession>(
            predicate: #Predicate { $0.id == workout.id }
        )
        
        do {
            if let existing = try context.fetch(descriptor).first {
                context.delete(existing)
                dataController.save()
                print("🗑️ SwiftData: Deleted workout: \(workout.id)")
            }
        } catch {
            print("❌ SwiftData: Failed to delete workout: \(error.localizedDescription)")
        }
    }
    
    /// Delete a workout by ID
    func deleteWorkout(id: UUID) {
        let descriptor = FetchDescriptor<PersistedWorkoutSession>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            if let existing = try context.fetch(descriptor).first {
                context.delete(existing)
                dataController.save()
                print("🗑️ SwiftData: Deleted workout: \(id)")
            }
        } catch {
            print("❌ SwiftData: Failed to delete workout: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Personal Records
    
    /// Fetch all personal records
    func fetchPersonalRecords() -> [PersonalRecord] {
        let descriptor = FetchDescriptor<PersistedPersonalRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let results = try context.fetch(descriptor)
            print("📖 SwiftData: Fetched \(results.count) personal records")
            return results.map { $0.toDomainModel() }
        } catch {
            print("❌ SwiftData: Failed to fetch personal records: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Get best personal record for each exercise (highest weight * reps)
    func fetchBestPersonalRecords() -> [PersonalRecord] {
        let allRecords = fetchPersonalRecords()
        
        // Group by exercise name and keep the best one (highest volume = weight * reps)
        var bestByExercise: [String: PersonalRecord] = [:]
        
        for record in allRecords {
            let volume = record.weight * Double(record.reps)
            if let existing = bestByExercise[record.exerciseName] {
                let existingVolume = existing.weight * Double(existing.reps)
                if volume > existingVolume {
                    bestByExercise[record.exerciseName] = record
                }
            } else {
                bestByExercise[record.exerciseName] = record
            }
        }
        
        return Array(bestByExercise.values).sorted { $0.date > $1.date }
    }
    
    /// Fetch workouts for a specific date
    func fetchWorkoutsForDate(_ date: Date) -> [WorkoutSession] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<PersistedWorkoutSession>(
            predicate: #Predicate { workout in
                workout.date >= startOfDay && workout.date < endOfDay
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let results = try context.fetch(descriptor)
            return results.map { $0.toDomainModel() }
        } catch {
            print("❌ SwiftData: Failed to fetch workouts for date: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch all dates that have workouts (for calendar display)
    func fetchWorkoutDates() -> [Date: [WorkoutSession]] {
        let workouts = fetchWorkouts()
        let calendar = Calendar.current
        
        var dateGroups: [Date: [WorkoutSession]] = [:]
        for workout in workouts {
            let startOfDay = calendar.startOfDay(for: workout.date)
            if dateGroups[startOfDay] != nil {
                dateGroups[startOfDay]?.append(workout)
            } else {
                dateGroups[startOfDay] = [workout]
            }
        }
        
        return dateGroups
    }
    
    /// Fetch previous exercise data for a given exercise name and body parts
    /// Returns all previous exercises matching the name (normalized) to show history/PRs
    func fetchPreviousExerciseData(exerciseName: String, bodyPartNames: [String]) -> [ExerciseRow] {
        guard !exerciseName.isEmpty else { return [] }
        
        let normalizedName = exerciseName.lowercased().trimmingCharacters(in: .whitespaces)
        let normalizedBodyParts = Set(bodyPartNames.map { $0.lowercased().trimmingCharacters(in: .whitespaces) })
        
        let allWorkouts = fetchWorkouts()
        var matchingExercises: [ExerciseRow] = []
        
        for workout in allWorkouts {
            // Check if workout has matching body parts
            let workoutBodyParts = Set(workout.bodyParts.map { $0.name.lowercased().trimmingCharacters(in: .whitespaces) })
            let hasMatchingBodyPart = !normalizedBodyParts.isDisjoint(with: workoutBodyParts)
            
            if hasMatchingBodyPart {
                // Find exercises with matching name
                for exercise in workout.exercises where exercise.isValid {
                    let exerciseNormalized = exercise.exerciseName.lowercased().trimmingCharacters(in: .whitespaces)
                    if exerciseNormalized == normalizedName {
                        matchingExercises.append(exercise)
                    }
                }
            }
        }
        
        // Sort by weight * reps (volume) descending to show best performances first
        return matchingExercises.sorted { ($0.weight * Double($0.reps)) > ($1.weight * Double($1.reps)) }
    }
    
    /// Get best PR for a specific exercise name
    func fetchBestPRForExercise(exerciseName: String) -> PersonalRecord? {
        let normalizedName = exerciseName.lowercased().trimmingCharacters(in: .whitespaces)
        let allRecords = fetchPersonalRecords()
        
        let matchingRecords = allRecords.filter {
            $0.exerciseName.lowercased().trimmingCharacters(in: .whitespaces) == normalizedName
        }
        
        // Return the one with highest volume
        return matchingRecords.max(by: { ($0.weight * Double($0.reps)) < ($1.weight * Double($1.reps)) })
    }
    
    // MARK: - Clear All Data
    
    /// Clear all workout data from storage
    func clearAllData() {
        dataController.deleteAllData()
        print("🧹 SwiftData: All data cleared")
    }
    
    // MARK: - Private Helpers
    
    /// Update exercises for an existing workout
    private func updateExercises(for workout: PersistedWorkoutSession, from exercises: [ExerciseRow]) {
        // Remove old exercises
        for exercise in workout.exercises {
            context.delete(exercise)
        }
        
        // Add new exercises
        for (index, exercise) in exercises.enumerated() where exercise.isValid {
            let persistedExercise = PersistedExerciseRow.from(exercise, order: index)
            persistedExercise.workoutSession = workout
            context.insert(persistedExercise)
        }
    }
    
    /// Update personal records based on workout exercises
    private func updatePersonalRecords(from workout: WorkoutSession) {
        for exercise in workout.exercises where exercise.isValid {
            // Check if this is a new personal record for this exercise
            let exerciseName = exercise.exerciseName.lowercased().trimmingCharacters(in: .whitespaces)
            let existingDescriptor = FetchDescriptor<PersistedPersonalRecord>(
                predicate: #Predicate { record in
                    record.exerciseName.localizedStandardContains(exerciseName)
                }
            )
            
            do {
                let existingRecords = try context.fetch(existingDescriptor)
                let exerciseVolume = exercise.weight * Double(exercise.reps)
                
                // Check if this beats any existing record
                let isBetterThanAll = existingRecords.allSatisfy { existing in
                    let existingVolume = existing.weight * Double(existing.reps)
                    return exerciseVolume > existingVolume
                }
                
                if existingRecords.isEmpty || isBetterThanAll {
                    // Create new personal record
                    let newRecord = PersonalRecord(
                        exerciseName: exercise.exerciseName,
                        weight: exercise.weight,
                        reps: exercise.reps,
                        unit: exercise.unit,
                        date: workout.date,
                        workoutSessionId: workout.id
                    )
                    let persistedRecord = PersistedPersonalRecord.from(newRecord)
                    context.insert(persistedRecord)
                    print("🏆 SwiftData: New personal record for \(exercise.exerciseName)")
                }
            } catch {
                print("❌ SwiftData: Failed to check personal records: \(error.localizedDescription)")
            }
        }
    }
}
