//
//  DemoSessionProvider.swift
//  HCD Interview Coach
//
//  DemoSessionProvider: Provides realistic sample session data for demo mode
//  Allows users to explore the full UI without BlackHole setup or API key
//  Simulates a Discovery Interview about a project management tool
//

import Foundation
import Combine

// MARK: - Demo Session Provider

/// Provides realistic sample session data for demo mode, allowing users to
/// explore the full app UI without configuring BlackHole audio or providing
/// an API key. Simulates a Discovery Interview about a project management tool.
@MainActor
final class DemoSessionProvider: ObservableObject {

    // MARK: - Singleton

    static let shared = DemoSessionProvider()

    // MARK: - Published Properties

    /// Whether the demo playback is currently active
    @Published private(set) var isPlayingDemo: Bool = false

    /// Current playback progress from 0.0 (start) to 1.0 (complete)
    @Published private(set) var playbackProgress: Double = 0.0

    /// Index of the most recently revealed utterance during playback
    @Published private(set) var currentUtteranceIndex: Int = 0

    // MARK: - Private Properties

    private var playbackTimer: Timer?
    private var playbackSpeed: Double = 1.0
    private var playbackStartTime: Date?
    private var accumulatedPlaybackTime: TimeInterval = 0
    private var demoSession: Session?

    // MARK: - Initialization

    private init() {}

    // MARK: - Demo Transcript

    /// The full demo conversation as a realistic UX research interview about task
    /// management tools. Contains 24 utterance pairs across 10-12 topic exchanges.
    var demoTranscript: [(speaker: Speaker, text: String, timestamp: Double)] {
        return [
            // Opening and Rapport Building
            (
                speaker: .interviewer,
                text: "Hi Sarah, thank you so much for taking the time to speak with me today. I'm really looking forward to hearing about your experience with project management tools. Before we begin, do you have any questions about how this session will work?",
                timestamp: 15.0
            ),
            (
                speaker: .participant,
                text: "No, I think I'm good. I read through the consent form you sent and I'm happy to share my thoughts. I've been dealing with a lot of project management headaches lately, so this is actually great timing.",
                timestamp: 35.0
            ),

            // Current Workflow
            (
                speaker: .interviewer,
                text: "Perfect. Let's start by talking about your current workflow. Can you walk me through a typical day and how you manage your tasks and projects?",
                timestamp: 65.0
            ),
            (
                speaker: .participant,
                text: "Sure. I usually start my morning by checking my email for any urgent requests. Then I open our team's shared spreadsheet where we track all our projects. I also have a personal to-do list in a notes app on my phone. Throughout the day, I'm constantly switching between these different tools trying to keep everything in sync.",
                timestamp: 90.0
            ),
            (
                speaker: .interviewer,
                text: "That sounds like quite a juggling act. How many projects are you typically managing at once?",
                timestamp: 140.0
            ),
            (
                speaker: .participant,
                text: "Usually between five and eight active projects at any given time. Each one has different stakeholders, different timelines, and different requirements. The most frustrating part is that there's no single place where I can see everything at a glance.",
                timestamp: 160.0
            ),

            // Pain Points
            (
                speaker: .interviewer,
                text: "You mentioned frustration. Can you tell me more about the specific challenges you face with your current setup?",
                timestamp: 210.0
            ),
            (
                speaker: .participant,
                text: "Oh, where do I start? The biggest problem is that things fall through the cracks. Last week, I completely missed a deadline because the update was buried in an email thread I hadn't checked. It's really difficult to track dependencies between tasks too. If one person is blocked, I might not find out until our weekly standup, which is way too late.",
                timestamp: 235.0
            ),
            (
                speaker: .interviewer,
                text: "That must be stressful. How does that impact your team?",
                timestamp: 290.0
            ),
            (
                speaker: .participant,
                text: "It creates a lot of confusion. People are constantly asking each other 'what's the status of this?' in Slack. I struggle with keeping everyone aligned because information is scattered across so many places. Sometimes team members end up doing duplicate work because they didn't know someone else was already on it.",
                timestamp: 315.0
            ),

            // Collaboration
            (
                speaker: .interviewer,
                text: "Let's talk more about collaboration. How does your team communicate about project updates?",
                timestamp: 375.0
            ),
            (
                speaker: .participant,
                text: "We use Slack for day-to-day chat, email for more formal communications, and then we have a weekly team meeting. But honestly, important decisions often get made in side conversations that not everyone is aware of. I've tried setting up dedicated Slack channels for each project, but they get noisy and people stop checking them.",
                timestamp: 400.0
            ),
            (
                speaker: .interviewer,
                text: "What would ideal team collaboration look like for you?",
                timestamp: 460.0
            ),
            (
                speaker: .participant,
                text: "I'd love a central hub where every team member can see what others are working on, leave comments on specific tasks, and get notified about changes that affect their work. The key thing is it needs to be easy to use. I've tried tools before that were so complicated that the team just stopped using them after a week.",
                timestamp: 485.0
            ),

            // Tool Preferences
            (
                speaker: .interviewer,
                text: "Speaking of tools you've tried before, what has your experience been with other project management solutions?",
                timestamp: 545.0
            ),
            (
                speaker: .participant,
                text: "We tried Jira about a year ago and it was way too complicated for our needs. The setup took forever and half the team found it confusing. Before that, we used Trello, which I actually love because of its visual board approach. The drag-and-drop interface is amazing and really intuitive. But it didn't scale well when our projects got more complex.",
                timestamp: 575.0
            ),
            (
                speaker: .interviewer,
                text: "What specifically about the visual board approach appeals to you?",
                timestamp: 640.0
            ),
            (
                speaker: .participant,
                text: "I'm a very visual person. Being able to see all my tasks laid out in columns and quickly drag them from 'in progress' to 'done' is so satisfying. It gives me an immediate sense of what's happening. I also enjoy being able to color-code things by priority or category. It makes the whole experience feel more organized and less overwhelming.",
                timestamp: 665.0
            ),

            // Ideal Solution
            (
                speaker: .interviewer,
                text: "If you could design your perfect project management tool, what would it look like?",
                timestamp: 730.0
            ),
            (
                speaker: .participant,
                text: "It would be simple enough that anyone on my team could pick it up in five minutes, but powerful enough to handle complex projects with dependencies and milestones. I'd want a great visual overview, maybe like a dashboard, where I can see all projects at once. Real-time updates are essential so I'm never looking at stale information.",
                timestamp: 760.0
            ),
            (
                speaker: .interviewer,
                text: "Are there any features that would be absolute must-haves for you?",
                timestamp: 825.0
            ),
            (
                speaker: .participant,
                text: "Definitely notifications for deadlines and blockers. I hate being surprised by missed deadlines. Also, some kind of workload view so I can see if anyone on the team is overloaded. And integration with the tools we already use, like Slack and Google Drive. I don't want to have to copy-paste things between systems.",
                timestamp: 850.0
            ),

            // Additional Context - Reporting
            (
                speaker: .interviewer,
                text: "How do you currently handle reporting and status updates for leadership?",
                timestamp: 920.0
            ),
            (
                speaker: .participant,
                text: "That's another pain point, honestly. Every Friday I spend about an hour manually compiling a status report from our spreadsheet, Slack messages, and email threads. It's tedious and error-prone. I wish I could just generate a report automatically from whatever tool we're using. That alone would save me so much time and the reports would be more accurate.",
                timestamp: 945.0
            ),

            // Wrap-Up - Priorities
            (
                speaker: .interviewer,
                text: "We're coming towards the end of our time. If you had to prioritize, what are the top three things that would make the biggest difference in how you manage projects?",
                timestamp: 1020.0
            ),
            (
                speaker: .participant,
                text: "Number one would be having everything in one place, a single source of truth for all project information. Number two is automated notifications so nothing falls through the cracks. And number three is simplicity. Whatever tool we use has to be easy enough that the whole team will actually adopt it. The perfect tool that nobody uses is worthless.",
                timestamp: 1050.0
            ),

            // Closing Exchange
            (
                speaker: .interviewer,
                text: "That's really insightful. Is there anything else about your project management experience that we haven't covered today?",
                timestamp: 1120.0
            ),
            (
                speaker: .participant,
                text: "I just want to emphasize how important the mobile experience is. I'm not always at my desk and I need to be able to check on things and make quick updates from my phone. A lot of tools I've tried have terrible mobile apps. If the mobile experience isn't great, I end up falling back on texting my team, which just creates more fragmentation.",
                timestamp: 1145.0
            ),

            // Final Close
            (
                speaker: .interviewer,
                text: "That's a great point about mobile. Thank you so much for sharing all of this, Sarah. Your insights are incredibly valuable and will really help shape the direction of our research.",
                timestamp: 1210.0
            ),
            (
                speaker: .participant,
                text: "Happy to help! I'm genuinely excited to see what comes out of this research. If you need any follow-up conversations, I'd be happy to participate again.",
                timestamp: 1235.0
            ),

            // Additional Context - Onboarding
            (
                speaker: .interviewer,
                text: "One more quick question before we wrap up. How important is the onboarding experience when your team adopts a new tool?",
                timestamp: 1290.0
            ),
            (
                speaker: .participant,
                text: "It's critical. With Jira, the onboarding was so confusing that half my team gave up after the first day. We need something that walks you through the basics quickly and lets you start being productive right away. Interactive tutorials or templates would be perfect because people learn by doing, not by reading documentation.",
                timestamp: 1315.0
            ),

            // Additional Context - Remote Work
            (
                speaker: .interviewer,
                text: "How has remote work affected your project management needs?",
                timestamp: 1380.0
            ),
            (
                speaker: .participant,
                text: "It's made everything more challenging. When we were in the office, you could just walk over to someone's desk and ask for a quick status update. Now everything has to be async, and things easily get lost in the shuffle. I think having a good project management tool is even more essential for remote teams. It replaces all those casual hallway conversations that used to keep everyone aligned.",
                timestamp: 1410.0
            ),

            // Additional Context - Budget
            (
                speaker: .interviewer,
                text: "Is cost a factor in your decision-making when it comes to project management tools?",
                timestamp: 1480.0
            ),
            (
                speaker: .participant,
                text: "Definitely. We're a small team and we don't have a huge budget for tools. But I'd rather pay for something that actually works well than use a free tool that creates more problems than it solves. The time I spend wrestling with our current setup probably costs more than a good subscription would. It's about value, not just price.",
                timestamp: 1510.0
            ),

            // Final Participant Thought
            (
                speaker: .interviewer,
                text: "Any final thoughts you'd like to share?",
                timestamp: 1570.0
            ),
            (
                speaker: .participant,
                text: "Just that I really appreciate you taking the time to understand our needs instead of just showing us a product and asking if we like it. This kind of research-first approach gives me a lot of confidence that whatever solution comes out of this will actually address the real problems we're facing every day.",
                timestamp: 1590.0
            ),

            // Absolute Final
            (
                speaker: .interviewer,
                text: "Thank you again, Sarah. This has been incredibly helpful. I'll follow up with a summary and next steps within the week.",
                timestamp: 1650.0
            ),
            (
                speaker: .participant,
                text: "Sounds great. Thanks for making this so comfortable. Looking forward to hearing back from you!",
                timestamp: 1670.0
            ),
        ]
    }

    // MARK: - Public Methods

    /// Create a realistic demo session populated with transcript data, insights,
    /// topic statuses, and coaching events.
    /// - Returns: A fully-populated Session instance for demonstration purposes.
    func createDemoSession() -> Session {
        let session = Session(
            participantName: "Sarah (Demo)",
            projectName: "Task Management Research",
            sessionMode: .full,
            startedAt: Date().addingTimeInterval(-1800),
            endedAt: Date(),
            totalDurationSeconds: 1800
        )

        // Add all utterances from the demo transcript
        let transcript = demoTranscript
        var utterances: [Utterance] = []
        for entry in transcript {
            let utterance = Utterance(
                speaker: entry.speaker,
                text: entry.text,
                timestampSeconds: entry.timestamp,
                confidence: Double.random(in: 0.85...0.98)
            )
            utterances.append(utterance)
        }
        session.utterances = utterances

        // Add realistic insights at key moments
        session.insights = [
            Insight(
                timestampSeconds: 160.0,
                quote: "The most frustrating part is that there's no single place where I can see everything at a glance",
                theme: "Information Fragmentation",
                source: .aiGenerated,
                tags: ["pain-point", "visibility", "dashboard"]
            ),
            Insight(
                timestampSeconds: 235.0,
                quote: "Things fall through the cracks... I completely missed a deadline because the update was buried in an email thread",
                theme: "Missed Deadlines",
                source: .userAdded,
                tags: ["pain-point", "notifications", "email"]
            ),
            Insight(
                timestampSeconds: 575.0,
                quote: "The drag-and-drop interface is amazing and really intuitive. But it didn't scale well when our projects got more complex",
                theme: "Simplicity vs Power",
                source: .aiGenerated,
                tags: ["tool-preference", "scalability", "usability"]
            ),
            Insight(
                timestampSeconds: 1050.0,
                quote: "The perfect tool that nobody uses is worthless",
                theme: "Adoption Challenge",
                source: .userAdded,
                tags: ["adoption", "simplicity", "team-dynamics"]
            ),
        ]

        // Add topic statuses with mixed coverage
        session.topicStatuses = [
            TopicStatus(
                topicId: "workflow",
                topicName: "Current Workflow",
                status: .fullyCovered,
                notes: "Detailed walkthrough of daily routine with spreadsheets and notes app"
            ),
            TopicStatus(
                topicId: "pain-points",
                topicName: "Pain Points",
                status: .fullyCovered,
                notes: "Multiple pain points identified including missed deadlines and information fragmentation"
            ),
            TopicStatus(
                topicId: "collaboration",
                topicName: "Collaboration",
                status: .fullyCovered,
                notes: "Team communication patterns discussed including Slack, email, and meetings"
            ),
            TopicStatus(
                topicId: "tool-preferences",
                topicName: "Tool Preferences",
                status: .partialCoverage,
                notes: "Discussed Jira and Trello experience but could explore more alternatives"
            ),
            TopicStatus(
                topicId: "ideal-solution",
                topicName: "Ideal Solution",
                status: .partialCoverage,
                notes: "High-level requirements gathered but specifics on workflows need more depth"
            ),
        ]

        // Add coaching events
        session.coachingEvents = [
            CoachingEvent(
                timestampSeconds: 200.0,
                promptText: "The participant mentioned frustration. Consider asking them to elaborate on specific incidents where this caused problems.",
                reason: "Emotional keyword detected with potential for deeper exploration",
                userResponse: .accepted
            ),
            CoachingEvent(
                timestampSeconds: 720.0,
                promptText: "The 'Ideal Solution' topic hasn't been covered yet. You might want to transition to that area soon.",
                reason: "Topic gap detected with sufficient time remaining",
                userResponse: .dismissed
            ),
        ]

        demoSession = session
        return session
    }

    /// Start simulated real-time playback of the demo transcript.
    /// Utterances are revealed progressively based on their timestamps.
    /// - Parameter speed: Playback speed multiplier (1.0 = real-time, 2.0 = double speed, etc.)
    func startPlayback(speed: Double = 1.0) {
        guard !isPlayingDemo else { return }

        playbackSpeed = speed
        isPlayingDemo = true
        playbackStartTime = Date()

        AppLogger.shared.info("Demo playback started at \(speed)x speed")

        startPlaybackTimer()
    }

    /// Stop the current demo playback.
    func stopPlayback() {
        guard isPlayingDemo else { return }

        if let startTime = playbackStartTime {
            accumulatedPlaybackTime += Date().timeIntervalSince(startTime) * playbackSpeed
        }

        playbackTimer?.invalidate()
        playbackTimer = nil
        playbackStartTime = nil
        isPlayingDemo = false

        AppLogger.shared.info("Demo playback stopped at progress \(String(format: "%.1f", playbackProgress * 100))%")
    }

    /// Reset playback to the beginning.
    func resetPlayback() {
        stopPlayback()
        playbackProgress = 0.0
        currentUtteranceIndex = 0
        accumulatedPlaybackTime = 0

        AppLogger.shared.info("Demo playback reset")
    }

    // MARK: - Private Methods

    private func startPlaybackTimer() {
        playbackTimer?.invalidate()

        // Update every 100ms for smooth progress
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePlayback()
            }
        }
    }

    private func updatePlayback() {
        let transcript = demoTranscript
        guard !transcript.isEmpty else {
            stopPlayback()
            return
        }

        let totalDuration = transcript.last?.timestamp ?? 1800.0
        let elapsedSinceStart: TimeInterval
        if let startTime = playbackStartTime {
            elapsedSinceStart = Date().timeIntervalSince(startTime) * playbackSpeed
        } else {
            elapsedSinceStart = 0
        }

        let currentSimulatedTime = accumulatedPlaybackTime + elapsedSinceStart
        playbackProgress = min(currentSimulatedTime / totalDuration, 1.0)

        // Determine how many utterances should be visible
        var newIndex = 0
        for (index, entry) in transcript.enumerated() {
            if entry.timestamp <= currentSimulatedTime {
                newIndex = index + 1
            } else {
                break
            }
        }

        if newIndex != currentUtteranceIndex {
            currentUtteranceIndex = newIndex
        }

        // Stop at end
        if playbackProgress >= 1.0 {
            playbackProgress = 1.0
            currentUtteranceIndex = transcript.count
            stopPlayback()
        }
    }
}
