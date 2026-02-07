import SwiftUI

struct ContentView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @State private var activeSessionConfig: SessionConfiguration?
    @State private var showAudioSetupWizard = false
    @State private var isAudioSetupIncomplete = AudioSetupLaunchHelper.isAudioSetupSkipped
    @State private var showDemoMode = false
    @State private var showAnalyticsDashboard = false

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
                if showDemoMode {
                    // Demo Mode (Feature 8)
                    DemoModeView(
                        onExit: {
                            withAnimation {
                                showDemoMode = false
                            }
                        }
                    )
                } else if showAnalyticsDashboard {
                    // Cross-Session Analytics (Feature 3)
                    CrossSessionAnalyticsView(
                        studyManager: StudyManager(),
                        analytics: CrossSessionAnalytics(),
                        onDismiss: {
                            withAnimation {
                                showAnalyticsDashboard = false
                            }
                        }
                    )
                } else if let sessionConfig = activeSessionConfig {
                    // Active session view with integrated features
                    ActiveSessionPlaceholderView(
                        sessionConfig: sessionConfig,
                        onEndSession: {
                            activeSessionConfig = nil
                        }
                    )
                } else {
                    // Session setup view with demo + analytics entry points
                    VStack(spacing: 0) {
                        SessionSetupView(
                            templateManager: serviceContainer.templateManager,
                            onStartSession: { template, mode in
                                startSession(template: template, mode: mode)
                            }
                        )

                        // Quick actions bar
                        HStack(spacing: Spacing.md) {
                            Button(action: {
                                withAnimation { showDemoMode = true }
                            }) {
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: "play.circle")
                                    Text("Try Demo")
                                }
                                .font(Typography.caption)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("Try demo mode")
                            .accessibilityHint("Explore the app with sample interview data")

                            Button(action: {
                                withAnimation { showAnalyticsDashboard = true }
                            }) {
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: "chart.bar")
                                    Text("Analytics")
                                }
                                .font(Typography.caption)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("View cross-session analytics")
                            .accessibilityHint("Opens the analytics dashboard for research studies")

                            Spacer()
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                    }
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
    @StateObject private var focusModeManager = FocusModeManager()
    @StateObject private var talkTimeAnalyzer = TalkTimeAnalyzer()
    @StateObject private var questionTypeAnalyzer = QuestionTypeAnalyzer()
    @StateObject private var followUpSuggester = FollowUpSuggester()

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar: Focus Mode + Talk-Time + Session Controls
            HStack(spacing: Spacing.md) {
                // Focus Mode Picker (Feature 4)
                FocusModePickerView(
                    manager: focusModeManager,
                    isCompact: true
                )

                Spacer()

                // Talk-Time Indicator (Feature 1)
                if focusModeManager.panelVisibility.showTalkTime {
                    TalkTimeIndicatorView(
                        analyzer: talkTimeAnalyzer,
                        isExpanded: false
                    )
                    .frame(width: 200)
                }

                // Session info
                HStack(spacing: Spacing.md) {
                    Text(sessionConfig.template.name)
                        .font(Typography.caption)
                        .foregroundColor(.secondary)

                    Text(formatElapsedTime(elapsedTime))
                        .font(Typography.body)
                        .fontWeight(.medium)
                        .monospacedDigit()

                    Button(action: {
                        timer?.invalidate()
                        onEndSession()
                    }) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "stop.circle.fill")
                            Text("End")
                        }
                        .font(Typography.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.small)
                    .accessibilityLabel("End session")
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(Color(.controlBackgroundColor))

            // Main content area with conditional panels
            HStack(spacing: 0) {
                // Left: Transcript area (always visible in all modes)
                VStack(spacing: Spacing.md) {
                    Text("Transcript")
                        .font(Typography.body)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.md)

                    // Talk-Time expanded (Feature 1)
                    if focusModeManager.panelVisibility.showTalkTime {
                        TalkTimeIndicatorView(
                            analyzer: talkTimeAnalyzer,
                            isExpanded: true
                        )
                        .padding(.horizontal, Spacing.md)
                    }

                    // Question Type Analysis (Feature 2) - in coached/analysis modes
                    if focusModeManager.panelVisibility.showCoaching {
                        QuestionTypeView(analyzer: questionTypeAnalyzer)
                            .padding(.horizontal, Spacing.md)
                    }

                    Spacer()

                    Text("Session in progress \u{2014} transcript will appear here during live sessions")
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(Spacing.lg)

                    Spacer()
                }
                .frame(maxWidth: .infinity)

                // Right sidebar: Topics + Insights + Follow-Up Suggestions
                if focusModeManager.panelVisibility.showTopics || focusModeManager.panelVisibility.showInsights {
                    Divider()

                    VStack(spacing: Spacing.md) {
                        // Topics panel
                        if focusModeManager.panelVisibility.showTopics {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Topics")
                                    .font(Typography.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)

                                ForEach(sessionConfig.template.topics, id: \.self) { topic in
                                    HStack(spacing: Spacing.xs) {
                                        Image(systemName: "circle")
                                            .font(.system(size: 8))
                                            .foregroundColor(.secondary)
                                        Text(topic)
                                            .font(Typography.caption)
                                    }
                                }
                            }
                            .padding(Spacing.md)
                        }

                        // Follow-Up Suggestions (Feature 7) - in coaching modes
                        if focusModeManager.panelVisibility.showCoaching {
                            FollowUpSuggestionView(suggester: followUpSuggester)
                                .padding(.horizontal, Spacing.sm)
                        }

                        Spacer()
                    }
                    .frame(width: 260)
                }
            }
        }
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

#Preview("Demo Mode") {
    DemoModeView(onExit: {})
        .frame(minWidth: 800, minHeight: 600)
}

