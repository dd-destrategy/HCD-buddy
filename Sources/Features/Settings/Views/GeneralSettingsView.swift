import SwiftUI

/// General settings view
/// Provides options for default session mode, launch at login, and update checks
/// Enhanced with Liquid Glass UI styling
struct GeneralSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                // Session Mode Section
                SettingsSection(title: "Default Session Mode") {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Picker("Session Mode", selection: $settings.defaultSessionMode) {
                            ForEach(SessionMode.allCases, id: \.self) { mode in
                                Text(mode.displayName)
                                    .tag(mode.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text("Choose the default interview mode for new sessions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Launch Settings Section
                SettingsSection(title: "Startup") {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SettingsToggleRow(
                            title: "Launch at Login",
                            description: "The app will start in the background on login",
                            isOn: $settings.launchAtLogin,
                            helpText: "Automatically launch HCD Interview Coach when you log in"
                        )

                        Divider()
                            .opacity(0.5)

                        SettingsToggleRow(
                            title: "Check for Updates Automatically",
                            description: "You will be notified when updates are available",
                            isOn: $settings.checkForUpdates,
                            helpText: "Automatically check for new versions when the app launches"
                        )
                    }
                }

                // Keyboard Shortcuts Section
                SettingsSection(title: "Keyboard Shortcuts") {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        KeyboardShortcutRow(action: "Open Settings", shortcut: "Cmd+,")
                        KeyboardShortcutRow(action: "Start/Stop Session", shortcut: "Cmd+S")
                        KeyboardShortcutRow(action: "Flag Insight", shortcut: "Cmd+I")
                        KeyboardShortcutRow(action: "Show Keyboard Shortcuts", shortcut: "Cmd+?")
                    }
                }

                // Link to full guide
                Link(destination: URL(string: "https://support.hcdinterviewcoach.com/shortcuts")!) {
                    HStack {
                        Text("View Full Keyboard Shortcuts Guide")
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal, Spacing.lg)

                Spacer()
            }
            .padding(Spacing.xl)
        }
    }
}

// MARK: - Settings Section Container

/// A reusable glass card container for settings sections
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .glassCard()
    }
}

// MARK: - Settings Toggle Row

/// A toggle row with title and description for settings
struct SettingsToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    var helpText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Toggle(title, isOn: $isOn)
                .help(helpText ?? "")

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Keyboard Shortcut Row

/// A row displaying a keyboard shortcut
struct KeyboardShortcutRow: View {
    let action: String
    let shortcut: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            Text(action)
                .font(.subheadline)
            Spacer()
            Text(shortcut)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(colorScheme == .dark
                            ? Color.white.opacity(0.08)
                            : Color.black.opacity(0.05))
                )
        }
        .padding(.vertical, Spacing.xs)
    }
}

#Preview {
    GeneralSettingsView()
        .environmentObject(AppSettings())
        .frame(width: 500, height: 500)
}
