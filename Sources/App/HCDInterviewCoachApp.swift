import SwiftUI

@main
struct HCDInterviewCoachApp: App {
    // MARK: - State
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        // Main window
        WindowGroup("HCD Interview Coach") {
            ContentView()
                .environmentObject(settings)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Preferences...") {
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        // Settings window
        Settings {
            SettingsView()
                .environmentObject(settings)
        }
    }
}

// MARK: - Content View (Placeholder)
struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("HCD Interview Coach")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Getting Started")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(.blue)
                        Text("Complete the audio setup wizard")
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(.blue)
                        Text("Configure your OpenAI API key in Settings")
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(.blue)
                        Text("Start your first interview session")
                    }
                }
            }
            .padding(16)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)

            Button(action: openSettings) {
                HStack {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }

    private func openSettings() {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}

#Preview {
    ContentView()
}
