//
//  WorkoutCardView.swift
//  OneRM
//

import SwiftUI

/// Card view for displaying a workout session in history
struct WorkoutCardView: View {
    let workout: WorkoutSession
    @EnvironmentObject var userPreferences: UserPreferences
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(workout.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(workout.exerciseCount) exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(Int(workout.displayTotalVolume(in: userPreferences.defaultWeightUnit))) \(userPreferences.defaultWeightUnit.displayName)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
            }
            
            // Body Parts
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(workout.bodyParts) { part in
                        Text(part.name)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.primary.opacity(0.15))
                            .foregroundStyle(.primary)
                            .clipShape(Capsule())
                    }
                }
            }
            
            // Expandable exercises
            if isExpanded && !workout.exercises.isEmpty {
                Divider()
                
                VStack(spacing: 4) {
                    ForEach(workout.exercises.filter { $0.isValid }) { exercise in
                        ExerciseRowView(exercise: exercise)
                            .environmentObject(userPreferences)
                    }
                }
            }
            
            // Expand/Collapse button
            if !workout.exercises.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                    HapticManager.shared.light()
                } label: {
                    HStack {
                        Text(isExpanded ? "Show Less" : "Show Exercises")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            WorkoutCardView(workout: WorkoutSession(
                name: "Push Day",
                date: Date(),
                bodyParts: [BodyPart(name: "Chest"), BodyPart(name: "Shoulders"), BodyPart(name: "Arms")],
                exercises: [
                    ExerciseRow(exerciseName: "Bench Press", weight: 185, reps: 8, unit: .lbs),
                    ExerciseRow(exerciseName: "Overhead Press", weight: 95, reps: 10, unit: .lbs),
                    ExerciseRow(exerciseName: "Tricep Pushdown", weight: 50, reps: 12, unit: .lbs)
                ]
            ))
            
            WorkoutCardView(workout: WorkoutSession(
                name: nil,
                date: Date().addingTimeInterval(-86400 * 2),
                bodyParts: [BodyPart(name: "Legs")],
                exercises: [
                    ExerciseRow(exerciseName: "Squat", weight: 225, reps: 5, unit: .lbs)
                ]
            ))
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .environmentObject(UserPreferences.shared)
}

