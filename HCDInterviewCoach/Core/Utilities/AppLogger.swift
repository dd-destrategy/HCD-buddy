import Foundation
import OSLog

/// Centralized logging infrastructure using OSLog for structured logging
final class AppLogger {
    static let shared = AppLogger()

    // MARK: - Subsystems

    private let subsystem = "com.hcdinterviewcoach.app"

    // MARK: - Categories

    private let generalLogger: Logger
    private let dataLogger: Logger
    private let audioLogger: Logger
    private let transcriptionLogger: Logger
    private let apiLogger: Logger
    private let uiLogger: Logger

    private init() {
        generalLogger = Logger(subsystem: subsystem, category: "general")
        dataLogger = Logger(subsystem: subsystem, category: "data")
        audioLogger = Logger(subsystem: subsystem, category: "audio")
        transcriptionLogger = Logger(subsystem: subsystem, category: "transcription")
        apiLogger = Logger(subsystem: subsystem, category: "api")
        uiLogger = Logger(subsystem: subsystem, category: "ui")
    }

    // MARK: - General Logging

    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let location = formatLocation(file: file, function: function, line: line)
        generalLogger.debug("\(location): \(message)")
    }

    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let location = formatLocation(file: file, function: function, line: line)
        generalLogger.info("\(location): \(message)")
    }

    func notice(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let location = formatLocation(file: file, function: function, line: line)
        generalLogger.notice("\(location): \(message)")
    }

    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let location = formatLocation(file: file, function: function, line: line)
        generalLogger.warning("\(location): \(message)")
    }

    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let location = formatLocation(file: file, function: function, line: line)
        generalLogger.error("\(location): \(message)")
    }

    func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let location = formatLocation(file: file, function: function, line: line)
        generalLogger.critical("\(location): \(message)")
    }

    // MARK: - Category-Specific Logging

    /// Log data/database operations
    func logData(_ message: String, level: LogLevel = .info) {
        switch level {
        case .debug:
            dataLogger.debug("\(message)")
        case .info:
            dataLogger.info("\(message)")
        case .notice:
            dataLogger.notice("\(message)")
        case .warning:
            dataLogger.warning("\(message)")
        case .error:
            dataLogger.error("\(message)")
        case .critical:
            dataLogger.critical("\(message)")
        }
    }

    /// Log audio operations
    func logAudio(_ message: String, level: LogLevel = .info) {
        switch level {
        case .debug:
            audioLogger.debug("\(message)")
        case .info:
            audioLogger.info("\(message)")
        case .notice:
            audioLogger.notice("\(message)")
        case .warning:
            audioLogger.warning("\(message)")
        case .error:
            audioLogger.error("\(message)")
        case .critical:
            audioLogger.critical("\(message)")
        }
    }

    /// Log transcription operations
    func logTranscription(_ message: String, level: LogLevel = .info) {
        switch level {
        case .debug:
            transcriptionLogger.debug("\(message)")
        case .info:
            transcriptionLogger.info("\(message)")
        case .notice:
            transcriptionLogger.notice("\(message)")
        case .warning:
            transcriptionLogger.warning("\(message)")
        case .error:
            transcriptionLogger.error("\(message)")
        case .critical:
            transcriptionLogger.critical("\(message)")
        }
    }

    /// Log API operations
    func logAPI(_ message: String, level: LogLevel = .info) {
        switch level {
        case .debug:
            apiLogger.debug("\(message)")
        case .info:
            apiLogger.info("\(message)")
        case .notice:
            apiLogger.notice("\(message)")
        case .warning:
            apiLogger.warning("\(message)")
        case .error:
            apiLogger.error("\(message)")
        case .critical:
            apiLogger.critical("\(message)")
        }
    }

    /// Log UI operations
    func logUI(_ message: String, level: LogLevel = .info) {
        switch level {
        case .debug:
            uiLogger.debug("\(message)")
        case .info:
            uiLogger.info("\(message)")
        case .notice:
            uiLogger.notice("\(message)")
        case .warning:
            uiLogger.warning("\(message)")
        case .error:
            uiLogger.error("\(message)")
        case .critical:
            uiLogger.critical("\(message)")
        }
    }

    // MARK: - Error Logging

    /// Log an error with full details
    func logError(_ error: Error, context: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let location = formatLocation(file: file, function: function, line: line)
        var message = "\(location): Error: \(error.localizedDescription)"
        if let context = context {
            message = "\(location): \(context) - Error: \(error.localizedDescription)"
        }
        generalLogger.error("\(message)")
    }

    // MARK: - Helpers

    private func formatLocation(file: String, function: String, line: Int) -> String {
        let filename = (file as NSString).lastPathComponent
        return "[\(filename):\(line) \(function)]"
    }
}

// MARK: - Log Level

enum LogLevel {
    case debug
    case info
    case notice
    case warning
    case error
    case critical
}
