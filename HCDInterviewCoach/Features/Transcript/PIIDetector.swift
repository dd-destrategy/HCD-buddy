//
//  PIIDetector.swift
//  HCDInterviewCoach
//
//  FEATURE C: Consent & PII Redaction Engine
//  Detects personally identifiable information in text using regex patterns and heuristics.
//

import Foundation

// MARK: - PII Types

/// Types of personally identifiable information that can be detected
enum PIIType: String, CaseIterable, Codable {
    case email = "email"
    case phone = "phone"
    case ssn = "ssn"
    case name = "name"
    case company = "company"
    case address = "address"
    case creditCard = "credit_card"

    /// Human-readable display name for the PII type
    var displayName: String {
        switch self {
        case .email: return "Email Address"
        case .phone: return "Phone Number"
        case .ssn: return "Social Security Number"
        case .name: return "Person Name"
        case .company: return "Company Name"
        case .address: return "Street Address"
        case .creditCard: return "Credit Card Number"
        }
    }

    /// SF Symbol icon name for the PII type
    var icon: String {
        switch self {
        case .email: return "envelope.fill"
        case .phone: return "phone.fill"
        case .ssn: return "lock.shield.fill"
        case .name: return "person.fill"
        case .company: return "building.2.fill"
        case .address: return "mappin.and.ellipse"
        case .creditCard: return "creditcard.fill"
        }
    }

    /// Redaction label used when replacing PII in text (e.g., "[EMAIL]", "[PHONE]")
    var redactionLabel: String {
        switch self {
        case .email: return "[EMAIL]"
        case .phone: return "[PHONE]"
        case .ssn: return "[SSN]"
        case .name: return "[NAME]"
        case .company: return "[COMPANY]"
        case .address: return "[ADDRESS]"
        case .creditCard: return "[CREDIT_CARD]"
        }
    }

    /// Severity level indicating the sensitivity of this PII type
    var severity: PIISeverity {
        switch self {
        case .ssn, .creditCard: return .high
        case .email, .phone: return .medium
        case .name, .address: return .medium
        case .company: return .low
        }
    }
}

// MARK: - PII Severity

/// Severity levels for PII detections, indicating sensitivity
enum PIISeverity: Int, Comparable, Codable {
    /// Company names, general locations
    case low = 1
    /// Email addresses, phone numbers
    case medium = 2
    /// SSN, credit card numbers
    case high = 3
    /// Combined PII that could identify someone
    case critical = 4

    static func < (lhs: PIISeverity, rhs: PIISeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Human-readable display name for the severity level
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

// MARK: - PII Detection

/// A single detected PII instance in text
struct PIIDetection: Identifiable, Codable, Equatable {
    let id: UUID
    let type: PIIType
    let matchedText: String
    let range: Range<String.Index>?
    let startOffset: Int
    let endOffset: Int
    let confidence: Double
    let utteranceId: UUID?
    let sessionId: UUID?

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, type, matchedText, startOffset, endOffset, confidence, utteranceId, sessionId
    }

    init(
        id: UUID = UUID(),
        type: PIIType,
        matchedText: String,
        range: Range<String.Index>? = nil,
        startOffset: Int,
        endOffset: Int,
        confidence: Double,
        utteranceId: UUID? = nil,
        sessionId: UUID? = nil
    ) {
        self.id = id
        self.type = type
        self.matchedText = matchedText
        self.range = range
        self.startOffset = startOffset
        self.endOffset = endOffset
        self.confidence = confidence
        self.utteranceId = utteranceId
        self.sessionId = sessionId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(PIIType.self, forKey: .type)
        matchedText = try container.decode(String.self, forKey: .matchedText)
        startOffset = try container.decode(Int.self, forKey: .startOffset)
        endOffset = try container.decode(Int.self, forKey: .endOffset)
        confidence = try container.decode(Double.self, forKey: .confidence)
        utteranceId = try container.decodeIfPresent(UUID.self, forKey: .utteranceId)
        sessionId = try container.decodeIfPresent(UUID.self, forKey: .sessionId)
        range = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(matchedText, forKey: .matchedText)
        try container.encode(startOffset, forKey: .startOffset)
        try container.encode(endOffset, forKey: .endOffset)
        try container.encode(confidence, forKey: .confidence)
        try container.encodeIfPresent(utteranceId, forKey: .utteranceId)
        try container.encodeIfPresent(sessionId, forKey: .sessionId)
    }

    // MARK: - Equatable

    static func == (lhs: PIIDetection, rhs: PIIDetection) -> Bool {
        lhs.id == rhs.id
            && lhs.type == rhs.type
            && lhs.matchedText == rhs.matchedText
            && lhs.startOffset == rhs.startOffset
            && lhs.endOffset == rhs.endOffset
            && lhs.confidence == rhs.confidence
            && lhs.utteranceId == rhs.utteranceId
            && lhs.sessionId == rhs.sessionId
    }
}

// MARK: - PII Detector

/// Detects PII in text using regex patterns and heuristics.
///
/// This is a pure service (not an ObservableObject) that can be used from any context.
/// It scans text for email addresses, phone numbers, SSNs, credit card numbers,
/// person names, company names, and street addresses.
final class PIIDetector {

    // MARK: - Properties

    /// Which PII types to scan for. Defaults to all types.
    var enabledTypes: Set<PIIType>

    // MARK: - Initialization

    /// Creates a PIIDetector that scans for the specified PII types.
    /// - Parameter enabledTypes: The set of PII types to detect. Defaults to all types.
    init(enabledTypes: Set<PIIType> = Set(PIIType.allCases)) {
        self.enabledTypes = enabledTypes
    }

    // MARK: - Public API

    /// Scan a single text string for PII.
    /// - Parameters:
    ///   - text: The text to scan
    ///   - utteranceId: Optional utterance ID to associate with detections
    ///   - sessionId: Optional session ID to associate with detections
    /// - Returns: An array of PII detections found in the text
    func detect(in text: String, utteranceId: UUID? = nil, sessionId: UUID? = nil) -> [PIIDetection] {
        var detections: [PIIDetection] = []

        if enabledTypes.contains(.email) {
            detections.append(contentsOf: detectEmails(in: text, utteranceId: utteranceId, sessionId: sessionId))
        }
        if enabledTypes.contains(.phone) {
            detections.append(contentsOf: detectPhones(in: text, utteranceId: utteranceId, sessionId: sessionId))
        }
        if enabledTypes.contains(.ssn) {
            detections.append(contentsOf: detectSSNs(in: text, utteranceId: utteranceId, sessionId: sessionId))
        }
        if enabledTypes.contains(.creditCard) {
            detections.append(contentsOf: detectCreditCards(in: text, utteranceId: utteranceId, sessionId: sessionId))
        }
        if enabledTypes.contains(.name) {
            detections.append(contentsOf: detectNames(in: text, utteranceId: utteranceId, sessionId: sessionId))
        }
        if enabledTypes.contains(.company) {
            detections.append(contentsOf: detectCompanies(in: text, utteranceId: utteranceId, sessionId: sessionId))
        }
        if enabledTypes.contains(.address) {
            detections.append(contentsOf: detectAddresses(in: text, utteranceId: utteranceId, sessionId: sessionId))
        }

        // Sort by position in text
        return detections.sorted { $0.startOffset < $1.startOffset }
    }

    /// Scan all utterances in a session for PII.
    /// - Parameters:
    ///   - utterances: The utterances to scan
    ///   - sessionId: The session ID to associate with detections
    /// - Returns: An array of all PII detections found across all utterances
    func scanSession(utterances: [Utterance], sessionId: UUID) -> [PIIDetection] {
        var allDetections: [PIIDetection] = []
        for utterance in utterances {
            let detections = detect(in: utterance.text, utteranceId: utterance.id, sessionId: sessionId)
            allDetections.append(contentsOf: detections)
        }
        return allDetections
    }

    /// Quick check whether text contains any PII.
    /// - Parameter text: The text to check
    /// - Returns: `true` if any PII is detected
    func containsPII(_ text: String) -> Bool {
        !detect(in: text).isEmpty
    }

    // MARK: - Private Detection Methods

    /// Detects email addresses using a standard email pattern.
    private func detectEmails(in text: String, utteranceId: UUID?, sessionId: UUID?) -> [PIIDetection] {
        let pattern = #"[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}"#
        return matchPattern(pattern, in: text, type: .email, confidence: 0.95, utteranceId: utteranceId, sessionId: sessionId)
    }

    /// Detects US phone numbers in various formats.
    private func detectPhones(in text: String, utteranceId: UUID?, sessionId: UUID?) -> [PIIDetection] {
        let pattern = #"\b(\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b"#
        return matchPattern(pattern, in: text, type: .phone, confidence: 0.9, utteranceId: utteranceId, sessionId: sessionId)
    }

    /// Detects Social Security Numbers in the standard format (XXX-XX-XXXX).
    private func detectSSNs(in text: String, utteranceId: UUID?, sessionId: UUID?) -> [PIIDetection] {
        let pattern = #"\b\d{3}-\d{2}-\d{4}\b"#
        return matchPattern(pattern, in: text, type: .ssn, confidence: 0.95, utteranceId: utteranceId, sessionId: sessionId)
    }

    /// Detects credit card numbers (4 groups of 4 digits, with optional separators).
    private func detectCreditCards(in text: String, utteranceId: UUID?, sessionId: UUID?) -> [PIIDetection] {
        let pattern = #"\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b"#
        return matchPattern(pattern, in: text, type: .creditCard, confidence: 0.9, utteranceId: utteranceId, sessionId: sessionId)
    }

    /// Detects person names using heuristics:
    /// - Phrases like "I'm John", "my name is Sarah Smith", "name's Mike", "called David"
    /// - Two or more consecutive capitalized words not at the start of a sentence
    private func detectNames(in text: String, utteranceId: UUID?, sessionId: UUID?) -> [PIIDetection] {
        var detections: [PIIDetection] = []

        // Pattern 1: "I'm <Name>", "my name is <Name>", "name's <Name>", "called <Name>"
        let introPatterns = [
            #"(?:I'm|I am|my name is|name's|they call me|called)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)"#,
            #"(?:this is|meet|introducing)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)"#
        ]

        for pattern in introPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
            let nsRange = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: nsRange)

            for match in matches {
                // Capture group 1 is the name portion
                guard match.numberOfRanges > 1,
                      let nameRange = Range(match.range(at: 1), in: text) else {
                    continue
                }
                let matchedName = String(text[nameRange])
                let startOffset = text.distance(from: text.startIndex, to: nameRange.lowerBound)
                let endOffset = text.distance(from: text.startIndex, to: nameRange.upperBound)

                // Higher confidence for multi-word names
                let confidence = matchedName.contains(" ") ? 0.8 : 0.7

                detections.append(PIIDetection(
                    type: .name,
                    matchedText: matchedName,
                    range: nameRange,
                    startOffset: startOffset,
                    endOffset: endOffset,
                    confidence: confidence,
                    utteranceId: utteranceId,
                    sessionId: sessionId
                ))
            }
        }

        // Pattern 2: Two or more consecutive capitalized words not at sentence start
        // We look for capitalized word sequences that appear mid-sentence
        let multiCapPattern = #"(?<=[a-z,;:]\s)([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)"#
        if let regex = try? NSRegularExpression(pattern: multiCapPattern, options: []) {
            let nsRange = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: nsRange)

            for match in matches {
                guard let matchRange = Range(match.range(at: 1), in: text) else { continue }
                let matchedText = String(text[matchRange])

                // Filter out common multi-cap phrases that are not names
                let commonPhrases = ["United States", "New York", "San Francisco", "Los Angeles",
                                     "United Kingdom", "New Zealand", "South Africa"]
                if commonPhrases.contains(matchedText) { continue }

                let startOffset = text.distance(from: text.startIndex, to: matchRange.lowerBound)
                let endOffset = text.distance(from: text.startIndex, to: matchRange.upperBound)

                // Check we haven't already captured this as part of an intro pattern
                let alreadyCaptured = detections.contains { existing in
                    existing.startOffset == startOffset && existing.endOffset == endOffset
                }
                if alreadyCaptured { continue }

                detections.append(PIIDetection(
                    type: .name,
                    matchedText: matchedText,
                    range: matchRange,
                    startOffset: startOffset,
                    endOffset: endOffset,
                    confidence: 0.6,
                    utteranceId: utteranceId,
                    sessionId: sessionId
                ))
            }
        }

        return detections
    }

    /// Detects company names using heuristics:
    /// - Words followed by corporate suffixes (Inc, Corp, LLC, Ltd, Company)
    /// - Words preceded by "at", "work for", "work at"
    private func detectCompanies(in text: String, utteranceId: UUID?, sessionId: UUID?) -> [PIIDetection] {
        var detections: [PIIDetection] = []

        // Pattern 1: Company with suffix (e.g., "Acme Corp", "Microsoft Inc", "Smith & Sons LLC")
        let suffixPattern = #"([A-Z][A-Za-z&.']+(?:\s+[A-Z][A-Za-z&.']+)*)\s+(?:Inc\.?|Corp\.?|LLC|Ltd\.?|Company|Co\.?|Corporation|Incorporated|Limited|Group|Holdings|Partners|Associates)"#
        if let regex = try? NSRegularExpression(pattern: suffixPattern, options: []) {
            let nsRange = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: nsRange)

            for match in matches {
                guard let fullRange = Range(match.range, in: text) else { continue }
                let matchedText = String(text[fullRange])
                let startOffset = text.distance(from: text.startIndex, to: fullRange.lowerBound)
                let endOffset = text.distance(from: text.startIndex, to: fullRange.upperBound)

                detections.append(PIIDetection(
                    type: .company,
                    matchedText: matchedText,
                    range: fullRange,
                    startOffset: startOffset,
                    endOffset: endOffset,
                    confidence: 0.7,
                    utteranceId: utteranceId,
                    sessionId: sessionId
                ))
            }
        }

        // Pattern 2: "at <Company>", "work for <Company>", "work at <Company>"
        let contextPattern = #"(?:work (?:at|for)|employed (?:at|by)|join(?:ed)?|at)\s+([A-Z][A-Za-z&.']+(?:\s+[A-Z][A-Za-z&.']+)*)"#
        if let regex = try? NSRegularExpression(pattern: contextPattern, options: []) {
            let nsRange = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: nsRange)

            for match in matches {
                guard match.numberOfRanges > 1,
                      let companyRange = Range(match.range(at: 1), in: text) else {
                    continue
                }
                let matchedText = String(text[companyRange])
                let startOffset = text.distance(from: text.startIndex, to: companyRange.lowerBound)
                let endOffset = text.distance(from: text.startIndex, to: companyRange.upperBound)

                // Check we haven't already captured this
                let alreadyCaptured = detections.contains { existing in
                    existing.startOffset == startOffset && existing.endOffset == endOffset
                }
                if alreadyCaptured { continue }

                detections.append(PIIDetection(
                    type: .company,
                    matchedText: matchedText,
                    range: companyRange,
                    startOffset: startOffset,
                    endOffset: endOffset,
                    confidence: 0.5,
                    utteranceId: utteranceId,
                    sessionId: sessionId
                ))
            }
        }

        return detections
    }

    /// Detects street addresses using a pattern for typical US addresses
    /// (e.g., "123 Main Street", "456 Oak Ave", "789 Elm Blvd Apt 2B").
    private func detectAddresses(in text: String, utteranceId: UUID?, sessionId: UUID?) -> [PIIDetection] {
        let pattern = #"\b\d{1,5}\s+[A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)*\s+(?:Street|St\.?|Avenue|Ave\.?|Boulevard|Blvd\.?|Drive|Dr\.?|Road|Rd\.?|Lane|Ln\.?|Court|Ct\.?|Place|Pl\.?|Way|Circle|Cir\.?|Trail|Trl\.?)(?:\s+(?:Apt\.?|Suite|Ste\.?|Unit|#)\s*\w+)?\b"#
        return matchPattern(pattern, in: text, type: .address, confidence: 0.85, utteranceId: utteranceId, sessionId: sessionId)
    }

    // MARK: - Private Helpers

    /// Generic helper that runs a regex pattern against text and returns PIIDetection instances.
    private func matchPattern(
        _ pattern: String,
        in text: String,
        type: PIIType,
        confidence: Double,
        utteranceId: UUID?,
        sessionId: UUID?
    ) -> [PIIDetection] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            AppLogger.shared.warning("Failed to compile regex for PII type: \(type.rawValue)")
            return []
        }

        let nsRange = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: nsRange)

        return matches.compactMap { match in
            guard let matchRange = Range(match.range, in: text) else { return nil }
            let matchedText = String(text[matchRange])
            let startOffset = text.distance(from: text.startIndex, to: matchRange.lowerBound)
            let endOffset = text.distance(from: text.startIndex, to: matchRange.upperBound)

            return PIIDetection(
                type: type,
                matchedText: matchedText,
                range: matchRange,
                startOffset: startOffset,
                endOffset: endOffset,
                confidence: confidence,
                utteranceId: utteranceId,
                sessionId: sessionId
            )
        }
    }
}
