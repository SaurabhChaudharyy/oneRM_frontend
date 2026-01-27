//
//  OneRMTests.swift
//  OneRMTests
//

import XCTest
@testable import OneRM

final class OneRMTests: XCTestCase {
    
    // MARK: - Exercise Row Tests
    
    func testExerciseRowTotalVolumeCalculation() {
        let row = ExerciseRow(exerciseName: "Bench Press", weight: 135, reps: 10, unit: .lbs)
        XCTAssertEqual(row.totalVolume, 1350, "Total volume should be weight × reps")
    }
    
    func testExerciseRowTotalVolumeWithZeroWeight() {
        let row = ExerciseRow(exerciseName: "Squat", weight: 0, reps: 10, unit: .lbs)
        XCTAssertEqual(row.totalVolume, 0, "Total volume should be 0 when weight is 0")
    }
    
    func testExerciseRowTotalVolumeWithZeroReps() {
        let row = ExerciseRow(exerciseName: "Deadlift", weight: 225, reps: 0, unit: .lbs)
        XCTAssertEqual(row.totalVolume, 0, "Total volume should be 0 when reps is 0")
    }
    
    func testExerciseRowIsValid() {
        let validRow = ExerciseRow(exerciseName: "Bench Press", weight: 135, reps: 8, unit: .lbs)
        let invalidRow = ExerciseRow(exerciseName: "", weight: 135, reps: 8, unit: .lbs)
        let emptyWeightRow = ExerciseRow(exerciseName: "Squat", weight: 0, reps: 8, unit: .lbs)
        
        XCTAssertTrue(validRow.isValid, "Row with name, weight, and reps should be valid")
        XCTAssertFalse(invalidRow.isValid, "Row without exercise name should be invalid")
        XCTAssertFalse(emptyWeightRow.isValid, "Row without weight should be invalid")
    }
    
    func testExerciseRowIsEmpty() {
        let emptyRow = ExerciseRow()
        let partialRow = ExerciseRow(exerciseName: "Squat", weight: 0, reps: 0, unit: .lbs)
        
        XCTAssertTrue(emptyRow.isEmpty, "Default row should be empty")
        XCTAssertFalse(partialRow.isEmpty, "Row with exercise name should not be empty")
    }
    
    // MARK: - Workout Session Tests
    
    func testWorkoutSessionTotalVolume() {
        let workout = WorkoutSession(
            name: "Test Workout",
            exercises: [
                ExerciseRow(exerciseName: "Bench", weight: 135, reps: 10, unit: .lbs),
                ExerciseRow(exerciseName: "Squat", weight: 185, reps: 8, unit: .lbs),
                ExerciseRow(exerciseName: "Deadlift", weight: 225, reps: 5, unit: .lbs)
            ]
        )
        
        let expectedTotal = (135.0 * 10) + (185.0 * 8) + (225.0 * 5)
        XCTAssertEqual(workout.totalVolume, expectedTotal, "Total volume should sum all exercises")
    }
    
    func testWorkoutSessionExerciseCount() {
        let workout = WorkoutSession(
            name: "Test Workout",
            exercises: [
                ExerciseRow(exerciseName: "Bench", weight: 135, reps: 10, unit: .lbs),
                ExerciseRow(exerciseName: "", weight: 0, reps: 0, unit: .lbs), // Invalid
                ExerciseRow(exerciseName: "Squat", weight: 185, reps: 8, unit: .lbs)
            ]
        )
        
        XCTAssertEqual(workout.exerciseCount, 2, "Should only count valid exercises")
    }
    
    func testWorkoutSessionDisplayName() {
        let namedWorkout = WorkoutSession(name: "Push Day")
        let unnamedWorkout = WorkoutSession(name: nil)
        
        XCTAssertEqual(namedWorkout.displayName, "Push Day", "Should use workout name if provided")
        XCTAssertFalse(unnamedWorkout.displayName.isEmpty, "Should use formatted date if no name")
    }
    
    // MARK: - Weight Unit Tests
    
    func testWeightUnitConversion() {
        let lbs = WeightUnit.lbs
        let kg = WeightUnit.kg
        
        // 100 lbs ≈ 45.36 kg
        let convertedToKg = lbs.convert(100, to: kg)
        XCTAssertEqual(convertedToKg, 45.3592, accuracy: 0.001)
        
        // 100 kg ≈ 220.46 lbs
        let convertedToLbs = kg.convert(100, to: lbs)
        XCTAssertEqual(convertedToLbs, 220.462, accuracy: 0.001)
        
        // Same unit should return same value
        XCTAssertEqual(lbs.convert(100, to: lbs), 100)
        XCTAssertEqual(kg.convert(100, to: kg), 100)
    }
    
    // MARK: - Body Part Tests
    
    func testDefaultBodyPartsExist() {
        let defaults = BodyPart.defaults
        XCTAssertFalse(defaults.isEmpty, "Should have default body parts")
        XCTAssertTrue(defaults.count >= 7, "Should have at least 7 default body parts")
    }
    
    func testDefaultBodyPartsAreNotCustom() {
        let defaults = BodyPart.defaults
        for bodyPart in defaults {
            XCTAssertFalse(bodyPart.isCustom, "\(bodyPart.name) should not be marked as custom")
        }
    }
    
    // MARK: - API Models Tests
    
    func testWorkoutSessionToRequestConversion() {
        let workout = WorkoutSession(
            name: "Test",
            date: Date(),
            bodyParts: [BodyPart(name: "Chest")],
            exercises: [ExerciseRow(exerciseName: "Bench", weight: 135, reps: 10, unit: .lbs)]
        )
        
        let request = workout.toRequest()
        XCTAssertEqual(request.name, "Test")
        XCTAssertEqual(request.bodyParts.count, 1)
        XCTAssertEqual(request.exercises.count, 1)
    }
}
