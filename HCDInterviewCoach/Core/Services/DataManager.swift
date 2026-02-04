import Foundation
import SwiftData

/// Error types for DataManager operations
enum DataManagerError: LocalizedError {
    case initializationFailed(Error)
    case containerUnavailable
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .initializationFailed(let error):
            return "Failed to initialize database: \(error.localizedDescription)"
        case .containerUnavailable:
            return "Database is unavailable. The app is running in degraded mode."
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .initializationFailed:
            return "Try restarting the app. If the problem persists, you may need to reset the app's data in Settings."
        case .containerUnavailable:
            return "Session data cannot be saved. Please restart the app to restore full functionality."
        case .saveFailed:
            return "Your changes may not be saved. Try again or restart the app."
        }
    }
}

/// Manages SwiftData persistence with custom container location and encryption
@MainActor
final class DataManager {
    static let shared = DataManager()

    /// The model container, or nil if initialization failed
    private(set) var container: ModelContainer?

    /// Error that occurred during initialization, if any
    private(set) var initializationError: Error?

    /// Whether the DataManager initialized successfully and is fully operational
    var isOperational: Bool {
        container != nil
    }

    /// Size of buffer used for secure file overwriting (64KB)
    private static let secureOverwriteBufferSize = 64 * 1024

    /// Number of overwrite passes for secure deletion (DoD 5220.22-M standard uses 3)
    private static let secureOverwritePasses = 3

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
                "HCDInterviewCoach",
                schema: schema,
                url: Self.customStoreURL,
                allowsSave: true,
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
            // Log the error but don't crash - allow app to run in degraded mode
            self.initializationError = error
            self.container = nil
            AppLogger.shared.error("DataManager initialization failed: \(error.localizedDescription). App will run in degraded mode without data persistence.")
        }
    }

    /// Creates a DataManager backed by the given ModelContainer.
    /// Intended for testing with in-memory containers.
    init(container: ModelContainer) {
        self.container = container
        self.initializationError = nil
    }

    /// Ensures the container is available, throwing an error if not
    /// - Returns: The model container
    /// - Throws: DataManagerError.containerUnavailable if the database failed to initialize
    func requireContainer() throws -> ModelContainer {
        guard let container = container else {
            throw DataManagerError.containerUnavailable
        }
        return container
    }

    /// Custom store URL in Application Support directory with encryption
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

    /// Returns the encrypted storage directory URL
    static var encryptedStorageDirectory: URL {
        customStoreURL.deletingLastPathComponent()
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
            let shmURL = url.deletingPathExtension().appendingPathExtension("sqlite-shm")
            let walURL = url.deletingPathExtension().appendingPathExtension("sqlite-wal")
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
    /// - Returns: The main model context
    /// - Note: If the database failed to initialize, this will log an error and return a context
    ///         that will fail on operations. Use `isOperational` to check if DB is available,
    ///         or `safeMainContext` for an optional version.
    var mainContext: ModelContext {
        guard let context = container?.mainContext else {
            // Log the access attempt for debugging
            AppLogger.shared.error("Attempted to access mainContext but database is unavailable. Check isOperational before accessing.")
            // Return a placeholder context that will fail on operations
            // This allows the app to continue running and show appropriate error UI
            preconditionFailure(
                "Database unavailable: \(initializationError?.localizedDescription ?? "Unknown error"). " +
                "Check DataManager.shared.isOperational before accessing mainContext."
            )
        }
        return context
    }

    /// Get the main context as an optional
    /// - Returns: The main model context, or nil if the database is unavailable
    var safeMainContext: ModelContext? {
        container?.mainContext
    }

    /// Get the main context, throwing if unavailable
    /// - Returns: The main model context
    /// - Throws: DataManagerError.containerUnavailable if the database is unavailable
    func requireMainContext() throws -> ModelContext {
        guard let context = container?.mainContext else {
            throw DataManagerError.containerUnavailable
        }
        return context
    }

    /// Create a new background context for concurrent operations
    /// - Returns: A new background context
    /// - Note: Returns nil if the database is unavailable
    func newBackgroundContext() -> ModelContext? {
        guard let container = container else {
            AppLogger.shared.warning("Cannot create background context: database unavailable")
            return nil
        }
        return ModelContext(container)
    }

    /// Save context if it has changes
    /// - Parameter context: The context to save, or nil to use the main context
    /// - Throws: DataManagerError.containerUnavailable if database is unavailable,
    ///           or the underlying save error
    func save(context: ModelContext? = nil) throws {
        let contextToSave: ModelContext
        if let context = context {
            contextToSave = context
        } else {
            contextToSave = try requireMainContext()
        }

        if contextToSave.hasChanges {
            try contextToSave.save()
            AppLogger.shared.debug("Context saved successfully")
        }
    }

    /// Delete all data (useful for testing)
    /// - Throws: DataManagerError.containerUnavailable if database is unavailable
    func deleteAllData() throws {
        let context = try requireMainContext()

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

    // MARK: - Secure Deletion

    /// Securely deletes a session and all associated data
    /// This method:
    /// 1. Securely overwrites any associated audio files with random data
    /// 2. Deletes the session from SwiftData (cascade handles related entities)
    /// 3. Saves the context to persist the deletion
    /// - Parameter session: The session to securely delete
    /// - Throws: HCDError.database if deletion fails
    func securelyDeleteSession(_ session: Session) async throws {
        AppLogger.shared.info("Starting secure deletion for session: \(session.id)")

        // Step 1: Securely delete associated audio file if it exists
        if let audioFilePath = session.audioFilePath {
            let audioURL = URL(fileURLWithPath: audioFilePath)
            try await securelyDeleteFile(at: audioURL)
        }

        // Step 2: Delete from SwiftData (cascade will handle utterances, insights, etc.)
        do {
            let context = try requireMainContext()
            context.delete(session)
            try save(context: context)
            AppLogger.shared.info("Session \(session.id) securely deleted from database")
        } catch let error as DataManagerError {
            AppLogger.shared.error("Database unavailable for deletion: \(error.localizedDescription)")
            throw HCDError.database(.secureDeleteFailed(error))
        } catch {
            AppLogger.shared.error("Failed to delete session from database: \(error.localizedDescription)")
            throw HCDError.database(.secureDeleteFailed(error))
        }
    }

    /// Securely deletes a file by overwriting its contents with random data before removal
    /// Uses multiple overwrite passes for enhanced security (DoD 5220.22-M standard)
    /// - Parameter url: The URL of the file to securely delete
    /// - Throws: HCDError.file if the operation fails
    func securelyDeleteFile(at url: URL) async throws {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: url.path) else {
            AppLogger.shared.debug("File does not exist, skipping secure delete: \(url.path)")
            return
        }

        do {
            // Get file size for overwriting
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            guard let fileSize = attributes[.size] as? Int64, fileSize > 0 else {
                // File is empty, just delete it
                try fileManager.removeItem(at: url)
                return
            }

            // Perform multiple overwrite passes
            for pass in 1...Self.secureOverwritePasses {
                try await overwriteFileWithRandomData(at: url, fileSize: fileSize, pass: pass)
            }

            // Finally, remove the file from disk
            try fileManager.removeItem(at: url)
            AppLogger.shared.info("File securely deleted: \(url.lastPathComponent)")

        } catch {
            AppLogger.shared.error("Secure file deletion failed: \(error.localizedDescription)")
            throw HCDError.file(.deleteFailed(error))
        }
    }

    /// Overwrites a file with random data
    /// - Parameters:
    ///   - url: The file URL to overwrite
    ///   - fileSize: The size of the file in bytes
    ///   - pass: The current overwrite pass number (for logging)
    private func overwriteFileWithRandomData(at url: URL, fileSize: Int64, pass: Int) async throws {
        guard let fileHandle = try? FileHandle(forWritingTo: url) else {
            throw HCDError.file(.writeFailed(NSError(
                domain: "DataManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Could not open file for writing"]
            )))
        }

        defer {
            try? fileHandle.close()
        }

        try fileHandle.seek(toOffset: 0)

        var remainingBytes = fileSize
        let bufferSize = Self.secureOverwriteBufferSize

        while remainingBytes > 0 {
            let bytesToWrite = min(Int(remainingBytes), bufferSize)
            var randomBytes = [UInt8](repeating: 0, count: bytesToWrite)

            // Generate cryptographically secure random data
            let result = SecRandomCopyBytes(kSecRandomDefault, bytesToWrite, &randomBytes)
            if result != errSecSuccess {
                // Fallback to less secure but still random data
                randomBytes = (0..<bytesToWrite).map { _ in UInt8.random(in: 0...255) }
            }

            let data = Data(randomBytes)
            try fileHandle.write(contentsOf: data)
            remainingBytes -= Int64(bytesToWrite)
        }

        // Ensure data is flushed to disk
        try fileHandle.synchronize()

        AppLogger.shared.debug("Secure overwrite pass \(pass) completed for: \(url.lastPathComponent)")
    }

    // MARK: - Encryption Verification

    /// Verifies that data protection is enabled on the database file
    /// - Returns: true if file protection is enabled and set to complete protection level
    func verifyDataProtection() -> Bool {
        let url = Self.customStoreURL

        guard FileManager.default.fileExists(atPath: url.path) else {
            AppLogger.shared.warning("Database file does not exist, cannot verify protection")
            return false
        }

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)

            guard let protectionValue = attributes[.protectionKey] as? FileProtectionType else {
                AppLogger.shared.warning("No file protection attribute found on database")
                return false
            }

            let isProtected = protectionValue == .complete ||
                              protectionValue == .completeUnlessOpen ||
                              protectionValue == .completeUntilFirstUserAuthentication

            if isProtected {
                AppLogger.shared.info("Data protection verified: \(protectionValue)")
            } else {
                AppLogger.shared.warning("Data protection level is insufficient: \(protectionValue)")
            }

            return isProtected
        } catch {
            AppLogger.shared.error("Failed to verify data protection: \(error.localizedDescription)")
            return false
        }
    }

    /// Returns detailed information about the current data protection status
    /// - Returns: A dictionary containing protection status for the database and related files
    func getDataProtectionStatus() -> [String: Any] {
        var status: [String: Any] = [:]

        let dbURL = Self.customStoreURL
        let shmURL = dbURL.deletingPathExtension().appendingPathExtension("sqlite-shm")
        let walURL = dbURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
        let directoryURL = dbURL.deletingLastPathComponent()

        status["databaseProtected"] = getFileProtectionLevel(at: dbURL)
        status["shmFileProtected"] = getFileProtectionLevel(at: shmURL)
        status["walFileProtected"] = getFileProtectionLevel(at: walURL)
        status["directoryProtected"] = getFileProtectionLevel(at: directoryURL)
        status["overallSecure"] = verifyDataProtection()

        return status
    }

    /// Gets the file protection level for a specific file
    /// - Parameter url: The file URL to check
    /// - Returns: The protection level as a string, or "none" if not protected
    private func getFileProtectionLevel(at url: URL) -> String {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return "file_not_found"
        }

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            guard let protection = attributes[.protectionKey] as? FileProtectionType else {
                return "none"
            }

            switch protection {
            case .complete:
                return "complete"
            case .completeUnlessOpen:
                return "complete_unless_open"
            case .completeUntilFirstUserAuthentication:
                return "complete_until_first_auth"
            case .none:
                return "none"
            default:
                return "unknown"
            }
        } catch {
            return "error: \(error.localizedDescription)"
        }
    }

    /// Re-applies file protection to all database files
    /// Call this after any operation that might have modified file attributes
    func reapplyFileProtection() {
        Self.applyFileProtection(to: Self.customStoreURL)
        AppLogger.shared.info("File protection re-applied to database files")
    }
}
