//
//  BodyPartGridView.swift
//  OneRM
//

import SwiftUI

struct BodyPartGridView: View, Equatable {
    let availableBodyParts: [BodyPart]
    let selectedBodyParts: Set<UUID>
    let onToggle: (BodyPart) -> Void
    let onAddCustom: () -> Void
    
    // Equatable conformance: Only redraw if data actually changes
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
