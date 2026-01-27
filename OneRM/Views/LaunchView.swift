//
//  LaunchView.swift
//  OneRM
//

import SwiftUI

/// Custom launch screen with app icon and smooth zoom animation
struct LaunchView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background - matches your app's theme
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.04, green: 0.04, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // App Icon with zoom animation
                Image("AppIconImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .shadow(color: .orange.opacity(0.4), radius: 20, x: 0, y: 10)
                    .scaleEffect(scale)
                    .opacity(opacity)
            }
        }
        .onAppear {
            // Smooth zoom-in animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    LaunchView()
}
