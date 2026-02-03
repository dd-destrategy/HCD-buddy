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
            usabilityTesting(),
            stakeholderInterview(),
            contextualInquiry()
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

    /// Discovery Interview: Exploring user needs and pain points
    private func discoveryInterview() -> InterviewTemplate {
        let systemPrompt = """
        DISCOVERY INTERVIEW COACHING GUIDANCE

        Purpose: Explore user needs, pain points, and desired outcomes to inform product decisions.

        TOPIC: Background
        Sample questions to suggest:
        - "Tell me about your role and how long you've been doing this work."
        - "Walk me through a typical day in your work."
        - "What tools or systems do you rely on most?"
        Coaching tip: Establish rapport before diving into problems. Listen for context clues.

        TOPIC: Current Workflow
        Sample questions to suggest:
        - "Can you walk me through how you currently handle [task]?"
        - "Who else is involved in this process?"
        - "How often do you need to do this?"
        Coaching tip: Ask for specific recent examples rather than generalizations.

        TOPIC: Pain Points
        Sample questions to suggest:
        - "What's the most frustrating part of this process?"
        - "Where do things typically go wrong?"
        - "What takes longer than it should?"
        Coaching tip: Probe for emotional language and follow up on hesitations.

        TOPIC: Ideal Solution
        Sample questions to suggest:
        - "If you could wave a magic wand, what would change?"
        - "What would success look like for you?"
        - "How would you know if things improved?"
        Coaching tip: Help users think beyond current constraints.

        TOPIC: Priorities
        Sample questions to suggest:
        - "Of the issues we discussed, which matters most to you?"
        - "What would you tackle first if you could?"
        - "What could you live without fixing?"
        Coaching tip: Use ranking or forced trade-offs to surface true priorities.
        """

        return InterviewTemplate(
            name: "Discovery Interview",
            description: "Exploring user needs and pain points to inform product decisions",
            duration: 60,
            topics: [
                "Background",
                "Current workflow",
                "Pain points",
                "Ideal solution",
                "Priorities"
            ],
            systemPromptAdditions: systemPrompt,
            consentVariant: .standard,
            isBuiltIn: true
        )
    }

    /// Usability Testing: Evaluating product usability with task-based structure
    private func usabilityTesting() -> InterviewTemplate {
        let systemPrompt = """
        USABILITY TESTING COACHING GUIDANCE

        Purpose: Evaluate product usability through observation and task completion analysis.

        TOPIC: First Impressions
        Sample questions to suggest:
        - "What are your initial thoughts looking at this screen?"
        - "What do you think you can do here?"
        - "Is anything unclear or unexpected?"
        Coaching tip: Capture immediate reactions before they rationalize. Silence is valuable here.

        TOPIC: Task Completion
        Sample prompts to suggest:
        - "Please try to [complete specific task]. Think aloud as you go."
        - "What are you looking for right now?"
        - "What do you expect to happen when you click that?"
        Coaching tip: Observe without guiding. Note where they hesitate or backtrack.

        TOPIC: Navigation
        Sample questions to suggest:
        - "How would you find [feature/content]?"
        - "Where would you expect to find that option?"
        - "Did the menu structure make sense to you?"
        Coaching tip: Watch for signs of disorientation. Note recovery strategies.

        TOPIC: Errors
        Sample questions to suggest:
        - "What happened there? What were you expecting?"
        - "How would you try to fix this?"
        - "Have you seen error messages like this before?"
        Coaching tip: Errors are gold. Explore the mental model mismatch.

        TOPIC: Overall Satisfaction
        Sample questions to suggest:
        - "On a scale of 1-5, how easy was that to complete? Why?"
        - "What would you change about this experience?"
        - "Would you use this again? Why or why not?"
        Coaching tip: Probe beyond the rating to understand the reasoning.
        """

        return InterviewTemplate(
            name: "Usability Testing",
            description: "Evaluating product usability through tasks and observation",
            duration: 45,
            topics: [
                "First impressions",
                "Task completion",
                "Navigation",
                "Errors",
                "Overall satisfaction"
            ],
            systemPromptAdditions: systemPrompt,
            consentVariant: .standard,
            isBuiltIn: true
        )
    }

    /// Stakeholder Interview: Understanding business requirements and constraints
    private func stakeholderInterview() -> InterviewTemplate {
        let systemPrompt = """
        STAKEHOLDER INTERVIEW COACHING GUIDANCE

        Purpose: Understand business requirements, constraints, and success criteria from decision makers.

        TOPIC: Goals
        Sample questions to suggest:
        - "What are the primary business objectives for this initiative?"
        - "How does this project align with company strategy?"
        - "What does success look like from your perspective?"
        Coaching tip: Distinguish between stated goals and underlying motivations.

        TOPIC: Constraints
        Sample questions to suggest:
        - "What limitations should we be aware of? (budget, timeline, technical)"
        - "Are there any non-negotiable requirements?"
        - "What has prevented progress on this in the past?"
        Coaching tip: Constraints often reveal organizational dynamics and politics.

        TOPIC: Success Metrics
        Sample questions to suggest:
        - "How will you measure whether this project succeeded?"
        - "What KPIs are you tracking?"
        - "Who needs to sign off on the final outcome?"
        Coaching tip: Push for specific, measurable criteria rather than vague aspirations.

        TOPIC: Timeline
        Sample questions to suggest:
        - "What's driving the timeline for this project?"
        - "Are there any key milestones or deadlines we should know about?"
        - "What happens if we miss the target date?"
        Coaching tip: Understand the consequences of delays to gauge true urgency.

        TOPIC: Concerns
        Sample questions to suggest:
        - "What keeps you up at night about this project?"
        - "What risks do you see?"
        - "What would cause you to consider this a failure?"
        Coaching tip: Create space for honest concerns. These often surface real priorities.
        """

        return InterviewTemplate(
            name: "Stakeholder Interview",
            description: "Understanding business requirements and constraints from decision makers",
            duration: 45,
            topics: [
                "Goals",
                "Constraints",
                "Success metrics",
                "Timeline",
                "Concerns"
            ],
            systemPromptAdditions: systemPrompt,
            consentVariant: .standard,
            isBuiltIn: true
        )
    }

    /// Contextual Inquiry: Observing users in their natural environment
    private func contextualInquiry() -> InterviewTemplate {
        let systemPrompt = """
        CONTEXTUAL INQUIRY COACHING GUIDANCE

        Purpose: Observe users in their natural work environment to understand real-world context.

        TOPIC: Environment
        Observation prompts to suggest:
        - "Tell me about your workspace setup."
        - "What's within arm's reach while you work?"
        - "How does this space affect how you work?"
        Coaching tip: Note physical layout, lighting, noise levels, and ergonomics.

        TOPIC: Tools Used
        Observation prompts to suggest:
        - "Show me the tools you use for this task."
        - "How did you learn to use these tools?"
        - "Which tools do you switch between most often?"
        Coaching tip: Watch for tool-switching friction and workarounds between systems.

        TOPIC: Workarounds
        Observation prompts to suggest:
        - "I noticed you did [action]. Tell me more about that."
        - "Is that the official way to do this, or your own approach?"
        - "What shortcuts have you developed over time?"
        Coaching tip: Workarounds reveal system failures and user creativity. Document them.

        TOPIC: Collaboration
        Observation prompts to suggest:
        - "Who do you need to coordinate with for this work?"
        - "How do you communicate with your team?"
        - "What information do you share, and how?"
        Coaching tip: Note formal vs. informal communication channels.

        TOPIC: Interruptions
        Observation prompts to suggest:
        - "How often do interruptions like this happen?"
        - "How do you get back on track after an interruption?"
        - "What types of interruptions are most disruptive?"
        Coaching tip: Interruptions reveal real workflow vs. ideal workflow. Track frequency.
        """

        return InterviewTemplate(
            name: "Contextual Inquiry",
            description: "Observing users in their natural environment to understand real-world context",
            duration: 90,
            topics: [
                "Environment",
                "Tools used",
                "Workarounds",
                "Collaboration",
                "Interruptions"
            ],
            systemPromptAdditions: systemPrompt,
            consentVariant: .research,
            isBuiltIn: true
        )
    }
}
