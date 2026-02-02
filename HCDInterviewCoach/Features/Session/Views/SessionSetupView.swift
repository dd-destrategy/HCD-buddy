import SwiftUI

/// Main session setup view integrating template selection, mode selection, and consent disclosure
struct SessionSetupView: View {
    @ObservedObject var templateManager: TemplateManager

    @State private var selectedTemplate: InterviewTemplate?
    @State private var selectedMode: SessionMode = .full

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Start New Session")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .accessibilityAddTraits(.isHeader)

                    Text("Select a template and configure your session")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(.controlBackgroundColor))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Start New Session. Select a template and configure your session.")

                // Scrollable content
                ScrollView {
                    VStack(spacing: 16) {
                        // Template selector
                        TemplateSelector(
                            selectedTemplate: $selectedTemplate,
                            templateManager: templateManager
                        )
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Template selection")
                        .accessibilityHint("Choose an interview template to use for this session")

                        // Session mode selector
                        if selectedTemplate != nil {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Interview Configuration")
                                    .font(.headline)
                                    .accessibilityAddTraits(.isHeader)

                                SessionModeSelector(selectedMode: $selectedMode)
                                    .accessibilityElement(children: .contain)
                                    .accessibilityLabel("Session mode selection")
                                    .accessibilityHint("Choose the recording mode for this interview session")

                                // Template topics display
                                if let template = selectedTemplate {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Topics to Cover")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)

                                        VStack(alignment: .leading, spacing: 4) {
                                            ForEach(template.topics, id: \.self) { topic in
                                                HStack(spacing: 8) {
                                                    Image(systemName: "checkmark.circle")
                                                        .foregroundColor(.blue)
                                                        .font(.body)

                                                    Text(topic)
                                                        .font(.body)
                                                        .foregroundColor(.primary)

                                                    Spacer()
                                                }
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                            }
                                        }
                                        .padding(12)
                                        .background(Color(.controlBackgroundColor))
                                        .cornerRadius(6)
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                        }

                        // Consent disclosure
                        if let template = selectedTemplate {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Consent & Disclosure")
                                    .font(.headline)

                                ConsentTemplateView(
                                    variant: template.consentVariant,
                                    sessionMode: selectedMode
                                )
                            }
                        }

                        Spacer()
                            .frame(height: 20)
                    }
                    .padding(16)
                }

                // Footer with action button
                VStack(spacing: 12) {
                    Divider()

                    if selectedTemplate != nil {
                        HStack(spacing: 12) {
                            Button(action: { selectedTemplate = nil }) {
                                Text("Back")
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("Back")
                            .accessibilityHint("Return to template selection")

                            Button(action: startSession) {
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                    Text("Start Session")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityLabel("Start Session")
                            .accessibilityHint("Begin the interview session with the selected template and mode")
                        }
                        .padding(16)
                    } else {
                        Text("Select a template to begin")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(16)
                    }
                }
            }
            .navigationTitle("Session Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Session Setup")
    }

    private func startSession() {
        // ISSUE-124: Session navigation integration pending
        // This will connect to the SessionCoordinator to start the active session view
        AppLogger.shared.info("Starting session with template: \(selectedTemplate?.name ?? "Unknown")")
        AppLogger.shared.info("Session mode: \(selectedMode.displayName)")
    }
}

// MARK: - Preview

#Preview {
    SessionSetupView(templateManager: TemplateManager())
        .frame(minWidth: 600, minHeight: 800)
}
