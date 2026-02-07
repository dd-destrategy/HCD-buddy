import SwiftUI

struct ContentView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @State private var activeSessionConfig: SessionConfiguration?
    @State private var showAudioSetupWizard = false
    @State private var isAudioSetupIncomplete = AudioSetupLaunchHelper.isAudioSetupSkipped
    @State private var showDemoMode = false
    @State private var showAnalyticsDashboard = false
    @State private var showQuoteLibrary = false
    @State private var showParticipantPicker = false
    @State private var showConsentFlow = false
    @State private var selectedParticipant: Participant?

    // Batch 2 service instances (shared across setup + session)
    @StateObject private var calendarService = CalendarService()
    @StateObject private var participantManager = ParticipantManager()
    @StateObject private var consentTracker = ConsentTracker()
    @StateObject private var highlightService = HighlightService()

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
                } else if showQuoteLibrary {
                    // Quote Library (Feature E — Highlight Reel)
                    QuoteLibraryView(
                        highlightService: highlightService,
                        onDismiss: {
                            withAnimation {
                                showQuoteLibrary = false
                            }
                        }
                    )
                } else if let sessionConfig = activeSessionConfig {
                    // Active session view with integrated features
                    ActiveSessionPlaceholderView(
                        sessionConfig: sessionConfig,
                        highlightService: highlightService,
                        consentTracker: consentTracker,
                        onEndSession: {
                            activeSessionConfig = nil
                        }
                    )
                } else {
                    // Session setup view with all entry points
                    SessionSetupArea(
                        serviceContainer: serviceContainer,
                        calendarService: calendarService,
                        participantManager: participantManager,
                        selectedParticipant: $selectedParticipant,
                        showDemoMode: $showDemoMode,
                        showAnalyticsDashboard: $showAnalyticsDashboard,
                        showQuoteLibrary: $showQuoteLibrary,
                        showParticipantPicker: $showParticipantPicker,
                        showConsentFlow: $showConsentFlow,
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
        .sheet(isPresented: $showParticipantPicker) {
            ParticipantPickerView(
                participantManager: participantManager,
                onSelect: { participant in
                    selectedParticipant = participant
                    showParticipantPicker = false
                }
            )
            .frame(minWidth: 500, minHeight: 400)
        }
        .sheet(isPresented: $showConsentFlow) {
            ConsentFlowView(
                consentTracker: consentTracker,
                sessionId: activeSessionConfig?.id ?? UUID(),
                onComplete: { status in
                    showConsentFlow = false
                    AppLogger.shared.info("Consent completed with status: \(status.displayName)")
                },
                onDismiss: {
                    showConsentFlow = false
                }
            )
            .frame(minWidth: 600, minHeight: 500)
        }
    }

    private func startSession(template: InterviewTemplate, mode: SessionMode) {
        let config = SessionConfiguration(
            template: template,
            mode: mode,
            startedAt: Date(),
            participantId: selectedParticipant?.id,
            calendarEventId: nil
        )

        activeSessionConfig = config

        // Link participant to session if selected
        if let participantId = selectedParticipant?.id {
            participantManager.linkSession(config.id, to: participantId)
        }

        AppLogger.shared.info("Starting session with template: \(template.name)")
        AppLogger.shared.info("Session mode: \(mode.displayName)")
        if let participant = selectedParticipant {
            AppLogger.shared.info("Participant: \(participant.name)")
        }
    }
}

// MARK: - Session Configuration

struct SessionConfiguration: Identifiable {
    let id = UUID()
    let template: InterviewTemplate
    let mode: SessionMode
    let startedAt: Date
    var participantId: UUID?
    var calendarEventId: String?
}

// MARK: - Session Setup Area

/// Extracted session setup view with Calendar, Participants, and quick actions
struct SessionSetupArea: View {
    let serviceContainer: ServiceContainer
    @ObservedObject var calendarService: CalendarService
    @ObservedObject var participantManager: ParticipantManager
    @Binding var selectedParticipant: Participant?
    @Binding var showDemoMode: Bool
    @Binding var showAnalyticsDashboard: Bool
    @Binding var showQuoteLibrary: Bool
    @Binding var showParticipantPicker: Bool
    @Binding var showConsentFlow: Bool
    var onStartSession: (InterviewTemplate, SessionMode) -> Void

    var body: some View {
        VStack(spacing: 0) {
            SessionSetupView(
                templateManager: serviceContainer.templateManager,
                onStartSession: { template, mode in
                    onStartSession(template, mode)
                }
            )

            // Upcoming Interviews from Calendar (Feature B)
            if calendarService.authorizationStatus == .authorized && !calendarService.upcomingInterviews.isEmpty {
                UpcomingInterviewsView(
                    calendarService: calendarService,
                    onStartSession: { interview in
                        // Auto-select participant if found
                        if let participant = participantManager.findOrSuggest(from: interview) {
                            selectedParticipant = participant
                        }
                        AppLogger.shared.info("Starting session from calendar event: \(interview.title)")
                    }
                )
                .frame(maxHeight: 200)
                .padding(.horizontal, Spacing.lg)
            }

            // Selected participant indicator
            if let participant = selectedParticipant {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("Participant: \(participant.name)")
                        .font(Typography.caption)
                    if let role = participant.role {
                        Text("(\(role))")
                            .font(Typography.small)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Change") {
                        showParticipantPicker = true
                    }
                    .font(Typography.small)
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    Button(action: { selectedParticipant = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove selected participant")
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.xs)
                .background(Color.accentColor.opacity(0.06))
            }

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

                Button(action: {
                    withAnimation { showQuoteLibrary = true }
                }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "text.quote")
                        Text("Quote Library")
                    }
                    .font(Typography.caption)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Open quote library")
                .accessibilityHint("Browse saved highlights and quotes across sessions")

                Button(action: {
                    showParticipantPicker = true
                }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "person.2")
                        Text("Participants")
                    }
                    .font(Typography.caption)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Manage participants")
                .accessibilityHint("Select or create a participant for this session")

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
        }
        .task {
            // Fetch upcoming interviews on appear
            if calendarService.authorizationStatus == .notDetermined {
                await calendarService.requestAccess()
            }
            if calendarService.authorizationStatus == .authorized {
                await calendarService.fetchUpcomingInterviews()
            }
        }
    }
}

// MARK: - Active Session Placeholder View

struct ActiveSessionPlaceholderView: View {
    let sessionConfig: SessionConfiguration
    let highlightService: HighlightService
    let consentTracker: ConsentTracker
    let onEndSession: () -> Void

    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showCoachingHistory = false
    @State private var showCulturalSettings = false
    @State private var showRedactionReview = false

    // Batch 1 features
    @StateObject private var focusModeManager = FocusModeManager()
    @StateObject private var talkTimeAnalyzer = TalkTimeAnalyzer()
    @StateObject private var questionTypeAnalyzer = QuestionTypeAnalyzer()
    @StateObject private var followUpSuggester = FollowUpSuggester()

    // Batch 2 features
    @StateObject private var coachingTimingSettings = CoachingTimingSettings()
    @StateObject private var sentimentAnalyzer = SentimentAnalyzer()
    @StateObject private var culturalContextManager = CulturalContextManager()
    @StateObject private var biasDetector = BiasDetector()
    @StateObject private var redactionService = RedactionService()

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            sessionToolbar

            // Main content area with conditional panels
            HStack(spacing: 0) {
                // Left: Transcript area (always visible)
                transcriptArea

                // Right sidebar
                if focusModeManager.panelVisibility.showTopics || focusModeManager.panelVisibility.showInsights {
                    Divider()
                    rightSidebar
                }
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .sheet(isPresented: $showCoachingHistory) {
            CoachingHistoryView(timingSettings: coachingTimingSettings)
                .frame(minWidth: 400, minHeight: 350)
        }
        .sheet(isPresented: $showCulturalSettings) {
            CulturalSettingsView(culturalContext: culturalContextManager)
                .frame(minWidth: 500, minHeight: 450)
        }
        .sheet(isPresented: $showRedactionReview) {
            RedactionReviewView(
                redactionService: redactionService,
                utterances: [],
                sessionId: sessionConfig.id
            )
            .frame(minWidth: 550, minHeight: 450)
        }
    }

    // MARK: - Session Toolbar

    private var sessionToolbar: some View {
        HStack(spacing: Spacing.md) {
            // Focus Mode Picker (Feature 4)
            FocusModePickerView(
                manager: focusModeManager,
                isCompact: true
            )

            // Coaching controls (Features A + D)
            HStack(spacing: Spacing.xs) {
                Button(action: { showCoachingHistory = true }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel("Coaching history")
                .accessibilityHint("View coaching prompt history and timing settings")

                Button(action: { showCulturalSettings = true }) {
                    Image(systemName: "globe")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel("Cultural sensitivity settings")
                .accessibilityHint("Adjust coaching behavior for cultural context")

                Button(action: { showRedactionReview = true }) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel("PII redaction review")
                .accessibilityHint("Scan and redact personally identifiable information")
            }

            Spacer()

            // Talk-Time Indicator (Feature 1)
            if focusModeManager.panelVisibility.showTalkTime {
                TalkTimeIndicatorView(
                    analyzer: talkTimeAnalyzer,
                    isExpanded: false
                )
                .frame(width: 200)
            }

            // Session info + controls
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
    }

    // MARK: - Transcript Area

    private var transcriptArea: some View {
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

            // Question Type Analysis (Feature 2)
            if focusModeManager.panelVisibility.showCoaching {
                QuestionTypeView(analyzer: questionTypeAnalyzer)
                    .padding(.horizontal, Spacing.md)
            }

            // Emotional Arc (Feature G) — compact in coached mode, expanded in analysis
            if focusModeManager.panelVisibility.showCoaching || focusModeManager.panelVisibility.showInsights {
                EmotionalArcView(
                    analyzer: sentimentAnalyzer,
                    isExpanded: focusModeManager.panelVisibility.showInsights
                )
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
    }

    // MARK: - Right Sidebar

    private var rightSidebar: some View {
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

            // Follow-Up Suggestions (Feature 7)
            if focusModeManager.panelVisibility.showCoaching {
                FollowUpSuggestionView(suggester: followUpSuggester)
                    .padding(.horizontal, Spacing.sm)
            }

            // Bias Alerts (Feature D) — shown when bias detection is enabled
            if culturalContextManager.context.enableBiasAlerts && !biasDetector.alerts.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.system(size: 10))
                        Text("Bias Alerts")
                            .font(Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }

                    ForEach(biasDetector.alerts.prefix(3)) { alert in
                        Text(alert.description)
                            .font(Typography.small)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(Spacing.sm)
            }

            Spacer()
        }
        .frame(width: 260)
    }

    // MARK: - Helpers

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
        highlightService: HighlightService(),
        consentTracker: ConsentTracker(),
        onEndSession: {}
    )
    .frame(minWidth: 800, minHeight: 600)
}

#Preview("Demo Mode") {
    DemoModeView(onExit: {})
        .frame(minWidth: 800, minHeight: 600)
}
