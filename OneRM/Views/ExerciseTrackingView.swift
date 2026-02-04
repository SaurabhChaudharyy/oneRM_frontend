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
                .frame(width: 40)
            Text("Effort")
                .frame(width: 50)
            Text("")  // Delete column
                .frame(width: 30)
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
    var viewModel: ExerciseTrackingViewModel
    @EnvironmentObject var userPreferences: UserPreferences
    @FocusState var focusedField: ExerciseTrackingView.FocusField?
    
    @State private var exerciseText: String = ""
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var showingEffortPicker = false
    @State private var selectedEffort: EffortLevel? = nil
    @State private var showPRBadge = false
    
    // Character limits - Updated for stricter validation
    private let maxExerciseNameLength = 15  // Reduced from 30
    private let maxWeightLength = 3         // Allows up to 999
    private let maxRepsLength = 2           // Reduced from 4 to 2 digits
    
    /// Get the previous PR for this exercise
    private var previousPR: PersonalRecord? {
        viewModel.getPreviousPR(for: exerciseText)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                // Exercise Name (limited to 15 characters, letters only)
                TextField("Exercise", text: $exerciseText)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .exercise(row.id))
                    .onChange(of: exerciseText) { _, newValue in
                        // Filter to only allow letters and spaces
                        let filtered = newValue.filter { $0.isLetter || $0.isWhitespace }
                        // Limit character input
                        if filtered.count > maxExerciseNameLength {
                            exerciseText = String(filtered.prefix(maxExerciseNameLength))
                        } else if filtered != newValue {
                            exerciseText = filtered
                        }
                        viewModel.updateExerciseName(for: row.id, name: exerciseText)
                        
                        // Fetch previous PR when exercise name changes
                        if !exerciseText.isEmpty {
                            Task {
                                await viewModel.fetchPreviousPR(for: exerciseText)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                
                // Weight (limited to 3 digits, numbers only)
                HStack(spacing: 4) {
                    TextField("0", text: $weightText)
                        .textFieldStyle(.plain)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .weight(row.id))
                        .onChange(of: weightText) { _, newValue in
                            // Filter to only allow digits
                            let filtered = newValue.filter { $0.isNumber }
                            // Limit to 3 digits
                            if filtered.count > maxWeightLength {
                                weightText = String(filtered.prefix(maxWeightLength))
                            } else if filtered != newValue {
                                weightText = filtered
                            }
                            if let weight = Double(weightText) {
                                viewModel.updateWeight(for: row.id, weight: weight)
                            } else if weightText.isEmpty {
                                viewModel.updateWeight(for: row.id, weight: 0)
                            }
                        }
                        .frame(width: 35)
                        .multilineTextAlignment(.trailing)
                    
                    // Static unit label
                    Text(userPreferences.defaultWeightUnit.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 70)
                
                // Reps (limited to 2 digits, numbers only)
                TextField("0", text: $repsText)
                    .textFieldStyle(.plain)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .reps(row.id))
                    .onChange(of: repsText) { _, newValue in
                        // Filter to only allow digits
                        let filtered = newValue.filter { $0.isNumber }
                        // Limit to 2 digits
                        if filtered.count > maxRepsLength {
                            repsText = String(filtered.prefix(maxRepsLength))
                        } else if filtered != newValue {
                            repsText = filtered
                        }
                        if let reps = Int(repsText) {
                            viewModel.updateReps(for: row.id, reps: reps)
                        } else if repsText.isEmpty {
                            viewModel.updateReps(for: row.id, reps: 0)
                        }
                    }
                    .frame(width: 40)
                    .multilineTextAlignment(.center)
                
                // Effort Level Button
                Button {
                    showingEffortPicker = true
                } label: {
                    if let effort = selectedEffort {
                        Image(systemName: effort.iconName)
                            .font(.title3)
                            .foregroundStyle(effortColor(for: effort))
                    } else {
                        Image(systemName: "plus.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 50)
                .confirmationDialog("How hard was this set?", isPresented: $showingEffortPicker, titleVisibility: .visible) {
                    ForEach(EffortLevel.allCases, id: \.self) { level in
                        Button(level.displayName) {
                            selectedEffort = level
                            viewModel.updateEffortLevel(for: row.id, effort: level)
                        }
                    }
                    Button("Clear", role: .destructive) {
                        selectedEffort = nil
                        viewModel.updateEffortLevel(for: row.id, effort: nil)
                    }
                    Button("Cancel", role: .cancel) { }
                }
                
                // Delete Button
                Button(role: .destructive) {
                    viewModel.deleteRow(row)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.8))
                }
                .frame(width: 30)
            }
            
            // Show Previous PR Badge if available
            if let pr = previousPR {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("PR: \(Int(pr.weight))\(userPreferences.defaultWeightUnit.displayName) × \(pr.reps) reps")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.top, 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, previousPR != nil ? 10 : 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .animation(.easeInOut(duration: 0.2), value: previousPR != nil)
        .onAppear {
            exerciseText = row.exerciseName
            weightText = row.weight > 0 ? String(format: "%.0f", row.weight) : ""
            repsText = row.reps > 0 ? "\(row.reps)" : ""
            selectedEffort = row.effortLevel
            
            // Fetch PR on appear if exercise name exists
            if !row.exerciseName.isEmpty {
                Task {
                    await viewModel.fetchPreviousPR(for: row.exerciseName)
                }
            }
        }
    }
    
    // Helper function to get color for effort level
    private func effortColor(for effort: EffortLevel) -> Color {
        switch effort {
        case .easy: return .green
        case .moderate: return .yellow
        case .hard: return .orange
        case .maxEffort: return .red
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

