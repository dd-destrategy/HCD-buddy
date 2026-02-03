//
//  TemplateManagerTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for TemplateManager interview template operations
//

import XCTest
import SwiftData
@testable import HCDInterviewCoach

@MainActor
final class TemplateManagerTests: XCTestCase {

    var templateManager: TemplateManager!

    override func setUp() {
        super.setUp()
        templateManager = TemplateManager()
    }

    override func tearDown() {
        templateManager = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestTemplate(
        name: String = "Test Template",
        description: String = "Test description",
        duration: Int = 45,
        topics: [String] = ["Topic 1", "Topic 2"],
        isBuiltIn: Bool = false
    ) -> InterviewTemplate {
        return InterviewTemplate(
            name: name,
            description: description,
            duration: duration,
            topics: topics,
            consentVariant: .standard,
            isBuiltIn: isBuiltIn
        )
    }

    // MARK: - Test: Load Default Templates

    func testLoadDefaultTemplates() {
        // Given: A fresh template manager

        // When: Loading built-in templates (done in init)
        templateManager.loadBuiltInTemplates()

        // Then: Built-in templates should be loaded
        let builtInTemplates = templateManager.getBuiltInTemplates()
        XCTAssertFalse(builtInTemplates.isEmpty)
        XCTAssertEqual(builtInTemplates.count, 4) // 4 default templates
    }

    func testLoadDefaultTemplates_hasDiscoveryInterview() {
        // Given: Template manager with loaded templates

        // Then: Should have Discovery Interview template
        let templates = templateManager.templates
        let discoveryTemplate = templates.first { $0.name == "Discovery Interview" }

        XCTAssertNotNil(discoveryTemplate)
        XCTAssertEqual(discoveryTemplate?.duration, 60)
        XCTAssertTrue(discoveryTemplate?.isBuiltIn ?? false)
    }

    func testLoadDefaultTemplates_hasUsabilityTesting() {
        // Given: Template manager with loaded templates

        // Then: Should have Usability Testing template
        let templates = templateManager.templates
        let usabilityTemplate = templates.first { $0.name == "Usability Testing" }

        XCTAssertNotNil(usabilityTemplate)
        XCTAssertEqual(usabilityTemplate?.duration, 45)
        XCTAssertTrue(usabilityTemplate?.isBuiltIn ?? false)
    }

    func testLoadDefaultTemplates_hasStakeholderInterview() {
        // Given: Template manager with loaded templates

        // Then: Should have Stakeholder Interview template
        let templates = templateManager.templates
        let stakeholderTemplate = templates.first { $0.name == "Stakeholder Interview" }

        XCTAssertNotNil(stakeholderTemplate)
        XCTAssertEqual(stakeholderTemplate?.duration, 45)
        XCTAssertTrue(stakeholderTemplate?.isBuiltIn ?? false)
    }

    func testLoadDefaultTemplates_hasContextualInquiry() {
        // Given: Template manager with loaded templates

        // Then: Should have Contextual Inquiry template
        let templates = templateManager.templates
        let contextualTemplate = templates.first { $0.name == "Contextual Inquiry" }

        XCTAssertNotNil(contextualTemplate)
        XCTAssertEqual(contextualTemplate?.duration, 90)
        XCTAssertEqual(contextualTemplate?.consentVariant, .research)
        XCTAssertTrue(contextualTemplate?.isBuiltIn ?? false)
    }

    func testLoadDefaultTemplates_templatesHaveSystemPrompts() {
        // Given: Template manager with loaded templates

        // Then: All built-in templates should have system prompt additions for coaching
        let templates = templateManager.getBuiltInTemplates()

        for template in templates {
            XCTAssertNotNil(
                template.systemPromptAdditions,
                "\(template.name) should have system prompt additions"
            )
            XCTAssertFalse(
                template.systemPromptAdditions?.isEmpty ?? true,
                "\(template.name) should have non-empty system prompt"
            )
        }
    }

    func testLoadDefaultTemplates_allHaveTopics() {
        // Given: Template manager with loaded templates

        // Then: All built-in templates should have topics
        let builtInTemplates = templateManager.getBuiltInTemplates()

        for template in builtInTemplates {
            XCTAssertFalse(template.topics.isEmpty, "\(template.name) should have topics")
            XCTAssertGreaterThanOrEqual(template.topics.count, 3, "\(template.name) should have at least 3 topics")
        }
    }

    // MARK: - Test: Create Template

    func testCreateTemplate() {
        // Given: A new custom template
        let template = createTestTemplate(
            name: "My Custom Template",
            description: "Custom description",
            duration: 60,
            topics: ["Custom Topic 1", "Custom Topic 2", "Custom Topic 3"]
        )

        // When: Saving the template
        templateManager.saveCustomTemplate(template)

        // Then: Template should be added to list
        let customTemplates = templateManager.getCustomTemplates()
        XCTAssertEqual(customTemplates.count, 1)

        let saved = customTemplates.first
        XCTAssertEqual(saved?.name, "My Custom Template")
        XCTAssertEqual(saved?.description, "Custom description")
        XCTAssertEqual(saved?.duration, 60)
        XCTAssertFalse(saved?.isBuiltIn ?? true)
    }

    func testCreateTemplate_multipleCustom() {
        // Given: Multiple custom templates
        let template1 = createTestTemplate(name: "Custom 1")
        let template2 = createTestTemplate(name: "Custom 2")
        let template3 = createTestTemplate(name: "Custom 3")

        // When: Saving all templates
        templateManager.saveCustomTemplate(template1)
        templateManager.saveCustomTemplate(template2)
        templateManager.saveCustomTemplate(template3)

        // Then: All should be saved
        let customTemplates = templateManager.getCustomTemplates()
        XCTAssertEqual(customTemplates.count, 3)

        let names = customTemplates.map { $0.name }
        XCTAssertTrue(names.contains("Custom 1"))
        XCTAssertTrue(names.contains("Custom 2"))
        XCTAssertTrue(names.contains("Custom 3"))
    }

    func testCreateTemplate_addedToAllTemplates() {
        // Given: Initial template count
        let initialCount = templateManager.templates.count

        // When: Adding a custom template
        let template = createTestTemplate(name: "New Template")
        templateManager.saveCustomTemplate(template)

        // Then: Total count should increase
        XCTAssertEqual(templateManager.templates.count, initialCount + 1)
    }

    // MARK: - Test: Update Template

    func testUpdateTemplate() {
        // Given: An existing custom template
        let template = createTestTemplate(name: "Original Name", duration: 30)
        templateManager.saveCustomTemplate(template)

        // When: Updating the template
        let updatedTemplate = InterviewTemplate(
            id: template.id,
            name: "Updated Name",
            description: "Updated description",
            duration: 60,
            topics: template.topics,
            consentVariant: .research,
            isBuiltIn: false
        )
        templateManager.saveCustomTemplate(updatedTemplate)

        // Then: Template should be updated
        let customTemplates = templateManager.getCustomTemplates()
        XCTAssertEqual(customTemplates.count, 1) // Not duplicated

        let saved = customTemplates.first
        XCTAssertEqual(saved?.name, "Updated Name")
        XCTAssertEqual(saved?.description, "Updated description")
        XCTAssertEqual(saved?.duration, 60)
    }

    func testUpdateTemplate_preservesOtherTemplates() {
        // Given: Multiple custom templates
        let template1 = createTestTemplate(name: "Template 1")
        let template2 = createTestTemplate(name: "Template 2")
        templateManager.saveCustomTemplate(template1)
        templateManager.saveCustomTemplate(template2)

        // When: Updating one template
        let updatedTemplate1 = InterviewTemplate(
            id: template1.id,
            name: "Updated Template 1",
            description: template1.description,
            duration: template1.duration,
            topics: template1.topics,
            consentVariant: template1.consentVariant,
            isBuiltIn: false
        )
        templateManager.saveCustomTemplate(updatedTemplate1)

        // Then: Other template should be unchanged
        let templates = templateManager.getCustomTemplates()
        XCTAssertEqual(templates.count, 2)

        let otherTemplate = templates.first { $0.id == template2.id }
        XCTAssertEqual(otherTemplate?.name, "Template 2")
    }

    // MARK: - Test: Delete Template

    func testDeleteTemplate() {
        // Given: A custom template
        let template = createTestTemplate(name: "To Delete")
        templateManager.saveCustomTemplate(template)
        XCTAssertEqual(templateManager.getCustomTemplates().count, 1)

        // When: Deleting the template
        templateManager.deleteCustomTemplate(id: template.id)

        // Then: Template should be removed
        XCTAssertEqual(templateManager.getCustomTemplates().count, 0)
    }

    func testDeleteTemplate_byId() {
        // Given: Multiple custom templates
        let template1 = createTestTemplate(name: "Keep 1")
        let template2 = createTestTemplate(name: "Delete Me")
        let template3 = createTestTemplate(name: "Keep 2")

        templateManager.saveCustomTemplate(template1)
        templateManager.saveCustomTemplate(template2)
        templateManager.saveCustomTemplate(template3)

        // When: Deleting by specific ID
        templateManager.deleteCustomTemplate(id: template2.id)

        // Then: Only that template should be removed
        let remaining = templateManager.getCustomTemplates()
        XCTAssertEqual(remaining.count, 2)

        let names = remaining.map { $0.name }
        XCTAssertTrue(names.contains("Keep 1"))
        XCTAssertFalse(names.contains("Delete Me"))
        XCTAssertTrue(names.contains("Keep 2"))
    }

    func testDeleteTemplate_nonExistent() {
        // Given: Some custom templates
        let template = createTestTemplate(name: "Existing")
        templateManager.saveCustomTemplate(template)

        // When: Deleting non-existent ID
        let nonExistentId = UUID()
        templateManager.deleteCustomTemplate(id: nonExistentId)

        // Then: Existing template should remain
        XCTAssertEqual(templateManager.getCustomTemplates().count, 1)
    }

    // MARK: - Test: Duplicate Template

    func testDuplicateTemplate() {
        // Given: A custom template
        let original = createTestTemplate(
            name: "Original",
            description: "Original desc",
            duration: 45,
            topics: ["Topic A", "Topic B"]
        )
        templateManager.saveCustomTemplate(original)

        // When: Creating a duplicate
        let duplicate = InterviewTemplate(
            name: "Original (Copy)",
            description: original.description,
            duration: original.duration,
            topics: original.topics,
            consentVariant: original.consentVariant,
            isBuiltIn: false
        )
        templateManager.saveCustomTemplate(duplicate)

        // Then: Both templates should exist
        let templates = templateManager.getCustomTemplates()
        XCTAssertEqual(templates.count, 2)

        let names = templates.map { $0.name }
        XCTAssertTrue(names.contains("Original"))
        XCTAssertTrue(names.contains("Original (Copy)"))

        // Duplicate should have different ID
        XCTAssertNotEqual(original.id, duplicate.id)
    }

    func testDuplicateTemplate_hasAllProperties() {
        // Given: A template with all properties
        let original = InterviewTemplate(
            name: "Full Template",
            description: "Full description",
            duration: 90,
            topics: ["T1", "T2", "T3", "T4"],
            systemPromptAdditions: "Custom system prompt",
            consentVariant: .research,
            isBuiltIn: false
        )

        // When: Duplicating
        let duplicate = InterviewTemplate(
            name: original.name + " (Copy)",
            description: original.description,
            duration: original.duration,
            topics: original.topics,
            systemPromptAdditions: original.systemPromptAdditions,
            consentVariant: original.consentVariant,
            isBuiltIn: false
        )

        // Then: All properties should match
        XCTAssertEqual(duplicate.description, original.description)
        XCTAssertEqual(duplicate.duration, original.duration)
        XCTAssertEqual(duplicate.topics, original.topics)
        XCTAssertEqual(duplicate.systemPromptAdditions, original.systemPromptAdditions)
        XCTAssertEqual(duplicate.consentVariant, original.consentVariant)
    }

    // MARK: - Test: Template Validation

    func testTemplateValidation_hasName() {
        // Given: Templates with and without names
        let validTemplate = createTestTemplate(name: "Valid Name")
        let emptyNameTemplate = createTestTemplate(name: "")

        // Then: Names should be as specified
        XCTAssertFalse(validTemplate.name.isEmpty)
        XCTAssertTrue(emptyNameTemplate.name.isEmpty)
    }

    func testTemplateValidation_hasTopics() {
        // Given: Templates with different topic counts
        let withTopics = createTestTemplate(topics: ["T1", "T2", "T3"])
        let withoutTopics = createTestTemplate(topics: [])

        // Then: Topics should be as specified
        XCTAssertEqual(withTopics.topics.count, 3)
        XCTAssertTrue(withoutTopics.topics.isEmpty)
    }

    func testTemplateValidation_durationRange() {
        // Given: Templates with various durations
        let shortDuration = createTestTemplate(duration: 15)
        let normalDuration = createTestTemplate(duration: 45)
        let longDuration = createTestTemplate(duration: 120)

        // Then: Durations should be as specified
        XCTAssertEqual(shortDuration.duration, 15)
        XCTAssertEqual(normalDuration.duration, 45)
        XCTAssertEqual(longDuration.duration, 120)
    }

    // MARK: - Test: Template Topics

    func testTemplateTopics_stored() {
        // Given: A template with specific topics
        let topics = ["Introduction", "Main Questions", "Follow-ups", "Wrap-up"]
        let template = createTestTemplate(topics: topics)

        // When: Saving and retrieving
        templateManager.saveCustomTemplate(template)
        let retrieved = templateManager.template(withId: template.id)

        // Then: Topics should be preserved
        XCTAssertEqual(retrieved?.topics, topics)
        XCTAssertEqual(retrieved?.topics.count, 4)
    }

    func testTemplateTopics_orderedCorrectly() {
        // Given: A template with ordered topics
        let orderedTopics = ["First", "Second", "Third", "Fourth", "Fifth"]
        let template = createTestTemplate(topics: orderedTopics)

        // When: Retrieving
        templateManager.saveCustomTemplate(template)
        let retrieved = templateManager.template(withId: template.id)

        // Then: Order should be preserved
        XCTAssertEqual(retrieved?.topics, orderedTopics)
        XCTAssertEqual(retrieved?.topics[0], "First")
        XCTAssertEqual(retrieved?.topics[4], "Fifth")
    }

    // MARK: - Test: Template Export

    func testTemplateExport_encodable() throws {
        // Given: A template
        let template = createTestTemplate(
            name: "Export Test",
            description: "Testing export",
            duration: 45,
            topics: ["Topic 1", "Topic 2"]
        )

        // When: Encoding to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(template)

        // Then: Should produce valid JSON
        XCTAssertNotNil(jsonData)
        XCTAssertGreaterThan(jsonData.count, 0)

        let jsonString = String(data: jsonData, encoding: .utf8)
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("Export Test") ?? false)
    }

    func testTemplateExport_containsAllFields() throws {
        // Given: A template with all fields
        let template = InterviewTemplate(
            name: "Full Export",
            description: "Full description for export",
            duration: 60,
            topics: ["T1", "T2"],
            systemPromptAdditions: "Custom prompt",
            consentVariant: .research,
            isBuiltIn: false
        )

        // When: Encoding
        let jsonData = try JSONEncoder().encode(template)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""

        // Then: All fields should be present
        XCTAssertTrue(jsonString.contains("Full Export"))
        XCTAssertTrue(jsonString.contains("Full description for export"))
        XCTAssertTrue(jsonString.contains("60"))
        XCTAssertTrue(jsonString.contains("T1"))
        XCTAssertTrue(jsonString.contains("Custom prompt"))
    }

    // MARK: - Test: Template Import

    func testTemplateImport_decodable() throws {
        // Given: A JSON representation of a template
        let json = """
        {
            "id": "A5C8F7B3-D21E-4A6B-9E8F-1C2D3E4F5A6B",
            "name": "Imported Template",
            "description": "Imported description",
            "duration": 30,
            "topics": ["Imported Topic 1", "Imported Topic 2"],
            "consentVariant": "Standard (Full AI)",
            "isBuiltIn": false
        }
        """
        let jsonData = json.data(using: .utf8)!

        // When: Decoding
        let decoder = JSONDecoder()
        let template = try decoder.decode(InterviewTemplate.self, from: jsonData)

        // Then: Template should be correctly decoded
        XCTAssertEqual(template.name, "Imported Template")
        XCTAssertEqual(template.description, "Imported description")
        XCTAssertEqual(template.duration, 30)
        XCTAssertEqual(template.topics.count, 2)
        XCTAssertEqual(template.consentVariant, .standard)
        XCTAssertFalse(template.isBuiltIn)
    }

    func testTemplateImport_roundTrip() throws {
        // Given: An original template
        let original = InterviewTemplate(
            name: "Round Trip",
            description: "Testing round trip",
            duration: 45,
            topics: ["A", "B", "C"],
            systemPromptAdditions: "Extra prompt",
            consentVariant: .minimal,
            isBuiltIn: false
        )

        // When: Encoding then decoding
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let jsonData = try encoder.encode(original)
        let decoded = try decoder.decode(InterviewTemplate.self, from: jsonData)

        // Then: All fields should match
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.duration, original.duration)
        XCTAssertEqual(decoded.topics, original.topics)
        XCTAssertEqual(decoded.systemPromptAdditions, original.systemPromptAdditions)
        XCTAssertEqual(decoded.consentVariant, original.consentVariant)
        XCTAssertEqual(decoded.isBuiltIn, original.isBuiltIn)
    }

    // MARK: - Test: Built-In Templates Immutable

    func testBuiltInTemplatesImmutable() {
        // Given: Built-in templates
        let builtInTemplates = templateManager.getBuiltInTemplates()
        let initialCount = builtInTemplates.count

        // When: Attempting to "save" a built-in template as custom
        // (The saveCustomTemplate method marks templates as non-built-in)
        if let firstBuiltIn = builtInTemplates.first {
            templateManager.saveCustomTemplate(firstBuiltIn)
        }

        // Then: Built-in templates count should remain unchanged
        let newBuiltInCount = templateManager.getBuiltInTemplates().count
        XCTAssertEqual(newBuiltInCount, initialCount)
    }

    func testBuiltInTemplates_cannotDelete() {
        // Given: Built-in templates
        let builtInTemplates = templateManager.getBuiltInTemplates()
        let initialCount = builtInTemplates.count

        // When: Attempting to delete a built-in template ID
        if let firstBuiltIn = builtInTemplates.first {
            templateManager.deleteCustomTemplate(id: firstBuiltIn.id)
        }

        // Then: Built-in templates should remain (delete only affects custom)
        XCTAssertEqual(templateManager.getBuiltInTemplates().count, initialCount)
    }

    func testBuiltInTemplates_allMarkedAsBuiltIn() {
        // Given: Built-in templates

        // Then: All should have isBuiltIn = true
        let builtInTemplates = templateManager.getBuiltInTemplates()
        XCTAssertTrue(builtInTemplates.allSatisfy { $0.isBuiltIn })
    }

    func testCustomTemplates_allMarkedAsCustom() {
        // Given: Custom templates
        let template1 = createTestTemplate(name: "Custom 1")
        let template2 = createTestTemplate(name: "Custom 2")
        templateManager.saveCustomTemplate(template1)
        templateManager.saveCustomTemplate(template2)

        // Then: All custom templates should have isBuiltIn = false
        let customTemplates = templateManager.getCustomTemplates()
        XCTAssertTrue(customTemplates.allSatisfy { !$0.isBuiltIn })
    }

    // MARK: - Test: Template Lookup

    func testTemplateLookup_byId() {
        // Given: Mixed templates
        let customTemplate = createTestTemplate(name: "Custom Lookup")
        templateManager.saveCustomTemplate(customTemplate)

        // When: Looking up by ID
        let found = templateManager.template(withId: customTemplate.id)

        // Then: Should find the correct template
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "Custom Lookup")
    }

    func testTemplateLookup_builtInById() {
        // Given: Built-in templates

        // When: Looking up a built-in template
        let builtIn = templateManager.getBuiltInTemplates().first
        let found = templateManager.template(withId: builtIn?.id ?? UUID())

        // Then: Should find the built-in template
        XCTAssertNotNil(found)
        XCTAssertTrue(found?.isBuiltIn ?? false)
    }

    func testTemplateLookup_notFound() {
        // Given: Some templates exist

        // When: Looking up non-existent ID
        let notFound = templateManager.template(withId: UUID())

        // Then: Should return nil
        XCTAssertNil(notFound)
    }

    // MARK: - Test: Template List Composition

    func testTemplateList_combinesBuiltInAndCustom() {
        // Given: Built-in templates and custom templates
        let customTemplate = createTestTemplate(name: "My Custom")
        templateManager.saveCustomTemplate(customTemplate)

        // When: Getting all templates
        let allTemplates = templateManager.templates

        // Then: Should include both built-in and custom
        let builtInCount = templateManager.getBuiltInTemplates().count
        let customCount = templateManager.getCustomTemplates().count

        XCTAssertEqual(allTemplates.count, builtInCount + customCount)
    }

    func testTemplateList_publishedChanges() {
        // Given: Initial template count
        let initialCount = templateManager.templates.count

        // When: Adding a custom template
        let template = createTestTemplate(name: "Trigger Update")
        templateManager.saveCustomTemplate(template)

        // Then: Published templates list should update
        XCTAssertEqual(templateManager.templates.count, initialCount + 1)
    }
}

// MARK: - ConsentVariant Tests

extension TemplateManagerTests {

    func testConsentVariant_standard() {
        let template = createTestTemplate()
        XCTAssertEqual(template.consentVariant, .standard)
        XCTAssertEqual(template.consentVariant.rawValue, "Standard (Full AI)")
    }

    func testConsentVariant_minimal() {
        let template = InterviewTemplate(
            name: "Minimal Consent",
            description: "Test",
            duration: 30,
            topics: ["Topic"],
            consentVariant: .minimal,
            isBuiltIn: false
        )
        XCTAssertEqual(template.consentVariant, .minimal)
        XCTAssertEqual(template.consentVariant.rawValue, "Minimal (Transcription Only)")
    }

    func testConsentVariant_research() {
        let template = InterviewTemplate(
            name: "Research Consent",
            description: "Test",
            duration: 30,
            topics: ["Topic"],
            consentVariant: .research,
            isBuiltIn: false
        )
        XCTAssertEqual(template.consentVariant, .research)
        XCTAssertEqual(template.consentVariant.rawValue, "Research (IRB-appropriate)")
    }
}
