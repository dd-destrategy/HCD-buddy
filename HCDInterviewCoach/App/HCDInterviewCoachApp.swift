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
                    // TODO: Show about window
                }
            }
        }
    }
}
