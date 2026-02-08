//
//  EnhancedSummaryView.swift
//  HCD Interview Coach
//
//  AI-Enhanced Session Summary View
//  Displays structured analysis of a completed interview session including
//  themes, pain points, highlights, key quotes, topic gaps, and follow-ups.
//

import SwiftUI

// MARK: - Enhanced Summary View

/// Main view for displaying an AI-enhanced session summary.
/// Shows quality score, themes, pain points, positive highlights,
/// key quotes, topic gaps, suggested follow-ups, and an export button.
struct EnhancedSummaryView: View {
    let session: Session

    @StateObject private var generator = SessionSummaryGenerator()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var expandedThemeIds: Set<UUID> = []
    @State private var showCopyConfirmation = false

    var body: some View {
        Group {
            if generator.isGenerating {
                loadingState
            } else if let error = generator.generationError {
                errorState(message: error)
            } else if let summary = generator.summary {
                summaryContent(summary)
            } else {
                emptyState
            }
        }
        .task {
            _ = await generator.generate(from: session)
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .controlSize(.large)

            Text("Analyzing session...")
                .font(Typography.heading3)
                .foregroundColor(.secondary)

            Text("Extracting themes, insights, and recommendations")
                .font(Typography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Generating session summary")
        .accessibilityHint("Please wait while the summary is being generated")
    }

    // MARK: - Error State

    private func errorState(message: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Summary Generation Failed")
                .font(Typography.heading2)

            Text(message)
                .font(Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: retrySummary) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .glassButton(isActive: true, style: .primary)
            .accessibilityLabel("Retry summary generation")
            .accessibilityHint("Attempts to generate the session summary again")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No Summary Available")
                .font(Typography.heading2)

            Text("The summary will be generated when the session data is ready.")
                .font(Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No summary available yet")
    }

    // MARK: - Summary Content

    private func summaryContent(_ summary: SessionSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                // Quality Score Header
                qualityScoreHeader(score: summary.sessionQualityScore)

                // Key Themes
                if !summary.keyThemes.isEmpty {
                    keyThemesSection(themes: summary.keyThemes)
                }

                // Pain Points
                if !summary.participantPainPoints.isEmpty {
                    painPointsSection(points: summary.participantPainPoints)
                }

                // Positive Highlights
                if !summary.positiveHighlights.isEmpty {
                    positiveHighlightsSection(highlights: summary.positiveHighlights)
                }

                // Key Quotes
                if !summary.keyQuotes.isEmpty {
                    keyQuotesSection(quotes: summary.keyQuotes)
                }

                // Topic Gaps
                if !summary.topicGaps.isEmpty {
                    topicGapsSection(gaps: summary.topicGaps)
                }

                // Suggested Follow-Ups
                if !summary.suggestedFollowUps.isEmpty {
                    followUpSection(suggestions: summary.suggestedFollowUps)
                }

                // Export Button
                exportButton(summary: summary)

                Spacer()
                    .frame(height: Spacing.xl)
            }
            .padding(Spacing.xl)
        }
    }

    // MARK: - Quality Score Header

    private func qualityScoreHeader(score: Double) -> some View {
        HStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Session Quality")
                    .font(Typography.heading2)

                Text("Overall assessment of interview depth and coverage")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            qualityScoreBadge(score: score)
        }
        .padding(Spacing.lg)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Session quality score: \(Int(score)) out of 100")
        .accessibilityHint(qualityScoreDescription(score: score))
    }

    private func qualityScoreBadge(score: Double) -> some View {
        ZStack {
            Circle()
                .fill(qualityScoreColor(score: score).opacity(0.15))
                .frame(width: 64, height: 64)

            Circle()
                .stroke(qualityScoreColor(score: score), lineWidth: 3)
                .frame(width: 64, height: 64)

            Text("\(Int(score))")
                .font(Typography.heading1)
                .foregroundColor(qualityScoreColor(score: score))
        }
        .accessibilityHidden(true)
    }

    private func qualityScoreColor(score: Double) -> Color {
        if score >= 75 {
            return .green
        } else if score >= 50 {
            return .orange
        } else {
            return .red
        }
    }

    private func qualityScoreDescription(score: Double) -> String {
        if score >= 75 {
            return "Excellent session with strong coverage and depth"
        } else if score >= 50 {
            return "Good session with room for improvement in some areas"
        } else {
            return "Session could benefit from deeper exploration of topics"
        }
    }

    // MARK: - Key Themes Section

    private func keyThemesSection(themes: [ThemeSummary]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader(title: "Key Themes", icon: "tag.fill", color: .blue)

            ForEach(themes) { theme in
                themeCard(theme: theme)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Key themes section with \(themes.count) themes")
    }

    private func themeCard(theme: ThemeSummary) -> some View {
        let isExpanded = expandedThemeIds.contains(theme.id)

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            Button(action: { toggleTheme(theme.id) }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 16)

                    Text(theme.name)
                        .font(Typography.bodyMedium)
                        .foregroundColor(.primary)

                    Spacer()

                    Text("\(theme.mentionCount) mentions")
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(theme.name), \(theme.mentionCount) mentions")
            .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to expand and see supporting quotes")

            if isExpanded && !theme.supportingQuotes.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(theme.supportingQuotes, id: \.self) { quote in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Rectangle()
                                .fill(Color.blue.opacity(0.4))
                                .frame(width: 3)

                            Text(quote)
                                .font(Typography.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                        .padding(.leading, Spacing.xl)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(Spacing.md)
        .glassCard(isSelected: isExpanded, accentColor: .blue)
    }

    // MARK: - Pain Points Section

    private func painPointsSection(points: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader(title: "Pain Points", icon: "exclamationmark.circle.fill", color: .red)

            ForEach(points, id: \.self) { point in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(Typography.caption)
                        .foregroundColor(.red)
                        .frame(width: 16, alignment: .center)

                    Text(point)
                        .font(Typography.body)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(Color.red.opacity(0.15), lineWidth: 1)
                )
                .accessibilityLabel("Pain point: \(point)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pain points section with \(points.count) items")
    }

    // MARK: - Positive Highlights Section

    private func positiveHighlightsSection(highlights: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader(title: "Positive Highlights", icon: "star.fill", color: .green)

            ForEach(highlights, id: \.self) { highlight in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Typography.caption)
                        .foregroundColor(.green)
                        .frame(width: 16, alignment: .center)

                    Text(highlight)
                        .font(Typography.body)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(Color.green.opacity(0.15), lineWidth: 1)
                )
                .accessibilityLabel("Positive highlight: \(highlight)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Positive highlights section with \(highlights.count) items")
    }

    // MARK: - Key Quotes Section

    private func keyQuotesSection(quotes: [KeyQuote]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader(title: "Key Quotes", icon: "quote.opening", color: .purple)

            ForEach(quotes) { quote in
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: "quote.opening")
                            .font(Typography.heading3)
                            .foregroundColor(.purple.opacity(0.4))

                        Text(quote.text)
                            .font(Typography.body)
                            .italic()
                            .foregroundColor(.primary)
                    }

                    HStack(spacing: Spacing.md) {
                        Label(quote.speaker, systemImage: "person.fill")
                            .font(Typography.caption)
                            .foregroundColor(.secondary)

                        Label(
                            TimeFormatting.formatCompactTimestamp(quote.timestamp),
                            systemImage: "clock"
                        )
                        .font(Typography.caption)
                        .foregroundColor(.secondary)

                        Spacer()

                        Text(quote.significance)
                            .font(Typography.small)
                            .foregroundColor(.purple)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                    }
                }
                .padding(Spacing.md)
                .glassCard(accentColor: .purple)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(quote.speaker) said: \(quote.text). \(quote.significance)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Key quotes section with \(quotes.count) quotes")
    }

    // MARK: - Topic Gaps Section

    private func topicGapsSection(gaps: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader(title: "Topic Gaps", icon: "exclamationmark.triangle.fill", color: .orange)

            ForEach(gaps, id: \.self) { gap in
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "arrow.right.circle")
                        .font(Typography.body)
                        .foregroundColor(.orange)
                        .frame(width: 20, alignment: .center)

                    Text(gap)
                        .font(Typography.body)
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding(Spacing.md)
                .background(Color.orange.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(Color.orange.opacity(0.15), lineWidth: 1)
                )
                .accessibilityLabel("Topic gap: \(gap)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Topic gaps section with \(gaps.count) gaps")
    }

    // MARK: - Follow-Up Section

    private func followUpSection(suggestions: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader(title: "Suggested Follow-Ups", icon: "lightbulb.fill", color: .yellow)

            ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Text("\(index + 1).")
                        .font(Typography.bodyMedium)
                        .foregroundColor(.accentColor)
                        .frame(width: 24, alignment: .trailing)

                    Text(suggestion)
                        .font(Typography.body)
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding(Spacing.md)
                .glassCard()
                .accessibilityLabel("Follow-up suggestion \(index + 1): \(suggestion)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Suggested follow-up questions section with \(suggestions.count) suggestions")
    }

    // MARK: - Export Button

    private func exportButton(summary: SessionSummary) -> some View {
        let markdownContent = generator.exportSummaryAsMarkdown(summary)

        return HStack {
            Spacer()

            #if os(iOS)
            ShareLink(item: markdownContent) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Summary")
                        .font(Typography.bodyMedium)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
            }
            .buttonStyle(.plain)
            .glassButton(style: .secondary)
            .accessibilityLabel("Share summary as markdown")
            .accessibilityHint("Opens the share sheet with the summary in Markdown format")
            #else
            Button(action: { exportToClipboard(summary: summary) }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: showCopyConfirmation ? "checkmark" : "doc.on.doc")
                    Text(showCopyConfirmation ? "Copied to Clipboard" : "Copy Summary as Markdown")
                        .font(Typography.bodyMedium)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
            }
            .buttonStyle(.plain)
            .glassButton(isActive: showCopyConfirmation, style: showCopyConfirmation ? .primary : .secondary)
            .accessibilityLabel(showCopyConfirmation ? "Summary copied to clipboard" : "Copy summary as markdown")
            .accessibilityHint("Copies the entire summary in Markdown format to the clipboard")
            #endif

            Spacer()
        }
    }

    // MARK: - Shared Components

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)

            Text(title)
                .font(Typography.heading2)

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel(title)
    }

    // MARK: - Actions

    private func toggleTheme(_ themeId: UUID) {
        if reduceMotion {
            if expandedThemeIds.contains(themeId) {
                expandedThemeIds.remove(themeId)
            } else {
                expandedThemeIds.insert(themeId)
            }
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                if expandedThemeIds.contains(themeId) {
                    expandedThemeIds.remove(themeId)
                } else {
                    expandedThemeIds.insert(themeId)
                }
            }
        }
    }

    private func exportToClipboard(summary: SessionSummary) {
        let markdown = generator.exportSummaryAsMarkdown(summary)
        ClipboardService.copy(markdown)

        if reduceMotion {
            showCopyConfirmation = true
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopyConfirmation = true
            }
        }

        // Reset after delay
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if reduceMotion {
                showCopyConfirmation = false
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCopyConfirmation = false
                }
            }
        }

        AppLogger.shared.info("Session summary exported to clipboard")
    }

    private func retrySummary() {
        Task {
            _ = await generator.generate(from: session)
        }
    }
}

// MARK: - Preview

#if DEBUG
private func makePreviewSession() -> Session {
    let session = Session(
        participantName: "Jane Smith",
        projectName: "Task Management Research",
        sessionMode: .full,
        startedAt: Date().addingTimeInterval(-1800),
        endedAt: Date(),
        totalDurationSeconds: 1800
    )

    session.utterances = [
        Utterance(speaker: .interviewer, text: "Can you tell me about your current workflow?", timestampSeconds: 30),
        Utterance(speaker: .participant, text: "I currently use a combination of spreadsheets and sticky notes, which is really frustrating because things get lost all the time.", timestampSeconds: 45),
        Utterance(speaker: .interviewer, text: "What are the biggest challenges you face?", timestampSeconds: 120),
        Utterance(speaker: .participant, text: "The most difficult thing is keeping track of deadlines. I struggle with knowing what my team members are working on and it feels overwhelming.", timestampSeconds: 140),
        Utterance(speaker: .participant, text: "I love how some tools let you drag and drop tasks between columns. That visual approach is amazing and really intuitive.", timestampSeconds: 300),
        Utterance(speaker: .interviewer, text: "How do you collaborate with your team?", timestampSeconds: 450),
        Utterance(speaker: .participant, text: "We mostly use email and chat, but important things get buried. I wish we had a central place for everything.", timestampSeconds: 470)
    ]

    session.insights = [
        Insight(timestampSeconds: 45, quote: "Things get lost all the time", theme: "Information Management", source: .aiGenerated),
        Insight(timestampSeconds: 300, quote: "Visual approach is amazing", theme: "UI Preference", source: .userAdded)
    ]

    session.topicStatuses = [
        TopicStatus(topicId: "1", topicName: "Current Workflow", status: .fullyCovered),
        TopicStatus(topicId: "2", topicName: "Pain Points", status: .fullyCovered),
        TopicStatus(topicId: "3", topicName: "Collaboration", status: .partialCoverage),
        TopicStatus(topicId: "4", topicName: "Tool Preferences", status: .partialCoverage),
        TopicStatus(topicId: "5", topicName: "Ideal Solution", status: .notCovered)
    ]

    return session
}

#Preview("Enhanced Summary") {
    EnhancedSummaryView(session: makePreviewSession())
        .frame(width: 650, height: 800)
}
#endif
