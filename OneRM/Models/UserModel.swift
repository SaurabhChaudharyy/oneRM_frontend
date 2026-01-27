//
//  UserModel.swift
//  OneRM
//
//  User authentication model for Sign in with Apple/Google.
//

import Foundation

/// Authentication provider types
enum AuthProvider: String, Codable {
    case apple = "apple"
    case google = "google"
}

/// User profile model
struct User: Codable, Identifiable {
    let id: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
    let provider: AuthProvider
    let createdAt: Date
    var lastSyncedAt: Date?
    
    init(
        id: String,
        email: String? = nil,
        displayName: String? = nil,
        photoURL: URL? = nil,
        provider: AuthProvider,
        createdAt: Date = Date(),
        lastSyncedAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.provider = provider
        self.createdAt = createdAt
        self.lastSyncedAt = lastSyncedAt
    }
    
    /// User's display name or fallback
    var name: String {
        if let displayName = displayName, !displayName.isEmpty {
            return displayName
        }
        if let email = email {
            return email.components(separatedBy: "@").first ?? email
        }
        return "User"
    }
    
    /// User's initials for avatar
    var initials: String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
