import Foundation
import SwiftData

// MARK: - Service Container Protocol

/// Protocol abstraction for ServiceContainer to enable testability
protocol ServiceContaining: AnyObject {
    var templateManager: TemplateManager { get }
    var dataManager: DataManager { get }
}

// MARK: - Service Container

/// Container for all application services and managers
/// Uses the singleton DataManager.shared for data persistence
@MainActor
class ServiceContainer: ObservableObject, ServiceContaining {
    @Published var templateManager: TemplateManager

    /// Data manager singleton for SwiftData persistence
    /// Defined in HCDInterviewCoach/Core/Services/DataManager.swift
    let dataManager: DataManager

    init(dataManager: DataManager = .shared) {
        // Use singleton DataManager for persistence
        self.dataManager = dataManager

        // Initialize template manager with modelContext from dataManager
        let modelContext = ModelContext(dataManager.container)
        self.templateManager = TemplateManager(modelContext: modelContext)
    }
}

// Note: DataManager is defined as a singleton in HCDInterviewCoach/Core/Services/DataManager.swift
// Use DataManager.shared for all data persistence operations
