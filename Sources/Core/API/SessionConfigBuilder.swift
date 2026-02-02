//
//  SessionConfigBuilder.swift
//  HCD Interview Coach
//
//  EPIC E3-S3: Implement Session Configuration
//  Builds OpenAI Realtime API session configuration
//

import Foundation

/// Builds session configuration for OpenAI Realtime API
struct SessionConfigBuilder {
    // MARK: - Public Methods

    /// Build API session configuration from app session config
    /// - Parameter config: App session configuration
    /// - Returns: Dictionary ready for API transmission
    /// - Throws: ConnectionError if configuration is invalid
    static func build(from config: SessionConfig) async throws -> [String: Any] {
        // Validate inputs
        guard !config.systemPrompt.isEmpty else {
            throw ConnectionError.invalidConfiguration
        }

        // Build system prompt with context
        let fullPrompt = buildSystemPrompt(
            basePrompt: config.systemPrompt,
            topics: config.topics,
            metadata: config.metadata,
            sessionMode: config.sessionMode
        )

        // Build function definitions based on session mode
        let tools = buildFunctionDefinitions(for: config.sessionMode)

        // Build VAD configuration
        let vadConfig = buildVADConfiguration()

        // Build audio format configuration
        let audioConfig = buildAudioConfiguration()

        // Assemble complete session configuration
        var sessionConfig: [String: Any] = [
            "modalities": ["text", "audio"],
            "instructions": fullPrompt,
            "voice": "alloy",
            "input_audio_format": audioConfig["input_format"] as Any,
            "output_audio_format": audioConfig["output_format"] as Any,
            "input_audio_transcription": [
                "model": "whisper-1"
            ],
            "turn_detection": vadConfig,
            "temperature": 0.7,
            "max_response_output_tokens": 200
        ]

        // Add tools if not observer-only mode
        if config.sessionMode != .observerOnly {
            sessionConfig["tools"] = tools
            sessionConfig["tool_choice"] = "auto"
        }

        return sessionConfig
    }

    // MARK: - System Prompt Building

    private static func buildSystemPrompt(
        basePrompt: String,
        topics: [String],
        metadata: SessionMetadata?,
        sessionMode: SessionMode
    ) -> String {
        var prompt = basePrompt

        // Add silence-first philosophy for full mode
        if sessionMode == .full {
            prompt += "\n\n" + silenceFirstPhilosophy
        }

        // Add research context if available
        if !topics.isEmpty {
            prompt += "\n\n## Current Research Context"
            prompt += "\nResearch Topics: \(topics.joined(separator: ", "))"
        }

        if let metadata = metadata {
            if let duration = metadata.plannedDuration {
                let minutes = Int(duration / 60)
                prompt += "\nSession Duration: \(minutes) minutes"
            }

            if let notes = metadata.researcherNotes, !notes.isEmpty {
                prompt += "\nResearcher's Note: \(notes)"
            }
        }

        return prompt
    }

    private static var silenceFirstPhilosophy: String {
        """
        ## Your Default State
        SILENCE. You are not a participant in this conversation. You are a safety net.

        ## When to Use show_nudge (Rare)
        Only call show_nudge when ALL of the following are true:
        1. The participant expressed something significant (strong emotion, explicit frustration, surprising statement, or contradiction)
        2. AND the researcher has not already responded to it or acknowledged it
        3. AND at least 2 minutes have passed since your last prompt
        4. AND the interviewer is NOT currently speaking
        5. AND at least 5 seconds have passed since the interviewer stopped speaking
        6. AND you have HIGH confidence this is genuinely important

        When in doubt, do not prompt. A missed opportunity is better than a mistimed interruption.

        ## When to Use flag_insight
        Flag moments that are genuinely notable:
        - Strong emotional statements ("I was so frustrated I almost quit")
        - Surprising revelations that contradict assumptions
        - Specific stories or examples that illustrate broader patterns
        - Explicit unmet needs or desires

        Do not flag:
        - General statements of satisfaction or dissatisfaction
        - Vague or unclear comments
        - Things the researcher is already exploring

        ## When to Use update_topic
        Update topic status only when:
        - "touched": The participant has mentioned the topic at least once with relevance
        - "explored": There has been substantial back-and-forth (3+ exchanges) about the topic

        Never:
        - Mark a topic as explored just because it was mentioned
        - Update topics based on superficial references

        ## Your Philosophy
        The researcher is skilled. They don't need guidance. Your job is to:
        1. Notice what they might have missed
        2. Capture insights they might not have time to note
        3. Track awareness of topics without creating anxiety

        Trust the researcher. Stay quiet. Intervene only when it truly matters.
        """
    }

    // MARK: - Function Definitions

    private static func buildFunctionDefinitions(for mode: SessionMode) -> [[String: Any]] {
        var functions: [[String: Any]] = []

        // Add functions based on session mode
        switch mode {
        case .full:
            // Full mode: all functions available
            functions.append(showNudgeFunction)
            functions.append(flagInsightFunction)
            functions.append(updateTopicFunction)

        case .transcriptionOnly:
            // Transcription only: just insights and topic tracking
            functions.append(flagInsightFunction)
            functions.append(updateTopicFunction)

        case .observerOnly:
            // Observer only: no functions
            break
        }

        return functions
    }

    private static var showNudgeFunction: [String: Any] {
        [
            "type": "function",
            "name": "show_nudge",
            "description": """
                Display a rare coaching prompt. Only call when highly confident the researcher missed \
                something significant. This should be used sparingly - most sessions should have 0-2 prompts.
                """,
            "parameters": [
                "type": "object",
                "properties": [
                    "text": [
                        "type": "string",
                        "description": "Brief prompt text for the researcher (max 100 characters)",
                        "maxLength": 100
                    ],
                    "reason": [
                        "type": "string",
                        "description": "Internal: detailed explanation of why this prompt is warranted"
                    ]
                ],
                "required": ["text", "reason"]
            ]
        ]
    }

    private static var flagInsightFunction: [String: Any] {
        [
            "type": "function",
            "name": "flag_insight",
            "description": """
                Mark a notable moment in the interview. Only flag genuinely significant statements - \
                strong emotions, surprising revelations, specific stories, or explicit unmet needs.
                """,
            "parameters": [
                "type": "object",
                "properties": [
                    "quote": [
                        "type": "string",
                        "description": "The notable quote or statement from the participant"
                    ],
                    "theme": [
                        "type": "string",
                        "description": "Suggested theme or category for this insight"
                    ]
                ],
                "required": ["quote", "theme"]
            ]
        ]
    }

    private static var updateTopicFunction: [String: Any] {
        [
            "type": "function",
            "name": "update_topic",
            "description": """
                Update the status of a research topic. Only update when there's clear evidence of discussion. \
                'touched' means mentioned with relevance. 'explored' means substantial back-and-forth (3+ exchanges).
                """,
            "parameters": [
                "type": "object",
                "properties": [
                    "topic_id": [
                        "type": "string",
                        "description": "The identifier of the topic being updated"
                    ],
                    "status": [
                        "type": "string",
                        "enum": ["touched", "explored"],
                        "description": "New status for the topic"
                    ]
                ],
                "required": ["topic_id", "status"]
            ]
        ]
    }

    // MARK: - VAD Configuration

    private static func buildVADConfiguration() -> [String: Any] {
        [
            "type": "server_vad",
            "threshold": 0.5,
            "prefix_padding_ms": 300,
            "silence_duration_ms": 500,
            "create_response": false  // We don't want AI to generate audio responses
        ]
    }

    // MARK: - Audio Configuration

    private static func buildAudioConfiguration() -> [String: String] {
        [
            "input_format": "pcm16",     // 16-bit PCM
            "output_format": "pcm16",    // 16-bit PCM
            "sample_rate": "24000"       // 24kHz
        ]
    }
}

// MARK: - Function Call Parsing Types

/// Parsed show_nudge function call
struct ShowNudgeCall: Equatable {
    let text: String
    let reason: String
    let timestamp: TimeInterval

    init(text: String, reason: String, timestamp: TimeInterval) {
        self.text = text
        self.reason = reason
        self.timestamp = timestamp
    }

    static func from(_ event: FunctionCallEvent) -> ShowNudgeCall? {
        guard event.name == "show_nudge",
              let text = event.arguments["text"],
              let reason = event.arguments["reason"] else {
            return nil
        }

        return ShowNudgeCall(
            text: text,
            reason: reason,
            timestamp: event.timestamp
        )
    }
}

/// Parsed flag_insight function call
struct FlagInsightCall: Equatable {
    let quote: String
    let theme: String
    let timestamp: TimeInterval

    init(quote: String, theme: String, timestamp: TimeInterval) {
        self.quote = quote
        self.theme = theme
        self.timestamp = timestamp
    }

    static func from(_ event: FunctionCallEvent) -> FlagInsightCall? {
        guard event.name == "flag_insight",
              let quote = event.arguments["quote"],
              let theme = event.arguments["theme"] else {
            return nil
        }

        return FlagInsightCall(
            quote: quote,
            theme: theme,
            timestamp: event.timestamp
        )
    }
}

/// Parsed update_topic function call
struct UpdateTopicCall: Equatable {
    let topicId: String
    let status: TopicAwareness
    let timestamp: TimeInterval

    init(topicId: String, status: TopicAwareness, timestamp: TimeInterval) {
        self.topicId = topicId
        self.status = status
        self.timestamp = timestamp
    }

    static func from(_ event: FunctionCallEvent) -> UpdateTopicCall? {
        guard event.name == "update_topic",
              let topicId = event.arguments["topic_id"],
              let statusString = event.arguments["status"],
              let status = TopicAwareness(rawValue: statusString) else {
            return nil
        }

        return UpdateTopicCall(
            topicId: topicId,
            status: status,
            timestamp: event.timestamp
        )
    }
}

/// Topic awareness status (from PRD)
enum TopicAwareness: String, Codable {
    case untouched
    case touched
    case explored
    // Note: no "completed" state per PRD
}
