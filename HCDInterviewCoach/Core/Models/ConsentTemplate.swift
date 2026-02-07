//
//  ConsentTemplate.swift
//  HCDInterviewCoach
//
//  FEATURE H: Accessible Consent System
//  Defines consent templates with multi-language support, versioning,
//  and individual permission items at a 5th-grade reading level.
//

import Foundation

// MARK: - Consent Language

/// Supported languages for consent templates
enum ConsentLanguage: String, CaseIterable, Codable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case japanese = "ja"
    case chinese = "zh"

    /// English display name for the language
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .japanese: return "Japanese"
        case .chinese: return "Chinese"
        }
    }

    /// The language name written in its own script
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Espa\u{00F1}ol"
        case .french: return "Fran\u{00E7}ais"
        case .german: return "Deutsch"
        case .japanese: return "\u{65E5}\u{672C}\u{8A9E}"
        case .chinese: return "\u{4E2D}\u{6587}"
        }
    }

    /// Visual icon for the language (flag emoji)
    var icon: String {
        switch self {
        case .english: return "\u{1F1FA}\u{1F1F8}"
        case .spanish: return "\u{1F1EA}\u{1F1F8}"
        case .french: return "\u{1F1EB}\u{1F1F7}"
        case .german: return "\u{1F1E9}\u{1F1EA}"
        case .japanese: return "\u{1F1EF}\u{1F1F5}"
        case .chinese: return "\u{1F1E8}\u{1F1F3}"
        }
    }
}

// MARK: - Consent Permission

/// A single permission item in the consent flow.
/// Each permission has a plain-language title and description written at a 5th-grade reading level.
struct ConsentPermission: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let isRequired: Bool
    var isAccepted: Bool

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        icon: String,
        isRequired: Bool,
        isAccepted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.isRequired = isRequired
        self.isAccepted = isAccepted
    }
}

// MARK: - Consent Template

/// A versioned consent template containing an introduction, a set of permissions,
/// and closing text. Templates support multiple languages and can be customized.
struct ConsentTemplate: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var version: String
    var language: ConsentLanguage
    var introductionText: String
    var permissions: [ConsentPermission]
    var closingText: String
    var isDefault: Bool
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        version: String = "1.0.0",
        language: ConsentLanguage = .english,
        introductionText: String,
        permissions: [ConsentPermission],
        closingText: String,
        isDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.language = language
        self.introductionText = introductionText
        self.permissions = permissions
        self.closingText = closingText
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Whether all required permissions have been accepted
    var allRequiredAccepted: Bool {
        permissions
            .filter { $0.isRequired }
            .allSatisfy { $0.isAccepted }
    }

    /// Total number of permissions in this template
    var permissionCount: Int {
        permissions.count
    }

    /// Number of permissions that have been accepted
    var acceptedCount: Int {
        permissions.filter { $0.isAccepted }.count
    }

    // MARK: - Default Templates

    /// Pre-built default English consent template at 5th-grade reading level
    static func defaultEnglish() -> ConsentTemplate {
        ConsentTemplate(
            name: "Standard Consent",
            version: "1.0.0",
            language: .english,
            introductionText: "Thank you for talking with us today. Before we start, we want to make sure you know what will happen. Please read each item below. You can say yes or no to each one. If you have questions, just ask.",
            permissions: [
                ConsentPermission(
                    title: "Record Our Talk",
                    description: "We will record what we say during this interview.",
                    icon: "mic.fill",
                    isRequired: true
                ),
                ConsentPermission(
                    title: "Use Your Words",
                    description: "We may use quotes from you in our research. We won't use your name.",
                    icon: "text.quote",
                    isRequired: true
                ),
                ConsentPermission(
                    title: "Take Notes",
                    description: "The computer will write down what we say as we talk.",
                    icon: "note.text",
                    isRequired: true
                ),
                ConsentPermission(
                    title: "Share Findings",
                    description: "We may share what we learn with our team. Your name stays private.",
                    icon: "person.2.fill",
                    isRequired: false
                ),
                ConsentPermission(
                    title: "Save for Later",
                    description: "We may keep this recording to listen to again.",
                    icon: "archivebox.fill",
                    isRequired: false
                )
            ],
            closingText: "You can change your mind at any time. Just let us know and we will stop. Your comfort matters most to us.",
            isDefault: true
        )
    }

    /// Pre-built default Spanish consent template at 5th-grade reading level
    static func defaultSpanish() -> ConsentTemplate {
        ConsentTemplate(
            name: "Consentimiento Est\u{00E1}ndar",
            version: "1.0.0",
            language: .spanish,
            introductionText: "Gracias por hablar con nosotros hoy. Antes de empezar, queremos que sepas lo que va a pasar. Por favor lee cada punto. Puedes decir s\u{00ED} o no a cada uno. Si tienes preguntas, solo preg\u{00FA}ntanos.",
            permissions: [
                ConsentPermission(
                    title: "Grabar Nuestra Charla",
                    description: "Vamos a grabar lo que digamos durante esta entrevista.",
                    icon: "mic.fill",
                    isRequired: true
                ),
                ConsentPermission(
                    title: "Usar Tus Palabras",
                    description: "Podemos usar citas tuyas en nuestra investigaci\u{00F3}n. No usaremos tu nombre.",
                    icon: "text.quote",
                    isRequired: true
                ),
                ConsentPermission(
                    title: "Tomar Notas",
                    description: "La computadora escribir\u{00E1} lo que digamos mientras hablamos.",
                    icon: "note.text",
                    isRequired: true
                ),
                ConsentPermission(
                    title: "Compartir Hallazgos",
                    description: "Podemos compartir lo que aprendamos con nuestro equipo. Tu nombre se mantiene privado.",
                    icon: "person.2.fill",
                    isRequired: false
                ),
                ConsentPermission(
                    title: "Guardar para Despu\u{00E9}s",
                    description: "Podemos guardar esta grabaci\u{00F3}n para escucharla de nuevo.",
                    icon: "archivebox.fill",
                    isRequired: false
                )
            ],
            closingText: "Puedes cambiar de opini\u{00F3}n en cualquier momento. Solo d\u{00ED}nos y pararemos. Tu comodidad es lo m\u{00E1}s importante para nosotros.",
            isDefault: true
        )
    }

    /// Pre-built default French consent template at 5th-grade reading level
    static func defaultFrench() -> ConsentTemplate {
        ConsentTemplate(
            name: "Consentement Standard",
            version: "1.0.0",
            language: .french,
            introductionText: "Merci de parler avec nous aujourd\u{2019}hui. Avant de commencer, nous voulons que vous sachiez ce qui va se passer. Veuillez lire chaque point. Vous pouvez dire oui ou non \u{00E0} chacun. Si vous avez des questions, demandez-nous.",
            permissions: [
                ConsentPermission(
                    title: "Enregistrer Notre Discussion",
                    description: "Nous allons enregistrer ce que nous disons pendant cet entretien.",
                    icon: "mic.fill",
                    isRequired: true
                ),
                ConsentPermission(
                    title: "Utiliser Vos Mots",
                    description: "Nous pouvons utiliser vos citations dans notre recherche. Nous n\u{2019}utiliserons pas votre nom.",
                    icon: "text.quote",
                    isRequired: true
                ),
                ConsentPermission(
                    title: "Prendre des Notes",
                    description: "L\u{2019}ordinateur \u{00E9}crira ce que nous disons pendant que nous parlons.",
                    icon: "note.text",
                    isRequired: true
                ),
                ConsentPermission(
                    title: "Partager les R\u{00E9}sultats",
                    description: "Nous pouvons partager ce que nous apprenons avec notre \u{00E9}quipe. Votre nom reste priv\u{00E9}.",
                    icon: "person.2.fill",
                    isRequired: false
                ),
                ConsentPermission(
                    title: "Garder pour Plus Tard",
                    description: "Nous pouvons garder cet enregistrement pour l\u{2019}\u{00E9}couter \u{00E0} nouveau.",
                    icon: "archivebox.fill",
                    isRequired: false
                )
            ],
            closingText: "Vous pouvez changer d\u{2019}avis \u{00E0} tout moment. Dites-le nous et nous arr\u{00EA}terons. Votre confort est le plus important pour nous.",
            isDefault: true
        )
    }
}
