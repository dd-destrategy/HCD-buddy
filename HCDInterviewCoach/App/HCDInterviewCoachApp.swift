import SwiftUI
import SwiftData

@main
struct HCDInterviewCoachApp: App {
    @StateObject private var serviceContainer = ServiceContainer()
    @State private var showAudioSetupFromMenu = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serviceContainer)
                .modelContainer(serviceContainer.dataManager.container)
                .audioSetupSheet(
                    isPresented: $showAudioSetupFromMenu,
                    onComplete: {
                        // Setup completed from Settings re-entry
                    }
                )
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About HCD Interview Coach") {
                    showAboutWindow()
                }
            }

            // Settings > Audio Setup command for re-entering the wizard
            CommandGroup(after: .appSettings) {
                Button("Audio Setup Wizard...") {
                    AudioSetupLaunchHelper.clearSkipState()
                    showAudioSetupFromMenu = true
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])
            }
        }
    }

    private func showAboutWindow() {
        NSApplication.shared.orderFrontStandardAboutPanel(options: [
            .applicationName: "HCD Interview Coach",
            .applicationVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0",
            .version: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1",
            .credits: NSAttributedString(
                string: "A real-time interview coaching tool for HCD researchers.",
                attributes: [
                    .font: NSFont.systemFont(ofSize: 11),
                    .foregroundColor: NSColor.secondaryLabelColor
                ]
            )
        ])
    }
}
