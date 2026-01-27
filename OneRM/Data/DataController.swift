//
//  DataController.swift
//  OneRM
//
//  Manages the SwiftData ModelContainer configuration.
//  This is the central point for database setup and schema management.
//

import Foundation
import SwiftData

/// Manages SwiftData configuration and provides the ModelContainer
@MainActor
final class DataController {
    /// Shared singleton instance
    static let shared = DataController()
    
    /// The main model container for SwiftData
    let container: ModelContainer
    
    /// The main model context for database operations
    var context: ModelContext {
        container.mainContext
    }
    
    private init() {
        // Define the schema with all our models
        let schema = Schema([
            PersistedWorkoutSession.self,
            PersistedExerciseRow.self,
            PersistedPersonalRecord.self
        ])
        
        // Configure the model - stored in app's documents directory
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,  // Persist to disk
            allowsSave: true
        )
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ SwiftData: ModelContainer initialized successfully")
        } catch {
            // If we fail to initialize, this is a critical error
            // In production, you might want to handle this differently (e.g., reset the database)
            fatalError("❌ SwiftData: Failed to initialize ModelContainer: \(error.localizedDescription)")
        }
    }
    
    /// Save any pending changes to the context
    func save() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            print("✅ SwiftData: Changes saved successfully")
        } catch {
            print("❌ SwiftData: Failed to save changes: \(error.localizedDescription)")
        }
    }
    
    /// Delete all data - useful for reset functionality
    func deleteAllData() {
        do {
            try context.delete(model: PersistedExerciseRow.self)
            try context.delete(model: PersistedWorkoutSession.self)
            try context.delete(model: PersistedPersonalRecord.self)
            try context.save()
            print("✅ SwiftData: All data deleted successfully")
        } catch {
            print("❌ SwiftData: Failed to delete all data: \(error.localizedDescription)")
        }
    }
}
