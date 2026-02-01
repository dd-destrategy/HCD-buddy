import Foundation

/// Represents a complete interview template with topics, duration, and consent variant
struct InterviewTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let duration: Int // minutes
    let topics: [String]
    let systemPromptAdditions: String?
    let consentVariant: ConsentVariant
    let isBuiltIn: Bool

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        duration: Int,
        topics: [String],
        systemPromptAdditions: String? = nil,
        consentVariant: ConsentVariant = .standard,
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.duration = duration
        self.topics = topics
        self.systemPromptAdditions = systemPromptAdditions
        self.consentVariant = consentVariant
        self.isBuiltIn = isBuiltIn
    }
}

/// Defines the consent disclosure variant for a template
enum ConsentVariant: String, Codable {
    case standard = "Standard (Full AI)"
    case minimal = "Minimal (Transcription Only)"
    case research = "Research (IRB-appropriate)"
}
