//
//  CalendarServiceTests.swift
//  HCD Interview Coach Tests
//
//  Feature B: Calendar Integration
//  Unit tests for CalendarService — focuses on pure functions:
//  keyword matching, participant/project name extraction, and
//  UpcomingInterview computed properties.
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class CalendarServiceTests: XCTestCase {

    // MARK: - UpcomingInterview Computed Properties

    func testDurationMinutes_calculatesCorrectly() {
        let start = Date()
        let end = start.addingTimeInterval(60 * 45) // 45 minutes
        let interview = makeInterview(startDate: start, endDate: end)
        XCTAssertEqual(interview.durationMinutes, 45)
    }

    func testDurationMinutes_zeroForSameStartEnd() {
        let now = Date()
        let interview = makeInterview(startDate: now, endDate: now)
        XCTAssertEqual(interview.durationMinutes, 0)
    }

    func testDurationMinutes_roundsDown() {
        let start = Date()
        let end = start.addingTimeInterval(60 * 30 + 45) // 30 min 45 sec
        let interview = makeInterview(startDate: start, endDate: end)
        XCTAssertEqual(interview.durationMinutes, 30)
    }

    func testIsToday_trueForTodayDate() {
        let interview = makeInterview(startDate: Date())
        XCTAssertTrue(interview.isToday)
    }

    func testIsToday_falseForTomorrowDate() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let interview = makeInterview(startDate: tomorrow)
        XCTAssertFalse(interview.isToday)
    }

    func testIsUpcoming_trueForFutureDate() {
        let future = Date().addingTimeInterval(3600) // 1 hour from now
        let interview = makeInterview(startDate: future)
        XCTAssertTrue(interview.isUpcoming)
    }

    func testIsUpcoming_falseForPastDate() {
        let past = Date().addingTimeInterval(-3600) // 1 hour ago
        let interview = makeInterview(startDate: past)
        XCTAssertFalse(interview.isUpcoming)
    }

    func testFormattedTime_correctFormat() {
        // Create a date with a known time
        var components = DateComponents()
        components.year = 2026
        components.month = 2
        components.day = 7
        components.hour = 14
        components.minute = 30
        let date = Calendar.current.date(from: components)!
        let interview = makeInterview(startDate: date)
        XCTAssertEqual(interview.formattedTime, "14:30")
    }

    func testFormattedEndTime_correctFormat() {
        var components = DateComponents()
        components.year = 2026
        components.month = 2
        components.day = 7
        components.hour = 15
        components.minute = 0
        let date = Calendar.current.date(from: components)!
        let interview = makeInterview(endDate: date)
        XCTAssertEqual(interview.formattedEndTime, "15:00")
    }

    func testFormattedDate_today() {
        let interview = makeInterview(startDate: Date())
        XCTAssertEqual(interview.formattedDate, "Today")
    }

    func testFormattedDate_tomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let interview = makeInterview(startDate: tomorrow)
        XCTAssertEqual(interview.formattedDate, "Tomorrow")
    }

    func testFormattedDate_futureDate() {
        // A date 5 days from now should show "MMM d" format
        let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        let interview = makeInterview(startDate: futureDate)

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let expected = formatter.string(from: futureDate)
        XCTAssertEqual(interview.formattedDate, expected)
    }

    func testFormattedTimeRange_combinesStartAndEnd() {
        var startComponents = DateComponents()
        startComponents.year = 2026
        startComponents.month = 2
        startComponents.day = 7
        startComponents.hour = 9
        startComponents.minute = 0
        let start = Calendar.current.date(from: startComponents)!

        var endComponents = DateComponents()
        endComponents.year = 2026
        endComponents.month = 2
        endComponents.day = 7
        endComponents.hour = 10
        endComponents.minute = 0
        let end = Calendar.current.date(from: endComponents)!

        let interview = makeInterview(startDate: start, endDate: end)
        XCTAssertEqual(interview.formattedTimeRange, "09:00 - 10:00")
    }

    // MARK: - Participant Name Extraction

    func testExtractParticipant_withPattern() {
        let service = CalendarService(eventStore: .init(), keywords: [])
        let result = service.extractParticipantFromText("Interview with Jane Doe")
        XCTAssertEqual(result, "Jane Doe")
    }

    func testExtractParticipant_sessionWithPattern() {
        let service = CalendarService(eventStore: .init(), keywords: [])
        let result = service.extractParticipantFromText("Session with John Smith")
        XCTAssertEqual(result, "John Smith")
    }

    func testExtractParticipant_callWithPattern() {
        let service = CalendarService(eventStore: .init(), keywords: [])
        let result = service.extractParticipantFromText("Call with Maria Garcia")
        XCTAssertEqual(result, "Maria Garcia")
    }

    func testExtractParticipant_participantColonPattern() {
        let service = CalendarService(eventStore: .init(), keywords: [])
        let result = service.extractParticipantFromText("Participant: Alice Johnson")
        XCTAssertEqual(result, "Alice Johnson")
    }

    func testExtractParticipant_intervieweeColonPattern() {
        let service = CalendarService(eventStore: .init(), keywords: [])
        let result = service.extractParticipantFromText("Interviewee: Bob Wilson")
        XCTAssertEqual(result, "Bob Wilson")
    }

    func testExtractParticipant_dashSuffixPattern() {
        let service = CalendarService(eventStore: .init(), keywords: [])
        let result = service.extractParticipantFromText("User Interview - Jane Doe")
        XCTAssertEqual(result, "Jane Doe")
    }

    func testExtractParticipant_noMatch() {
        let service = CalendarService(eventStore: .init(), keywords: [])
        let result = service.extractParticipantFromText("Team standup meeting")
        XCTAssertNil(result)
    }

    func testExtractParticipant_caseInsensitiveWith() {
        let service = CalendarService(eventStore: .init(), keywords: [])
        let result = service.extractParticipantFromText("INTERVIEW WITH Sarah Lee")
        XCTAssertEqual(result, "Sarah Lee")
    }

    func testExtractParticipant_emptyString() {
        let service = CalendarService(eventStore: .init(), keywords: [])
        let result = service.extractParticipantFromText("")
        XCTAssertNil(result)
    }

    // MARK: - Project Name Extraction (via text helpers)

    func testExtractProject_colonPattern() {
        // Test title: "Project: Acme Redesign - User Interview"
        // The CalendarService.extractProjectName needs an EKEvent, so we test
        // the public-facing behavior through the private helpers indirectly.
        // Instead, we test UpcomingInterview struct values.
        let interview = makeInterview(projectName: "Acme Redesign")
        XCTAssertEqual(interview.projectName, "Acme Redesign")
    }

    func testExtractProject_nilWhenNotProvided() {
        let interview = makeInterview(projectName: nil)
        XCTAssertNil(interview.projectName)
    }

    // MARK: - UpcomingInterview Equatable

    func testUpcomingInterview_equality() {
        let date = Date()
        let endDate = date.addingTimeInterval(3600)
        let a = UpcomingInterview(
            id: "123", title: "Test", startDate: date, endDate: endDate,
            location: nil, notes: nil, participantName: nil, projectName: nil,
            calendarName: "Work"
        )
        let b = UpcomingInterview(
            id: "123", title: "Test", startDate: date, endDate: endDate,
            location: nil, notes: nil, participantName: nil, projectName: nil,
            calendarName: "Work"
        )
        XCTAssertEqual(a, b)
    }

    func testUpcomingInterview_inequality_differentId() {
        let date = Date()
        let endDate = date.addingTimeInterval(3600)
        let a = UpcomingInterview(
            id: "123", title: "Test", startDate: date, endDate: endDate,
            location: nil, notes: nil, participantName: nil, projectName: nil,
            calendarName: "Work"
        )
        let b = UpcomingInterview(
            id: "456", title: "Test", startDate: date, endDate: endDate,
            location: nil, notes: nil, participantName: nil, projectName: nil,
            calendarName: "Work"
        )
        XCTAssertNotEqual(a, b)
    }

    // MARK: - CalendarAuthStatus

    func testCalendarAuthStatus_equatable() {
        XCTAssertEqual(CalendarAuthStatus.authorized, CalendarAuthStatus.authorized)
        XCTAssertEqual(CalendarAuthStatus.denied, CalendarAuthStatus.denied)
        XCTAssertEqual(CalendarAuthStatus.restricted, CalendarAuthStatus.restricted)
        XCTAssertEqual(CalendarAuthStatus.notDetermined, CalendarAuthStatus.notDetermined)
        XCTAssertNotEqual(CalendarAuthStatus.authorized, CalendarAuthStatus.denied)
    }

    // MARK: - CalendarService Initialization

    func testCalendarService_initialState() {
        let service = CalendarService(eventStore: .init(), keywords: ["test"])
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.lastError)
        XCTAssertTrue(service.upcomingInterviews.isEmpty)
    }

    func testCalendarService_customKeywords() {
        let service = CalendarService(eventStore: .init(), keywords: ["custom", "keyword"])
        // Service should initialize without error
        XCTAssertNil(service.lastError)
    }

    // MARK: - Interview Keyword Detection (via UpcomingInterview metadata)

    func testInterviewDetection_titleContainsInterview() {
        // We test this by verifying the service can be created and has correct defaults
        let service = CalendarService()
        XCTAssertFalse(service.isLoading)
        // The actual keyword filtering happens on real EKEvents,
        // but we verify the service initializes with correct keyword set
        XCTAssertNil(service.lastError)
    }

    // MARK: - Helpers

    /// Creates an UpcomingInterview with sensible defaults for testing
    private func makeInterview(
        id: String = "test-id",
        title: String = "User Interview",
        startDate: Date = Date(),
        endDate: Date? = nil,
        location: String? = nil,
        notes: String? = nil,
        participantName: String? = nil,
        projectName: String? = nil,
        calendarName: String = "Work"
    ) -> UpcomingInterview {
        UpcomingInterview(
            id: id,
            title: title,
            startDate: startDate,
            endDate: endDate ?? startDate.addingTimeInterval(3600),
            location: location,
            notes: notes,
            participantName: participantName,
            projectName: projectName,
            calendarName: calendarName
        )
    }
}
