//
//  SwiftDataModels.swift
//  OneRM
//
//  SwiftData models for persistent local storage.
//  These models mirror the domain models in WorkoutModels.swift
//  and handle database persistence.
//

import Foundation
import SwiftData

// MARK: - Persisted Workout Session

@Model
final class PersistedWorkoutSession {
    @Attribute(.unique) var id: UUID
    var name: String?
    var date: Date
    var bodyPartNames: [String]  // Store as simple strings for simplicity
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \PersistedExerciseRow.workoutSession)
    var exercises: [PersistedExerciseRow]
    
    init(
        id: UUID = UUID(),
        name: String? = nil,
        date: Date = Date(),
        bodyPartNames: [String] = [],
        exercises: [PersistedExerciseRow] = []
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.bodyPartNames = bodyPartNames
        self.exercises = exercises
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// Convert to domain model
    func toDomainModel() -> WorkoutSession {
        let bodyParts = bodyPartNames.map { BodyPart(name: $0) }
        let exerciseRows = exercises.sorted { $0.order < $1.order }.map { $0.toDomainModel() }
        
        var session = WorkoutSession(
            id: id,
            name: name,
            date: date,
            bodyParts: bodyParts,
            exercises: exerciseRows
        )
        // Preserve original timestamps
        session.createdAt = createdAt
        session.updatedAt = updatedAt
        return session
    }
    
    /// Update from domain model
    func update(from session: WorkoutSession) {
        self.name = session.name
        self.date = session.date
        self.bodyPartNames = session.bodyParts.map { $0.name }
        self.updatedAt = Date()
        // Exercises are updated separately to handle relationships properly
    }
}

// MARK: - Persisted Exercise Row

@Model
final class PersistedExerciseRow {
    @Attribute(.unique) var id: UUID
    var exerciseName: String
    var weight: Double
    var reps: Int
    var unitRawValue: String  // Store WeightUnit as string
    var order: Int  // To maintain exercise order within workout
    
    var workoutSession: PersistedWorkoutSession?
    
    init(
        id: UUID = UUID(),
        exerciseName: String = "",
        weight: Double = 0,
        reps: Int = 0,
        unitRawValue: String = "kg",
        order: Int = 0
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.unitRawValue = unitRawValue
        self.order = order
    }
    
    /// Convert to domain model
    func toDomainModel() -> ExerciseRow {
        ExerciseRow(
            id: id,
            exerciseName: exerciseName,
            weight: weight,
            reps: reps,
            unit: WeightUnit(rawValue: unitRawValue) ?? .kg
        )
    }
    
    /// Update from domain model
    func update(from row: ExerciseRow, order: Int) {
        self.exerciseName = row.exerciseName
        self.weight = row.weight
        self.reps = row.reps
        self.unitRawValue = row.unit.rawValue
        self.order = order
    }
}

// MARK: - Persisted Personal Record

@Model
final class PersistedPersonalRecord {
    @Attribute(.unique) var id: UUID
    var exerciseName: String
    var weight: Double
    var reps: Int
    var unitRawValue: String
    var date: Date
    var workoutSessionId: UUID
    
    init(
        id: UUID = UUID(),
        exerciseName: String,
        weight: Double,
        reps: Int,
        unitRawValue: String,
        date: Date,
        workoutSessionId: UUID
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.unitRawValue = unitRawValue
        self.date = date
        self.workoutSessionId = workoutSessionId
    }
    
    /// Convert to domain model
    func toDomainModel() -> PersonalRecord {
        PersonalRecord(
            id: id,
            exerciseName: exerciseName,
            weight: weight,
            reps: reps,
            unit: WeightUnit(rawValue: unitRawValue) ?? .kg,
            date: date,
            workoutSessionId: workoutSessionId
        )
    }
}

// MARK: - Factory Extensions

extension PersistedWorkoutSession {
    /// Create from domain model
    static func from(_ session: WorkoutSession) -> PersistedWorkoutSession {
        let persisted = PersistedWorkoutSession(
            id: session.id,
            name: session.name,
            date: session.date,
            bodyPartNames: session.bodyParts.map { $0.name }
        )
        persisted.createdAt = session.createdAt
        persisted.updatedAt = session.updatedAt
        return persisted
    }
}

extension PersistedExerciseRow {
    /// Create from domain model with order
    static func from(_ row: ExerciseRow, order: Int) -> PersistedExerciseRow {
        PersistedExerciseRow(
            id: row.id,
            exerciseName: row.exerciseName,
            weight: row.weight,
            reps: row.reps,
            unitRawValue: row.unit.rawValue,
            order: order
        )
    }
}

extension PersistedPersonalRecord {
    /// Create from domain model
    static func from(_ record: PersonalRecord) -> PersistedPersonalRecord {
        PersistedPersonalRecord(
            id: record.id,
            exerciseName: record.exerciseName,
            weight: record.weight,
            reps: record.reps,
            unitRawValue: record.unit.rawValue,
            date: record.date,
            workoutSessionId: record.workoutSessionId
        )
    }
}
