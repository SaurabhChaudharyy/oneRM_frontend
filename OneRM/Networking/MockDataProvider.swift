//
//  MockDataProvider.swift
//  OneRM
//

import Foundation

/// Provides mock data for development and testing
class MockDataProvider {
    static let shared = MockDataProvider()
    
    private var savedWorkouts: [WorkoutSession] = []
    
    private init() {
        setupSampleWorkouts()
    }
    
    // MARK: - Body Parts
    
    func getBodyParts() -> [BodyPart] {
        return BodyPart.defaults
    }
    
    // MARK: - Exercise Suggestions
    
    func getExerciseSuggestions(query: String) -> [String] {
        let allExercises = [
            "Bench Press", "Incline Bench Press", "Decline Bench Press", "Dumbbell Fly",
            "Deadlift", "Romanian Deadlift", "Barbell Row", "Lat Pulldown", "Pull-ups",
            "Overhead Press", "Lateral Raise", "Front Raise", "Face Pull",
            "Bicep Curl", "Hammer Curl", "Tricep Pushdown", "Skull Crusher",
            "Squat", "Leg Press", "Lunges", "Leg Curl", "Leg Extension", "Calf Raise",
            "Plank", "Crunches", "Russian Twist", "Hanging Leg Raise"
        ]
        
        guard !query.isEmpty else { return allExercises }
        return allExercises.filter { $0.lowercased().contains(query.lowercased()) }
    }
    
    // MARK: - Workouts
    
    func getWorkouts() -> [WorkoutSession] {
        return savedWorkouts.sorted { $0.date > $1.date }
    }
    
    func saveWorkout(_ workout: WorkoutSession) -> WorkoutSession {
        var saved = workout
        saved.updatedAt = Date()
        
        if let index = savedWorkouts.firstIndex(where: { $0.id == workout.id }) {
            savedWorkouts[index] = saved
        } else {
            savedWorkouts.append(saved)
        }
        return saved
    }
    
    /// Clear all saved workouts
    func clearAllWorkouts() {
        savedWorkouts = []
    }
    
    // MARK: - Personal Records
    
    func getPersonalRecords() -> [PersonalRecord] {
        // Derive personal records from saved workouts
        guard !savedWorkouts.isEmpty else { return [] }
        
        var prMap: [String: PersonalRecord] = [:]
        
        for workout in savedWorkouts {
            for exercise in workout.exercises where exercise.isValid {
                let key = exercise.exerciseName.lowercased()
                if let existing = prMap[key] {
                    // Compare by estimated 1RM
                    let existingOneRM = existing.estimatedOneRepMax
                    let newOneRM = exercise.weight * (36.0 / (37.0 - Double(exercise.reps)))
                    if newOneRM > existingOneRM {
                        prMap[key] = PersonalRecord(
                            exerciseName: exercise.exerciseName,
                            weight: exercise.weight,
                            reps: exercise.reps,
                            unit: exercise.unit,
                            date: workout.date,
                            workoutSessionId: workout.id
                        )
                    }
                } else {
                    prMap[key] = PersonalRecord(
                        exerciseName: exercise.exerciseName,
                        weight: exercise.weight,
                        reps: exercise.reps,
                        unit: exercise.unit,
                        date: workout.date,
                        workoutSessionId: workout.id
                    )
                }
            }
        }
        
        return Array(prMap.values).sorted { $0.exerciseName < $1.exerciseName }
    }
    
    // MARK: - Sample Data Setup
    
    private func setupSampleWorkouts() {
        let workout1 = WorkoutSession(
            name: "Push Day",
            date: Date().addingTimeInterval(-86400 * 2),
            bodyParts: [BodyPart(name: "Chest"), BodyPart(name: "Shoulders")],
            exercises: [
                ExerciseRow(exerciseName: "Bench Press", weight: 185, reps: 8, unit: .lbs),
                ExerciseRow(exerciseName: "Overhead Press", weight: 95, reps: 10, unit: .lbs),
                ExerciseRow(exerciseName: "Incline Dumbbell Press", weight: 60, reps: 10, unit: .lbs)
            ]
        )
        
        let workout2 = WorkoutSession(
            name: "Pull Day",
            date: Date().addingTimeInterval(-86400 * 4),
            bodyParts: [BodyPart(name: "Back"), BodyPart(name: "Arms")],
            exercises: [
                ExerciseRow(exerciseName: "Deadlift", weight: 275, reps: 5, unit: .lbs),
                ExerciseRow(exerciseName: "Barbell Row", weight: 135, reps: 8, unit: .lbs),
                ExerciseRow(exerciseName: "Bicep Curl", weight: 35, reps: 12, unit: .lbs)
            ]
        )
        
        let workout3 = WorkoutSession(
            name: "Leg Day",
            date: Date().addingTimeInterval(-86400 * 6),
            bodyParts: [BodyPart(name: "Legs")],
            exercises: [
                ExerciseRow(exerciseName: "Squat", weight: 225, reps: 6, unit: .lbs),
                ExerciseRow(exerciseName: "Leg Press", weight: 360, reps: 10, unit: .lbs),
                ExerciseRow(exerciseName: "Lunges", weight: 40, reps: 12, unit: .lbs)
            ]
        )
        
        savedWorkouts = [workout1, workout2, workout3]
    }
}

