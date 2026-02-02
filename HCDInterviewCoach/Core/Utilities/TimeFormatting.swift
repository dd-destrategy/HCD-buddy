//
//  TimeFormatting.swift
//  HCD Interview Coach
//
//  Shared time formatting utilities to avoid code duplication.
//  Previously, identical formatting logic was copy-pasted in 5+ locations.
//

import Foundation

/// Centralized time formatting utilities for consistent display across the app
enum TimeFormatting {

    // MARK: - Duration Formatting

    /// Format a duration in seconds to human-readable string (e.g., "1:23:45" or "23:45")
    /// - Parameters:
    ///   - duration: Duration in seconds
    ///   - alwaysShowHours: If true, always show hours even if 0
    /// - Returns: Formatted time string
    static func formatDuration(_ duration: TimeInterval, alwaysShowHours: Bool = false) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 || alwaysShowHours {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /// Format a duration for display with labels (e.g., "1 hour and 23 minutes")
    /// - Parameter duration: Duration in seconds
    /// - Returns: Human-readable duration string with labels
    static func formatDurationVerbose(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        var parts: [String] = []

        if hours > 0 {
            parts.append("\(hours) hour\(hours == 1 ? "" : "s")")
        }
        if minutes > 0 {
            parts.append("\(minutes) minute\(minutes == 1 ? "" : "s")")
        }
        if seconds > 0 && hours == 0 {
            parts.append("\(seconds) second\(seconds == 1 ? "" : "s")")
        }

        if parts.isEmpty {
            return "0 seconds"
        } else if parts.count == 1 {
            return parts[0]
        } else {
            let last = parts.removeLast()
            return parts.joined(separator: ", ") + " and " + last
        }
    }

    /// Format a timestamp for display in transcript (e.g., "[00:23:45]")
    /// - Parameter timestamp: Timestamp in seconds from session start
    /// - Returns: Bracketed timestamp string
    static func formatTimestamp(_ timestamp: TimeInterval) -> String {
        return "[\(formatDuration(timestamp))]"
    }

    /// Format a compact timestamp (e.g., "23:45")
    /// - Parameter timestamp: Timestamp in seconds
    /// - Returns: Compact time string without brackets
    static func formatCompactTimestamp(_ timestamp: TimeInterval) -> String {
        return formatDuration(timestamp, alwaysShowHours: false)
    }

    // MARK: - Cached Date Formatters

    /// Thread-safe cached DateFormatter for dates (e.g., "Feb 1, 2026")
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Thread-safe cached DateFormatter for times (e.g., "2:30 PM")
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    /// Thread-safe cached DateFormatter for date and time (e.g., "Feb 1, 2026 at 2:30 PM")
    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// Thread-safe cached ISO8601 formatter for export
    static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Thread-safe cached DateFormatter for file names (e.g., "2026-02-01_143045")
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter
    }()

    // MARK: - Convenience Methods

    /// Format a date for display
    static func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }

    /// Format a time for display
    static func formatTime(_ date: Date) -> String {
        return timeFormatter.string(from: date)
    }

    /// Format a date and time for display
    static func formatDateTime(_ date: Date) -> String {
        return dateTimeFormatter.string(from: date)
    }

    /// Format a date for ISO8601 export
    static func formatISO8601(_ date: Date) -> String {
        return iso8601Formatter.string(from: date)
    }

    /// Format a date for use in file names
    static func formatForFileName(_ date: Date) -> String {
        return fileNameFormatter.string(from: date)
    }
}

// MARK: - TimeInterval Extension

extension TimeInterval {
    /// Format this duration as a time string (e.g., "1:23:45")
    var formattedDuration: String {
        return TimeFormatting.formatDuration(self)
    }

    /// Format this duration with verbose labels (e.g., "1 hour and 23 minutes")
    var formattedDurationVerbose: String {
        return TimeFormatting.formatDurationVerbose(self)
    }

    /// Format this as a transcript timestamp (e.g., "[00:23:45]")
    var formattedTimestamp: String {
        return TimeFormatting.formatTimestamp(self)
    }
}

// MARK: - Date Extension

extension Date {
    /// Format this date for display
    var formattedDate: String {
        return TimeFormatting.formatDate(self)
    }

    /// Format this date and time for display
    var formattedDateTime: String {
        return TimeFormatting.formatDateTime(self)
    }

    /// Format this date for ISO8601 export
    var iso8601String: String {
        return TimeFormatting.formatISO8601(self)
    }

    /// Format this date for use in file names
    var fileNameString: String {
        return TimeFormatting.formatForFileName(self)
    }
}
