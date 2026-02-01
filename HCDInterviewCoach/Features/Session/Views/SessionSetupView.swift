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

                    Text("Select a template and configure your session")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(.controlBackgroundColor))

                // Scrollable content
                ScrollView {
                    VStack(spacing: 16) {
                        // Template selector
                        TemplateSelector(
                            selectedTemplate: $selectedTemplate,
                            templateManager: templateManager
                        )

                        // Session mode selector
                        if selectedTemplate != nil {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Interview Configuration")
                                    .font(.headline)

                                SessionModeSelector(selectedMode: $selectedMode)

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

                            Button(action: startSession) {
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                    Text("Start Session")
                                }
                            }
                            .buttonStyle(.borderedProminent)
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
    }

    private func startSession() {
        // TODO: Navigate to active session view with selected template and mode
        print("Starting session with template: \(selectedTemplate?.name ?? "Unknown")")
        print("Session mode: \(selectedMode.displayName)")
    }
}

// MARK: - Preview

#Preview {
    SessionSetupView(templateManager: TemplateManager())
        .frame(minWidth: 600, minHeight: 800)
}
