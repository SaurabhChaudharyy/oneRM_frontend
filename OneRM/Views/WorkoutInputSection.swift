//
//  WorkoutInputSection.swift
//  OneRM
//

import SwiftUI

/// Isolated input section to prevent full view re-renders during typing
struct WorkoutInputSection: View {
    @Binding var workoutName: String
    @Binding var workoutDate: Date
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 48))
                    .foregroundStyle(.primary)
                
                Text("Let's Get Started")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Configure your workout session")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            
            // Date Section
            VStack(alignment: .leading, spacing: 12) {
                Label("Workout Date", systemImage: "calendar")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                DatePicker(
                    "Select Date",
                    selection: $workoutDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            // Name Section
            VStack(alignment: .leading, spacing: 12) {
                Label("Workout Name (Optional)", systemImage: "pencil")
                    .font(.headline)
                
                TextField("e.g., Push Day, Leg Day", text: $workoutName)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
