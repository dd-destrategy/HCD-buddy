import SwiftUI

/// Displays consent disclosure text based on variant and session mode
struct ConsentTemplateView: View {
    let variant: ConsentVariant
    let sessionMode: SessionMode

    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            VStack(alignment: .leading, spacing: 4) {
                Text("Consent Disclosure")
                    .font(.headline)
                Text(variant.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Consent text display
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    Text(consentText)
                        .font(.body)
                        .lineSpacing(4)
                        .padding(12)
                }
                .frame(minHeight: 150)
                .background(PlatformColor.controlBackground)
                .cornerRadius(8)
                .border(Color.secondary.opacity(0.3), width: 1)
            }

            // Copy button
            HStack {
                Button(action: copyToClipboard) {
                    HStack {
                        Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        Text(isCopied ? "Copied!" : "Copy to Clipboard")
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isCopied ? Color.green : Color.blue)
                .cornerRadius(6)

                Spacer()
            }

            Spacer()
        }
        .padding(16)
    }

    // MARK: - Private Methods

    private var consentText: String {
        switch variant {
        case .standard:
            return standardConsentText()
        case .minimal:
            return minimalConsentText()
        case .research:
            return researchConsentText()
        }
    }

    private func standardConsentText() -> String {
        "This interview will be recorded and transcribed using AI assistance. The AI helps me stay focused but does not participate in the conversation. Your responses will be stored securely and used only for research purposes.\n\nDo you have any questions before we begin?"
    }

    private func minimalConsentText() -> String {
        "This interview will be recorded and transcribed. The transcript helps me ensure I capture your thoughts accurately."
    }

    private func researchConsentText() -> String {
        """
        This session will be recorded and transcribed using AI transcription. The AI processes audio in real-time but does not store data beyond the session. Transcripts will be stored securely and retained for 12 months. You may request deletion of your data at any time.

        This research is being conducted to improve our interview techniques and understand user needs better.

        Do you have any questions before we begin?
        """
    }

    private func copyToClipboard() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(consentText, forType: .string)
        #else
        UIPasteboard.general.string = consentText
        #endif

        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCopied = false
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ConsentTemplateView(variant: .standard, sessionMode: .full)
        Divider()
        ConsentTemplateView(variant: .minimal, sessionMode: .transcriptionOnly)
        Divider()
        ConsentTemplateView(variant: .research, sessionMode: .full)
    }
    .padding()
}
