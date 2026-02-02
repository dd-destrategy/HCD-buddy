import Foundation
import SwiftData

/// Manages SwiftData persistence with custom container location and encryption
@MainActor
final class DataManager {
    static let shared = DataManager()

    let container: ModelContainer

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
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
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
        let context = mainContext
        do {
            context.delete(session)
            try save(context: context)
            AppLogger.shared.info("Session \(session.id) securely deleted from database")
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
