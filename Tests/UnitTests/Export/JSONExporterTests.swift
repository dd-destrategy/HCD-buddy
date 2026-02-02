//
//  JSONExporterTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E9: Export System
//  Unit tests for JSONExporter
//

import XCTest
@testable import HCDInterviewCoach

final class JSONExporterTests: XCTestCase {

    var exporter: JSONExporter!
    var testSession: Session!

    override func setUp() {
        super.setUp()
        exporter = JSONExporter()
        testSession = createTestSession()
    }

    override func tearDown() {
        exporter = nil
        testSession = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestSession() -> Session {
        let session = Session(
            participantName: "Alice Johnson",
            projectName: "E-Commerce UX Study",
            sessionMode: .transcriptionOnly,
            startedAt: Date(timeIntervalSince1970: 1700000000), // Fixed date for testing
            endedAt: Date(timeIntervalSince1970: 1700003600),
            totalDurationSeconds: 3600,
            notes: "Focus on checkout flow"
        )

        // Add utterances
        let utterances = [
            Utterance(
                speaker: .interviewer,
                text: "Please walk me through your checkout process.",
                timestampSeconds: 0,
                confidence: 0.98
            ),
            Utterance(
                speaker: .participant,
                text: "I usually start by reviewing my cart.",
                timestampSeconds: 5,
                confidence: 0.95
            )
        ]
        session.utterances = utterances

        // Add insights
        let insights = [
            Insight(
                timestampSeconds: 120,
                quote: "The shipping options are confusing",
                theme: "Shipping UX",
                source: .aiGenerated,
                tags: ["shipping", "confusion"]
            )
        ]
        session.insights = insights

        // Add topics
        let topics = [
            TopicStatus(
                topicId: "checkout",
                topicName: "Checkout Flow",
                status: .fullyCovered,
                notes: "Discussed in detail"
            )
        ]
        session.topicStatuses = topics

        return session
    }

    private func parseJSON(_ data: Data) throws -> [String: Any] {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json ?? [:]
    }

    // MARK: - Basic Export Tests

    func testExportProducesValidJSON() throws {
        // When
        let data = try exporter.export(testSession)

        // Then
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data))
    }

    func testExportToStringProducesValidJSON() throws {
        // When
        let jsonString = try exporter.exportToString(testSession)

        // Then
        XCTAssertFalse(jsonString.isEmpty)
        let data = jsonString.data(using: .utf8)!
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data))
    }

    // MARK: - Schema Tests

    func testJSONContainsSchemaVersion() throws {
        // When
        let data = try exporter.export(testSession)
        let json = try parseJSON(data)

        // Then
        let schemaVersion = json["schemaVersion"] as? String
        XCTAssertNotNil(schemaVersion)
        XCTAssertEqual(schemaVersion, "1.0.0")
    }

    func testJSONContainsExportedAt() throws {
        // When
        let data = try exporter.export(testSession)
        let json = try parseJSON(data)

        // Then
        let exportedAt = json["exportedAt"] as? String
        XCTAssertNotNil(exportedAt)
        // Should be ISO 8601 format
        XCTAssertTrue(exportedAt!.contains("T"))
    }

    // MARK: - Session Data Tests

    func testSessionDataFields() throws {
        // When
        let data = try exporter.export(testSession)
        let json = try parseJSON(data)

        // Then
        let session = json["session"] as? [String: Any]
        XCTAssertNotNil(session)

        XCTAssertNotNil(session?["id"] as? String)
        XCTAssertEqual(session?["projectName"] as? String, "E-Commerce UX Study")
        XCTAssertEqual(session?["participantName"] as? String, "Alice Johnson")
        XCTAssertEqual(session?["sessionMode"] as? String, "Transcription Only")
        XCTAssertNotNil(session?["startedAt"] as? String)
        XCTAssertNotNil(session?["endedAt"] as? String)
        XCTAssertEqual(session?["totalDurationSeconds"] as? Double, 3600)
        XCTAssertEqual(session?["notes"] as? String, "Focus on checkout flow")
    }

    func testSessionComputedFields() throws {
        // When
        let data = try exporter.export(testSession)
        let json = try parseJSON(data)

        // Then
        let session = json["session"] as? [String: Any]
        XCTAssertEqual(session?["utteranceCount"] as? Int, 2)
        XCTAssertEqual(session?["insightCount"] as? Int, 1)
        XCTAssertEqual(session?["isInProgress"] as? Bool, false)
    }

    // MARK: - Transcript Tests

    func testTranscriptArrayExists() throws {
        // When
        let data = try exporter.export(testSession)
        let json = try parseJSON(data)

        // Then
        let transcript = json["transcript"] as? [[String: Any]]
        XCTAssertNotNil(transcript)
        XCTAssertEqual(transcript?.count, 2)
    }

    func testTranscriptUtteranceFields() throws {
        // When
        let data = try exporter.export(testSession)
        let json = try parseJSON(data)

        // Then
        let transcript = json["transcript"] as? [[String: Any]]
        let firstUtterance = transcript?.first

        XCTAssertNotNil(firstUtterance?["id"] as? String)
        XCTAssertEqual(firstUtterance?["speaker"] as? String, "interviewer")
        XCTAssertEqual(firstUtterance?["text"] as? String, "Please walk me through your checkout process.")
        XCTAssertEqual(firstUtterance?["timestampSeconds"] as? Double, 0)
        XCTAssertEqual(firstUtterance?["confidence"] as? Double, 0.98)
        XCTAssertNotNil(firstUtterance?["createdAt"] as? String)
    }

    func testTranscriptUtteranceComputedFields() throws {
        // When
        let data = try exporter.export(testSession)
        let json = try parseJSON(data)

        // Then
        let transcript = json["transcript"] as? [[String: Any]]
        let firstUtterance = transcript?.first

        XCTAssertEqual(firstUtterance?["formattedTimestamp"] as? String, "00:00")
        XCTAssertNotNil(firstUtterance?["wordCount"] as? Int)
    }

    func testTranscriptOrderedByTimestamp() throws {
        // When
        let data = try exporter.export(testSession)
        let json = try parseJSON(data)

        // Then
        let transcript = json["transcript"] as? [[String: Any]]
        let timestamps = transcript?.compactMap { $0["timestampSeconds"] as? Double }

        XCTAssertEqual(timestamps, [0, 5])
    }

    // MARK: - Insights Tests

    func testInsightsArrayExists() throws {
        // When
        let data = try exporter.export(testSession)
        let json = try parseJSON(data)

        // Then
        let insights = json["insights"] as? [[String: Any]]
        XCTAssertNotNil(insights)
        XCTAssertEqual(insights?.count, 1)
    }

    func testInsightFields() throws {
        // When
        let data = try exporter.export(testSession)
        let json = try parseJSON(data)

        // Then
        let insights = json["insights"] as? [[String: Any]]
        let firstInsight = insights?.first

        XCTAssertNotNil(firstInsight?["id"] as? String)
        XCTAssertEqual(firstInsight?["timestampSeconds"] as? Double, 120)
        XCTAssertEqual(firstInsight?["quote"] as? String, "The shipping options are confusing")
        XCTAssertEqual(firstInsight?["theme"] as? String, "Shipping UX")
        XCTAssertEqual(firstInsight?["source"] as? String, "ai_generated")
        XCTAssertNotNil(firstInsight?["createdAt"] as? String)

        let tags = firstInsight?["tags"] as? [String]
        XCTAssertEqual(tags, ["shipping", "confusion"])
    }

    func testInsightComputedFields() throws {
        // When
        let data = try exporter.export(testSession)
        let json = try parseJSON(data)

        // Then
        let insights = json["insights"] as? [[String: Any]]
        let firstInsight = insights?.first

        XCTAssertEqual(firstInsight?["formattedTimestamp"] as? String, "02:00")
        XCTAssertEqual(firstInsight?["isAIGenerated"] as? Bool, true)
    }

    // MARK: - Topic Coverage Tests

    func testTopicCoverageArrayExists() throws {
        // When
        let data = try exporter.export(testSession)
        let json = try parseJSON(data)

        // Then
        let topicCoverage = json["topicCoverage"] as? [[String: Any]]
        XCTAssertNotNil(topicCoverage)
        XCTAssertEqual(topicCoverage?.count, 1)
    }

    func testTopicFields() throws {
        // When
        let data = try exporter.export(testSession)
        let json = try parseJSON(data)

        // Then
        let topicCoverage = json["topicCoverage"] as? [[String: Any]]
        let firstTopic = topicCoverage?.first

        XCTAssertNotNil(firstTopic?["id"] as? String)
        XCTAssertEqual(firstTopic?["topicId"] as? String, "checkout")
        XCTAssertEqual(firstTopic?["topicName"] as? String, "Checkout Flow")
        XCTAssertEqual(firstTopic?["status"] as? String, "fully_covered")
        XCTAssertNotNil(firstTopic?["lastUpdated"] as? String)
        XCTAssertEqual(firstTopic?["notes"] as? String, "Discussed in detail")
    }

    func testTopicComputedFields() throws {
        // When
        let data = try exporter.export(testSession)
        let json = try parseJSON(data)

        // Then
        let topicCoverage = json["topicCoverage"] as? [[String: Any]]
        let firstTopic = topicCoverage?.first

        XCTAssertEqual(firstTopic?["isCovered"] as? Bool, true)
        XCTAssertEqual(firstTopic?["isFullyCovered"] as? Bool, true)
    }

    // MARK: - Metadata Tests

    func testMetadataFields() throws {
        // When
        let data = try exporter.export(testSession)
        let json = try parseJSON(data)

        // Then
        let metadata = json["metadata"] as? [String: Any]
        XCTAssertNotNil(metadata)

        XCTAssertEqual(metadata?["appName"] as? String, "HCD Interview Coach")
        XCTAssertNotNil(metadata?["appVersion"] as? String)
        XCTAssertEqual(metadata?["platform"] as? String, "macOS")
        XCTAssertEqual(metadata?["exportFormat"] as? String, "JSON")
    }

    // MARK: - Configuration Tests

    func testPrettyPrintingEnabled() throws {
        // Given
        var config = JSONExporter.Configuration.default
        config.prettyPrint = true
        let prettyExporter = JSONExporter(configuration: config)

        // When
        let jsonString = try prettyExporter.exportToString(testSession)

        // Then
        XCTAssertTrue(jsonString.contains("\n"))
        XCTAssertTrue(jsonString.contains("  ")) // Indentation
    }

    func testPrettyPrintingDisabled() throws {
        // Given
        var config = JSONExporter.Configuration.default
        config.prettyPrint = false
        let compactExporter = JSONExporter(configuration: config)

        // When
        let jsonString = try compactExporter.exportToString(testSession)

        // Then
        // Compact JSON should have fewer newlines (only at document boundaries if any)
        let lineCount = jsonString.components(separatedBy: "\n").count
        XCTAssertLessThan(lineCount, 5) // Compact should be mostly single line
    }

    func testSortedKeysEnabled() throws {
        // Given
        var config = JSONExporter.Configuration.default
        config.sortKeys = true
        config.prettyPrint = true
        let sortedExporter = JSONExporter(configuration: config)

        // When
        let jsonString = try sortedExporter.exportToString(testSession)

        // Then
        // In a sorted JSON, "exportedAt" should come before "session" alphabetically
        if let exportedAtRange = jsonString.range(of: "\"exportedAt\""),
           let sessionRange = jsonString.range(of: "\"session\"") {
            XCTAssertTrue(exportedAtRange.lowerBound < sessionRange.lowerBound)
        }
    }

    func testExportWithoutComputedFields() throws {
        // Given
        var config = JSONExporter.Configuration.default
        config.includeComputedFields = false
        let noComputedExporter = JSONExporter(configuration: config)

        // When
        let data = try noComputedExporter.export(testSession)
        let json = try parseJSON(data)

        // Then
        let session = json["session"] as? [String: Any]
        XCTAssertNil(session?["utteranceCount"])
        XCTAssertNil(session?["insightCount"])
        XCTAssertNil(session?["isInProgress"])

        let transcript = json["transcript"] as? [[String: Any]]
        let firstUtterance = transcript?.first
        XCTAssertNil(firstUtterance?["formattedTimestamp"])
        XCTAssertNil(firstUtterance?["wordCount"])
    }

    // MARK: - Schema Documentation Tests

    func testSchemaDocumentation() {
        // When
        let documentation = JSONExporter.schemaDocumentation

        // Then
        XCTAssertFalse(documentation.isEmpty)
        XCTAssertTrue(documentation.contains("# HCD Interview Coach Export Schema"))
        XCTAssertTrue(documentation.contains("## Root Object"))
        XCTAssertTrue(documentation.contains("## Session Object"))
        XCTAssertTrue(documentation.contains("## Utterance Object"))
        XCTAssertTrue(documentation.contains("## Insight Object"))
        XCTAssertTrue(documentation.contains("## Topic Object"))
    }

    // MARK: - ISO 8601 Date Format Tests

    func testDatesAreISO8601Formatted() throws {
        // When
        let data = try exporter.export(testSession)
        let json = try parseJSON(data)

        // Then
        let session = json["session"] as? [String: Any]
        let startedAt = session?["startedAt"] as? String

        XCTAssertNotNil(startedAt)
        // ISO 8601 format should contain "T" separator and end with "Z" or timezone
        XCTAssertTrue(startedAt!.contains("T"))
    }

    // MARK: - Edge Cases

    func testEmptyTagsArray() throws {
        // Given
        testSession.insights = [
            Insight(
                timestampSeconds: 0,
                quote: "No tags",
                theme: "Tagless",
                source: .userAdded,
                tags: []
            )
        ]

        // When
        let data = try exporter.export(testSession)
        let json = try parseJSON(data)

        // Then
        let insights = json["insights"] as? [[String: Any]]
        let firstInsight = insights?.first
        let tags = firstInsight?["tags"] as? [String]

        XCTAssertNotNil(tags)
        XCTAssertEqual(tags?.count, 0)
    }

    func testNilOptionalFields() throws {
        // Given
        testSession.notes = nil
        testSession.topicStatuses = [
            TopicStatus(topicId: "t1", topicName: "Test", status: .notCovered)
        ]

        // When
        let data = try exporter.export(testSession)
        let json = try parseJSON(data)

        // Then
        let session = json["session"] as? [String: Any]
        // notes should be absent or null
        XCTAssertTrue(session?["notes"] == nil || session?["notes"] is NSNull)

        let topicCoverage = json["topicCoverage"] as? [[String: Any]]
        let firstTopic = topicCoverage?.first
        // notes should be absent or null
        XCTAssertTrue(firstTopic?["notes"] == nil || firstTopic?["notes"] is NSNull)
    }
}
