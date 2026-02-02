import Foundation

/// Comprehensive error types for the HCD Interview Coach app
enum HCDError: Error {
    // MARK: - Error Categories

    case keychain(KeychainError)
    case database(DatabaseError)
    case audio(AudioError)
    case transcription(TranscriptionError)
    case api(APIError)
    case file(FileError)
    case validation(ValidationError)
    case unknown(String)

    // MARK: - Keychain Errors

    enum KeychainError: Error {
        case saveFailed(OSStatus)
        case retrieveFailed(OSStatus)
        case deleteFailed(OSStatus)
        case encodingFailed
        case decodingFailed
    }

    // MARK: - Database Errors

    enum DatabaseError: Error {
        case fetchFailed(Error)
        case saveFailed(Error)
        case deleteFailed(Error)
        case notFound
        case invalidData
    }

    // MARK: - Audio Errors

    enum AudioError: Error {
        case recordingPermissionDenied
        case recordingFailed(Error)
        case recordingNotStarted
        case recordingAlreadyStarted
        case audioEngineStartFailed(Error)
        case audioEngineNotRunning
        case fileNotFound(URL)
        case fileReadFailed(Error)
    }

    // MARK: - Transcription Errors

    enum TranscriptionError: Error {
        case initializationFailed(Error)
        case recognitionFailed(Error)
        case noAudioData
        case invalidFormat
        case timeout
    }

    // MARK: - API Errors

    enum APIError: Error {
        case noAPIKey
        case invalidAPIKey
        case requestFailed(Error)
        case invalidResponse
        case decodingFailed(Error)
        case rateLimitExceeded
        case serverError(Int)
        case networkUnavailable
    }

    // MARK: - File Errors

    enum FileError: Error {
        case notFound(URL)
        case readFailed(Error)
        case writeFailed(Error)
        case deleteFailed(Error)
        case invalidPath
        case permissionDenied
    }

    // MARK: - Validation Errors

    enum ValidationError: Error {
        case emptyField(String)
        case invalidFormat(String)
        case outOfRange(String)
        case invalidConfiguration
    }
}

// MARK: - LocalizedError

extension HCDError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .keychain(let error):
            return error.localizedDescription
        case .database(let error):
            return error.localizedDescription
        case .audio(let error):
            return error.localizedDescription
        case .transcription(let error):
            return error.localizedDescription
        case .api(let error):
            return error.localizedDescription
        case .file(let error):
            return error.localizedDescription
        case .validation(let error):
            return error.localizedDescription
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - KeychainError LocalizedError

extension HCDError.KeychainError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to keychain (status: \(status))"
        case .retrieveFailed(let status):
            return "Failed to retrieve from keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete from keychain (status: \(status))"
        case .encodingFailed:
            return "Failed to encode data for keychain"
        case .decodingFailed:
            return "Failed to decode data from keychain"
        }
    }
}

// MARK: - DatabaseError LocalizedError

extension HCDError.DatabaseError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch from database: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save to database: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete from database: \(error.localizedDescription)"
        case .notFound:
            return "Item not found in database"
        case .invalidData:
            return "Invalid data in database"
        }
    }
}

// MARK: - AudioError LocalizedError

extension HCDError.AudioError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .recordingPermissionDenied:
            return "Microphone permission denied. Please grant access in System Settings."
        case .recordingFailed(let error):
            return "Recording failed: \(error.localizedDescription)"
        case .recordingNotStarted:
            return "Recording has not been started"
        case .recordingAlreadyStarted:
            return "Recording is already in progress"
        case .audioEngineStartFailed(let error):
            return "Failed to start audio engine: \(error.localizedDescription)"
        case .audioEngineNotRunning:
            return "Audio engine is not running"
        case .fileNotFound(let url):
            return "Audio file not found: \(url.lastPathComponent)"
        case .fileReadFailed(let error):
            return "Failed to read audio file: \(error.localizedDescription)"
        }
    }
}

// MARK: - TranscriptionError LocalizedError

extension HCDError.TranscriptionError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .initializationFailed(let error):
            return "Failed to initialize transcription: \(error.localizedDescription)"
        case .recognitionFailed(let error):
            return "Speech recognition failed: \(error.localizedDescription)"
        case .noAudioData:
            return "No audio data available for transcription"
        case .invalidFormat:
            return "Invalid audio format for transcription"
        case .timeout:
            return "Transcription timed out"
        }
    }
}

// MARK: - APIError LocalizedError

extension HCDError.APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Please add your OpenAI API key in settings."
        case .invalidAPIKey:
            return "Invalid API key. Please check your OpenAI API key."
        case .requestFailed(let error):
            return "API request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from API"
        case .decodingFailed(let error):
            return "Failed to decode API response: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "API rate limit exceeded. Please try again later."
        case .serverError(let code):
            return "Server error (code: \(code))"
        case .networkUnavailable:
            return "Network unavailable. Please check your internet connection."
        }
    }
}

// MARK: - FileError LocalizedError

extension HCDError.FileError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notFound(let url):
            return "File not found: \(url.lastPathComponent)"
        case .readFailed(let error):
            return "Failed to read file: \(error.localizedDescription)"
        case .writeFailed(let error):
            return "Failed to write file: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete file: \(error.localizedDescription)"
        case .invalidPath:
            return "Invalid file path"
        case .permissionDenied:
            return "File permission denied"
        }
    }
}

// MARK: - ValidationError LocalizedError

extension HCDError.ValidationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return "\(field) cannot be empty"
        case .invalidFormat(let field):
            return "Invalid format for \(field)"
        case .outOfRange(let field):
            return "\(field) is out of valid range"
        case .invalidConfiguration:
            return "Invalid configuration"
        }
    }
}
