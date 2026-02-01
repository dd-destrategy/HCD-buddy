import SwiftUI

/// Coaching settings view
/// Provides options to enable/disable coaching and configure prompt behavior
struct CoachingSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var showPromptPreview: Bool = false
    @State private var showResetConfirmation: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable Coaching", isOn: $settings.coachingEnabled)
                        .help("Enable AI-powered coaching prompts during interviews")

                    Text("When enabled, the coach will provide real-time prompts to help you ask better interview questions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if settings.coachingEnabled {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Auto-Dismiss Time")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            Slider(
                                value: $settings.autoDismissTime,
                                in: 5 ... 15,
                                step: 0.5
                            )

                            HStack {
                                Text("5 seconds")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(settings.autoDismissTimeFormatted)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("15 seconds")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Text("Coaching prompts will automatically dismiss after this duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Maximum Prompts Per Session")
                            .font(.headline)

                        HStack {
                            Button(action: decreaseMaxPrompts) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("Decrease maximum prompts")

                            Spacer()

                            Text(String(settings.maxPromptsPerSession))
                                .font(.headline)
                                .frame(width: 50)

                            Spacer()

                            Button(action: increaseMaxPrompts) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("Increase maximum prompts")
                        }

                        Text("The coach will show up to this many prompts during a single session (minimum 1, maximum 5)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: { showPromptPreview = true }) {
                            HStack {
                                Image(systemName: "eye")
                                Text("Preview Coaching Prompt")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .help("See an example of what coaching prompts look like")

                        Text("This is a simulation of a coaching prompt that appears during interviews")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Button(action: { showResetConfirmation = true }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to Defaults")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .help("Reset all coaching settings to their default values")

                    Text("This will reset coaching settings to recommended defaults")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(24)
        }
        .sheet(isPresented: $showPromptPreview) {
            CoachingPromptPreviewView(isPresented: $showPromptPreview)
        }
        .alert("Reset Coaching Settings?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetToDefaults()
            }
        } message: {
            Text("This will reset auto-dismiss time to 8 seconds and maximum prompts to 3. This action cannot be undone.")
        }
    }

    private func increaseMaxPrompts() {
        if settings.maxPromptsPerSession < 5 {
            settings.maxPromptsPerSession += 1
        }
    }

    private func decreaseMaxPrompts() {
        if settings.maxPromptsPerSession > 1 {
            settings.maxPromptsPerSession -= 1
        }
    }

    private func resetToDefaults() {
        settings.autoDismissTime = 8.0
        settings.maxPromptsPerSession = 3
    }
}

// MARK: - Coaching Prompt Preview View
struct CoachingPromptPreviewView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Coaching Prompt Preview")
                    .font(.headline)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "brain.fill")
                        .font(.title2)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Coaching Tip")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.semibold)

                        Text("Interviewer")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Text("You haven't asked about the candidate's experience with distributed systems. Consider asking: \"Tell me about a project where you worked with distributed systems. What challenges did you face?\"")
                    .font(.body)
                    .lineLimit(nil)

                HStack {
                    Spacer()
                    Text("This prompt will auto-dismiss in 8s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("Coaching prompts appear during your interviews to help you:")
                    .font(.caption)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Cover all important topics")
                            .font(.caption)
                    }

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Ask follow-up questions")
                            .font(.caption)
                    }

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Avoid common interviewing pitfalls")
                            .font(.caption)
                    }
                }
            }
            .padding(12)
            .background(Color(.controlBackgroundColor).opacity(0.5))
            .cornerRadius(6)

            Spacer()

            HStack {
                Spacer()
                Button("Close") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(width: 450, height: 500)
    }
}

#Preview {
    CoachingSettingsView()
        .environmentObject(AppSettings())
}
