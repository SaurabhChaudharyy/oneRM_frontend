//
//  LoginView.swift
//  OneRM
//
//  Sign In view with Apple and Google authentication options.
//  Provides a beautiful, premium login experience.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                mainContent
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    closeButton
                }
            }
            .alert("Sign In Error", isPresented: $showError) {
                Button("OK") {
                    authManager.clearError()
                }
            } message: {
                Text(authManager.error?.errorDescription ?? "An unknown error occurred")
            }
            .onChange(of: authManager.error) { _, newValue in
                showError = newValue != nil
            }
            .onChange(of: authManager.isSignedIn) { _, isSignedIn in
                if isSignedIn {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var closeButton: some View {
        Button("Close") {
            dismiss()
        }
        .foregroundColor(.primary)
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)
                headerSection
                Spacer(minLength: 20)
                benefitsSection
                Spacer(minLength: 20)
                signInButtonsSection
                skipButton
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var backgroundGradient: some View {
        let darkColors = [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.1, blue: 0.2)]
        let lightColors = [Color(red: 0.95, green: 0.95, blue: 1.0), Color.white]
        let colors = colorScheme == .dark ? darkColors : lightColors
        
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            appIcon
            appTitle
            subtitle
        }
    }
    
    private var appIcon: some View {
        Image("AppIconImage")
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var appTitle: some View {
        Text("OneRM")
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
    }
    
    private var subtitle: some View {
        Text("Sign in to sync your workouts across devices")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }
    
    private var benefitsSection: some View {
        VStack(spacing: 16) {
            BenefitRow(icon: "icloud.fill", title: "Cloud Backup", description: "Never lose your workout data")
            BenefitRow(icon: "arrow.triangle.2.circlepath", title: "Sync Across Devices", description: "Access workouts on all your devices")
            BenefitRow(icon: "lock.shield.fill", title: "Secure & Private", description: "Your data is encrypted and protected")
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(benefitsBackground)
    }
    
    private var benefitsBackground: some View {
        let fillColor = colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03)
        return RoundedRectangle(cornerRadius: 16).fill(fillColor)
    }
    
    private var signInButtonsSection: some View {
        VStack(spacing: 16) {
            appleSignInButton
            googleSignInButton
        }
    }
    
    private var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            let appleRequest = authManager.createAppleSignInRequest()
            request.requestedScopes = appleRequest.requestedScopes
            request.nonce = appleRequest.nonce
        } onCompletion: { result in
            authManager.handleAppleSignIn(result: result)
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var googleSignInButton: some View {
        Button {
            Task {
                try? await authManager.signInWithGoogle()
            }
        } label: {
            googleSignInButtonLabel
        }
        .overlay(googleSignInButtonBorder)
    }
    
    private var googleSignInButtonLabel: some View {
        HStack(spacing: 12) {
            Image(systemName: "g.circle.fill")
                .font(.title2)
            Text("Sign in with Google")
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(googleSignInButtonBackground)
        .foregroundColor(.black)
    }
    
    private var googleSignInButtonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var googleSignInButtonBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
    }
    
    private var skipButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Continue without signing in")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            iconView
            textContent
            Spacer()
        }
    }
    
    private var iconView: some View {
        Image(systemName: icon)
            .font(.title2)
            .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 44, height: 44)
            .background(Circle().fill(Color.blue.opacity(0.1)))
    }
    
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager.shared)
}

