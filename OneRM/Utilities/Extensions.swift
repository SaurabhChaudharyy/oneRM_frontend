//
//  Extensions.swift
//  OneRM
//

import Foundation
import SwiftUI

// MARK: - Date Extensions

extension Date {
    /// Returns true if this date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Returns true if this date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// Returns a relative date string (e.g., "Today", "Yesterday", "Jan 15")
    var relativeString: String {
        if isToday {
            return "Today"
        } else if isYesterday {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: self)
        }
    }
    
    /// Returns the start of the day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

// MARK: - Double Extensions

extension Double {
    /// Formats the number with appropriate decimal places
    var formatted: String {
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", self)
        } else {
            return String(format: "%.1f", self)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Conditionally applies a transformation to the view
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Hides the keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Color Extensions

extension Color {
    /// App accent color for consistent theming
    static let appAccent = Color.orange
    
    /// Gold color for personal records
    static let prGold = Color(red: 1.0, green: 0.84, blue: 0.0)
    
    /// Success green
    static let successGreen = Color.green
    
    /// Error red
    static let errorRed = Color.red
}

// MARK: - String Extensions

extension String {
    /// Returns true if the string is empty or contains only whitespace
    var isBlank: Bool {
        trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    /// Trims whitespace and newlines
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Array Extensions

extension Array {
    /// Safe subscript that returns nil for out-of-bounds indices
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
