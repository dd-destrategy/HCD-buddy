import Foundation
import SwiftData

/// Manages SwiftData persistence with custom container location
final class DataManager {
    static let shared = DataManager()

    let container: ModelContainer

    private init() {
        do {
            let schema = Schema([
                Session.self,
                Utterance.self,
                Insight.self,
                TopicStatus.self,
                CoachingEvent.self
            ])

            let configuration = ModelConfiguration(
                schema: schema,
                url: Self.customStoreURL,
                allowsSave: true,
                groupContainer: .none,
                cloudKitDatabase: .none
            )

            container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            // Apply file protection to the database file for encryption at rest
            Self.applyFileProtection(to: Self.customStoreURL)

            AppLogger.shared.info("DataManager initialized with custom store at: \(Self.customStoreURL.path)")
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    /// Custom store URL in Application Support directory
    private static var customStoreURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let appDirectory = appSupport.appendingPathComponent("HCDInterviewCoach", isDirectory: true)

        // Create directory if it doesn't exist with file protection
        // NSFileProtectionComplete ensures data is encrypted and inaccessible when device is locked
        try? FileManager.default.createDirectory(
            at: appDirectory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )

        return appDirectory.appendingPathComponent("HCDInterviewCoach.sqlite")
    }

    /// Apply file protection to ensure database encryption at rest
    /// NSFileProtectionComplete encrypts data and makes it inaccessible when device is locked
    private static func applyFileProtection(to url: URL) {
        do {
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: url.path
            )
            // Also protect related SQLite files (-shm, -wal)
            let shmURL = url.appendingPathExtension("sqlite-shm")
            let walURL = url.appendingPathExtension("sqlite-wal")
            try? FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: shmURL.path
            )
            try? FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: walURL.path
            )
        } catch {
            AppLogger.shared.warning("Could not apply file protection to database: \(error.localizedDescription)")
        }
    }

    /// Get the main context
    var mainContext: ModelContext {
        container.mainContext
    }

    /// Create a new background context for concurrent operations
    func newBackgroundContext() -> ModelContext {
        let context = ModelContext(container)
        return context
    }

    /// Save context if it has changes
    func save(context: ModelContext? = nil) throws {
        let contextToSave = context ?? mainContext
        if contextToSave.hasChanges {
            try contextToSave.save()
            AppLogger.shared.debug("Context saved successfully")
        }
    }

    /// Delete all data (useful for testing)
    func deleteAllData() throws {
        let context = mainContext

        // Delete all sessions (cascade will handle related entities)
        let sessions = try context.fetch(FetchDescriptor<Session>())
        for session in sessions {
            context.delete(session)
        }

        try save(context: context)
        AppLogger.shared.info("All data deleted")
    }

    /// Get store file size
    func getStoreSize() -> Int64? {
        let url = Self.customStoreURL
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) else {
            return nil
        }
        return attributes[.size] as? Int64
    }
}
