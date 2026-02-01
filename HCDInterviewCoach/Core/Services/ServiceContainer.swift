import Foundation
import SwiftData

/// Container for all application services and managers
class ServiceContainer: ObservableObject {
    @Published var templateManager: TemplateManager

    let dataManager: DataManager

    init() {
        // Initialize data manager
        self.dataManager = DataManager()

        // Initialize template manager
        self.templateManager = TemplateManager()
    }
}

/// Manages SwiftData container and persistence
class DataManager {
    let container: ModelContainer

    init() {
        do {
            let config = ModelConfiguration(
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            self.container = try ModelContainer(
                for: modelTypes,
                configurations: config
            )
        } catch {
            fatalError("Could not initialize DataManager: \(error)")
        }
    }

    private var modelTypes: [any PersistentModel.Type] {
        return []
    }
}
