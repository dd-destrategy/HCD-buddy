import SwiftUI
import SwiftData

@main
struct HCDInterviewCoachApp: App {
    @StateObject private var serviceContainer = ServiceContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serviceContainer)
                .modelContainer(serviceContainer.dataManager.container)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About HCD Interview Coach") {
                    showAboutWindow()
                }
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
