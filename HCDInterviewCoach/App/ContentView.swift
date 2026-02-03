import SwiftUI

struct ContentView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @State private var activeSessionConfig: SessionConfiguration?
    
    var body: some View {
        Group {
            if let sessionConfig = activeSessionConfig {
                // Active session view - placeholder for now
                ActiveSessionPlaceholderView(
                    sessionConfig: sessionConfig,
                    onEndSession: {
                        activeSessionConfig = nil
                    }
                )
            } else {
                // Session setup view
                SessionSetupView(
                    templateManager: serviceContainer.templateManager,
                    onStartSession: { template, mode in
                        startSession(template: template, mode: mode)
                    }
                )
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .environmentObject(serviceContainer)
    }
    
    private func startSession(template: InterviewTemplate, mode: SessionMode) {
        // Create session configuration
        let config = SessionConfiguration(
            template: template,
            mode: mode,
            startedAt: Date()
        )
        
        activeSessionConfig = config
        
        AppLogger.shared.info("Starting session with template: \(template.name)")
        AppLogger.shared.info("Session mode: \(mode.displayName)")
    }
}

// MARK: - Session Configuration

struct SessionConfiguration: Identifiable {
    let id = UUID()
    let template: InterviewTemplate
    let mode: SessionMode
    let startedAt: Date
}

// MARK: - Active Session Placeholder View

struct ActiveSessionPlaceholderView: View {
    let sessionConfig: SessionConfiguration
    let onEndSession: () -> Void

    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Active Session")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(sessionConfig.template.name)
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Session info
            VStack(spacing: 16) {
                HStack(spacing: 40) {
                    VStack {
                        Text("Mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(sessionConfig.mode.displayName)
                            .font(.headline)
                    }
                    
                    VStack {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(sessionConfig.template.duration) min")
                            .font(.headline)
                    }
                    
                    VStack {
                        Text("Elapsed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatElapsedTime(elapsedTime))
                            .font(.headline)
                            .monospacedDigit()
                    }
                }
                .padding(24)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(12)
                
                // Topics
                VStack(alignment: .leading, spacing: 12) {
                    Text("Topics to Cover")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(sessionConfig.template.topics, id: \.self) { topic in
                            HStack {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary)
                                Text(topic)
                            }
                        }
                    }
                }
                .frame(maxWidth: 500)
                .padding(20)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(12)
            }
            
            Spacer()
            
            // Controls
            VStack(spacing: 12) {
                Text("Session in progress...")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Button(action: onEndSession) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("End Session")
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding(40)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func startTimer() {
        // Invalidate any existing timer first
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                elapsedTime += 1
            }
        }
    }
    
    private func formatElapsedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview("Setup") {
    ContentView()
        .environmentObject(ServiceContainer())
}
#Preview("Active Session") {
    let config = SessionConfiguration(
        template: InterviewTemplate(
            name: "Discovery Interview",
            description: "Test",
            duration: 60,
            topics: ["Background", "Workflow", "Pain points"]
        ),
        mode: .full,
        startedAt: Date()
    )
    
    return ActiveSessionPlaceholderView(
        sessionConfig: config,
        onEndSession: {}
    )
    .frame(minWidth: 800, minHeight: 600)
}

