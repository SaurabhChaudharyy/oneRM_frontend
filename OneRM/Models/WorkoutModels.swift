//
//  WorkoutModels.swift
//  OneRM
//

import Foundation

// MARK: - Weight Unit
enum WeightUnit: String, Codable, CaseIterable {
    case lbs = "lbs"
    case kg = "kg"
    
    var displayName: String { rawValue }
    
    func convert(_ weight: Double, to targetUnit: WeightUnit) -> Double {
        if self == targetUnit { return weight }
        switch (self, targetUnit) {
        case (.lbs, .kg): return weight * 0.453592
        case (.kg, .lbs): return weight * 2.20462
        default: return weight
        }
    }
}

// MARK: - Body Part
struct BodyPart: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var isCustom: Bool
    
    init(id: UUID = UUID(), name: String, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.isCustom = isCustom
    }
    
    static let defaults: [BodyPart] = [
        BodyPart(name: "Chest"),
        BodyPart(name: "Back"),
        BodyPart(name: "Shoulders"),
        BodyPart(name: "Arms"),
        BodyPart(name: "Legs"),
        BodyPart(name: "Core/Abs"),
        BodyPart(name: "Full Body")
    ]
}

// MARK: - Exercise Row
struct ExerciseRow: Identifiable, Codable {
    let id: UUID
    var exerciseName: String
    var weight: Double
    var reps: Int
    var unit: WeightUnit
    
    var totalVolume: Double { weight * Double(reps) }
    
    var formattedTotal: String {
        let total = totalVolume
        if total == 0 { return "-" }
        return total.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(total)) \(unit.displayName)"
            : String(format: "%.1f \(unit.displayName)", total)
    }
    
    init(id: UUID = UUID(), exerciseName: String = "", weight: Double = 0, reps: Int = 0, unit: WeightUnit = .lbs) {
        self.id = id
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.unit = unit
    }
    
    var isValid: Bool { !exerciseName.trimmingCharacters(in: .whitespaces).isEmpty && weight > 0 && reps > 0 }
    var isEmpty: Bool { exerciseName.trimmingCharacters(in: .whitespaces).isEmpty && weight == 0 && reps == 0 }
    
    // MARK: - Unit Conversion Methods
    
    /// Get the weight converted to the user's preferred display unit
    func displayWeight(in displayUnit: WeightUnit) -> Double {
        return unit.convert(weight, to: displayUnit)
    }
    
    /// Get the total volume converted to the user's preferred display unit
    func displayTotalVolume(in displayUnit: WeightUnit) -> Double {
        return unit.convert(totalVolume, to: displayUnit)
    }
    
    /// Get formatted weight string in the user's preferred display unit
    func formattedWeight(in displayUnit: WeightUnit) -> String {
        let convertedWeight = displayWeight(in: displayUnit)
        if convertedWeight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(convertedWeight))"
        }
        return String(format: "%.1f", convertedWeight)
    }
    
    /// Get formatted total string in the user's preferred display unit
    func formattedTotal(in displayUnit: WeightUnit) -> String {
        let total = displayTotalVolume(in: displayUnit)
        if total == 0 { return "-" }
        return total.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(total)) \(displayUnit.displayName)"
            : String(format: "%.1f \(displayUnit.displayName)", total)
    }
}

// MARK: - Workout Session
struct WorkoutSession: Identifiable, Codable {
    let id: UUID
    var name: String?
    var date: Date
    var bodyParts: [BodyPart]
    var exercises: [ExerciseRow]
    var createdAt: Date
    var updatedAt: Date
    
    var totalVolume: Double { exercises.reduce(0) { $0 + $1.totalVolume } }
    var exerciseCount: Int { exercises.filter { $0.isValid }.count }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var displayName: String {
        if let name = name, !name.trimmingCharacters(in: .whitespaces).isEmpty { return name }
        return formattedDate
    }
    
    init(id: UUID = UUID(), name: String? = nil, date: Date = Date(), bodyParts: [BodyPart] = [], exercises: [ExerciseRow] = []) {
        self.id = id
        self.name = name
        self.date = date
        self.bodyParts = bodyParts
        self.exercises = exercises
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Unit Conversion Methods
    
    /// Get total volume converted to displayed unit
    func displayTotalVolume(in displayUnit: WeightUnit) -> Double {
        return exercises.reduce(0) { $0 + $1.displayTotalVolume(in: displayUnit) }
    }
}

// MARK: - Personal Record
struct PersonalRecord: Identifiable, Codable {
    let id: UUID
    let exerciseName: String
    let weight: Double
    let reps: Int
    let unit: WeightUnit
    let date: Date
    let workoutSessionId: UUID
    
    init(id: UUID = UUID(), exerciseName: String, weight: Double, reps: Int, unit: WeightUnit, date: Date, workoutSessionId: UUID) {
        self.id = id
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.unit = unit
        self.date = date
        self.workoutSessionId = workoutSessionId
    }
    
    var estimatedOneRepMax: Double {
        guard reps > 0 && reps < 37 else { return weight }
        return weight * (36.0 / (37.0 - Double(reps)))
    }
    
    // MARK: - Unit Conversion Methods
    
    /// Get the weight converted to the user's preferred display unit
    func displayWeight(in displayUnit: WeightUnit) -> Double {
        return unit.convert(weight, to: displayUnit)
    }
    
    /// Get formatted weight string in the user's preferred display unit
    func formattedWeight(in displayUnit: WeightUnit) -> String {
        let convertedWeight = displayWeight(in: displayUnit)
        if convertedWeight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(convertedWeight))"
        }
        return String(format: "%.1f", convertedWeight)
    }
}

