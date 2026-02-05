import SwiftUI

/// Main Settings window with tabbed interface
/// Provides access to General, Audio, Coaching, and API settings
/// Enhanced with Liquid Glass UI styling
struct SettingsView: View {
    @StateObject private var settings = AppSettings()
    @Environment(\.colorScheme) private var colorScheme

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
        .frame(width: 520, height: 480)
        .background(settingsBackground)
        .environmentObject(settings)
    }

    @ViewBuilder
    private var settingsBackground: some View {
        ZStack {
            // Subtle gradient background
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(white: 0.08), Color(white: 0.12)]
                    : [Color(white: 0.94), Color(white: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Glass overlay for depth
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SettingsView()
}
