//
//  BodyPartChip.swift
//  OneRM
//

import SwiftUI

/// Selectable chip component for body part selection
struct BodyPartChip: View {
    let bodyPart: BodyPart
    let isSelected: Bool
    let action: () -> Void
    var onDelete: (() -> Void)? = nil  // Optional delete callback for custom body parts
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if bodyPart.isCustom {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                }
                Text(bodyPart.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // Delete button for custom body parts
                if bodyPart.isCustom, let onDelete = onDelete {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(
                isSelected
                    ? Color.primary
                    : Color(.secondarySystemGroupedBackground)
            )
            .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.primary : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            }
            .shadow(color: isSelected ? Color.primary.opacity(0.2) : .clear, radius: 8, y: 4)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(bodyPart.name), \(isSelected ? "selected" : "not selected")")
        .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select")")
    }
}

#Preview {
    VStack(spacing: 16) {
        BodyPartChip(bodyPart: BodyPart(name: "Chest"), isSelected: true, action: { })
        BodyPartChip(bodyPart: BodyPart(name: "Back"), isSelected: false, action: { })
        BodyPartChip(bodyPart: BodyPart(name: "Custom", isCustom: true), isSelected: true, action: { }, onDelete: { print("Delete") })
    }
    .padding()
}

