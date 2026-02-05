import SwiftUI

/// Coaching settings view
/// Provides options to enable/disable coaching and configure prompt behavior
/// Enhanced with Liquid Glass UI styling
struct CoachingSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var showPromptPreview: Bool = false
    @State private var showResetConfirmation: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                // Enable Coaching Section
                SettingsSection(title: "Coaching Mode") {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Toggle("Enable Coaching", isOn: $settings.coachingEnabled)
                            .help("Enable AI-powered coaching prompts during interviews")

                        Text("When enabled, the coach will provide real-time prompts to help you ask better interview questions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if settings.coachingEnabled {
                    // Auto-Dismiss Section
                    SettingsSection(title: "Auto-Dismiss Time") {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Slider(
                                value: $settings.autoDismissTime,
                                in: 5 ... 15,
                                step: 0.5
                            )
                            .accentColor(.accentColor)

                            HStack {
                                Text("5 seconds")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(settings.autoDismissTimeFormatted)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.accentColor)
                                Spacer()
                                Text("15 seconds")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text("Coaching prompts will automatically dismiss after this duration")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Max Prompts Section
                    SettingsSection(title: "Maximum Prompts Per Session") {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                Button(action: decreaseMaxPrompts) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(settings.maxPromptsPerSession > 1 ? .accentColor : .secondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("Decrease maximum prompts")
                                .disabled(settings.maxPromptsPerSession <= 1)

                                Spacer()

                                Text(String(settings.maxPromptsPerSession))
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .frame(width: 60)
                                    .padding(.vertical, Spacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                                            .fill(colorScheme == .dark
                                                ? Color.white.opacity(0.05)
                                                : Color.black.opacity(0.03))
                                    )

                                Spacer()

                                Button(action: increaseMaxPrompts) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(settings.maxPromptsPerSession < 5 ? .accentColor : .secondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("Increase maximum prompts")
                                .disabled(settings.maxPromptsPerSession >= 5)
                            }

                            Text("The coach will show up to this many prompts during a single session (minimum 1, maximum 5)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Preview Button Section
                    SettingsSection(title: "Preview") {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Button(action: { showPromptPreview = true }) {
                                HStack {
                                    Image(systemName: "eye")
                                    Text("Preview Coaching Prompt")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.sm)
                            }
                            .glassButton(style: .secondary)
                            .help("See an example of what coaching prompts look like")

                            Text("This is a simulation of a coaching prompt that appears during interviews")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Reset Section
                SettingsSection(title: "Reset") {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Button(action: { showResetConfirmation = true }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset to Defaults")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                        }
                        .glassButton(style: .secondary)
                        .help("Reset all coaching settings to their default values")

                        Text("This will reset coaching settings to recommended defaults")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(Spacing.xl)
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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Header
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

            // Sample Coaching Prompt
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "brain.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)

                    VStack(alignment: .leading, spacing: 2) {
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
            .padding(Spacing.lg)
            .glassFloating(isActive: true)

            // Benefits List
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Coaching prompts appear during your interviews to help you:")
                    .font(.caption)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    BenefitRow(icon: "checkmark.circle.fill", text: "Cover all important topics")
                    BenefitRow(icon: "checkmark.circle.fill", text: "Ask follow-up questions")
                    BenefitRow(icon: "checkmark.circle.fill", text: "Avoid common interviewing pitfalls")
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(colorScheme == .dark
                        ? Color.white.opacity(0.03)
                        : Color.black.opacity(0.02))
            )

            Spacer()

            // Close Button
            HStack {
                Spacer()
                Button("Close") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                .glassButton(style: .secondary)
            }
        }
        .padding(Spacing.xl)
        .frame(width: 450, height: 500)
        .glassSheet()
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(.green)
            Text(text)
                .font(.caption)
        }
    }
}

#Preview {
    CoachingSettingsView()
        .environmentObject(AppSettings())
        .frame(width: 500, height: 600)
}
