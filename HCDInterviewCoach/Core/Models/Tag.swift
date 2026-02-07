//
//  Tag.swift
//  HCDInterviewCoach
//
//  FEATURE 5: Post-Session Tagging & Coding
//  User-defined tags for coding transcript segments.
//  Uses lightweight struct approach (not SwiftData @Model) to avoid schema migration complexity.
//

import Foundation

// MARK: - Tag

/// A user-defined tag used to code and categorize transcript segments.
///
/// Tags support an optional parent-child hierarchy via `parentId` and are
/// identified by a hex color string for visual distinction in the UI.
///
/// Persisted as JSON by `TaggingService` rather than as a SwiftData model.
struct Tag: Identifiable, Codable, Hashable {

    /// Unique identifier for the tag
    var id: UUID

    /// Human-readable name (e.g., "Pain Point", "User Need")
    var name: String

    /// Hex color string including the hash (e.g., "#E74C3C")
    var colorHex: String

    /// Optional parent tag ID for hierarchical tag structures
    var parentId: UUID?

    /// When the tag was created
    var createdAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        parentId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.parentId = parentId
        self.createdAt = createdAt
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - UtteranceTagAssignment

/// Represents the assignment of a tag to a specific utterance within a session.
///
/// Each assignment links a `Tag` to an `Utterance` (by ID) and optionally
/// includes a researcher note explaining the coding decision.
struct UtteranceTagAssignment: Identifiable, Codable {

    /// Unique identifier for this assignment
    var id: UUID

    /// The ID of the utterance being tagged
    var utteranceId: UUID

    /// The ID of the tag applied
    var tagId: UUID

    /// The ID of the session containing the utterance
    var sessionId: UUID

    /// Optional researcher note for this specific tag assignment
    var note: String?

    /// When this assignment was created
    var createdAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        utteranceId: UUID,
        tagId: UUID,
        sessionId: UUID,
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.utteranceId = utteranceId
        self.tagId = tagId
        self.sessionId = sessionId
        self.note = note
        self.createdAt = createdAt
    }
}

// MARK: - Equatable

extension UtteranceTagAssignment: Equatable {
    static func == (lhs: UtteranceTagAssignment, rhs: UtteranceTagAssignment) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension UtteranceTagAssignment: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
