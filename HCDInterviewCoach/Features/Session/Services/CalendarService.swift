//
//  CalendarService.swift
//  HCD Interview Coach
//
//  Feature B: Calendar Integration
//  Detects upcoming interview events from macOS Calendar and extracts
//  participant/project metadata to pre-populate session setup.
//

import Foundation
import EventKit

// MARK: - Upcoming Interview

/// Represents a detected upcoming interview from the user's calendar
struct UpcomingInterview: Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let notes: String?
    let participantName: String?
    let projectName: String?
    let calendarName: String

    /// Duration of the event in minutes
    var durationMinutes: Int {
        Int(endDate.timeIntervalSince(startDate) / 60)
    }

    /// Whether the event starts today
    var isToday: Bool {
        Calendar.current.isDateInToday(startDate)
    }

    /// Whether the event has not yet started
    var isUpcoming: Bool {
        startDate > Date()
    }

    /// Formatted start time in HH:mm format
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: startDate)
    }

    /// Formatted end time in HH:mm format
    var formattedEndTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: endDate)
    }

    /// Formatted date label: "Today", "Tomorrow", or "MMM d"
    var formattedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(startDate) {
            return "Today"
        } else if calendar.isDateInTomorrow(startDate) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: startDate)
        }
    }

    /// Formatted time range string, e.g. "09:00 - 10:00"
    var formattedTimeRange: String {
        "\(formattedTime) - \(formattedEndTime)"
    }
}

// MARK: - Calendar Auth Status

/// Authorization status for calendar access
enum CalendarAuthStatus: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

// MARK: - Calendar Service

/// Service that detects upcoming interview events from the macOS Calendar.
///
/// Scans the user's calendars for events matching UX research keywords,
/// extracts participant and project metadata, and presents them for
/// quick session setup.
@MainActor
final class CalendarService: ObservableObject {

    // MARK: - Published Properties

    @Published var authorizationStatus: CalendarAuthStatus = .notDetermined
    @Published var upcomingInterviews: [UpcomingInterview] = []
    @Published var isLoading: Bool = false
    @Published var lastError: String?

    // MARK: - Private Properties

    private let eventStore: EKEventStore
    private let interviewKeywords: [String]

    // MARK: - Initialization

    /// Creates a CalendarService with the default event store and keyword list.
    /// - Parameter eventStore: The EKEventStore to query (defaults to a new instance)
    init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
        self.interviewKeywords = [
            "interview", "user research", "usability", "ux research",
            "user testing", "user test", "participant", "research session",
            "discovery", "contextual inquiry", "focus group", "moderated test",
            "card sort", "tree test", "diary study"
        ]
        checkAuthorizationStatus()
    }

    /// Creates a CalendarService with a custom event store and keywords (for testing).
    /// - Parameters:
    ///   - eventStore: The EKEventStore to query
    ///   - keywords: Custom list of keywords to match against event titles/notes
    init(eventStore: EKEventStore, keywords: [String]) {
        self.eventStore = eventStore
        self.interviewKeywords = keywords
        checkAuthorizationStatus()
    }

    // MARK: - Public Methods

    /// Requests calendar access from the user.
    ///
    /// Updates `authorizationStatus` based on the result. On success,
    /// automatically fetches upcoming interviews.
    func requestAccess() async {
        do {
            let granted: Bool
            if #available(macOS 14.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }

            if granted {
                authorizationStatus = .authorized
                AppLogger.shared.info("Calendar access granted")
                await fetchUpcomingInterviews()
            } else {
                authorizationStatus = .denied
                AppLogger.shared.warning("Calendar access denied by user")
            }
        } catch {
            authorizationStatus = .denied
            lastError = error.localizedDescription
            AppLogger.shared.logError(error, context: "Requesting calendar access")
        }
    }

    /// Fetches upcoming interview events from the calendar.
    ///
    /// Queries events in the next N days, filters them by interview keywords,
    /// and populates `upcomingInterviews` sorted by start date.
    ///
    /// - Parameter days: Number of days ahead to search (default: 7)
    func fetchUpcomingInterviews(days: Int = 7) async {
        guard authorizationStatus == .authorized else {
            AppLogger.shared.debug("Skipping calendar fetch: not authorized")
            return
        }

        isLoading = true
        lastError = nil

        let calendar = Calendar.current
        let now = Date()
        guard let endDate = calendar.date(byAdding: .day, value: days, to: now) else {
            isLoading = false
            lastError = "Failed to calculate date range"
            return
        }

        let predicate = eventStore.predicateForEvents(
            withStart: now,
            end: endDate,
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)

        let interviews = events
            .filter { isInterviewEvent($0) }
            .map { convertToUpcomingInterview($0) }
            .sorted { $0.startDate < $1.startDate }

        upcomingInterviews = interviews
        isLoading = false

        AppLogger.shared.info("Found \(interviews.count) upcoming interviews in next \(days) days")
    }

    // MARK: - Name Extraction (Public for Testing)

    /// Extracts a participant name from an event's title or notes.
    ///
    /// Recognizes patterns such as:
    /// - "Interview with Jane Doe"
    /// - "Participant: Jane Doe"
    /// - "Session - Jane Doe"
    /// - Attendee names from the event's attendees list
    ///
    /// - Parameter event: The calendar event to extract from
    /// - Returns: The extracted participant name, or nil if none found
    func extractParticipantName(from event: EKEvent) -> String? {
        // Try title-based patterns first
        if let name = extractParticipantFromText(event.title ?? "") {
            return name
        }

        // Try notes-based patterns
        if let notes = event.notes, let name = extractParticipantFromText(notes) {
            return name
        }

        // Try extracting from attendees (exclude the organizer)
        if let attendees = event.attendees {
            let nonOrganizer = attendees.filter { !$0.isCurrentUser }
            if let firstAttendee = nonOrganizer.first, let name = firstAttendee.name {
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }

        return nil
    }

    /// Extracts a project name from an event's title, notes, or calendar name.
    ///
    /// Recognizes patterns such as:
    /// - "Project: Acme Redesign"
    /// - "[Acme Redesign] Interview"
    /// - "Acme Redesign - User Interview"
    ///
    /// - Parameter event: The calendar event to extract from
    /// - Returns: The extracted project name, or nil if none found
    func extractProjectName(from event: EKEvent) -> String? {
        let title = event.title ?? ""
        let notes = event.notes ?? ""

        // Pattern: "Project: ProjectName" (in title or notes)
        if let name = extractProjectFromColonPattern(title) {
            return name
        }
        if let name = extractProjectFromColonPattern(notes) {
            return name
        }

        // Pattern: "[ProjectName] ..." in title
        if let name = extractProjectFromBrackets(title) {
            return name
        }

        // Pattern: "ProjectName - Interview/Research/Session..." in title
        if let name = extractProjectFromDashPattern(title) {
            return name
        }

        // Fall back to calendar name if it looks like a project
        let calendarName = event.calendar?.title ?? ""
        let genericCalendarNames = [
            "calendar", "home", "work", "personal", "default",
            "birthdays", "holidays", "other"
        ]
        let lowerCalName = calendarName.lowercased()
        if !calendarName.isEmpty && !genericCalendarNames.contains(lowerCalName) {
            // If calendar name contains research-related keywords, use it
            let projectIndicators = ["research", "study", "project", "ux", "design"]
            if projectIndicators.contains(where: { lowerCalName.contains($0) }) {
                return calendarName
            }
        }

        return nil
    }

    // MARK: - Private Methods

    /// Checks the current authorization status for calendar access
    private func checkAuthorizationStatus() {
        let status: EKAuthorizationStatus
        if #available(macOS 14.0, *) {
            status = EKEventStore.authorizationStatus(for: .event)
        } else {
            status = EKEventStore.authorizationStatus(for: .event)
        }

        switch status {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .fullAccess, .authorized:
            authorizationStatus = .authorized
        case .denied:
            authorizationStatus = .denied
        case .restricted:
            authorizationStatus = .restricted
        case .writeOnly:
            authorizationStatus = .denied
        @unknown default:
            authorizationStatus = .notDetermined
        }

        AppLogger.shared.debug("Calendar authorization status: \(String(describing: authorizationStatus))")
    }

    /// Determines whether a calendar event is likely an interview/research session.
    ///
    /// Performs case-insensitive keyword matching against the event title and notes.
    ///
    /// - Parameter event: The calendar event to evaluate
    /// - Returns: true if the event matches interview keywords
    private func isInterviewEvent(_ event: EKEvent) -> Bool {
        let title = (event.title ?? "").lowercased()
        let notes = (event.notes ?? "").lowercased()
        let combined = title + " " + notes

        return interviewKeywords.contains { keyword in
            combined.contains(keyword.lowercased())
        }
    }

    /// Converts an EKEvent to an UpcomingInterview model.
    ///
    /// - Parameter event: The EKEvent to convert
    /// - Returns: An UpcomingInterview with extracted metadata
    private func convertToUpcomingInterview(_ event: EKEvent) -> UpcomingInterview {
        UpcomingInterview(
            id: event.eventIdentifier ?? UUID().uuidString,
            title: event.title ?? "Untitled Event",
            startDate: event.startDate,
            endDate: event.endDate,
            location: event.location,
            notes: event.notes,
            participantName: extractParticipantName(from: event),
            projectName: extractProjectName(from: event),
            calendarName: event.calendar?.title ?? "Unknown"
        )
    }

    // MARK: - Text Extraction Helpers

    /// Extracts a participant name from text using common patterns.
    ///
    /// Supported patterns:
    /// - "with FirstName LastName"
    /// - "Participant: FirstName LastName"
    /// - "Interviewee: FirstName LastName"
    /// - "Session - FirstName LastName"
    ///
    /// - Parameter text: The text to search
    /// - Returns: The extracted name, or nil
    func extractParticipantFromText(_ text: String) -> String? {
        // Pattern: "with Name" (e.g., "Interview with Jane Doe")
        let withPattern = try? NSRegularExpression(
            pattern: #"(?:interview|session|call|meeting|chat)\s+with\s+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)*)"#,
            options: [.caseInsensitive]
        )
        if let match = withPattern?.firstMatch(
            in: text,
            range: NSRange(text.startIndex..., in: text)
        ) {
            if let range = Range(match.range(at: 1), in: text) {
                let name = String(text[range]).trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { return name }
            }
        }

        // Pattern: "Participant: Name" or "Interviewee: Name"
        let colonPattern = try? NSRegularExpression(
            pattern: #"(?:participant|interviewee|respondent|user)\s*:\s*([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)*)"#,
            options: [.caseInsensitive]
        )
        if let match = colonPattern?.firstMatch(
            in: text,
            range: NSRange(text.startIndex..., in: text)
        ) {
            if let range = Range(match.range(at: 1), in: text) {
                let name = String(text[range]).trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { return name }
            }
        }

        // Pattern: "... - Name" at the end (e.g., "User Interview - Jane Doe")
        let dashPattern = try? NSRegularExpression(
            pattern: #"\s+-\s+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)+)\s*$"#,
            options: []
        )
        if let match = dashPattern?.firstMatch(
            in: text,
            range: NSRange(text.startIndex..., in: text)
        ) {
            if let range = Range(match.range(at: 1), in: text) {
                let name = String(text[range]).trimmingCharacters(in: .whitespaces)
                // Only return if it looks like a person's name (2+ words, not a project keyword)
                let words = name.split(separator: " ")
                let projectKeywords = ["interview", "research", "session", "test", "study", "review"]
                let isProjectName = words.contains { projectKeywords.contains($0.lowercased()) }
                if words.count >= 2 && !isProjectName {
                    return name
                }
            }
        }

        return nil
    }

    /// Extracts a project name from "Project: Name" pattern.
    ///
    /// - Parameter text: The text to search
    /// - Returns: The extracted project name, or nil
    private func extractProjectFromColonPattern(_ text: String) -> String? {
        let pattern = try? NSRegularExpression(
            pattern: #"(?:project|study|program)\s*:\s*(.+?)(?:\s*[-\|]|$)"#,
            options: [.caseInsensitive]
        )
        if let match = pattern?.firstMatch(
            in: text,
            range: NSRange(text.startIndex..., in: text)
        ) {
            if let range = Range(match.range(at: 1), in: text) {
                let name = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty { return name }
            }
        }
        return nil
    }

    /// Extracts a project name from "[ProjectName]" bracket pattern in text.
    ///
    /// - Parameter text: The text to search
    /// - Returns: The extracted project name, or nil
    private func extractProjectFromBrackets(_ text: String) -> String? {
        let pattern = try? NSRegularExpression(
            pattern: #"\[([^\]]+)\]"#,
            options: []
        )
        if let match = pattern?.firstMatch(
            in: text,
            range: NSRange(text.startIndex..., in: text)
        ) {
            if let range = Range(match.range(at: 1), in: text) {
                let name = String(text[range]).trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { return name }
            }
        }
        return nil
    }

    /// Extracts a project name from "ProjectName - Interview/Research..." pattern.
    ///
    /// - Parameter text: The text to search
    /// - Returns: The extracted project name, or nil
    private func extractProjectFromDashPattern(_ text: String) -> String? {
        let suffixKeywords = [
            "interview", "research", "session", "test", "testing",
            "usability", "study", "participant", "user"
        ]
        let suffixGroup = suffixKeywords.joined(separator: "|")
        let pattern = try? NSRegularExpression(
            pattern: "^(.+?)\\s+-\\s+(?:\(suffixGroup))",
            options: [.caseInsensitive]
        )
        if let match = pattern?.firstMatch(
            in: text,
            range: NSRange(text.startIndex..., in: text)
        ) {
            if let range = Range(match.range(at: 1), in: text) {
                let name = String(text[range]).trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { return name }
            }
        }
        return nil
    }
}
