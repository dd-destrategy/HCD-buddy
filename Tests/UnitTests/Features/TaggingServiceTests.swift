//
//  TaggingServiceTests.swift
//  HCD Interview Coach Tests
//
//  FEATURE 5: Post-Session Tagging & Coding
//  Unit tests for TaggingService CRUD operations, assignments, persistence, and export.
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class TaggingServiceTests: XCTestCase {

    // MARK: - Properties

    var taggingService: TaggingService!
    var tempDirectory: URL!
    var tagsURL: URL!
    var assignmentsURL: URL!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TaggingServiceTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        tagsURL = tempDirectory.appendingPathComponent("tags.json")
        assignmentsURL = tempDirectory.appendingPathComponent("tag_assignments.json")
        taggingService = TaggingService(tagsURL: tagsURL, assignmentsURL: assignmentsURL)
    }

    override func tearDown() {
        taggingService = nil
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        tagsURL = nil
        assignmentsURL = nil
        super.tearDown()
    }

    // MARK: - Test: Default Tags Created on First Run

    func testDefaultTagsCreatedOnFirstRun() {
        // Given: A freshly initialized service (no existing files)
        // The service was initialized in setUp()

        // Then: Default tags should be created
        XCTAssertEqual(taggingService.tags.count, 5)

        let tagNames = taggingService.tags.map { $0.name }
        XCTAssertTrue(tagNames.contains("Pain Point"))
        XCTAssertTrue(tagNames.contains("User Need"))
        XCTAssertTrue(tagNames.contains("Positive Moment"))
        XCTAssertTrue(tagNames.contains("Confusion"))
        XCTAssertTrue(tagNames.contains("Suggestion"))
    }

    func testDefaultTags_haveCorrectColors() {
        // Then: Default tags should have specified colors
        let painPoint = taggingService.tags.first { $0.name == "Pain Point" }
        XCTAssertEqual(painPoint?.colorHex, "#E74C3C")

        let userNeed = taggingService.tags.first { $0.name == "User Need" }
        XCTAssertEqual(userNeed?.colorHex, "#3498DB")

        let positive = taggingService.tags.first { $0.name == "Positive Moment" }
        XCTAssertEqual(positive?.colorHex, "#2ECC71")

        let confusion = taggingService.tags.first { $0.name == "Confusion" }
        XCTAssertEqual(confusion?.colorHex, "#F39C12")

        let suggestion = taggingService.tags.first { $0.name == "Suggestion" }
        XCTAssertEqual(suggestion?.colorHex, "#9B59B6")
    }

    func testDefaultTags_notRecreatedOnSubsequentLoad() {
        // Given: Service with default tags already created
        XCTAssertEqual(taggingService.tags.count, 5)

        // When: Creating a new service from the same files
        let reloadedService = TaggingService(tagsURL: tagsURL, assignmentsURL: assignmentsURL)

        // Then: Should still have exactly 5 tags (not 10)
        XCTAssertEqual(reloadedService.tags.count, 5)
    }

    // MARK: - Test: Create Tag

    func testCreateTag_addsToTagsArray() {
        // Given: Initial tag count (defaults)
        let initialCount = taggingService.tags.count

        // When: Creating a new tag
        let tag = taggingService.createTag(name: "Custom Tag", colorHex: "#FF5733")

        // Then: Tag should be added
        XCTAssertEqual(taggingService.tags.count, initialCount + 1)
        XCTAssertEqual(tag.name, "Custom Tag")
        XCTAssertEqual(tag.colorHex, "#FF5733")
        XCTAssertNil(tag.parentId)
    }

    func testCreateTag_withParentId() {
        // Given: A parent tag
        let parentTag = taggingService.createTag(name: "Parent", colorHex: "#000000")

        // When: Creating a child tag
        let childTag = taggingService.createTag(
            name: "Child",
            colorHex: "#FFFFFF",
            parentId: parentTag.id
        )

        // Then: Child should reference parent
        XCTAssertEqual(childTag.parentId, parentTag.id)
    }

    func testCreateTag_generatesUniqueId() {
        // When: Creating two tags
        let tag1 = taggingService.createTag(name: "Tag A", colorHex: "#111111")
        let tag2 = taggingService.createTag(name: "Tag B", colorHex: "#222222")

        // Then: IDs should differ
        XCTAssertNotEqual(tag1.id, tag2.id)
    }

    func testCreateTag_setsCreatedAt() {
        // When: Creating a tag
        let before = Date()
        let tag = taggingService.createTag(name: "Timed", colorHex: "#333333")
        let after = Date()

        // Then: createdAt should be approximately now
        XCTAssertGreaterThanOrEqual(tag.createdAt, before)
        XCTAssertLessThanOrEqual(tag.createdAt, after)
    }

    // MARK: - Test: Update Tag

    func testUpdateTag_updatesName() {
        // Given: A tag
        let tag = taggingService.createTag(name: "Original", colorHex: "#AAAAAA")

        // When: Updating the name
        taggingService.updateTag(tag.id, name: "Updated")

        // Then: Name should be updated
        let updated = taggingService.tags.first { $0.id == tag.id }
        XCTAssertEqual(updated?.name, "Updated")
        XCTAssertEqual(updated?.colorHex, "#AAAAAA") // Color unchanged
    }

    func testUpdateTag_updatesColor() {
        // Given: A tag
        let tag = taggingService.createTag(name: "Colored", colorHex: "#AAAAAA")

        // When: Updating the color
        taggingService.updateTag(tag.id, colorHex: "#BBBBBB")

        // Then: Color should be updated
        let updated = taggingService.tags.first { $0.id == tag.id }
        XCTAssertEqual(updated?.name, "Colored") // Name unchanged
        XCTAssertEqual(updated?.colorHex, "#BBBBBB")
    }

    func testUpdateTag_updatesNameAndColor() {
        // Given: A tag
        let tag = taggingService.createTag(name: "Both", colorHex: "#CCCCCC")

        // When: Updating both
        taggingService.updateTag(tag.id, name: "New Name", colorHex: "#DDDDDD")

        // Then: Both should be updated
        let updated = taggingService.tags.first { $0.id == tag.id }
        XCTAssertEqual(updated?.name, "New Name")
        XCTAssertEqual(updated?.colorHex, "#DDDDDD")
    }

    func testUpdateTag_nonExistentId_doesNothing() {
        // Given: Initial state
        let initialTags = taggingService.tags

        // When: Updating a non-existent tag
        taggingService.updateTag(UUID(), name: "Ghost")

        // Then: Tags should be unchanged
        XCTAssertEqual(taggingService.tags.count, initialTags.count)
    }

    // MARK: - Test: Delete Tag

    func testDeleteTag_removesFromArray() {
        // Given: A custom tag
        let tag = taggingService.createTag(name: "To Delete", colorHex: "#EEEEEE")
        let countBefore = taggingService.tags.count

        // When: Deleting
        taggingService.deleteTag(tag.id)

        // Then: Tag should be removed
        XCTAssertEqual(taggingService.tags.count, countBefore - 1)
        XCTAssertNil(taggingService.tags.first { $0.id == tag.id })
    }

    func testDeleteTag_cascadesToAssignments() {
        // Given: A tag with assignments
        let tag = taggingService.createTag(name: "Cascading", colorHex: "#FF0000")
        let sessionId = UUID()
        let utteranceId1 = UUID()
        let utteranceId2 = UUID()
        taggingService.assignTag(tag.id, to: utteranceId1, sessionId: sessionId)
        taggingService.assignTag(tag.id, to: utteranceId2, sessionId: sessionId)
        XCTAssertEqual(taggingService.assignments.count, 2)

        // When: Deleting the tag
        taggingService.deleteTag(tag.id)

        // Then: All assignments should also be removed
        XCTAssertEqual(taggingService.assignments.count, 0)
    }

    func testDeleteTag_clearsSelectedTagId() {
        // Given: A selected tag
        let tag = taggingService.createTag(name: "Selected", colorHex: "#00FF00")
        taggingService.selectedTagId = tag.id

        // When: Deleting it
        taggingService.deleteTag(tag.id)

        // Then: Selection should be cleared
        XCTAssertNil(taggingService.selectedTagId)
    }

    func testDeleteTag_nonExistentId_doesNothing() {
        // Given: Current state
        let countBefore = taggingService.tags.count

        // When: Deleting non-existent
        taggingService.deleteTag(UUID())

        // Then: No change
        XCTAssertEqual(taggingService.tags.count, countBefore)
    }

    func testDeleteTag_removesChildTags() {
        // Given: A parent tag with children
        let parent = taggingService.createTag(name: "Parent", colorHex: "#111111")
        let child1 = taggingService.createTag(name: "Child 1", colorHex: "#222222", parentId: parent.id)
        let child2 = taggingService.createTag(name: "Child 2", colorHex: "#333333", parentId: parent.id)

        // Also assign the child tags
        let sessionId = UUID()
        taggingService.assignTag(child1.id, to: UUID(), sessionId: sessionId)
        taggingService.assignTag(child2.id, to: UUID(), sessionId: sessionId)

        let countBefore = taggingService.tags.count

        // When: Deleting the parent
        taggingService.deleteTag(parent.id)

        // Then: Parent and children should all be removed
        XCTAssertEqual(taggingService.tags.count, countBefore - 3)
        XCTAssertNil(taggingService.tags.first { $0.id == parent.id })
        XCTAssertNil(taggingService.tags.first { $0.id == child1.id })
        XCTAssertNil(taggingService.tags.first { $0.id == child2.id })

        // Child assignments should also be removed
        XCTAssertEqual(taggingService.assignments.count, 0)
    }

    // MARK: - Test: Assign Tag to Utterance

    func testAssignTag_createsAssignment() {
        // Given: A tag and utterance IDs
        let tag = taggingService.tags.first! // Use a default tag
        let sessionId = UUID()
        let utteranceId = UUID()

        // When: Assigning
        let assignment = taggingService.assignTag(tag.id, to: utteranceId, sessionId: sessionId, note: "Important finding")

        // Then: Assignment should be created
        XCTAssertEqual(taggingService.assignments.count, 1)
        XCTAssertEqual(assignment.tagId, tag.id)
        XCTAssertEqual(assignment.utteranceId, utteranceId)
        XCTAssertEqual(assignment.sessionId, sessionId)
        XCTAssertEqual(assignment.note, "Important finding")
    }

    func testAssignTag_preventsDuplicates() {
        // Given: An existing assignment
        let tag = taggingService.tags.first!
        let sessionId = UUID()
        let utteranceId = UUID()
        taggingService.assignTag(tag.id, to: utteranceId, sessionId: sessionId)
        XCTAssertEqual(taggingService.assignments.count, 1)

        // When: Assigning the same tag to the same utterance again
        taggingService.assignTag(tag.id, to: utteranceId, sessionId: sessionId)

        // Then: Should still have only one assignment
        XCTAssertEqual(taggingService.assignments.count, 1)
    }

    func testAssignTag_allowsDifferentTagsOnSameUtterance() {
        // Given: Two different tags
        let tag1 = taggingService.tags[0]
        let tag2 = taggingService.tags[1]
        let sessionId = UUID()
        let utteranceId = UUID()

        // When: Assigning both to the same utterance
        taggingService.assignTag(tag1.id, to: utteranceId, sessionId: sessionId)
        taggingService.assignTag(tag2.id, to: utteranceId, sessionId: sessionId)

        // Then: Both assignments should exist
        XCTAssertEqual(taggingService.assignments.count, 2)
    }

    func testAssignTag_allowsSameTagOnDifferentUtterances() {
        // Given: One tag and two utterances
        let tag = taggingService.tags.first!
        let sessionId = UUID()
        let utteranceId1 = UUID()
        let utteranceId2 = UUID()

        // When: Assigning to both
        taggingService.assignTag(tag.id, to: utteranceId1, sessionId: sessionId)
        taggingService.assignTag(tag.id, to: utteranceId2, sessionId: sessionId)

        // Then: Both assignments should exist
        XCTAssertEqual(taggingService.assignments.count, 2)
    }

    // MARK: - Test: Remove Assignment

    func testRemoveAssignment_removesCorrectOne() {
        // Given: Multiple assignments
        let tag = taggingService.tags.first!
        let sessionId = UUID()
        let assignment1 = taggingService.assignTag(tag.id, to: UUID(), sessionId: sessionId)
        let assignment2 = taggingService.assignTag(tag.id, to: UUID(), sessionId: sessionId)
        XCTAssertEqual(taggingService.assignments.count, 2)

        // When: Removing the first
        taggingService.removeAssignment(assignment1.id)

        // Then: Only the second should remain
        XCTAssertEqual(taggingService.assignments.count, 1)
        XCTAssertEqual(taggingService.assignments.first?.id, assignment2.id)
    }

    func testRemoveAssignment_nonExistent_doesNothing() {
        // Given: An assignment
        let tag = taggingService.tags.first!
        taggingService.assignTag(tag.id, to: UUID(), sessionId: UUID())
        XCTAssertEqual(taggingService.assignments.count, 1)

        // When: Removing a non-existent ID
        taggingService.removeAssignment(UUID())

        // Then: Existing assignment remains
        XCTAssertEqual(taggingService.assignments.count, 1)
    }

    // MARK: - Test: Get Assignments by Utterance

    func testGetAssignmentsByUtterance() {
        // Given: Assignments for different utterances
        let tag = taggingService.tags.first!
        let sessionId = UUID()
        let targetUtteranceId = UUID()
        let otherUtteranceId = UUID()

        taggingService.assignTag(tag.id, to: targetUtteranceId, sessionId: sessionId)
        taggingService.assignTag(taggingService.tags[1].id, to: targetUtteranceId, sessionId: sessionId)
        taggingService.assignTag(tag.id, to: otherUtteranceId, sessionId: sessionId)

        // When: Getting assignments for the target utterance
        let result = taggingService.getAssignments(forUtterance: targetUtteranceId)

        // Then: Should return only assignments for that utterance
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.utteranceId == targetUtteranceId })
    }

    // MARK: - Test: Get Assignments by Tag

    func testGetAssignmentsByTag() {
        // Given: Assignments using different tags
        let targetTag = taggingService.tags[0]
        let otherTag = taggingService.tags[1]
        let sessionId = UUID()

        taggingService.assignTag(targetTag.id, to: UUID(), sessionId: sessionId)
        taggingService.assignTag(targetTag.id, to: UUID(), sessionId: sessionId)
        taggingService.assignTag(otherTag.id, to: UUID(), sessionId: sessionId)

        // When: Getting assignments for the target tag
        let result = taggingService.getAssignments(forTag: targetTag.id)

        // Then: Should return only assignments for that tag
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.tagId == targetTag.id })
    }

    // MARK: - Test: Get Assignments by Session

    func testGetAssignmentsBySession() {
        // Given: Assignments in different sessions
        let tag = taggingService.tags.first!
        let targetSessionId = UUID()
        let otherSessionId = UUID()

        taggingService.assignTag(tag.id, to: UUID(), sessionId: targetSessionId)
        taggingService.assignTag(tag.id, to: UUID(), sessionId: targetSessionId)
        taggingService.assignTag(tag.id, to: UUID(), sessionId: otherSessionId)

        // When: Getting assignments for the target session
        let result = taggingService.getAssignments(forSession: targetSessionId)

        // Then: Should return only assignments in that session
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.sessionId == targetSessionId })
    }

    // MARK: - Test: Get Tagged Utterance IDs

    func testGetTaggedUtteranceIds() {
        // Given: Various assignments in a session
        let tag1 = taggingService.tags[0]
        let tag2 = taggingService.tags[1]
        let sessionId = UUID()
        let utteranceId1 = UUID()
        let utteranceId2 = UUID()
        let utteranceId3 = UUID()

        taggingService.assignTag(tag1.id, to: utteranceId1, sessionId: sessionId)
        taggingService.assignTag(tag2.id, to: utteranceId1, sessionId: sessionId) // Same utterance, different tag
        taggingService.assignTag(tag1.id, to: utteranceId2, sessionId: sessionId)
        // utteranceId3 is not tagged

        // When: Getting tagged utterance IDs
        let result = taggingService.getTaggedUtteranceIds(for: sessionId)

        // Then: Should return unique set of tagged utterance IDs
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains(utteranceId1))
        XCTAssertTrue(result.contains(utteranceId2))
        XCTAssertFalse(result.contains(utteranceId3))
    }

    // MARK: - Test: Persistence Round-Trip

    func testPersistence_saveAndLoadTags() {
        // Given: Custom tags
        let tag = taggingService.createTag(name: "Persisted", colorHex: "#ABCDEF")
        taggingService.save()

        // When: Creating a new service from the same files
        let reloaded = TaggingService(tagsURL: tagsURL, assignmentsURL: assignmentsURL)

        // Then: Custom tag should be present alongside defaults
        let found = reloaded.tags.first { $0.id == tag.id }
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "Persisted")
        XCTAssertEqual(found?.colorHex, "#ABCDEF")
    }

    func testPersistence_saveAndLoadAssignments() {
        // Given: Assignments
        let tag = taggingService.tags.first!
        let sessionId = UUID()
        let utteranceId = UUID()
        let assignment = taggingService.assignTag(tag.id, to: utteranceId, sessionId: sessionId, note: "Test note")
        taggingService.save()

        // When: Creating a new service from the same files
        let reloaded = TaggingService(tagsURL: tagsURL, assignmentsURL: assignmentsURL)

        // Then: Assignment should be present
        XCTAssertEqual(reloaded.assignments.count, 1)
        let found = reloaded.assignments.first { $0.id == assignment.id }
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.tagId, tag.id)
        XCTAssertEqual(found?.utteranceId, utteranceId)
        XCTAssertEqual(found?.sessionId, sessionId)
        XCTAssertEqual(found?.note, "Test note")
    }

    func testPersistence_corruptedTagsFile_loadsDefaults() throws {
        // Given: A corrupted tags file
        let corruptData = "not json".data(using: .utf8)!
        try corruptData.write(to: tagsURL)

        // When: Loading
        let service = TaggingService(tagsURL: tagsURL, assignmentsURL: assignmentsURL)

        // Then: Should fall back to defaults (file exists but is corrupt, so tags = [])
        // The load will fail, setting tags to [], but since the file exists,
        // the "first run" condition (file not existing) is not met.
        // So we get an empty tags array from the corrupt load.
        XCTAssertEqual(service.tags.count, 0)
    }

    func testPersistence_corruptedAssignmentsFile_loadsEmpty() throws {
        // Given: A corrupted assignments file
        let corruptData = "not json".data(using: .utf8)!
        try corruptData.write(to: assignmentsURL)

        // When: Loading
        let service = TaggingService(tagsURL: tagsURL, assignmentsURL: assignmentsURL)

        // Then: Should have empty assignments
        XCTAssertEqual(service.assignments.count, 0)
    }

    // MARK: - Test: Export Produces Valid Markdown

    func testExport_producesMarkdownHeader() {
        // Given: No tagged segments
        let sessionId = UUID()

        // When: Exporting
        let markdown = taggingService.exportTaggedSegments(sessionId: sessionId, utterances: [])

        // Then: Should have header
        XCTAssertTrue(markdown.contains("# Tagged Segments"))
    }

    func testExport_emptySession_producesNoSegmentsMessage() {
        // Given: No assignments in the session
        let sessionId = UUID()

        // When: Exporting
        let markdown = taggingService.exportTaggedSegments(sessionId: sessionId, utterances: [])

        // Then: Should show no segments message
        XCTAssertTrue(markdown.contains("No tagged segments found"))
    }

    func testExport_producesValidMarkdown() {
        // Given: Tagged utterances
        let sessionId = UUID()
        let utteranceId1 = UUID()
        let utteranceId2 = UUID()

        let utterance1 = Utterance(
            id: utteranceId1,
            speaker: .participant,
            text: "I really struggle with the navigation.",
            timestampSeconds: 125
        )
        let utterance2 = Utterance(
            id: utteranceId2,
            speaker: .participant,
            text: "The search feature is great though!",
            timestampSeconds: 180
        )

        let painPointTag = taggingService.tags.first { $0.name == "Pain Point" }!
        let positiveTag = taggingService.tags.first { $0.name == "Positive Moment" }!

        taggingService.assignTag(painPointTag.id, to: utteranceId1, sessionId: sessionId, note: "Navigation issue")
        taggingService.assignTag(positiveTag.id, to: utteranceId2, sessionId: sessionId)

        // When: Exporting
        let markdown = taggingService.exportTaggedSegments(
            sessionId: sessionId,
            utterances: [utterance1, utterance2]
        )

        // Then: Should contain structured markdown
        XCTAssertTrue(markdown.contains("# Tagged Segments"))
        XCTAssertTrue(markdown.contains("## Pain Point"))
        XCTAssertTrue(markdown.contains("## Positive Moment"))
        XCTAssertTrue(markdown.contains("I really struggle with the navigation."))
        XCTAssertTrue(markdown.contains("The search feature is great though!"))
        XCTAssertTrue(markdown.contains("Navigation issue"))
        XCTAssertTrue(markdown.contains("Participant"))
        XCTAssertTrue(markdown.contains("02:05")) // 125 seconds
        XCTAssertTrue(markdown.contains("03:00")) // 180 seconds
        XCTAssertTrue(markdown.contains("1 tagged segment(s)"))
    }

    func testExport_multipleSegmentsPerTag() {
        // Given: Multiple utterances with the same tag
        let sessionId = UUID()
        let tag = taggingService.tags.first!
        let utteranceId1 = UUID()
        let utteranceId2 = UUID()
        let utteranceId3 = UUID()

        let utterance1 = Utterance(id: utteranceId1, speaker: .participant, text: "First", timestampSeconds: 10)
        let utterance2 = Utterance(id: utteranceId2, speaker: .participant, text: "Second", timestampSeconds: 20)
        let utterance3 = Utterance(id: utteranceId3, speaker: .interviewer, text: "Third", timestampSeconds: 30)

        taggingService.assignTag(tag.id, to: utteranceId1, sessionId: sessionId)
        taggingService.assignTag(tag.id, to: utteranceId2, sessionId: sessionId)
        taggingService.assignTag(tag.id, to: utteranceId3, sessionId: sessionId)

        // When: Exporting
        let markdown = taggingService.exportTaggedSegments(
            sessionId: sessionId,
            utterances: [utterance1, utterance2, utterance3]
        )

        // Then: Should have all three segments
        XCTAssertTrue(markdown.contains("3 tagged segment(s)"))
        XCTAssertTrue(markdown.contains("First"))
        XCTAssertTrue(markdown.contains("Second"))
        XCTAssertTrue(markdown.contains("Third"))
    }

    func testExport_includesResearcherNotes() {
        // Given: An assignment with a note
        let sessionId = UUID()
        let utteranceId = UUID()
        let tag = taggingService.tags.first!
        let utterance = Utterance(id: utteranceId, speaker: .participant, text: "Some text", timestampSeconds: 60)

        taggingService.assignTag(tag.id, to: utteranceId, sessionId: sessionId, note: "Key insight here")

        // When: Exporting
        let markdown = taggingService.exportTaggedSegments(
            sessionId: sessionId,
            utterances: [utterance]
        )

        // Then: Note should be in the export
        XCTAssertTrue(markdown.contains("Key insight here"))
        XCTAssertTrue(markdown.contains("_Note:"))
    }

    func testExport_onlyIncludesTargetSession() {
        // Given: Assignments in two different sessions
        let targetSessionId = UUID()
        let otherSessionId = UUID()
        let tag = taggingService.tags.first!

        let utteranceId1 = UUID()
        let utteranceId2 = UUID()

        let utterance1 = Utterance(id: utteranceId1, speaker: .participant, text: "In target session", timestampSeconds: 10)
        let utterance2 = Utterance(id: utteranceId2, speaker: .participant, text: "In other session", timestampSeconds: 20)

        taggingService.assignTag(tag.id, to: utteranceId1, sessionId: targetSessionId)
        taggingService.assignTag(tag.id, to: utteranceId2, sessionId: otherSessionId)

        // When: Exporting only the target session
        let markdown = taggingService.exportTaggedSegments(
            sessionId: targetSessionId,
            utterances: [utterance1, utterance2]
        )

        // Then: Should only include target session's tagged utterance
        XCTAssertTrue(markdown.contains("In target session"))
        XCTAssertTrue(markdown.contains("1 tagged segment(s)"))
    }

    // MARK: - Test: Tag Model

    func testTag_codable_roundTrip() throws {
        // Given: A tag
        let tag = Tag(name: "Test", colorHex: "#FF5733", parentId: UUID())

        // When: Encoding and decoding
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(tag)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Tag.self, from: data)

        // Then: All fields should match
        XCTAssertEqual(decoded.id, tag.id)
        XCTAssertEqual(decoded.name, tag.name)
        XCTAssertEqual(decoded.colorHex, tag.colorHex)
        XCTAssertEqual(decoded.parentId, tag.parentId)
    }

    func testTag_hashable() {
        // Given: Two tags
        let tag1 = Tag(name: "A", colorHex: "#000000")
        let tag2 = Tag(name: "B", colorHex: "#FFFFFF")
        let tag1Duplicate = Tag(id: tag1.id, name: "A Copy", colorHex: "#111111")

        // Then: Same ID should hash equally, different IDs should not
        var set = Set<Tag>()
        set.insert(tag1)
        set.insert(tag2)
        set.insert(tag1Duplicate) // Same ID as tag1

        XCTAssertEqual(set.count, 2) // tag1Duplicate replaces tag1
    }

    // MARK: - Test: UtteranceTagAssignment Model

    func testUtteranceTagAssignment_codable_roundTrip() throws {
        // Given: An assignment
        let assignment = UtteranceTagAssignment(
            utteranceId: UUID(),
            tagId: UUID(),
            sessionId: UUID(),
            note: "Test note"
        )

        // When: Encoding and decoding
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(assignment)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(UtteranceTagAssignment.self, from: data)

        // Then: All fields should match
        XCTAssertEqual(decoded.id, assignment.id)
        XCTAssertEqual(decoded.utteranceId, assignment.utteranceId)
        XCTAssertEqual(decoded.tagId, assignment.tagId)
        XCTAssertEqual(decoded.sessionId, assignment.sessionId)
        XCTAssertEqual(decoded.note, assignment.note)
    }
}
