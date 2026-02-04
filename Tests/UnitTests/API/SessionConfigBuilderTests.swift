//
//  SessionConfigBuilderTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for SessionConfigBuilder session configuration
//

import XCTest
@testable import HCDInterviewCoach

final class SessionConfigBuilderTests: XCTestCase {

    // MARK: - Helper Methods

    /// Creates a valid session config for testing
    private func createValidSessionConfig(
        systemPrompt: String = "You are a helpful interview coach.",
        topics: [String] = ["Topic 1", "Topic 2"],
        sessionMode: SessionMode = .full,
        metadata: SessionMetadata? = nil
    ) -> SessionConfig {
        SessionConfig(
            apiKey: "test-api-key",
            systemPrompt: systemPrompt,
            topics: topics,
            sessionMode: sessionMode,
            metadata: metadata
        )
    }

    // MARK: - Test: Default Config

    func testDefaultConfig_hasRequiredFields() async throws {
        // Given: A valid session configuration
        let config = createValidSessionConfig()

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: Should have all required fields
        XCTAssertNotNil(apiConfig["modalities"])
        XCTAssertNotNil(apiConfig["instructions"])
        XCTAssertNotNil(apiConfig["voice"])
        XCTAssertNotNil(apiConfig["input_audio_format"])
        XCTAssertNotNil(apiConfig["output_audio_format"])
        XCTAssertNotNil(apiConfig["input_audio_transcription"])
        XCTAssertNotNil(apiConfig["turn_detection"])
        XCTAssertNotNil(apiConfig["temperature"])
        XCTAssertNotNil(apiConfig["max_response_output_tokens"])
    }

    func testDefaultConfig_modalitiesIncludeTextAndAudio() async throws {
        // Given: A valid session configuration
        let config = createValidSessionConfig()

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: Modalities should include both text and audio
        let modalities = apiConfig["modalities"] as? [String]
        XCTAssertNotNil(modalities)
        XCTAssertTrue(modalities?.contains("text") ?? false)
        XCTAssertTrue(modalities?.contains("audio") ?? false)
    }

    func testDefaultConfig_usesWhisperTranscription() async throws {
        // Given: A valid session configuration
        let config = createValidSessionConfig()

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: Should use Whisper-1 for transcription
        let transcriptionConfig = apiConfig["input_audio_transcription"] as? [String: Any]
        XCTAssertEqual(transcriptionConfig?["model"] as? String, "whisper-1")
    }

    func testDefaultConfig_usesAlloyVoice() async throws {
        // Given: A valid session configuration
        let config = createValidSessionConfig()

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: Should use alloy voice
        XCTAssertEqual(apiConfig["voice"] as? String, "alloy")
    }

    // MARK: - Test: Transcription Only Mode

    func testTranscriptionOnlyMode_hasFunctionDefinitions() async throws {
        // Given: Transcription-only mode configuration
        let config = createValidSessionConfig(sessionMode: .transcriptionOnly)

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: Should have limited function definitions (no show_nudge)
        let tools = apiConfig["tools"] as? [[String: Any]]
        XCTAssertNotNil(tools)

        let toolNames = tools?.compactMap { $0["name"] as? String } ?? []
        XCTAssertFalse(toolNames.contains("show_nudge"), "Transcription-only should not have show_nudge")
        XCTAssertTrue(toolNames.contains("flag_insight"), "Should still have flag_insight")
        XCTAssertTrue(toolNames.contains("update_topic"), "Should still have update_topic")
    }

    // MARK: - Test: Coaching Mode (Full)

    func testCoachingMode_hasAllFunctions() async throws {
        // Given: Full mode configuration
        let config = createValidSessionConfig(sessionMode: .full)

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: Should have all function definitions
        let tools = apiConfig["tools"] as? [[String: Any]]
        XCTAssertNotNil(tools)

        let toolNames = tools?.compactMap { $0["name"] as? String } ?? []
        XCTAssertTrue(toolNames.contains("show_nudge"), "Full mode should have show_nudge")
        XCTAssertTrue(toolNames.contains("flag_insight"), "Full mode should have flag_insight")
        XCTAssertTrue(toolNames.contains("update_topic"), "Full mode should have update_topic")
    }

    func testCoachingMode_toolChoiceIsAuto() async throws {
        // Given: Full mode configuration
        let config = createValidSessionConfig(sessionMode: .full)

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: Tool choice should be auto
        XCTAssertEqual(apiConfig["tool_choice"] as? String, "auto")
    }

    func testCoachingMode_includesSilenceFirstPhilosophy() async throws {
        // Given: Full mode configuration
        let config = createValidSessionConfig(sessionMode: .full)

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: Instructions should include silence-first philosophy
        let instructions = apiConfig["instructions"] as? String
        XCTAssertNotNil(instructions)
        XCTAssertTrue(instructions?.contains("SILENCE") ?? false)
        XCTAssertTrue(instructions?.contains("Default State") ?? false)
    }

    // MARK: - Test: Observer Only Mode

    func testObserverOnlyMode_noFunctions() async throws {
        // Given: Observer-only mode configuration
        let config = createValidSessionConfig(sessionMode: .observerOnly)

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: Should not have tools
        XCTAssertNil(apiConfig["tools"])
        XCTAssertNil(apiConfig["tool_choice"])
    }

    // MARK: - Test: Custom System Prompt

    func testCustomSystemPrompt_includedInInstructions() async throws {
        // Given: A custom system prompt
        let customPrompt = "You are a specialized UX research assistant focusing on accessibility."
        let config = createValidSessionConfig(systemPrompt: customPrompt)

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: Instructions should contain the custom prompt
        let instructions = apiConfig["instructions"] as? String
        XCTAssertTrue(instructions?.contains(customPrompt) ?? false)
    }

    func testCustomSystemPrompt_emptyPromptThrows() async {
        // Given: An empty system prompt
        let config = createValidSessionConfig(systemPrompt: "")

        // When/Then: Building should throw
        do {
            _ = try await SessionConfigBuilder.build(from: config)
            XCTFail("Should throw for empty system prompt")
        } catch {
            XCTAssertEqual(error as? ConnectionError, ConnectionError.invalidConfiguration)
        }
    }

    // MARK: - Test: Temperature Setting

    func testTemperatureSetting_defaultValue() async throws {
        // Given: A valid configuration
        let config = createValidSessionConfig()

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: Temperature should be 0.7
        XCTAssertEqual(apiConfig["temperature"] as? Double, 0.7)
    }

    // MARK: - Test: Language Setting

    func testLanguageSetting_viaMetadata() async throws {
        // Given: Configuration with metadata
        let metadata = SessionMetadata(
            participantName: "Test User",
            projectName: "Test Project",
            researcherNotes: "Interview in English"
        )
        let config = createValidSessionConfig(metadata: metadata)

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: Should include researcher notes in instructions
        let instructions = apiConfig["instructions"] as? String
        XCTAssertTrue(instructions?.contains("Interview in English") ?? false)
    }

    // MARK: - Test: Function Definitions

    func testFunctionDefinitions_showNudgeStructure() async throws {
        // Given: Full mode configuration
        let config = createValidSessionConfig(sessionMode: .full)

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: show_nudge should have correct structure
        let tools = apiConfig["tools"] as? [[String: Any]] ?? []
        let showNudge = tools.first { ($0["name"] as? String) == "show_nudge" }

        XCTAssertNotNil(showNudge)
        XCTAssertEqual(showNudge?["type"] as? String, "function")
        XCTAssertNotNil(showNudge?["description"])
        XCTAssertNotNil(showNudge?["parameters"])
    }

    func testFunctionDefinitions_flagInsightStructure() async throws {
        // Given: Full mode configuration
        let config = createValidSessionConfig(sessionMode: .full)

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: flag_insight should have correct structure
        let tools = apiConfig["tools"] as? [[String: Any]] ?? []
        let flagInsight = tools.first { ($0["name"] as? String) == "flag_insight" }

        XCTAssertNotNil(flagInsight)

        let params = flagInsight?["parameters"] as? [String: Any]
        let properties = params?["properties"] as? [String: Any]
        XCTAssertNotNil(properties?["quote"])
        XCTAssertNotNil(properties?["theme"])
    }

    func testFunctionDefinitions_updateTopicStructure() async throws {
        // Given: Full mode configuration
        let config = createValidSessionConfig(sessionMode: .full)

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: update_topic should have correct structure
        let tools = apiConfig["tools"] as? [[String: Any]] ?? []
        let updateTopic = tools.first { ($0["name"] as? String) == "update_topic" }

        XCTAssertNotNil(updateTopic)

        let params = updateTopic?["parameters"] as? [String: Any]
        let properties = params?["properties"] as? [String: Any]
        XCTAssertNotNil(properties?["topic_id"])
        XCTAssertNotNil(properties?["status"])
    }

    // MARK: - Test: Build Valid Config

    func testBuildValidConfig_withTopics() async throws {
        // Given: Configuration with topics
        let topics = ["User Onboarding", "Feature Discovery", "Pain Points"]
        let config = createValidSessionConfig(topics: topics)

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: Topics should be included in instructions
        let instructions = apiConfig["instructions"] as? String
        for topic in topics {
            XCTAssertTrue(instructions?.contains(topic) ?? false, "Should include topic: \(topic)")
        }
    }

    func testBuildValidConfig_withDuration() async throws {
        // Given: Configuration with planned duration
        let metadata = SessionMetadata(
            plannedDuration: 3600  // 60 minutes
        )
        let config = createValidSessionConfig(metadata: metadata)

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: Duration should be mentioned in instructions
        let instructions = apiConfig["instructions"] as? String
        XCTAssertTrue(instructions?.contains("60 minutes") ?? false)
    }

    func testBuildValidConfig_vadConfiguration() async throws {
        // Given: A valid configuration
        let config = createValidSessionConfig()

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: VAD configuration should be correct
        let vadConfig = apiConfig["turn_detection"] as? [String: Any]
        XCTAssertNotNil(vadConfig)
        XCTAssertEqual(vadConfig?["type"] as? String, "server_vad")
        XCTAssertEqual(vadConfig?["threshold"] as? Double, 0.5)
        XCTAssertEqual(vadConfig?["create_response"] as? Bool, false)
    }

    func testBuildValidConfig_audioFormat() async throws {
        // Given: A valid configuration
        let config = createValidSessionConfig()

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: Audio format should be PCM16
        XCTAssertEqual(apiConfig["input_audio_format"] as? String, "pcm16")
        XCTAssertEqual(apiConfig["output_audio_format"] as? String, "pcm16")
    }

    func testBuildValidConfig_maxTokens() async throws {
        // Given: A valid configuration
        let config = createValidSessionConfig()

        // When: Building the API config
        let apiConfig = try await SessionConfigBuilder.build(from: config)

        // Then: Max tokens should be limited
        XCTAssertEqual(apiConfig["max_response_output_tokens"] as? Int, 200)
    }
}

// MARK: - Function Call Parsing Tests

final class FunctionCallParsingTests: XCTestCase {

    // MARK: - Test: ShowNudgeCall

    func testShowNudgeCall_validParsing() {
        // Given: A valid show_nudge event
        let event = FunctionCallEvent(
            name: "show_nudge",
            arguments: [
                "text": "Consider asking about their experience",
                "reason": "Participant mentioned frustration"
            ],
            timestamp: 10.5
        )

        // When: Parsing
        let call = ShowNudgeCall.from(event)

        // Then: Should parse correctly
        XCTAssertNotNil(call)
        XCTAssertEqual(call?.text, "Consider asking about their experience")
        XCTAssertEqual(call?.reason, "Participant mentioned frustration")
        XCTAssertEqual(call?.timestamp, 10.5)
    }

    func testShowNudgeCall_wrongFunctionName() {
        // Given: An event with wrong function name
        let event = FunctionCallEvent(
            name: "flag_insight",
            arguments: ["text": "Test", "reason": "Test"],
            timestamp: 0
        )

        // When: Parsing
        let call = ShowNudgeCall.from(event)

        // Then: Should return nil
        XCTAssertNil(call)
    }

    func testShowNudgeCall_missingArguments() {
        // Given: An event missing required arguments
        let event = FunctionCallEvent(
            name: "show_nudge",
            arguments: ["text": "Only text"],  // Missing reason
            timestamp: 0
        )

        // When: Parsing
        let call = ShowNudgeCall.from(event)

        // Then: Should return nil
        XCTAssertNil(call)
    }

    // MARK: - Test: FlagInsightCall

    func testFlagInsightCall_validParsing() {
        // Given: A valid flag_insight event
        let event = FunctionCallEvent(
            name: "flag_insight",
            arguments: [
                "quote": "I almost quit because of this issue",
                "theme": "Frustration with onboarding"
            ],
            timestamp: 25.0
        )

        // When: Parsing
        let call = FlagInsightCall.from(event)

        // Then: Should parse correctly
        XCTAssertNotNil(call)
        XCTAssertEqual(call?.quote, "I almost quit because of this issue")
        XCTAssertEqual(call?.theme, "Frustration with onboarding")
        XCTAssertEqual(call?.timestamp, 25.0)
    }

    func testFlagInsightCall_wrongFunctionName() {
        // Given: An event with wrong function name
        let event = FunctionCallEvent(
            name: "show_nudge",
            arguments: ["quote": "Test", "theme": "Test"],
            timestamp: 0
        )

        // When: Parsing
        let call = FlagInsightCall.from(event)

        // Then: Should return nil
        XCTAssertNil(call)
    }

    func testFlagInsightCall_missingArguments() {
        // Given: An event missing required arguments
        let event = FunctionCallEvent(
            name: "flag_insight",
            arguments: ["quote": "Only quote"],  // Missing theme
            timestamp: 0
        )

        // When: Parsing
        let call = FlagInsightCall.from(event)

        // Then: Should return nil
        XCTAssertNil(call)
    }

    // MARK: - Test: UpdateTopicCall

    func testUpdateTopicCall_validParsing() {
        // Given: A valid update_topic event
        let event = FunctionCallEvent(
            name: "update_topic",
            arguments: [
                "topic_id": "onboarding",
                "status": "explored"
            ],
            timestamp: 45.0
        )

        // When: Parsing
        let call = UpdateTopicCall.from(event)

        // Then: Should parse correctly
        XCTAssertNotNil(call)
        XCTAssertEqual(call?.topicId, "onboarding")
        XCTAssertEqual(call?.status, .explored)
        XCTAssertEqual(call?.timestamp, 45.0)
    }

    func testUpdateTopicCall_touchedStatus() {
        // Given: An event with touched status
        let event = FunctionCallEvent(
            name: "update_topic",
            arguments: ["topic_id": "feature-x", "status": "touched"],
            timestamp: 0
        )

        // When: Parsing
        let call = UpdateTopicCall.from(event)

        // Then: Should have touched status
        XCTAssertEqual(call?.status, .touched)
    }

    func testUpdateTopicCall_invalidStatus() {
        // Given: An event with invalid status
        let event = FunctionCallEvent(
            name: "update_topic",
            arguments: ["topic_id": "test", "status": "invalid_status"],
            timestamp: 0
        )

        // When: Parsing
        let call = UpdateTopicCall.from(event)

        // Then: Should return nil
        XCTAssertNil(call)
    }

    func testUpdateTopicCall_wrongFunctionName() {
        // Given: An event with wrong function name
        let event = FunctionCallEvent(
            name: "flag_insight",
            arguments: ["topic_id": "test", "status": "touched"],
            timestamp: 0
        )

        // When: Parsing
        let call = UpdateTopicCall.from(event)

        // Then: Should return nil
        XCTAssertNil(call)
    }

    // MARK: - Test: TopicAwareness Enum

    func testTopicAwareness_notCovered() {
        // Given: The notCovered status
        let status = TopicAwareness.notCovered

        // Then: Raw value should match
        XCTAssertEqual(status.rawValue, "not_covered")
    }

    func testTopicAwareness_partialCoverage() {
        // Given: The partialCoverage status
        let status = TopicAwareness.partialCoverage

        // Then: Raw value should match
        XCTAssertEqual(status.rawValue, "partial_coverage")
    }

    func testTopicAwareness_fullyCovered() {
        // Given: The fullyCovered status
        let status = TopicAwareness.fullyCovered

        // Then: Raw value should match
        XCTAssertEqual(status.rawValue, "fully_covered")
    }

    func testTopicAwareness_codable() throws {
        // Given: A status
        let status = TopicAwareness.fullyCovered

        // When: Encoding and decoding
        let encoded = try JSONEncoder().encode(status)
        let decoded = try JSONDecoder().decode(TopicAwareness.self, from: encoded)

        // Then: Should round-trip correctly
        XCTAssertEqual(decoded, status)
    }

    // MARK: - Test: Equatable Conformance

    func testShowNudgeCall_equatable() {
        // Given: Two identical calls
        let call1 = ShowNudgeCall(text: "Test", reason: "Reason", timestamp: 1.0)
        let call2 = ShowNudgeCall(text: "Test", reason: "Reason", timestamp: 1.0)

        // Then: Should be equal
        XCTAssertEqual(call1, call2)
    }

    func testFlagInsightCall_equatable() {
        // Given: Two identical calls
        let call1 = FlagInsightCall(quote: "Quote", theme: "Theme", timestamp: 1.0)
        let call2 = FlagInsightCall(quote: "Quote", theme: "Theme", timestamp: 1.0)

        // Then: Should be equal
        XCTAssertEqual(call1, call2)
    }

    func testUpdateTopicCall_equatable() {
        // Given: Two identical calls
        let call1 = UpdateTopicCall(topicId: "topic", status: .touched, timestamp: 1.0)
        let call2 = UpdateTopicCall(topicId: "topic", status: .touched, timestamp: 1.0)

        // Then: Should be equal
        XCTAssertEqual(call1, call2)
    }
}
