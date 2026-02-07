//
//  FeatureIntegrationTests.swift
//  HCDInterviewCoach
//
//  Integration tests verifying that all 8 new features work together
//  and integrate properly with the existing codebase.
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class FeatureIntegrationTests: XCTestCase {

    // MARK: - Feature 1 + Feature 4: Talk-Time with Focus Modes

    func testTalkTimeVisibilityFollowsFocusMode() {
        let focusManager = FocusModeManager()
        let talkTimeAnalyzer = TalkTimeAnalyzer()

        // Analysis mode: talk-time should be visible
        focusManager.setMode(.analysis)
        XCTAssertTrue(focusManager.panelVisibility.showTalkTime)

        // Interview mode: talk-time should be hidden
        focusManager.setMode(.interview)
        XCTAssertFalse(focusManager.panelVisibility.showTalkTime)

        // Coached mode: talk-time should be visible
        focusManager.setMode(.coached)
        XCTAssertTrue(focusManager.panelVisibility.showTalkTime)

        // Analyzer should work regardless of visibility
        let utterance = Utterance(
            speaker: .interviewer,
            text: "How do you handle your daily workflow?",
            timestampSeconds: 10.0
        )
        talkTimeAnalyzer.processUtterance(utterance)
        XCTAssertGreaterThan(talkTimeAnalyzer.totalSpeakingTime, 0)
    }

    // MARK: - Feature 2 + Feature 7: Question Analysis feeds Follow-Up Suggestions

    func testQuestionAnalyzerAndFollowUpSuggesterWorkInParallel() {
        let questionAnalyzer = QuestionTypeAnalyzer()
        let followUpSuggester = FollowUpSuggester()
        followUpSuggester.isEnabled = true

        // Interviewer asks a closed question
        let closedQuestion = Utterance(
            speaker: .interviewer,
            text: "Do you use a project management tool?",
            timestampSeconds: 60.0
        )
        let classification = questionAnalyzer.classify(closedQuestion)
        XCTAssertNotNil(classification)
        XCTAssertEqual(classification?.type, .closed)

        // Participant gives a short response
        let shortAnswer = Utterance(
            speaker: .participant,
            text: "Yes, I do.",
            timestampSeconds: 65.0
        )
        followUpSuggester.generateSuggestions(from: shortAnswer, topics: ["Workflow", "Tools"])
        XCTAssertFalse(followUpSuggester.suggestions.isEmpty, "Short answer should generate elaboration suggestion")
    }

    // MARK: - Feature 2: Question Type Classification Accuracy

    func testQuestionTypeCoversAllCategories() {
        let analyzer = QuestionTypeAnalyzer()

        let testCases: [(String, QuestionType)] = [
            ("How do you typically manage your projects?", .openEnded),
            ("Do you use Jira?", .closed),
            ("Don't you think agile is better?", .leading),
            ("Why is that important to you?", .probing),
            ("What do you mean by seamless?", .clarifying),
            ("What if you had unlimited budget?", .hypothetical),
        ]

        for (text, expectedType) in testCases {
            let utterance = Utterance(speaker: .interviewer, text: text, timestampSeconds: 0)
            let classification = analyzer.classify(utterance)
            XCTAssertNotNil(classification, "Should classify: \(text)")
            XCTAssertEqual(classification?.type, expectedType, "Expected \(expectedType) for: \(text)")
        }
    }

    // MARK: - Feature 3: Cross-Session Analytics with Study

    func testStudyManagerAndAnalyticsIntegrate() async {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-studies-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let studyManager = StudyManager(storageURL: tempURL)
        let analytics = CrossSessionAnalytics()

        // Create a study and verify
        let study = studyManager.createStudy(name: "Usability Study", description: "Q1 2026")
        XCTAssertEqual(studyManager.studies.count, 1)
        XCTAssertEqual(study.name, "Usability Study")

        // Add session IDs
        let sessionId1 = UUID()
        let sessionId2 = UUID()
        studyManager.addSession(sessionId1, to: study.id)
        studyManager.addSession(sessionId2, to: study.id)

        let updated = studyManager.studies.first
        XCTAssertEqual(updated?.sessionCount, 2)
    }

    // MARK: - Feature 5: Tagging Service round-trip

    func testTaggingServiceCreateAndAssign() {
        let tagsURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-tags-\(UUID().uuidString).json")
        let assignmentsURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-assignments-\(UUID().uuidString).json")
        defer {
            try? FileManager.default.removeItem(at: tagsURL)
            try? FileManager.default.removeItem(at: assignmentsURL)
        }

        let taggingService = TaggingService(tagsURL: tagsURL, assignmentsURL: assignmentsURL)

        // Should have default tags
        XCTAssertEqual(taggingService.tags.count, 5)

        // Create custom tag
        let tag = taggingService.createTag(name: "Workaround", colorHex: "#FF6600")
        XCTAssertEqual(taggingService.tags.count, 6)

        // Assign to utterance
        let utteranceId = UUID()
        let sessionId = UUID()
        taggingService.assignTag(tag.id, to: utteranceId, sessionId: sessionId, note: "Important workaround")
        XCTAssertEqual(taggingService.assignments.count, 1)

        // Query back
        let assignments = taggingService.getAssignments(for: utteranceId)
        XCTAssertEqual(assignments.count, 1)
        XCTAssertEqual(assignments.first?.note, "Important workaround")

        // Tagged utterance IDs
        let taggedIds = taggingService.getTaggedUtteranceIds(for: sessionId)
        XCTAssertTrue(taggedIds.contains(utteranceId))
    }

    // MARK: - Feature 6: Session Summary Generation

    func testSessionSummaryGeneratorProducesResults() async {
        let generator = SessionSummaryGenerator()

        let session = Session(
            participantName: "Test User",
            projectName: "Test Project",
            sessionMode: .full,
            startedAt: Date().addingTimeInterval(-1800),
            endedAt: Date(),
            totalDurationSeconds: 1800
        )

        // Add utterances with pain point keywords
        let utterances = [
            Utterance(speaker: .participant, text: "The most frustrating thing about our current tool is the constant crashes during peak hours", timestampSeconds: 120),
            Utterance(speaker: .participant, text: "I love how the search feature works though, it saves us so much time", timestampSeconds: 240),
            Utterance(speaker: .interviewer, text: "Tell me more about the crashes", timestampSeconds: 360),
            Utterance(speaker: .participant, text: "The crashes happen every day during our standup meetings when everyone is using the tool simultaneously", timestampSeconds: 420),
        ]
        session.utterances = utterances

        let summary = await generator.generate(from: session)
        XCTAssertFalse(summary.participantPainPoints.isEmpty, "Should detect pain points")
        XCTAssertFalse(summary.positiveHighlights.isEmpty, "Should detect positive moments")
        XCTAssertGreaterThan(summary.sessionQualityScore, 0)
        XCTAssertFalse(summary.keyThemes.isEmpty, "Should extract themes")
    }

    // MARK: - Feature 8: Demo Mode Session Creation

    func testDemoSessionIsComplete() {
        let provider = DemoSessionProvider.shared
        let session = provider.createDemoSession()

        // Verify session basics
        XCTAssertEqual(session.participantName, "Sarah (Demo)")
        XCTAssertEqual(session.projectName, "Task Management Research")
        XCTAssertGreaterThan(session.utterances.count, 20)

        // Verify speaker distribution
        let interviewerCount = session.utterances.filter { $0.speaker == .interviewer }.count
        let participantCount = session.utterances.filter { $0.speaker == .participant }.count
        XCTAssertGreaterThan(interviewerCount, 0)
        XCTAssertGreaterThan(participantCount, 0)

        // Verify insights
        XCTAssertGreaterThan(session.insights.count, 0)

        // Verify topic statuses
        XCTAssertGreaterThan(session.topicStatuses.count, 0)

        // Verify transcript is non-empty
        XCTAssertFalse(provider.demoTranscript.isEmpty)
    }

    // MARK: - Feature 6 + Feature 8: Summary from Demo Session

    func testSummaryGeneratorWorksWithDemoSession() async {
        let provider = DemoSessionProvider.shared
        let session = provider.createDemoSession()

        let generator = SessionSummaryGenerator()
        let summary = await generator.generate(from: session)

        XCTAssertFalse(summary.keyThemes.isEmpty, "Demo session should produce themes")
        XCTAssertGreaterThan(summary.sessionQualityScore, 0, "Demo session should have quality score")

        // Verify markdown export works
        let markdown = generator.exportSummaryAsMarkdown(summary)
        XCTAssertTrue(markdown.contains("Session Summary"), "Markdown should have header")
        XCTAssertFalse(markdown.isEmpty)
    }

    // MARK: - Feature 1 + Feature 8: Talk-Time from Demo Session

    func testTalkTimeAnalyzerProcessesDemoUtterances() {
        let provider = DemoSessionProvider.shared
        let session = provider.createDemoSession()

        let analyzer = TalkTimeAnalyzer()
        analyzer.processUtterances(session.utterances)

        XCTAssertGreaterThan(analyzer.totalSpeakingTime, 0)
        XCTAssertGreaterThan(analyzer.interviewerRatio, 0)
        XCTAssertGreaterThan(analyzer.participantRatio, 0)
        // Ratio should sum to ~1.0
        XCTAssertEqual(analyzer.interviewerRatio + analyzer.participantRatio, 1.0, accuracy: 0.01)
    }

    // MARK: - Feature 2 + Feature 8: Question Analysis on Demo Session

    func testQuestionAnalyzerProcessesDemoQuestions() {
        let provider = DemoSessionProvider.shared
        let session = provider.createDemoSession()

        let analyzer = QuestionTypeAnalyzer()
        var classifiedCount = 0
        for utterance in session.utterances where utterance.speaker == .interviewer {
            if analyzer.classify(utterance) != nil {
                classifiedCount += 1
            }
        }

        XCTAssertGreaterThan(classifiedCount, 0, "Should classify some interviewer utterances as questions")
        XCTAssertGreaterThan(analyzer.sessionStats.totalQuestions, 0)
        XCTAssertGreaterThan(analyzer.sessionStats.qualityScore, 0)
    }

    // MARK: - Feature 4: Focus Mode Persistence

    func testFocusModeDefaultIsAnalysis() {
        let manager = FocusModeManager()
        XCTAssertEqual(manager.currentMode, .analysis)
        XCTAssertTrue(manager.panelVisibility.showTranscript)
        XCTAssertTrue(manager.panelVisibility.showTopics)
        XCTAssertTrue(manager.panelVisibility.showInsights)
        XCTAssertTrue(manager.panelVisibility.showCoaching)
        XCTAssertTrue(manager.panelVisibility.showTalkTime)
    }

    func testFocusModeInterviewHidesNonTranscript() {
        let manager = FocusModeManager()
        manager.setMode(.interview)

        XCTAssertTrue(manager.panelVisibility.showTranscript)
        XCTAssertFalse(manager.panelVisibility.showTopics)
        XCTAssertFalse(manager.panelVisibility.showInsights)
        XCTAssertFalse(manager.panelVisibility.showCoaching)
        XCTAssertFalse(manager.panelVisibility.showTalkTime)
    }

    // MARK: - Feature 5 + Feature 8: Tag Demo Session Utterances

    func testTaggingDemoSessionUtterances() {
        let provider = DemoSessionProvider.shared
        let session = provider.createDemoSession()

        let tagsURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-tags-int-\(UUID().uuidString).json")
        let assignmentsURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-assignments-int-\(UUID().uuidString).json")
        defer {
            try? FileManager.default.removeItem(at: tagsURL)
            try? FileManager.default.removeItem(at: assignmentsURL)
        }

        let taggingService = TaggingService(tagsURL: tagsURL, assignmentsURL: assignmentsURL)

        // Tag first participant utterance with "Pain Point"
        guard let painPointTag = taggingService.tags.first(where: { $0.name == "Pain Point" }),
              let firstParticipant = session.utterances.first(where: { $0.speaker == .participant }) else {
            XCTFail("Missing default tag or participant utterance")
            return
        }

        taggingService.assignTag(painPointTag.id, to: firstParticipant.id, sessionId: session.id, note: nil)
        XCTAssertEqual(taggingService.assignments.count, 1)

        // Export tagged segments
        let markdown = taggingService.exportTaggedSegments(sessionId: session.id, utterances: session.utterances)
        XCTAssertTrue(markdown.contains("Pain Point"), "Export should include tag name")
    }
}
