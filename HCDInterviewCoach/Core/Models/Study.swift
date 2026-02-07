//
//  Study.swift
//  HCDInterviewCoach
//
//  FEATURE 3: Cross-Session Analytics & Study Organization
//  Groups multiple sessions into a research study.
//  Uses lightweight struct approach stored as JSON to avoid schema migration complexity.
//

import Foundation

/// Represents a research study that groups multiple interview sessions together
/// for cross-session analysis and organization.
///
/// This is intentionally NOT a SwiftData `@Model` to avoid schema migration complexity.
/// Studies are persisted as JSON to a separate file managed by `StudyManager`.
struct Study: Identifiable, Codable {

    // MARK: - Properties

    /// Unique identifier for the study
    var id: UUID

    /// Human-readable name for the study (e.g., "Q1 Onboarding Research")
    var name: String

    /// Optional longer description of the study's purpose and goals
    var description: String

    /// When the study was first created
    var createdAt: Date

    /// When the study was last modified
    var updatedAt: Date

    /// References to Session IDs that belong to this study
    var sessionIds: [UUID]

    /// Freeform tags for categorizing the study (e.g., "onboarding", "mobile")
    var tags: [String]

    /// Research questions guiding this study
    var researchQuestions: [String]

    // MARK: - Computed Properties

    /// Number of sessions currently in this study
    var sessionCount: Int {
        sessionIds.count
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sessionIds: [UUID] = [],
        tags: [String] = [],
        researchQuestions: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sessionIds = sessionIds
        self.tags = tags
        self.researchQuestions = researchQuestions
    }
}

// MARK: - Equatable

extension Study: Equatable {
    static func == (lhs: Study, rhs: Study) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension Study: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
