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
        case secureDeleteFailed(Error)
        case notFound
        case invalidData
        case dataProtectionNotEnabled
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

    // MARK: - Audio Setup Errors

    /// Errors specific to the audio setup wizard flow.
    /// Each case provides a clear description of what went wrong,
    /// why it happened, and how to fix it.
    enum AudioSetupError: Error {
        /// BlackHole 2ch virtual audio driver is not installed on this Mac.
        case blackHoleNotFound
        /// A BlackHole driver was detected, but it is not the required 2-channel version.
        case blackHoleIncompatibleVersion
        /// No Multi-Output Device exists in Audio MIDI Setup.
        case multiOutputNotFound
        /// A Multi-Output Device exists but does not include BlackHole 2ch.
        case multiOutputMissingBlackHole
        /// A Multi-Output Device exists but does not include any speaker or headphone output.
        case multiOutputMissingSpeakers
        /// A Multi-Output Device exists but is not properly configured.
        case multiOutputNotConfigured
        /// The system sound output is not set to the Multi-Output Device.
        case systemAudioNotConfigured
        /// The audio verification test did not detect any captured audio.
        case verificationNoAudioDetected
        /// The audio verification test failed for an unknown reason.
        case verificationFailed(String)
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
        case .secureDeleteFailed(let error):
            return "Failed to securely delete data: \(error.localizedDescription)"
        case .notFound:
            return "Item not found in database"
        case .invalidData:
            return "Invalid data in database"
        case .dataProtectionNotEnabled:
            return "Data protection is not enabled on the database file"
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

// MARK: - AudioSetupError LocalizedError

extension HCDError.AudioSetupError: LocalizedError {

    /// A short, user-visible title describing what went wrong.
    var errorDescription: String? {
        switch self {
        case .blackHoleNotFound:
            return "BlackHole 2ch is not installed"
        case .blackHoleIncompatibleVersion:
            return "Incompatible BlackHole version detected"
        case .multiOutputNotFound:
            return "No Multi-Output Device found"
        case .multiOutputMissingBlackHole:
            return "Multi-Output Device is missing BlackHole"
        case .multiOutputMissingSpeakers:
            return "Multi-Output Device is missing speakers"
        case .multiOutputNotConfigured:
            return "Multi-Output Device is not properly configured"
        case .systemAudioNotConfigured:
            return "System output is not set to Multi-Output Device"
        case .verificationNoAudioDetected:
            return "No audio was captured during the test"
        case .verificationFailed(let detail):
            return "Audio verification failed: \(detail)"
        }
    }

    /// A detailed explanation of why the error occurred.
    var failureReason: String? {
        switch self {
        case .blackHoleNotFound:
            return "HCD Interview Coach uses BlackHole 2ch to capture system audio (such as your participant's voice from a video call). This free, open-source virtual audio driver must be installed before audio capture can work."
        case .blackHoleIncompatibleVersion:
            return "A BlackHole driver was found on your system, but it appears to be the 16-channel or 64-channel version. HCD Interview Coach requires the 2-channel version (BlackHole 2ch) for proper audio capture."
        case .multiOutputNotFound:
            return "A Multi-Output Device lets your Mac send audio to your speakers and BlackHole at the same time. Without it, you either cannot hear your participant or cannot capture the audio."
        case .multiOutputMissingBlackHole:
            return "Your Multi-Output Device exists but does not include BlackHole 2ch as one of its outputs. Without BlackHole in the device, the app cannot capture system audio."
        case .multiOutputMissingSpeakers:
            return "Your Multi-Output Device exists but does not include any speaker or headphone output. Without speakers, you will not be able to hear your participant during the interview."
        case .multiOutputNotConfigured:
            return "A Multi-Output Device was found but it is not set up correctly. It needs to include both BlackHole 2ch and your speakers or headphones."
        case .systemAudioNotConfigured:
            return "Your Mac's sound output is currently set to a different device. Audio will not be routed through the Multi-Output Device until you select it as your system output."
        case .verificationNoAudioDetected:
            return "The app played a test sound but did not detect any audio coming through BlackHole. This usually means the Multi-Output Device is not selected as the system output, or BlackHole is not included in it."
        case .verificationFailed:
            return "The audio capture test did not complete successfully. This may indicate a configuration issue with your audio devices."
        }
    }

    /// Step-by-step instructions telling the user how to fix the problem.
    var recoverySuggestion: String? {
        switch self {
        case .blackHoleNotFound:
            return """
            1. Open Terminal and run: brew install blackhole-2ch
               (Or download the installer from existential.audio/blackhole)
            2. Follow the installer prompts and enter your password if asked.
            3. Restart your Mac if the driver is not detected after installation.
            4. Return to this screen and click "Re-check" to verify.
            """
        case .blackHoleIncompatibleVersion:
            return """
            1. Open Terminal and run: brew install blackhole-2ch
               (This installs the correct 2-channel version alongside other versions.)
            2. If you previously installed a different version manually, remove it first \
            using the uninstaller from existential.audio/blackhole.
            3. Restart your Mac, then click "Re-check" to verify.
            """
        case .multiOutputNotFound:
            return """
            1. Open Audio MIDI Setup (Applications > Utilities, or search in Spotlight).
            2. Click the "+" button in the bottom-left corner.
            3. Select "Create Multi-Output Device".
            4. Check both "BlackHole 2ch" and your speakers/headphones.
            5. Click the gear icon and set your speakers as the Master Device.
            6. Return here and click "Re-check".
            """
        case .multiOutputMissingBlackHole:
            return """
            1. Open Audio MIDI Setup (Applications > Utilities).
            2. Select your Multi-Output Device in the left sidebar.
            3. In the device list on the right, check the box next to "BlackHole 2ch".
            4. If BlackHole 2ch is not listed, go back to Step 2 and install it first.
            5. Click "Re-check" when done.
            """
        case .multiOutputMissingSpeakers:
            return """
            1. Open Audio MIDI Setup (Applications > Utilities).
            2. Select your Multi-Output Device in the left sidebar.
            3. In the device list, check the box next to your speakers \
            (e.g., "MacBook Pro Speakers" or "External Headphones").
            4. Set your speakers as the Master Device using the gear icon.
            5. Click "Re-check" when done.
            """
        case .multiOutputNotConfigured:
            return """
            1. Open Audio MIDI Setup (Applications > Utilities).
            2. Select your Multi-Output Device in the left sidebar.
            3. Ensure both BlackHole 2ch and your speakers are checked.
            4. Set your speakers as the Master Device via the gear icon.
            5. Click "Re-check" to verify the configuration.
            """
        case .systemAudioNotConfigured:
            return """
            1. Open System Settings > Sound (or click the button below).
            2. Under "Output", select your Multi-Output Device.
            Alternatively: Hold Option and click the Sound icon in the menu bar, \
            then choose your Multi-Output Device.
            3. Click "Re-check" to verify.
            """
        case .verificationNoAudioDetected:
            return """
            1. Check System Settings > Sound > Output is set to your Multi-Output Device.
            2. Make sure your volume is not muted (try pressing the volume-up key).
            3. Verify BlackHole 2ch is included in your Multi-Output Device \
            (open Audio MIDI Setup to check).
            4. Try playing audio from another app (e.g., Music or a browser).
            5. Click "Try Again" to re-run the test.
            """
        case .verificationFailed:
            return """
            1. Go back to the previous steps and verify each one is marked as successful.
            2. Restart Audio MIDI Setup and re-check your Multi-Output Device.
            3. If the issue persists, try restarting your Mac and running setup again.
            4. Click "Try Again" to re-run the verification test.
            """
        }
    }
}
