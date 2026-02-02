//
//  JSONExporter.swift
//  HCD Interview Coach
//
//  EPIC E9: Export System
//  Generates JSON export of session data for integration with other tools
//

import Foundation

/// Generates JSON exports from session data
/// Produces valid, well-structured JSON with ISO 8601 timestamps
final class JSONExporter {

    // MARK: - Configuration

    /// Configuration options for JSON export
    struct Configuration {
        /// Use pretty printing for human readability
        var prettyPrint: Bool = true

        /// Sort keys alphabetically
        var sortKeys: Bool = true

        /// Include null values for missing optional fields
        var includeNullValues: Bool = false

        /// Include session metadata
        var includeMetadata: Bool = true

        /// Include computed/derived fields
        var includeComputedFields: Bool = true

        static let `default` = Configuration()
    }

    // MARK: - JSON Schema Version

    fileprivate static let schemaVersion = "1.0.0"

    // MARK: - Properties

    private let configuration: Configuration
    private let encoder: JSONEncoder

    // MARK: - Initialization

    init(configuration: Configuration = .default) {
        self.configuration = configuration

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601

        var formatting: JSONEncoder.OutputFormatting = []
        if configuration.prettyPrint {
            formatting.insert(.prettyPrinted)
        }
        if configuration.sortKeys {
            formatting.insert(.sortedKeys)
        }
        self.encoder.outputFormatting = formatting
    }

    // MARK: - Public Interface

    /// Exports a session to JSON format
    /// - Parameter session: The session to export
    /// - Returns: The generated JSON data
    /// - Throws: An error if encoding fails
    func export(_ session: Session) throws -> Data {
        let exportModel = SessionExportModel(session: session, configuration: configuration)
        return try encoder.encode(exportModel)
    }

    /// Exports a session to a JSON string
    /// - Parameter session: The session to export
    /// - Returns: The generated JSON string
    /// - Throws: An error if encoding fails
    func exportToString(_ session: Session) throws -> String {
        let data = try export(session)
        guard let string = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "JSONExporter", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to convert JSON data to string"
            ])
        }
        return string
    }
}

// MARK: - Export Models

/// Root export model containing all session data
private struct SessionExportModel: Encodable {
    let schemaVersion: String
    let exportedAt: Date
    let session: SessionData
    let transcript: [UtteranceData]
    let insights: [InsightData]
    let topicCoverage: [TopicData]
    let metadata: ExportMetadata

    init(session: Session, configuration: JSONExporter.Configuration) {
        self.schemaVersion = JSONExporter.schemaVersion
        self.exportedAt = Date()
        self.session = SessionData(session: session, includeComputed: configuration.includeComputedFields)
        self.transcript = session.utterances
            .sorted { $0.timestampSeconds < $1.timestampSeconds }
            .map { UtteranceData(utterance: $0, includeComputed: configuration.includeComputedFields) }
        self.insights = session.insights
            .sorted { $0.timestampSeconds < $1.timestampSeconds }
            .map { InsightData(insight: $0, includeComputed: configuration.includeComputedFields) }
        self.topicCoverage = session.topicStatuses
            .sorted { $0.topicName < $1.topicName }
            .map { TopicData(topicStatus: $0, includeComputed: configuration.includeComputedFields) }
        self.metadata = ExportMetadata()
    }
}

/// Core session data
private struct SessionData: Encodable {
    let id: String
    let projectName: String
    let participantName: String
    let sessionMode: String
    let startedAt: Date
    let endedAt: Date?
    let totalDurationSeconds: Double
    let notes: String?

    // Computed fields
    let utteranceCount: Int?
    let insightCount: Int?
    let isInProgress: Bool?

    init(session: Session, includeComputed: Bool) {
        self.id = session.id.uuidString
        self.projectName = session.projectName
        self.participantName = session.participantName
        self.sessionMode = session.sessionMode.rawValue
        self.startedAt = session.startedAt
        self.endedAt = session.endedAt
        self.totalDurationSeconds = session.totalDurationSeconds
        self.notes = session.notes

        if includeComputed {
            self.utteranceCount = session.utteranceCount
            self.insightCount = session.insightCount
            self.isInProgress = session.isInProgress
        } else {
            self.utteranceCount = nil
            self.insightCount = nil
            self.isInProgress = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case projectName
        case participantName
        case sessionMode
        case startedAt
        case endedAt
        case totalDurationSeconds
        case notes
        case utteranceCount
        case insightCount
        case isInProgress
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(projectName, forKey: .projectName)
        try container.encode(participantName, forKey: .participantName)
        try container.encode(sessionMode, forKey: .sessionMode)
        try container.encode(startedAt, forKey: .startedAt)
        try container.encodeIfPresent(endedAt, forKey: .endedAt)
        try container.encode(totalDurationSeconds, forKey: .totalDurationSeconds)
        try container.encodeIfPresent(notes, forKey: .notes)

        // Only encode computed fields if they have values
        if let utteranceCount = utteranceCount {
            try container.encode(utteranceCount, forKey: .utteranceCount)
        }
        if let insightCount = insightCount {
            try container.encode(insightCount, forKey: .insightCount)
        }
        if let isInProgress = isInProgress {
            try container.encode(isInProgress, forKey: .isInProgress)
        }
    }
}

/// Utterance data for export
private struct UtteranceData: Encodable {
    let id: String
    let speaker: String
    let text: String
    let timestampSeconds: Double
    let confidence: Double?
    let createdAt: Date

    // Computed fields
    let formattedTimestamp: String?
    let wordCount: Int?

    init(utterance: Utterance, includeComputed: Bool) {
        self.id = utterance.id.uuidString
        self.speaker = utterance.speaker.rawValue
        self.text = utterance.text
        self.timestampSeconds = utterance.timestampSeconds
        self.confidence = utterance.confidence
        self.createdAt = utterance.createdAt

        if includeComputed {
            self.formattedTimestamp = utterance.formattedTimestamp
            self.wordCount = utterance.wordCount
        } else {
            self.formattedTimestamp = nil
            self.wordCount = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case speaker
        case text
        case timestampSeconds
        case confidence
        case createdAt
        case formattedTimestamp
        case wordCount
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(speaker, forKey: .speaker)
        try container.encode(text, forKey: .text)
        try container.encode(timestampSeconds, forKey: .timestampSeconds)
        try container.encodeIfPresent(confidence, forKey: .confidence)
        try container.encode(createdAt, forKey: .createdAt)

        if let formattedTimestamp = formattedTimestamp {
            try container.encode(formattedTimestamp, forKey: .formattedTimestamp)
        }
        if let wordCount = wordCount {
            try container.encode(wordCount, forKey: .wordCount)
        }
    }
}

/// Insight data for export
private struct InsightData: Encodable {
    let id: String
    let timestampSeconds: Double
    let quote: String
    let theme: String
    let source: String
    let createdAt: Date
    let tags: [String]

    // Computed fields
    let formattedTimestamp: String?
    let isAIGenerated: Bool?

    init(insight: Insight, includeComputed: Bool) {
        self.id = insight.id.uuidString
        self.timestampSeconds = insight.timestampSeconds
        self.quote = insight.quote
        self.theme = insight.theme
        self.source = insight.source.rawValue
        self.createdAt = insight.createdAt
        self.tags = insight.tags

        if includeComputed {
            self.formattedTimestamp = insight.formattedTimestamp
            self.isAIGenerated = insight.isAIGenerated
        } else {
            self.formattedTimestamp = nil
            self.isAIGenerated = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case timestampSeconds
        case quote
        case theme
        case source
        case createdAt
        case tags
        case formattedTimestamp
        case isAIGenerated
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(timestampSeconds, forKey: .timestampSeconds)
        try container.encode(quote, forKey: .quote)
        try container.encode(theme, forKey: .theme)
        try container.encode(source, forKey: .source)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(tags, forKey: .tags)

        if let formattedTimestamp = formattedTimestamp {
            try container.encode(formattedTimestamp, forKey: .formattedTimestamp)
        }
        if let isAIGenerated = isAIGenerated {
            try container.encode(isAIGenerated, forKey: .isAIGenerated)
        }
    }
}

/// Topic status data for export
private struct TopicData: Encodable {
    let id: String
    let topicId: String
    let topicName: String
    let status: String
    let lastUpdated: Date
    let notes: String?

    // Computed fields
    let isCovered: Bool?
    let isFullyCovered: Bool?

    init(topicStatus: TopicStatus, includeComputed: Bool) {
        self.id = topicStatus.id.uuidString
        self.topicId = topicStatus.topicId
        self.topicName = topicStatus.topicName
        self.status = topicStatus.status.rawValue
        self.lastUpdated = topicStatus.lastUpdated
        self.notes = topicStatus.notes

        if includeComputed {
            self.isCovered = topicStatus.isCovered
            self.isFullyCovered = topicStatus.isFullyCovered
        } else {
            self.isCovered = nil
            self.isFullyCovered = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case topicId
        case topicName
        case status
        case lastUpdated
        case notes
        case isCovered
        case isFullyCovered
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(topicId, forKey: .topicId)
        try container.encode(topicName, forKey: .topicName)
        try container.encode(status, forKey: .status)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        try container.encodeIfPresent(notes, forKey: .notes)

        if let isCovered = isCovered {
            try container.encode(isCovered, forKey: .isCovered)
        }
        if let isFullyCovered = isFullyCovered {
            try container.encode(isFullyCovered, forKey: .isFullyCovered)
        }
    }
}

/// Export metadata
private struct ExportMetadata: Encodable {
    let appName: String = "HCD Interview Coach"
    let appVersion: String
    let platform: String = "macOS"
    let exportFormat: String = "JSON"

    init() {
        // Get app version from bundle
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.appVersion = version
        } else {
            self.appVersion = "1.0.0"
        }
    }
}

// MARK: - JSON Schema Documentation

extension JSONExporter {
    /// Returns the JSON schema documentation for the export format
    static var schemaDocumentation: String {
        """
        # HCD Interview Coach Export Schema v\(schemaVersion)

        ## Root Object
        - `schemaVersion`: String - Version of the export schema
        - `exportedAt`: ISO 8601 Date - When the export was created
        - `session`: Object - Core session data
        - `transcript`: Array - Ordered list of utterances
        - `insights`: Array - Extracted insights
        - `topicCoverage`: Array - Topic coverage status
        - `metadata`: Object - Export metadata

        ## Session Object
        - `id`: UUID String - Unique session identifier
        - `projectName`: String - Name of the research project
        - `participantName`: String - Name of the interview participant
        - `sessionMode`: String - "Full", "Transcription Only", or "Observer Only"
        - `startedAt`: ISO 8601 Date - When the session started
        - `endedAt`: ISO 8601 Date (optional) - When the session ended
        - `totalDurationSeconds`: Number - Total session duration
        - `notes`: String (optional) - Session notes
        - `utteranceCount`: Number (computed) - Number of utterances
        - `insightCount`: Number (computed) - Number of insights
        - `isInProgress`: Boolean (computed) - Whether session is active

        ## Utterance Object
        - `id`: UUID String - Unique utterance identifier
        - `speaker`: String - "interviewer", "participant", or "unknown"
        - `text`: String - Spoken text content
        - `timestampSeconds`: Number - Seconds from session start
        - `confidence`: Number (optional) - Transcription confidence 0-1
        - `createdAt`: ISO 8601 Date - When utterance was created
        - `formattedTimestamp`: String (computed) - "MM:SS" format
        - `wordCount`: Number (computed) - Words in utterance

        ## Insight Object
        - `id`: UUID String - Unique insight identifier
        - `timestampSeconds`: Number - Seconds from session start
        - `quote`: String - Supporting quote text
        - `theme`: String - Insight theme/title
        - `source`: String - "ai_generated", "user_added", or "automated"
        - `createdAt`: ISO 8601 Date - When insight was created
        - `tags`: Array of String - Applied tags
        - `formattedTimestamp`: String (computed) - "MM:SS" format
        - `isAIGenerated`: Boolean (computed) - AI source flag

        ## Topic Object
        - `id`: UUID String - Unique topic status identifier
        - `topicId`: String - Template topic identifier
        - `topicName`: String - Display name
        - `status`: String - "not_covered", "partial_coverage", "fully_covered", "skipped"
        - `lastUpdated`: ISO 8601 Date - Last status change
        - `notes`: String (optional) - Topic notes
        - `isCovered`: Boolean (computed) - Any coverage
        - `isFullyCovered`: Boolean (computed) - Full coverage
        """
    }
}
