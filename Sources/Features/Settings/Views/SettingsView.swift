import SwiftUI

/// Main Settings window with tabbed interface
/// Provides access to General, Audio, Coaching, and API settings
struct SettingsView: View {
    @StateObject private var settings = AppSettings()

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag("general")

            AudioSettingsView()
                .tabItem {
                    Label("Audio", systemImage: "speaker.wave.2")
                }
                .tag("audio")

            CoachingSettingsView()
                .tabItem {
                    Label("Coaching", systemImage: "brain")
                }
                .tag("coaching")

            APISettingsView()
                .tabItem {
                    Label("API", systemImage: "key")
                }
                .tag("api")
        }
        .frame(width: 500, height: 400)
        .environmentObject(settings)
    }
}

#Preview {
    SettingsView()
}
