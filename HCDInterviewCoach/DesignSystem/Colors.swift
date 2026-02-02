import SwiftUI

/// Semantic color tokens for the HCD Interview Coach app
/// Supports both light and dark mode
extension Color {
    // MARK: - Primary Colors

    static let hcdPrimary = Color("Primary", bundle: .main)
    static let hcdPrimaryLight = Color("PrimaryLight", bundle: .main)
    static let hcdPrimaryDark = Color("PrimaryDark", bundle: .main)

    // MARK: - Secondary Colors

    static let hcdSecondary = Color("Secondary", bundle: .main)
    static let hcdSecondaryLight = Color("SecondaryLight", bundle: .main)
    static let hcdSecondaryDark = Color("SecondaryDark", bundle: .main)

    // MARK: - Semantic Colors

    /// Background colors
    static let hcdBackground = Color("Background", bundle: .main)
    static let hcdBackgroundSecondary = Color("BackgroundSecondary", bundle: .main)
    static let hcdBackgroundTertiary = Color("BackgroundTertiary", bundle: .main)

    /// Surface colors
    static let hcdSurface = Color("Surface", bundle: .main)
    static let hcdSurfaceElevated = Color("SurfaceElevated", bundle: .main)

    /// Text colors
    static let hcdTextPrimary = Color("TextPrimary", bundle: .main)
    static let hcdTextSecondary = Color("TextSecondary", bundle: .main)
    static let hcdTextTertiary = Color("TextTertiary", bundle: .main)
    static let hcdTextDisabled = Color("TextDisabled", bundle: .main)

    /// Border colors
    static let hcdBorder = Color("Border", bundle: .main)
    static let hcdBorderLight = Color("BorderLight", bundle: .main)
    static let hcdDivider = Color("Divider", bundle: .main)

    // MARK: - Status Colors

    /// Success
    static let hcdSuccess = Color("Success", bundle: .main)
    static let hcdSuccessLight = Color("SuccessLight", bundle: .main)
    static let hcdSuccessDark = Color("SuccessDark", bundle: .main)

    /// Warning
    static let hcdWarning = Color("Warning", bundle: .main)
    static let hcdWarningLight = Color("WarningLight", bundle: .main)
    static let hcdWarningDark = Color("WarningDark", bundle: .main)

    /// Error
    static let hcdError = Color("Error", bundle: .main)
    static let hcdErrorLight = Color("ErrorLight", bundle: .main)
    static let hcdErrorDark = Color("ErrorDark", bundle: .main)

    /// Info
    static let hcdInfo = Color("Info", bundle: .main)
    static let hcdInfoLight = Color("InfoLight", bundle: .main)
    static let hcdInfoDark = Color("InfoDark", bundle: .main)

    // MARK: - Feature-Specific Colors

    /// Audio/Recording
    static let hcdRecording = Color("Recording", bundle: .main)
    static let hcdRecordingActive = Color("RecordingActive", bundle: .main)

    /// Transcription
    static let hcdTranscription = Color("Transcription", bundle: .main)
    static let hcdInterviewer = Color("Interviewer", bundle: .main)
    static let hcdParticipant = Color("Participant", bundle: .main)

    /// Coaching
    static let hcdCoaching = Color("Coaching", bundle: .main)
    static let hcdCoachingPrompt = Color("CoachingPrompt", bundle: .main)

    /// Insights
    static let hcdInsight = Color("Insight", bundle: .main)
    static let hcdInsightHighlight = Color("InsightHighlight", bundle: .main)

    // MARK: - Fallback Colors (for when assets are not available)

    static func fallbackColor(_ name: String) -> Color {
        switch name {
        // Primary
        case "Primary": return Color.accentColor
        case "PrimaryLight": return Color.accentColor.opacity(0.7)
        case "PrimaryDark": return Color.accentColor.opacity(0.9)

        // Secondary
        case "Secondary": return Color.blue
        case "SecondaryLight": return Color.blue.opacity(0.7)
        case "SecondaryDark": return Color.blue.opacity(0.9)

        // Background
        case "Background": return Color(nsColor: .windowBackgroundColor)
        case "BackgroundSecondary": return Color(nsColor: .controlBackgroundColor)
        case "BackgroundTertiary": return Color(nsColor: .underPageBackgroundColor)

        // Surface
        case "Surface": return Color(nsColor: .controlBackgroundColor)
        case "SurfaceElevated": return Color(nsColor: .controlColor)

        // Text
        case "TextPrimary": return Color.primary
        case "TextSecondary": return Color.secondary
        case "TextTertiary": return Color.secondary.opacity(0.6)
        case "TextDisabled": return Color.secondary.opacity(0.4)

        // Border
        case "Border": return Color.gray.opacity(0.3)
        case "BorderLight": return Color.gray.opacity(0.2)
        case "Divider": return Color.gray.opacity(0.15)

        // Status
        case "Success": return Color.green
        case "SuccessLight": return Color.green.opacity(0.7)
        case "SuccessDark": return Color.green.opacity(0.9)
        case "Warning": return Color.orange
        case "WarningLight": return Color.orange.opacity(0.7)
        case "WarningDark": return Color.orange.opacity(0.9)
        case "Error": return Color.red
        case "ErrorLight": return Color.red.opacity(0.7)
        case "ErrorDark": return Color.red.opacity(0.9)
        case "Info": return Color.blue
        case "InfoLight": return Color.blue.opacity(0.7)
        case "InfoDark": return Color.blue.opacity(0.9)

        // Feature-specific
        case "Recording": return Color.red
        case "RecordingActive": return Color.red.opacity(0.8)
        case "Transcription": return Color.purple
        case "Interviewer": return Color.blue
        case "Participant": return Color.green
        case "Coaching": return Color.orange
        case "CoachingPrompt": return Color.orange.opacity(0.8)
        case "Insight": return Color.purple
        case "InsightHighlight": return Color.purple.opacity(0.2)

        default: return Color.gray
        }
    }
}

// MARK: - NSColor Extension

extension NSColor {
    /// Convenience method to create NSColor from hex
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
