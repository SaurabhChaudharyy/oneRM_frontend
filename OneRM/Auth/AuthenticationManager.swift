//
//  AuthenticationManager.swift
//  OneRM
//
//  Manages user authentication with Apple and Google Sign-In.
//  Handles sign-in, sign-out, and session persistence.
//

import Foundation
import AuthenticationServices
import CryptoKit

/// Authentication error types
enum AuthError: LocalizedError, Equatable {
    case signInFailed(String)
    case signOutFailed(String)
    case userCancelled
    case invalidResponse
    case noCredentials
    
    var errorDescription: String? {
        switch self {
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .signOutFailed(let message):
            return "Sign out failed: \(message)"
        case .userCancelled:
            return "Sign in was cancelled"
        case .invalidResponse:
            return "Invalid response from authentication provider"
        case .noCredentials:
            return "No credentials available"
        }
    }
}

/// Authentication state
enum AuthState: Equatable {
    case unknown
    case signedOut
    case signedIn(User)
    
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown), (.signedOut, .signedOut):
            return true
        case (.signedIn(let user1), .signedIn(let user2)):
            return user1.id == user2.id
        default:
            return false
        }
    }
}

/// Manages authentication with Apple and Google
@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    static let shared = AuthenticationManager()
    
    // MARK: - Published Properties
    
    @Published var authState: AuthState = .unknown
    @Published var isLoading = false
    @Published var error: AuthError?
    
    // MARK: - Private Properties
    
    private let userDefaultsKey = "com.onerm.currentUser"
    private var currentNonce: String?
    
    // MARK: - Computed Properties
    
    var isSignedIn: Bool {
        if case .signedIn = authState {
            return true
        }
        return false
    }
    
    var currentUser: User? {
        if case .signedIn(let user) = authState {
            return user
        }
        return nil
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        loadSavedUser()
    }
    
    // MARK: - Session Persistence
    
    private func loadSavedUser() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            authState = .signedOut
            return
        }
        authState = .signedIn(user)
        print("✅ Auth: Loaded saved user: \(user.name)")
    }
    
    private func saveUser(_ user: User) {
        guard let data = try? JSONEncoder().encode(user) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
        print("✅ Auth: Saved user to UserDefaults")
    }
    
    private func clearSavedUser() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        print("✅ Auth: Cleared saved user")
    }
    
    // MARK: - Sign In with Apple
    
    /// Generate a random nonce for Apple Sign In
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    /// SHA256 hash of input string
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
    }
    
    /// Create Apple Sign In request
    func createAppleSignInRequest() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        return request
    }
    
    /// Handle Apple Sign In authorization result
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        isLoading = true
        
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                error = .invalidResponse
                isLoading = false
                return
            }
            
            let userId = appleIDCredential.user
            let email = appleIDCredential.email
            let fullName = appleIDCredential.fullName
            
            // Build display name from name components
            var displayName: String?
            if let nameComponents = fullName {
                let givenName = nameComponents.givenName ?? ""
                let familyName = nameComponents.familyName ?? ""
                let name = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    displayName = name
                }
            }
            
            // If we don't have name/email, check if we have stored info from previous sign-in
            let savedEmail = email ?? UserDefaults.standard.string(forKey: "apple_email_\(userId)")
            let savedName = displayName ?? UserDefaults.standard.string(forKey: "apple_name_\(userId)")
            
            // Save for future sign-ins (Apple only provides this info on first sign-in)
            if let email = email {
                UserDefaults.standard.set(email, forKey: "apple_email_\(userId)")
            }
            if let displayName = displayName {
                UserDefaults.standard.set(displayName, forKey: "apple_name_\(userId)")
            }
            
            let user = User(
                id: userId,
                email: savedEmail,
                displayName: savedName,
                photoURL: nil,
                provider: .apple
            )
            
            saveUser(user)
            authState = .signedIn(user)
            error = nil
            isLoading = false
            
            print("✅ Auth: Apple Sign In successful for \(user.name)")
            HapticManager.shared.success()
            
        case .failure(let authError):
            isLoading = false
            if let authError = authError as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    error = .userCancelled
                default:
                    error = .signInFailed(authError.localizedDescription)
                }
            } else {
                error = .signInFailed(authError.localizedDescription)
            }
            print("❌ Auth: Apple Sign In failed: \(authError.localizedDescription)")
            HapticManager.shared.error()
        }
    }
    
    // MARK: - Sign In with Google
    
    /// Handle Google Sign In
    /// Note: Requires GoogleSignIn SDK to be added via SPM
    /// For now, this is a placeholder that shows the expected interface
    func signInWithGoogle() async throws {
        isLoading = true
        
        // TODO: Implement Google Sign In when SDK is added
        // 1. Add GoogleSignIn package via Swift Package Manager
        // 2. Configure in Google Cloud Console
        // 3. Add URL scheme to Info.plist
        
        // For now, show an error that Google Sign In is not yet configured
        isLoading = false
        error = .signInFailed("Google Sign In requires additional setup. Please configure the GoogleSignIn SDK.")
        
        print("⚠️ Auth: Google Sign In not yet configured")
        HapticManager.shared.error()
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        clearSavedUser()
        authState = .signedOut
        error = nil
        print("✅ Auth: User signed out")
        HapticManager.shared.light()
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        error = nil
    }
}
