import SwiftUI

/// Main session setup view integrating template selection, mode selection, and consent disclosure
struct SessionSetupView: View {
    @ObservedObject var templateManager: TemplateManager
        let onStartSession: (InterviewTemplate, SessionMode) -> Void

    @State private var selectedTemplate: InterviewTemplate?
    @State private var selectedMode: SessionMode = .full

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Start New Session")
                        .font(Typography.display)
                        .accessibilityAddTraits(.isHeader)

                    Text("Select a template and configure your session")
                        .font(Typography.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.lg)
                .glassToolbar()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Start New Session. Select a template and configure your session.")

                // Scrollable content
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Template selector section
                        TemplateSelector(
                            selectedTemplate: $selectedTemplate,
                            templateManager: templateManager
                        )
                        .glassCard()
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Template selection")
                        .accessibilityHint("Choose an interview template to use for this session")

                        // Session mode selector
                        if selectedTemplate != nil {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Interview Configuration")
                                    .font(Typography.heading2)
                                    .accessibilityAddTraits(.isHeader)

                                SessionModeSelector(selectedMode: $selectedMode)
                                    .accessibilityElement(children: .contain)
                                    .accessibilityLabel("Session mode selection")
                                    .accessibilityHint("Choose the recording mode for this interview session")

                                // Template topics display
                                if let template = selectedTemplate {
                                    VStack(alignment: .leading, spacing: Spacing.sm) {
                                        Text("Topics to Cover")
                                            .font(Typography.heading3)

                                        VStack(alignment: .leading, spacing: Spacing.xs) {
                                            ForEach(template.topics, id: \.self) { topic in
                                                HStack(spacing: Spacing.sm) {
                                                    Image(systemName: "checkmark.circle")
                                                        .foregroundColor(.accentColor)
                                                        .font(Typography.body)

                                                    Text(topic)
                                                        .font(Typography.body)
                                                        .foregroundColor(.primary)

                                                    Spacer()
                                                }
                                                .padding(.horizontal, Spacing.sm)
                                                .padding(.vertical, Spacing.xs)
                                            }
                                        }
                                        .padding(Spacing.md)
                                        .liquidGlass(
                                            material: .thin,
                                            cornerRadius: CornerRadius.medium,
                                            borderStyle: .subtle,
                                            enableHover: false
                                        )
                                    }
                                }
                            }
                            .padding(Spacing.lg)
                            .glassCard()
                        }

                        // Consent disclosure
                        if let template = selectedTemplate {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Consent & Disclosure")
                                    .font(Typography.heading2)

                                ConsentTemplateView(
                                    variant: template.consentVariant,
                                    sessionMode: selectedMode
                                )
                            }
                            .padding(Spacing.lg)
                            .glassCard()
                        }

                        Spacer()
                            .frame(height: Spacing.xl)
                    }
                    .padding(Spacing.lg)
                }

                // Footer with action button
                VStack(spacing: Spacing.md) {
                    Divider()

                    if selectedTemplate != nil {
                        HStack(spacing: Spacing.md) {
                            Button(action: { selectedTemplate = nil }) {
                                Text("Back")
                                    .font(Typography.bodyMedium)
                                    .padding(.horizontal, Spacing.lg)
                                    .padding(.vertical, Spacing.sm)
                            }
                            .buttonStyle(.plain)
                            .glassButton(isActive: false, style: .secondary)
                            .accessibilityLabel("Back")
                            .accessibilityHint("Return to template selection")

                            Button(action: startSession) {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "play.circle.fill")
                                    Text("Start Session")
                                }
                                .font(Typography.bodyMedium)
                                .foregroundColor(.white)
                                .padding(.horizontal, Spacing.xl)
                                .padding(.vertical, Spacing.sm)
                            }
                            .buttonStyle(.plain)
                            .glassButton(isActive: true, style: .primary)
                            .accessibilityLabel("Start Session")
                            .accessibilityHint("Begin the interview session with the selected template and mode")
                        }
                        .padding(Spacing.lg)
                    } else {
                        Text("Select a template to begin")
                            .font(Typography.caption)
                            .foregroundColor(.secondary)
                            .padding(Spacing.lg)
                    }
                }
                .glassToolbar()
            }
            .navigationTitle("Session Setup")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Session Setup")
    }

    private func startSession() {
        guard let template = selectedTemplate else {
            AppLogger.shared.warning("Attempted to start session without template selected")
            return
        }
        
        AppLogger.shared.info("Starting session with template: \(template.name)")
        AppLogger.shared.info("Session mode: \(selectedMode.displayName)")
        
        // Call the navigation callback
        onStartSession(template, selectedMode)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // Background gradient to showcase glass effects
        LinearGradient(
            colors: [.blue.opacity(0.2), .purple.opacity(0.2), .cyan.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        SessionSetupView(
            templateManager: TemplateManager(),
            onStartSession: { template, mode in
                print("Starting session: \(template.name) in \(mode.displayName) mode")
            }
        )
    }
    .frame(minWidth: 600, minHeight: 800)
}
