import SwiftUI

#if os(iOS)

/// iOS navigation shell using TabView (iPhone) or NavigationSplitView (iPad).
///
/// This view serves as the main entry point on iOS/iPadOS, replacing
/// ContentView's macOS-oriented navigation with mobile-appropriate patterns:
/// - **iPhone**: TabView with NavigationStack per tab
/// - **iPad**: NavigationSplitView with sidebar + detail
///
/// Implements: I1 (iPhone TabView), I2 (iPad NavigationSplitView),
/// I3 (stacked mobile session layout), I7 (on-screen action buttons),
/// I11 (compact toolbar), N4 (pull-to-refresh), N5 (iPad multitasking),
/// N13 (.searchable modifier)
struct MobileContentView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @StateObject private var calendarService = CalendarService()
    @StateObject private var participantManager = ParticipantManager()
    @StateObject private var consentTracker = ConsentTracker()
    @StateObject private var highlightService = HighlightService()

    @State private var selectedTab: AppTab = .session
    @State private var activeSessionConfig: SessionConfiguration?
    @State private var selectedParticipant: Participant?
    @State private var showParticipantPicker = false
    @State private var showConsentFlow = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Tab Definition

    enum AppTab: String, CaseIterable {
        case session = "Session"
        case transcript = "Transcript"
        case insights = "Insights"
        case library = "Library"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .session: return "mic.circle"
            case .transcript: return "text.alignleft"
            case .insights: return "lightbulb"
            case .library: return "books.vertical"
            case .settings: return "gear"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .environmentObject(serviceContainer)
    }

    // MARK: - iPhone Layout (TabView + NavigationStack)

    private var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            // Session Tab
            NavigationStack {
                if let config = activeSessionConfig {
                    MobileSessionView(
                        sessionConfig: config,
                        highlightService: highlightService,
                        consentTracker: consentTracker,
                        onEndSession: { activeSessionConfig = nil }
                    )
                } else {
                    MobileSetupView(
                        serviceContainer: serviceContainer,
                        calendarService: calendarService,
                        participantManager: participantManager,
                        selectedParticipant: $selectedParticipant,
                        onStartSession: { template, mode in
                            startSession(template: template, mode: mode)
                        }
                    )
                }
            }
            .tabItem {
                Label(AppTab.session.rawValue, systemImage: AppTab.session.icon)
            }
            .tag(AppTab.session)

            // Library Tab (Quote Library + Analytics)
            NavigationStack {
                MobileLibraryView(highlightService: highlightService)
            }
            .tabItem {
                Label(AppTab.library.rawValue, systemImage: AppTab.library.icon)
            }
            .tag(AppTab.library)

            // Settings Tab
            NavigationStack {
                MobileSettingsView()
            }
            .tabItem {
                Label(AppTab.settings.rawValue, systemImage: AppTab.settings.icon)
            }
            .tag(AppTab.settings)
        }
    }

    // MARK: - iPad Layout (NavigationSplitView)

    private var iPadLayout: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .navigationTitle("HCD Coach")
        } detail: {
            switch selectedTab {
            case .session:
                if let config = activeSessionConfig {
                    MobileSessionView(
                        sessionConfig: config,
                        highlightService: highlightService,
                        consentTracker: consentTracker,
                        onEndSession: { activeSessionConfig = nil }
                    )
                } else {
                    MobileSetupView(
                        serviceContainer: serviceContainer,
                        calendarService: calendarService,
                        participantManager: participantManager,
                        selectedParticipant: $selectedParticipant,
                        onStartSession: { template, mode in
                            startSession(template: template, mode: mode)
                        }
                    )
                }
            case .transcript:
                Text("Select a session to view transcript")
                    .font(Typography.body)
                    .foregroundColor(.secondary)
            case .insights:
                Text("Insights will appear during active sessions")
                    .font(Typography.body)
                    .foregroundColor(.secondary)
            case .library:
                MobileLibraryView(highlightService: highlightService)
            case .settings:
                MobileSettingsView()
            }
        }
    }

    // MARK: - Session Lifecycle

    private func startSession(template: InterviewTemplate, mode: SessionMode) {
        let config = SessionConfiguration(
            template: template,
            mode: mode,
            startedAt: Date(),
            participantId: selectedParticipant?.id,
            calendarEventId: nil
        )
        activeSessionConfig = config
        if let participantId = selectedParticipant?.id {
            participantManager.linkSession(config.id, to: participantId)
        }
    }
}

// MARK: - Mobile Session View (Stacked Layout — I3, I7, I11)

/// Active session view optimized for mobile devices.
///
/// Uses a stacked vertical layout instead of the macOS side-by-side panels.
/// Key actions that are keyboard shortcuts on macOS (Flag, Coach, Topics,
/// Speaker) are presented as on-screen buttons in a bottom toolbar (I7).
/// Sheets provide drill-down into coaching and topic details.
struct MobileSessionView: View {
    let sessionConfig: SessionConfiguration
    let highlightService: HighlightService
    let consentTracker: ConsentTracker
    let onEndSession: () -> Void

    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showCoachingSheet = false
    @State private var showTopicsSheet = false

    @StateObject private var talkTimeAnalyzer = TalkTimeAnalyzer()
    @StateObject private var questionTypeAnalyzer = QuestionTypeAnalyzer()
    @StateObject private var sentimentAnalyzer = SentimentAnalyzer()
    @StateObject private var followUpSuggester = FollowUpSuggester()

    var body: some View {
        VStack(spacing: 0) {
            // Session header (compact toolbar — I11)
            sessionHeader

            // Transcript area (full width, scrollable)
            ScrollView {
                VStack(spacing: Spacing.md) {
                    // Emotional arc (compact)
                    EmotionalArcView(
                        analyzer: sentimentAnalyzer,
                        isExpanded: false
                    )
                    .padding(.horizontal, Spacing.md)

                    Text("Transcript will appear here during live sessions")
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 300)
                }
            }

            // Bottom toolbar with on-screen action buttons (I7)
            bottomToolbar
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
        .sheet(isPresented: $showCoachingSheet) {
            coachingSheet
        }
        .sheet(isPresented: $showTopicsSheet) {
            topicsSheet
        }
    }

    // MARK: - Session Header

    private var sessionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(sessionConfig.template.name)
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
                Text(formatElapsedTime(elapsedTime))
                    .font(Typography.heading2)
                    .monospacedDigit()
            }

            Spacer()

            // Talk-time compact indicator
            TalkTimeIndicatorView(
                analyzer: talkTimeAnalyzer,
                isExpanded: false
            )
            .frame(width: 100)

            Button(role: .destructive, action: {
                timer?.invalidate()
                onEndSession()
            }) {
                Image(systemName: "stop.circle.fill")
                    .font(.title2)
            }
            .accessibilityLabel("End session")
            .accessibilityHint("Stops the current interview session")
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(PlatformColor.controlBackground)
    }

    // MARK: - Bottom Toolbar (On-Screen Buttons — I7)

    private var bottomToolbar: some View {
        HStack(spacing: Spacing.lg) {
            Button(action: { /* flag insight */ }) {
                VStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.title3)
                    Text("Flag")
                        .font(Typography.small)
                }
            }
            .frame(minWidth: Spacing.touchTarget, minHeight: Spacing.touchTarget)
            .accessibilityLabel("Flag insight")
            .accessibilityHint("Marks the current moment as a noteworthy insight")

            Button(action: { showCoachingSheet = true }) {
                VStack(spacing: 2) {
                    Image(systemName: "lightbulb")
                        .font(.title3)
                    Text("Coach")
                        .font(Typography.small)
                }
            }
            .frame(minWidth: Spacing.touchTarget, minHeight: Spacing.touchTarget)
            .accessibilityLabel("Show coaching suggestions")
            .accessibilityHint("Opens coaching panel with question analysis and follow-up suggestions")

            Button(action: { showTopicsSheet = true }) {
                VStack(spacing: 2) {
                    Image(systemName: "list.bullet")
                        .font(.title3)
                    Text("Topics")
                        .font(Typography.small)
                }
            }
            .frame(minWidth: Spacing.touchTarget, minHeight: Spacing.touchTarget)
            .accessibilityLabel("Show topics")
            .accessibilityHint("Shows the interview topic checklist")

            Button(action: { /* toggle speaker */ }) {
                VStack(spacing: 2) {
                    Image(systemName: "person.2")
                        .font(.title3)
                    Text("Speaker")
                        .font(Typography.small)
                }
            }
            .frame(minWidth: Spacing.touchTarget, minHeight: Spacing.touchTarget)
            .accessibilityLabel("Toggle speaker")
            .accessibilityHint("Switches between interviewer and participant speaker labels")
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(PlatformColor.controlBackground)
    }

    // MARK: - Coaching Sheet

    private var coachingSheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.md) {
                QuestionTypeView(analyzer: questionTypeAnalyzer)
                FollowUpSuggestionView(suggester: followUpSuggester)
                Spacer()
            }
            .padding()
            .navigationTitle("Coaching")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showCoachingSheet = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Topics Sheet

    private var topicsSheet: some View {
        NavigationStack {
            List(sessionConfig.template.topics, id: \.self) { topic in
                HStack {
                    Image(systemName: "circle")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                    Text(topic)
                        .font(Typography.body)
                }
            }
            .navigationTitle("Topics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showTopicsSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
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

// MARK: - Mobile Setup View (N4 Pull-to-Refresh)

/// Session setup screen for iOS with pull-to-refresh on calendar events.
struct MobileSetupView: View {
    let serviceContainer: ServiceContainer
    @ObservedObject var calendarService: CalendarService
    @ObservedObject var participantManager: ParticipantManager
    @Binding var selectedParticipant: Participant?
    var onStartSession: (InterviewTemplate, SessionMode) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Participant section
                if let participant = selectedParticipant {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.accentColor)
                        Text(participant.name)
                            .font(Typography.body)
                        Spacer()
                        Button("Change") { /* show picker */ }
                            .font(Typography.caption)
                    }
                    .padding()
                    .background(Color.accentColor.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                }

                // Calendar events
                if calendarService.authorizationStatus == .authorized {
                    UpcomingInterviewsView(
                        calendarService: calendarService,
                        onStartSession: { _ in }
                    )
                }

                // Template selector
                SessionSetupView(
                    templateManager: serviceContainer.templateManager,
                    onStartSession: { template, mode in
                        onStartSession(template, mode)
                    }
                )
            }
            .padding(.horizontal, Spacing.lg)
        }
        .navigationTitle("New Session")
        .refreshable {
            // Pull-to-refresh for calendar events (N4)
            if calendarService.authorizationStatus == .authorized {
                await calendarService.fetchUpcomingInterviews()
            }
        }
    }
}

// MARK: - Mobile Library View (N13 .searchable)

/// Library view for browsing highlights and analytics on iOS.
/// Uses `.searchable()` for native iOS search experience (N13).
struct MobileLibraryView: View {
    @ObservedObject var highlightService: HighlightService
    @State private var showAnalytics = false

    var body: some View {
        List {
            Section("Quick Access") {
                NavigationLink {
                    QuoteLibraryView(
                        highlightService: highlightService,
                        onDismiss: { }
                    )
                } label: {
                    Label("Quote Library", systemImage: "text.quote")
                }

                NavigationLink {
                    CrossSessionAnalyticsView(
                        studyManager: StudyManager(),
                        analytics: CrossSessionAnalytics(),
                        onDismiss: { }
                    )
                } label: {
                    Label("Analytics", systemImage: "chart.bar")
                }
            }

            Section("Highlights (\(highlightService.totalCount))") {
                if highlightService.highlights.isEmpty {
                    Text("No highlights saved yet")
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(highlightService.highlights.prefix(10)) { highlight in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(highlight.title)
                                .font(Typography.bodyMedium)
                            Text(highlight.quoteText)
                                .font(Typography.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .navigationTitle("Library")
        .searchable(text: $highlightService.searchQuery, prompt: "Search highlights")
    }
}

// MARK: - Mobile Settings View

/// Settings view for iOS with navigation links to coaching and cultural preferences.
struct MobileSettingsView: View {
    @StateObject private var culturalContext = CulturalContextManager()
    @StateObject private var coachingTiming = CoachingTimingSettings()

    var body: some View {
        List {
            Section("Coaching") {
                NavigationLink("Timing & Delivery") {
                    CoachingHistoryView(timingSettings: coachingTiming)
                }
                NavigationLink("Cultural Sensitivity") {
                    CulturalSettingsView(culturalContext: culturalContext)
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#endif
