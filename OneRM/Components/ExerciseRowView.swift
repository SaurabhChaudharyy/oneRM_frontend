//
//  ExerciseRowView.swift
//  OneRM
//

import SwiftUI

/// Display-only exercise row for history view
struct ExerciseRowView: View {
    let exercise: ExerciseRow
    var isPR: Bool = false
    @EnvironmentObject var userPreferences: UserPreferences
    
    var body: some View {
        HStack(spacing: 12) {
            // Exercise Name
            HStack(spacing: 6) {
                Text(exercise.exerciseName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if isPR {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Weight (converted to user's preferred unit)
            HStack(spacing: 2) {
                Text(exercise.formattedWeight(in: userPreferences.defaultWeightUnit))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(userPreferences.defaultWeightUnit.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 65, alignment: .trailing)
            
            // Reps
            HStack(spacing: 2) {
                Text("\(exercise.reps)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("reps")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 55, alignment: .trailing)
            
            // Total (converted to user's preferred unit)
            Text(exercise.formattedTotal(in: userPreferences.defaultWeightUnit))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.orange)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isPR ? Color.yellow.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    VStack(spacing: 8) {
        ExerciseRowView(
            exercise: ExerciseRow(exerciseName: "Bench Press", weight: 185, reps: 8, unit: .lbs)
        )
        ExerciseRowView(
            exercise: ExerciseRow(exerciseName: "Squat", weight: 225, reps: 5, unit: .lbs),
            isPR: true
        )
    }
    .padding()
    .background(Color(.secondarySystemGroupedBackground))
    .environmentObject(UserPreferences.shared)
}

