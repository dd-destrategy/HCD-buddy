import SwiftUI
import SwiftData
#if canImport(AppKit)
import AppKit
#endif

@main
struct HCDInterviewCoachApp: App {
    @StateObject private var serviceContainer = ServiceContainer()
    #if os(macOS)
    @State private var showAudioSetupFromMenu = false
    #endif
    @State private var showAboutSheet = false

    var body: some Scene {
        WindowGroup {
            contentView
                #if os(macOS)
                .audioSetupSheet(
                    isPresented: $showAudioSetupFromMenu,
                    onComplete: {
                        // Setup completed from Settings re-entry
                    }
                )
                #endif
                #if os(iOS)
                .sheet(isPresented: $showAboutSheet) {
                    aboutSheetView
                }
                #endif
        }
        #if os(macOS)
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
        #endif
    }

    @ViewBuilder
    private var contentView: some View {
        if let container = serviceContainer.dataManager.container {
            ContentView()
                .environmentObject(serviceContainer)
                .modelContainer(container)
        } else {
            ContentView()
                .environmentObject(serviceContainer)
        }
    }

    #if os(macOS)
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
    #endif

    #if os(iOS)
    private var aboutSheetView: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "waveform.and.mic")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)

                Text("HCD Interview Coach")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0") (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("A real-time interview coaching tool for HCD researchers.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showAboutSheet = false
                    }
                }
            }
        }
    }
    #endif
}
