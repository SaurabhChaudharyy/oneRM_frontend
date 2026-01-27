//
//  ExerciseTrackingView.swift
//  OneRM
//

import SwiftUI

/// Screen 2: Exercise Tracking - Log exercises with weight, reps, and calculated totals
struct ExerciseTrackingView: View {
    @StateObject private var viewModel: ExerciseTrackingViewModel
    @EnvironmentObject var userPreferences: UserPreferences
    @Environment(\.dismiss) private var dismiss
    @State private var showingDiscardAlert = false
    @State private var showingSuccessToast = false
    @FocusState private var focusedField: FocusField?
    
    enum FocusField: Hashable {
        case exercise(UUID)
        case weight(UUID)
        case reps(UUID)
    }
    
    init(workoutSession: WorkoutSession) {
        _viewModel = StateObject(wrappedValue: ExerciseTrackingViewModel(workoutSession: workoutSession))
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    headerInfo
                    columnHeaders
                    exerciseRows
                    addRowButton
                    summarySection
                }
                .padding()
                .contentShape(Rectangle())
            }
            .scrollDismissesKeyboard(.immediately)
            .simultaneousGesture(
                TapGesture().onEnded {
                    focusedField = nil
                }
            )
        }
        .navigationTitle(viewModel.workoutSession.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.hasUnsavedChanges)
        .toolbar {
            toolbarContent
            
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
                .fontWeight(.semibold)
            }
        }
        .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) { }
        } message: {
            Text("You have unsaved changes. Are you sure you want to leave?")
        }
        .alert("Workout Saved!", isPresented: $viewModel.saveSuccess) {
            Button("OK") {
                viewModel.clearSaveStatus()
                // Navigation back to root is handled by the parent view's navigationDestination
                dismiss()
            }
        } message: {
            Text("Your workout has been saved successfully.")
        }
        .alert("Save Failed", isPresented: .constant(viewModel.saveError != nil)) {
            Button("Try Again") {
                Task { await viewModel.saveWorkout() }
            }
            Button("Cancel", role: .cancel) {
                viewModel.clearSaveStatus()
            }
        } message: {
            Text(viewModel.saveError ?? "Unknown error occurred")
        }
        .overlay {
            if viewModel.isSaving {
                LoadingView(message: "Saving workout...")
            }
        }
    }
    
    // MARK: - Header Info
    
    private var headerInfo: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.workoutSession.formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(viewModel.workoutSession.bodyParts.prefix(3)) { part in
                        Text(part.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.15))
                            .foregroundStyle(.primary)
                            .clipShape(Capsule())
                    }
                    if viewModel.workoutSession.bodyParts.count > 3 {
                        Text("+\(viewModel.workoutSession.bodyParts.count - 3)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Column Headers
    
    private var columnHeaders: some View {
        HStack(spacing: 8) {
            Text("Exercise")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Weight")
                .frame(width: 70)
            Text("Reps")
                .frame(width: 50)
            Text("Total")
                .frame(width: 80)
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Exercise Rows
    
    private var exerciseRows: some View {
        LazyVStack(spacing: 8) {
            ForEach(viewModel.exerciseRows) { row in
                ExerciseInputRow(
                    row: row,
                    viewModel: viewModel,
                    focusedField: _focusedField
                )
                .id(row.id)
            }
            .onDelete(perform: viewModel.deleteRow)
        }
    }
    
    // MARK: - Add Row Button
    
    private var addRowButton: some View {
        Button {
            viewModel.addRow()
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Exercise Row")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .foregroundStyle(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Volume")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(viewModel.totalVolume)) \(userPreferences.defaultWeightUnit.displayName)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.validExerciseCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(
            Color(.tertiarySystemGroupedBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.2), lineWidth: 1))
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if viewModel.hasUnsavedChanges {
                Button("Cancel") { showingDiscardAlert = true }
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button {
                focusedField = nil
                Task { await viewModel.saveWorkout() }
            } label: {
                Text("Save")
                    .fontWeight(.semibold)
            }
            .disabled(!viewModel.canSave)
        }
    }
}

// MARK: - Exercise Input Row

struct ExerciseInputRow: View {
    let row: ExerciseRow
    var viewModel: ExerciseTrackingViewModel // Removed @ObservedObject to prevent unnecessary redraws
    @EnvironmentObject var userPreferences: UserPreferences
    @FocusState var focusedField: ExerciseTrackingView.FocusField?
    
    @State private var exerciseText: String = ""
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    
    // Character limits
    private let maxExerciseNameLength = 30
    private let maxWeightLength = 6
    private let maxRepsLength = 4
    
    var body: some View {
        HStack(spacing: 8) {
            // Exercise Name (limited to 30 characters)
            TextField("Exercise", text: $exerciseText)
                .textFieldStyle(.plain)
                .focused($focusedField, equals: .exercise(row.id))
                .onChange(of: exerciseText) { _, newValue in
                    // Limit character input
                    if newValue.count > maxExerciseNameLength {
                        exerciseText = String(newValue.prefix(maxExerciseNameLength))
                    }
                    viewModel.updateExerciseName(for: row.id, name: exerciseText)
                }
                .frame(maxWidth: .infinity)
            
            // Weight (limited to 6 characters, uses default unit)
            HStack(spacing: 4) {
                TextField("0", text: $weightText)
                    .textFieldStyle(.plain)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .weight(row.id))
                    .onChange(of: weightText) { _, newValue in
                        // Limit character input
                        if newValue.count > maxWeightLength {
                            weightText = String(newValue.prefix(maxWeightLength))
                        }
                        if let weight = Double(weightText) {
                            viewModel.updateWeight(for: row.id, weight: weight)
                        }
                    }
                    .frame(width: 45)
                    .multilineTextAlignment(.trailing)
                
                // Static unit label (no toggle - uses default unit from settings)
                Text(userPreferences.defaultWeightUnit.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 70)
            
            // Reps (limited to 4 characters)
            TextField("0", text: $repsText)
                .textFieldStyle(.plain)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .reps(row.id))
                .onChange(of: repsText) { _, newValue in
                    // Limit character input
                    if newValue.count > maxRepsLength {
                        repsText = String(newValue.prefix(maxRepsLength))
                    }
                    if let reps = Int(repsText) {
                        viewModel.updateReps(for: row.id, reps: reps)
                    }
                }
                .frame(width: 50)
                .multilineTextAlignment(.center)
            
            // Total (calculated, read-only) - uses default unit
            Text(row.formattedTotal(in: userPreferences.defaultWeightUnit))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(row.totalVolume > 0 ? .primary : .secondary)
                .frame(width: 80)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.deleteRow(row)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .onAppear {
            exerciseText = row.exerciseName
            weightText = row.weight > 0 ? String(format: "%.0f", row.weight) : ""
            repsText = row.reps > 0 ? "\(row.reps)" : ""
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseTrackingView(workoutSession: WorkoutSession(
            name: "Push Day",
            bodyParts: [BodyPart(name: "Chest"), BodyPart(name: "Shoulders")]
        ))
    }
    .environmentObject(UserPreferences.shared)
}
