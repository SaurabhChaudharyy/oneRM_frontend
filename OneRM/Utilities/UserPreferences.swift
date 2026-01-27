//
//  UserPreferences.swift
//  OneRM
//

import Foundation
import SwiftUI

/// Manages user preferences stored in UserDefaults
class UserPreferences: ObservableObject {
    static let shared = UserPreferences()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    
    private enum Keys {
        static let defaultWeightUnit = "defaultWeightUnit"
        static let isDarkMode = "isDarkMode"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }
    
    // MARK: - Published Properties
    
    @Published var defaultWeightUnit: WeightUnit {
        didSet {
            defaults.set(defaultWeightUnit.rawValue, forKey: Keys.defaultWeightUnit)
        }
    }
    
    @Published var isDarkMode: Bool {
        didSet {
            defaults.set(isDarkMode, forKey: Keys.isDarkMode)
        }
    }
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load saved preferences or use defaults
        if let unitString = defaults.string(forKey: Keys.defaultWeightUnit),
           let unit = WeightUnit(rawValue: unitString) {
            self.defaultWeightUnit = unit
        } else {
            self.defaultWeightUnit = .kg
        }
        
        self.isDarkMode = defaults.bool(forKey: Keys.isDarkMode)
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
    }
    
    // MARK: - Methods
    
    /// Reset all preferences to defaults
    func reset() {
        hasCompletedOnboarding = false
        
        // Clear all stored data
        let domain = Bundle.main.bundleIdentifier ?? ""
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
    }
}
