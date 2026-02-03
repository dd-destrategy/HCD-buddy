//
//  LiquidGlassExamples.swift
//  HCDInterviewCoach
//
//  Examples demonstrating how to apply Liquid Glass UI effects
//  to various views in the HCD Interview Coach application.
//

import SwiftUI

// MARK: - Example: Coaching Prompt with Glass Effect

/// Example of applying liquid glass to a coaching prompt view.
/// Uses `.glassFloating()` for the distinctive floating card look.
struct GlassCoachingPromptExample: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.hcdCoaching)

                Text("Coaching Suggestion")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .glassButton(style: .ghost)
                }
                .buttonStyle(.plain)
            }

            // Prompt text
            Text("Try asking an open-ended question to explore this topic further.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)

            // Action buttons with glass effect
            HStack(spacing: 8) {
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text("Later")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .glassButton(style: .secondary)

                Spacer()

                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Got it")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .glassButton(isActive: true, style: .primary)
            }
        }
        .padding(16)
        .frame(maxWidth: 360)
        .glassFloating(isActive: true, pulseAnimation: true)
    }
}

// MARK: - Example: Insights Panel with Glass Effect

/// Example of applying liquid glass to an insights panel.
/// Uses `.glassPanel()` for sidebar styling with edge-aware corner radii.
struct GlassInsightsPanelExample: View {
    @State private var isCollapsed = false
    @State private var selectedInsight: String?

    let insights = [
        ("User pain point", "2:34"),
        ("Workflow insight", "5:12"),
        ("Feature request", "8:45")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Panel header
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.hcdInsight)

                Text("Insights")
                    .font(.system(size: 14, weight: .semibold))

                Text("\(insights.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .liquidGlass(
                        material: .ultraThin,
                        cornerRadius: CornerRadius.small,
                        borderStyle: .subtle
                    )

                Spacer()

                Button(action: { isCollapsed.toggle() }) {
                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            if !isCollapsed {
                Divider()
                    .padding(.horizontal, 12)

                // Insight cards
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(insights, id: \.0) { insight in
                            InsightCardExample(
                                title: insight.0,
                                timestamp: insight.1,
                                isSelected: selectedInsight == insight.0
                            )
                            .onTapGesture {
                                selectedInsight = insight.0
                            }
                        }
                    }
                    .padding(12)
                }
            }
        }
        .frame(width: 280)
        .glassPanel(edge: .trailing)
    }
}

/// Individual insight card with glass card styling
struct InsightCardExample: View {
    let title: String
    let timestamp: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.hcdInsight)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            Text(timestamp)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassCard(isSelected: isSelected, accentColor: .hcdInsight)
    }
}

// MARK: - Example: Topic Awareness Card with Glass Effect

/// Example of applying liquid glass to topic cards.
/// Uses `.glassCard()` with status-based accent colors.
struct GlassTopicCardExample: View {
    let topic: String
    let status: TopicStatusExample
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(status.color)
                .frame(width: 12, height: 12)
                .glowEffect(color: status.color, radius: 4, isActive: status == .deepDive)

            // Topic name
            Text(topic)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            // Status badge
            Text(status.label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(status.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .liquidGlass(
                    material: .ultraThin,
                    cornerRadius: CornerRadius.small,
                    borderStyle: .accent(status.color)
                )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassCard(isSelected: isSelected, accentColor: status.color)
    }

    enum TopicStatusExample: String {
        case notStarted = "Not Started"
        case mentioned = "Mentioned"
        case explored = "Explored"
        case deepDive = "Deep Dive"

        var label: String { rawValue }

        var color: Color {
            switch self {
            case .notStarted: return .gray
            case .mentioned: return .yellow
            case .explored: return .blue
            case .deepDive: return .green
            }
        }
    }
}

// MARK: - Example: Session Status Bar with Glass Effect

/// Example of applying liquid glass to a toolbar/status bar.
/// Uses `.glassToolbar()` for navigation bar styling.
struct GlassSessionToolbarExample: View {
    @State private var isRecording = true
    @State private var isCoachingEnabled = true

    var body: some View {
        HStack(spacing: 16) {
            // Session info
            HStack(spacing: 8) {
                Circle()
                    .fill(isRecording ? Color.red : Color.gray)
                    .frame(width: 10, height: 10)
                    .glowEffect(color: .red, radius: 6, isActive: isRecording)

                Text("Recording")
                    .font(.system(size: 13, weight: .medium))

                Text("12:34")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Coaching toggle
            Button(action: { isCoachingEnabled.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: isCoachingEnabled ? "lightbulb.fill" : "lightbulb.slash")
                        .font(.system(size: 14))

                    if isCoachingEnabled {
                        Text("Coaching On")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .glassButton(isActive: isCoachingEnabled, style: isCoachingEnabled ? .primary : .secondary)

            // End session button
            Button(action: {}) {
                Text("End Session")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .glassButton(style: .destructive)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassToolbar()
    }
}

// MARK: - Example: Modal Sheet with Glass Effect

/// Example of applying liquid glass to a modal sheet.
/// Uses `.glassSheet()` for modal/popover styling.
struct GlassModalSheetExample: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Session Settings")
                    .font(.headline)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Content
            VStack(alignment: .leading, spacing: 16) {
                settingRow(
                    icon: "waveform",
                    title: "Audio Input",
                    value: "BlackHole 2ch"
                )

                settingRow(
                    icon: "lightbulb",
                    title: "Coaching",
                    value: "Enabled"
                )

                settingRow(
                    icon: "doc.text",
                    title: "Topics",
                    value: "6 configured"
                )
            }
            .padding()

            Spacer()

            // Action buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .glassButton(style: .secondary)

                Button("Start Session") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .glassButton(isActive: true, style: .primary)
            }
            .padding()
        }
        .frame(width: 400, height: 350)
        .glassSheet()
    }

    private func settingRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            Text(title)
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .liquidGlass(
            material: .thin,
            cornerRadius: CornerRadius.medium,
            borderStyle: .subtle,
            enableHover: true
        )
    }
}

// MARK: - Example: All Glass Materials Preview

/// Preview showing all glass material variants side by side
struct GlassMaterialsPreview: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("Glass Material Variants")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: Spacing.md) {
                materialSample(.ultraThin, "Ultra Thin")
                materialSample(.thin, "Thin")
                materialSample(.regular, "Regular")
                materialSample(.thick, "Thick")
                materialSample(.chrome, "Chrome")
            }
        }
        .padding()
    }

    private func materialSample(_ material: GlassMaterial, _ name: String) -> some View {
        VStack(spacing: Spacing.sm) {
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 40)

            Text(name)
                .font(.caption)
                .foregroundColor(.white)
        }
        .frame(width: 80, height: 100)
        .liquidGlass(
            material: material,
            cornerRadius: CornerRadius.large,
            borderStyle: .standard
        )
    }
}

// MARK: - Example: Border Styles Preview

/// Preview showing all glass border style variants
struct GlassBorderStylesPreview: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("Border Style Variants")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: Spacing.md) {
                borderSample(.none, "None")
                borderSample(.subtle, "Subtle")
                borderSample(.standard, "Standard")
                borderSample(.rainbow, "Rainbow")
                borderSample(.accent(.blue), "Accent")
            }
        }
        .padding()
    }

    private func borderSample(_ style: GlassBorderStyle, _ name: String) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(.white)

            Text(name)
                .font(.caption)
                .foregroundColor(.white)
        }
        .frame(width: 80, height: 80)
        .liquidGlass(
            material: .regular,
            cornerRadius: CornerRadius.medium,
            borderStyle: style
        )
    }
}

// MARK: - Full Demo Preview

struct LiquidGlassExamples_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Vibrant gradient background to show glass effects
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.8),
                    Color(red: 0.2, green: 0.4, blue: 0.9),
                    Color(red: 0.1, green: 0.6, blue: 0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 40) {
                    // Materials preview
                    GlassMaterialsPreview()

                    // Border styles preview
                    GlassBorderStylesPreview()

                    // Coaching prompt
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Coaching Prompt (.glassFloating)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        GlassCoachingPromptExample()
                    }

                    // Topic cards
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Topic Cards (.glassCard)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        VStack(spacing: 8) {
                            GlassTopicCardExample(topic: "User Goals", status: .deepDive, isSelected: true)
                            GlassTopicCardExample(topic: "Pain Points", status: .explored, isSelected: false)
                            GlassTopicCardExample(topic: "Workflow", status: .mentioned, isSelected: false)
                            GlassTopicCardExample(topic: "Features", status: .notStarted, isSelected: false)
                        }
                        .frame(width: 300)
                    }

                    // Toolbar
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Session Toolbar (.glassToolbar)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        GlassSessionToolbarExample()
                            .frame(width: 500)
                    }

                    // Buttons row
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Button Styles (.glassButton)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        HStack(spacing: 12) {
                            Button("Primary") {}
                                .buttonStyle(.plain)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .glassButton(isActive: true, style: .primary)

                            Button("Secondary") {}
                                .buttonStyle(.plain)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .glassButton(style: .secondary)

                            Button("Destructive") {}
                                .buttonStyle(.plain)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .glassButton(style: .destructive)
                        }
                    }
                }
                .padding(40)
            }
        }
        .frame(width: 700, height: 900)
        .preferredColorScheme(.dark)
        .previewDisplayName("Liquid Glass Components")
    }
}
