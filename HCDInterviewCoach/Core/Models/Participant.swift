//
//  Participant.swift
//  HCDInterviewCoach
//
//  FEATURE F: Participant Management System
//  A research participant in the participant database.
//  Uses lightweight Codable struct with JSON file persistence
//  to avoid SwiftData schema migration complexity.
//

import Foundation

// MARK: - Experience Level

/// Experience level of a research participant
enum ExperienceLevel: String, CaseIterable, Codable {
    case novice = "novice"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"

    /// Human-readable display name for the experience level
    var displayName: String {
        switch self {
        case .novice:
            return "Novice"
        case .intermediate:
            return "Intermediate"
        case .advanced:
            return "Advanced"
        case .expert:
            return "Expert"
        }
    }
}

// MARK: - Participant

/// A research participant in the participant database.
///
/// Participants can be linked to one or more interview sessions via `sessionIds`.
/// Custom screener data is stored in the `metadata` dictionary as key-value pairs.
///
/// Persisted as JSON by `ParticipantManager` rather than as a SwiftData model.
struct Participant: Identifiable, Codable, Equatable, Hashable {

    /// Unique identifier for the participant
    let id: UUID

    /// Full name of the participant
    var name: String

    /// Contact email address
    var email: String?

    /// Job title or role (e.g., "Product Manager", "End User")
    var role: String?

    /// Department within their organization
    var department: String?

    /// Organization or company name
    var organization: String?

    /// Self-reported or assessed experience level
    var experienceLevel: ExperienceLevel?

    /// Free-form notes about the participant
    var notes: String

    /// Custom screener fields stored as key-value pairs
    var metadata: [String: String]

    /// IDs of sessions this participant has been linked to
    var sessionIds: [UUID]

    /// When the participant record was created
    let createdAt: Date

    /// When the participant record was last modified
    var updatedAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        email: String? = nil,
        role: String? = nil,
        department: String? = nil,
        organization: String? = nil,
        experienceLevel: ExperienceLevel? = nil,
        notes: String = "",
        metadata: [String: String] = [:],
        sessionIds: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.department = department
        self.organization = organization
        self.experienceLevel = experienceLevel
        self.notes = notes
        self.metadata = metadata
        self.sessionIds = sessionIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Number of sessions this participant has been part of
    var sessionCount: Int {
        sessionIds.count
    }

    /// Whether the participant has been linked to any sessions
    var hasSessionHistory: Bool {
        !sessionIds.isEmpty
    }

    // MARK: - Equatable

    static func == (lhs: Participant, rhs: Participant) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
