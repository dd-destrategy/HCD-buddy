import SwiftUI

struct ContentView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer

    var body: some View {
        SessionSetupView(templateManager: serviceContainer.templateManager)
            .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView()
        .environmentObject(ServiceContainer())
}
