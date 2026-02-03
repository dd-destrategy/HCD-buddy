import SwiftUI

struct ContentView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @State private var activeSessionConfig: SessionConfiguration?
    @State private var showAudioSetupWizard = false
    @State private var isAudioSetupIncomplete = AudioSetupLaunchHelper.isAudioSetupSkipped

    var body: some View {
        VStack(spacing: 0) {
            // Incomplete audio setup banner
            if isAudioSetupIncomplete {
                AudioSetupIncompleteBanner(
                    onSetupNow: {
                        showAudioSetupWizard = true
                    },
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isAudioSetupIncomplete = false
                        }
                    }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

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
        }
        .frame(minWidth: 800, minHeight: 600)
        .environmentObject(serviceContainer)
        .audioSetupSheet(
            isPresented: $showAudioSetupWizard,
            onComplete: {
                withAnimation {
                    isAudioSetupIncomplete = false
                }
            },
            onSkipSetup: {
                // Already skipped, keep banner visible
            }
        )
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
                
                Button(action: {
                    timer?.invalidate()
                    onEndSession()
                }) {
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
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
        }
    }
    
    private func formatElapsedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Audio Setup Incomplete Banner

/// A subtle, dismissable banner indicating that audio setup was skipped.
/// Provides a one-tap path back into the setup wizard.
struct AudioSetupIncompleteBanner: View {
    let onSetupNow: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(Typography.body)
                .foregroundColor(.orange)
                .accessibilityHidden(true)

            Text("Audio setup incomplete \u{2014} running in limited mode.")
                .font(Typography.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button(action: onSetupNow) {
                Text("Set Up Now")
                    .font(Typography.caption)
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("Open audio setup wizard")
            .accessibilityHint("Launches the audio setup wizard to configure full audio capture")

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss audio setup banner")
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(Color.orange.opacity(0.08))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.orange.opacity(0.15)),
            alignment: .bottom
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Audio setup is incomplete. The app is running in limited mode.")
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

