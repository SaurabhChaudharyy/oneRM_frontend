//
//  EmptyStateView.swift
//  OneRM
//

import SwiftUI

/// Empty state placeholder with icon, title, subtitle, and optional action
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated icon
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(.primary)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.primary)
                        .foregroundStyle(Color(.systemBackground))
                        .clipShape(Capsule())
                        .shadow(color: Color.primary.opacity(0.2), radius: 10, y: 5)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    EmptyStateView(
        icon: "calendar.badge.plus",
        title: "No Workouts Yet",
        subtitle: "Start tracking your workouts to see your history here.",
        actionTitle: "Start First Workout"
    ) {
        print("Action tapped")
    }
}
