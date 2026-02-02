import Foundation
import SwiftData

/// Manages interview templates including built-in and custom templates
@MainActor
class TemplateManager: ObservableObject {
    @Published var templates: [InterviewTemplate] = []

    private let modelContext: ModelContext?
    private var builtInTemplates: [InterviewTemplate] = []
    private var customTemplates: [InterviewTemplate] = []

    // MARK: - Initialization

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        loadBuiltInTemplates()
        loadCustomTemplates()
    }

    // MARK: - Public Methods

    /// Loads all built-in templates
    func loadBuiltInTemplates() {
        builtInTemplates = [
            discoveryInterview(),
            usabilityTestDebrief(),
            stakeholderInterview(),
            jobsToBeFound(),
            customerFeedback()
        ]
        updateTemplatesList()
    }

    /// Loads all custom templates from storage
    func loadCustomTemplates() {
        // In a full implementation, this would load from SwiftData
        // For now, we'll initialize with an empty array
        customTemplates = []
        updateTemplatesList()
    }

    /// Saves a custom template
    func saveCustomTemplate(_ template: InterviewTemplate) {
        var mutableTemplate = template
        // Ensure it's marked as custom (not built-in)
        mutableTemplate = InterviewTemplate(
            id: mutableTemplate.id,
            name: mutableTemplate.name,
            description: mutableTemplate.description,
            duration: mutableTemplate.duration,
            topics: mutableTemplate.topics,
            systemPromptAdditions: mutableTemplate.systemPromptAdditions,
            consentVariant: mutableTemplate.consentVariant,
            isBuiltIn: false
        )

        // Add or update in custom templates
        if let index = customTemplates.firstIndex(where: { $0.id == mutableTemplate.id }) {
            customTemplates[index] = mutableTemplate
        } else {
            customTemplates.append(mutableTemplate)
        }

        updateTemplatesList()
    }

    /// Deletes a custom template by ID
    func deleteCustomTemplate(id: UUID) {
        customTemplates.removeAll { $0.id == id }
        updateTemplatesList()
    }

    /// Returns a template by ID
    func template(withId id: UUID) -> InterviewTemplate? {
        return templates.first { $0.id == id }
    }

    /// Returns all built-in templates
    func getBuiltInTemplates() -> [InterviewTemplate] {
        return builtInTemplates
    }

    /// Returns all custom templates
    func getCustomTemplates() -> [InterviewTemplate] {
        return customTemplates
    }

    // MARK: - Private Methods

    private func updateTemplatesList() {
        templates = builtInTemplates + customTemplates
    }

    // MARK: - Built-In Template Definitions

    private func discoveryInterview() -> InterviewTemplate {
        InterviewTemplate(
            name: "Discovery Interview",
            description: "In-depth exploration of user background, workflow, and pain points",
            duration: 60,
            topics: [
                "Background",
                "Current workflow",
                "Pain points",
                "Workarounds",
                "Ideal state"
            ],
            consentVariant: .standard,
            isBuiltIn: true
        )
    }

    private func usabilityTestDebrief() -> InterviewTemplate {
        InterviewTemplate(
            name: "Usability Test Debrief",
            description: "Quick debrief after a usability testing session",
            duration: 30,
            topics: [
                "First impressions",
                "Task completion",
                "Difficulties",
                "Suggestions"
            ],
            consentVariant: .standard,
            isBuiltIn: true
        )
    }

    private func stakeholderInterview() -> InterviewTemplate {
        InterviewTemplate(
            name: "Stakeholder Interview",
            description: "Interview with business stakeholders and decision makers",
            duration: 45,
            topics: [
                "Role context",
                "Business goals",
                "Success metrics",
                "Concerns",
                "Priorities"
            ],
            consentVariant: .standard,
            isBuiltIn: true
        )
    }

    private func jobsToBeFound() -> InterviewTemplate {
        InterviewTemplate(
            name: "Jobs-to-be-Done",
            description: "Explore the jobs customers are trying to accomplish",
            duration: 45,
            topics: [
                "Trigger events",
                "Desired outcomes",
                "Current solutions",
                "Switching costs"
            ],
            consentVariant: .standard,
            isBuiltIn: true
        )
    }

    private func customerFeedback() -> InterviewTemplate {
        InterviewTemplate(
            name: "Customer Feedback",
            description: "Gather feedback from existing customers",
            duration: 30,
            topics: [
                "Usage patterns",
                "Satisfaction",
                "Feature requests",
                "Recommendations"
            ],
            consentVariant: .standard,
            isBuiltIn: true
        )
    }
}
