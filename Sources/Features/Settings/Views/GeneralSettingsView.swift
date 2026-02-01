import SwiftUI

/// General settings view
/// Provides options for default session mode, launch at login, and update checks
struct GeneralSettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Default Session Mode")
                        .font(.headline)

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

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                        .help("Automatically launch HCD Interview Coach when you log in")

                    Text("The app will start in the background on login")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Check for Updates Automatically", isOn: $settings.checkForUpdates)
                        .help("Automatically check for new versions when the app launches")

                    Text("You will be notified when updates are available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Keyboard Shortcuts")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Open Settings")
                            Spacer()
                            Text("⌘,")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Start/Stop Session")
                            Spacer()
                            Text("⌘S")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Flag Insight")
                            Spacer()
                            Text("⌘I")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Show Keyboard Shortcuts")
                            Spacer()
                            Text("⌘?")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(6)

                    Link(destination: URL(string: "https://support.hcdinterviewcoach.com/shortcuts")!) {
                        HStack {
                            Text("View Full Keyboard Shortcuts Guide")
                                .foregroundColor(.blue)
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                    .font(.caption)
                }

                Spacer()
            }
            .padding(24)
        }
    }
}

#Preview {
    GeneralSettingsView()
        .environmentObject(AppSettings())
}
