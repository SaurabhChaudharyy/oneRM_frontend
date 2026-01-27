//
//  WorkoutSetupView.swift
//  OneRM
//

import SwiftUI

/// Screen 1: Workout Setup - Select body parts and configure workout
struct WorkoutSetupView: View {
    @StateObject private var viewModel = WorkoutSetupViewModel()
    @State private var navigateToTracking = false
    @EnvironmentObject var userPreferences: UserPreferences
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Isolated Input Section (Header, Date, Name)
                WorkoutInputSection(
                    workoutName: $viewModel.workoutName,
                    workoutDate: $viewModel.workoutDate
                )
                
                // Equatable Grid (Only redraws when chips change, ignores typing)
                BodyPartGridView(
                    availableBodyParts: viewModel.availableBodyParts,
                    selectedBodyParts: viewModel.selectedBodyParts,
                    onToggle: viewModel.toggleBodyPart,
                    onAddCustom: { viewModel.showingAddCustom = true }
                )
                
                selectedChipsSection
                continueButton
            }
            .padding()
            .contentShape(Rectangle())
        }
        .scrollDismissesKeyboard(.immediately)
        .background(
            Color(.systemGroupedBackground)
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        )
        .navigationTitle("OneRM")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $navigateToTracking) {
            ExerciseTrackingView(workoutSession: viewModel.createWorkoutSession())
        }
        .onChange(of: navigateToTracking) { _, newValue in
            if !newValue {
                viewModel.reset()
            }
        }
        .sheet(isPresented: $viewModel.showingAddCustom) {
            addCustomBodyPartSheet
        }
        .overlay {
            if viewModel.isLoading {
                LoadingView()
            }
        }
    }
    
    // MARK: - Selected Chips Section
    
    @ViewBuilder
    private var selectedChipsSection: some View {
        if !viewModel.selectedBodyPartsList.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("Selected (\(viewModel.selectedBodyPartsList.count))", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.selectedBodyPartsList) { bodyPart in
                        HStack(spacing: 4) {
                            Text(bodyPart.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Button {
                                viewModel.toggleBodyPart(bodyPart)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Continue Button
    
    private var continueButton: some View {
        Button {
            HapticManager.shared.medium()
            navigateToTracking = true
        } label: {
            HStack {
                Text("Continue to Exercises")
                    .fontWeight(.semibold)
                Image(systemName: "arrow.right")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.canContinue ? Color.primary : Color.gray.opacity(0.3))
            .foregroundColor(viewModel.canContinue ? Color(.systemBackground) : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!viewModel.canContinue)
        .padding(.top, 8)
    }
    
    // MARK: - Add Custom Body Part Sheet
    
    private var addCustomBodyPartSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.primary)
                    
                    Text("Add Custom Muscle Group")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top, 32)
                
                TextField("Enter muscle group name", text: $viewModel.customBodyPartName)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                
                Spacer()
                
                Button {
                    viewModel.addCustomBodyPart()
                } label: {
                    Text("Add Muscle Group")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.customBodyPartName.isEmpty ? Color.gray.opacity(0.3) : Color.primary)
                        .foregroundColor(viewModel.customBodyPartName.isEmpty ? .secondary : Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(viewModel.customBodyPartName.isEmpty)
                .padding()
            }
            .navigationTitle("Custom Muscle Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showingAddCustom = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Flow Layout for Chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
        
        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

#Preview {
    NavigationStack {
        WorkoutSetupView()
    }
    .environmentObject(UserPreferences.shared)
    .environmentObject(WorkoutRepository.shared)
}

// MARK: - Input Section
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
                     // Important: Toolbar here for Done button if needed, or rely on parent dismissal
                     .submitLabel(.done)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Equatable Grid
struct BodyPartGridView: View, Equatable {
    let availableBodyParts: [BodyPart]
    let selectedBodyParts: Set<UUID>
    let onToggle: (BodyPart) -> Void
    let onAddCustom: () -> Void
    
    static func == (lhs: BodyPartGridView, rhs: BodyPartGridView) -> Bool {
        lhs.availableBodyParts == rhs.availableBodyParts &&
        lhs.selectedBodyParts == rhs.selectedBodyParts
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Target Muscle Groups", systemImage: "figure.arms.open")
                    .font(.headline)
                
                Spacer()
                
                Button(action: onAddCustom) {
                    Label("Add Custom", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                ForEach(availableBodyParts) { bodyPart in
                    BodyPartChip(
                        bodyPart: bodyPart,
                        isSelected: selectedBodyParts.contains(bodyPart.id)
                    ) {
                        onToggle(bodyPart)
                    }
                }
            }
        }
    }
}
