//
//  QuestionTypeView.swift
//  HCD Interview Coach
//
//  SwiftUI panel showing question type analysis:
//  distribution chart, quality score, recent questions, and anti-pattern alerts.
//

import SwiftUI

// MARK: - Question Type View

/// Main panel view for displaying question type analysis during an interview session.
/// Shows distribution chart, quality score badge, recent question list, and anti-pattern alerts.
struct QuestionTypeView: View {

    // MARK: - Properties

    @ObservedObject var analyzer: QuestionTypeAnalyzer
    @State private var isCompact: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            if isCompact {
                compactContent
            } else {
                expandedContent
            }
        }
        .padding(Spacing.lg)
        .glassPanel(edge: .trailing)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Question type analysis panel")
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private var expandedContent: some View {
        // Header with quality score
        headerSection

        // Distribution chart
        if analyzer.sessionStats.totalQuestions > 0 {
            distributionSection

            Divider()
                .foregroundColor(.hcdDivider)

            // Anti-pattern alerts
            if !analyzer.currentAntiPatterns.isEmpty {
                antiPatternSection

                Divider()
                    .foregroundColor(.hcdDivider)
            }

            // Recent questions list
            recentQuestionsSection
        } else {
            emptyStateView
        }

        Spacer()

        // Compact mode toggle
        compactToggle
    }

    // MARK: - Compact Content

    @ViewBuilder
    private var compactContent: some View {
        HStack(spacing: Spacing.sm) {
            qualityScoreBadge

            if analyzer.sessionStats.totalQuestions > 0 {
                Text("\(analyzer.sessionStats.totalQuestions) Qs")
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextSecondary)
            }

            Spacer()

            if !analyzer.currentAntiPatterns.isEmpty {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.hcdWarning)
                    .accessibilityLabel("\(analyzer.currentAntiPatterns.count) anti-patterns detected")
            }

            compactToggle
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(compactAccessibilityLabel)
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Question Analysis")
                    .font(Typography.heading3)
                    .foregroundColor(.hcdTextPrimary)

                Text("\(analyzer.sessionStats.totalQuestions) questions analyzed")
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextSecondary)
            }

            Spacer()

            qualityScoreBadge
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Question analysis: \(analyzer.sessionStats.totalQuestions) questions, quality score \(Int(analyzer.sessionStats.qualityScore))")
    }

    // MARK: - Quality Score Badge

    @ViewBuilder
    private var qualityScoreBadge: some View {
        let score = analyzer.sessionStats.qualityScore

        VStack(spacing: 2) {
            Text("\(Int(score))")
                .font(Typography.heading2)
                .foregroundColor(qualityScoreColor(score))

            Text("Quality")
                .font(Typography.small)
                .foregroundColor(.hcdTextTertiary)
        }
        .frame(width: 52, height: 52)
        .background(qualityScoreColor(score).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .stroke(qualityScoreColor(score).opacity(0.3), lineWidth: 1)
        )
        .accessibilityLabel("Quality score: \(Int(score)) out of 100")
        .accessibilityHint("Higher scores indicate more open-ended and probing questions")
    }

    // MARK: - Distribution Section

    @ViewBuilder
    private var distributionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Distribution")
                .font(Typography.bodyMedium)
                .foregroundColor(.hcdTextPrimary)

            distributionChart
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Question type distribution")
    }

    @ViewBuilder
    private var distributionChart: some View {
        let stats = analyzer.sessionStats
        let total = max(stats.totalQuestions, 1)

        VStack(spacing: Spacing.sm) {
            // Stacked horizontal bar
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(distributionData(stats: stats, total: total), id: \.type) { entry in
                        if entry.count > 0 {
                            Rectangle()
                                .fill(colorForQuestionType(entry.type))
                                .frame(width: geometry.size.width * entry.fraction)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
            }
            .frame(height: 12)
            .accessibilityHidden(true)

            // Legend
            FlowLayout(spacing: Spacing.sm) {
                ForEach(distributionData(stats: stats, total: total), id: \.type) { entry in
                    if entry.count > 0 {
                        distributionLegendItem(type: entry.type, count: entry.count)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func distributionLegendItem(type: QuestionType, count: Int) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(colorForQuestionType(type))
                .frame(width: 8, height: 8)

            Text("\(type.displayName): \(count)")
                .font(Typography.small)
                .foregroundColor(.hcdTextSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.displayName): \(count) questions")
    }

    // MARK: - Anti-Pattern Section

    @ViewBuilder
    private var antiPatternSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.hcdWarning)

                Text("Patterns to Watch")
                    .font(Typography.bodyMedium)
                    .foregroundColor(.hcdTextPrimary)
            }

            ForEach(analyzer.currentAntiPatterns, id: \.self) { pattern in
                antiPatternRow(pattern)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Anti-patterns detected")
    }

    @ViewBuilder
    private func antiPatternRow(_ pattern: AntiPattern) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: pattern.icon)
                .font(.system(size: 11))
                .foregroundColor(.hcdWarning)
                .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(pattern.displayName)
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextPrimary)

                Text(pattern.description)
                    .font(Typography.small)
                    .foregroundColor(.hcdTextTertiary)
                    .lineLimit(2)
            }
        }
        .padding(Spacing.sm)
        .background(Color.hcdWarning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pattern.displayName): \(pattern.description)")
    }

    // MARK: - Recent Questions Section

    @ViewBuilder
    private var recentQuestionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Recent Questions")
                .font(Typography.bodyMedium)
                .foregroundColor(.hcdTextPrimary)

            let recentClassifications = Array(analyzer.classifications.suffix(5).reversed())

            ForEach(recentClassifications) { classification in
                recentQuestionRow(classification)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Recent questions")
    }

    @ViewBuilder
    private func recentQuestionRow(_ classification: QuestionClassification) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                // Type pill
                questionTypePill(classification.type)

                Spacer()

                // Timestamp
                Text(formattedTimestamp(classification.timestamp))
                    .font(Typography.small)
                    .foregroundColor(.hcdTextTertiary)
            }

            // Question text
            Text(classification.text)
                .font(Typography.caption)
                .foregroundColor(.hcdTextSecondary)
                .lineLimit(2)

            // Anti-pattern indicators
            if !classification.antiPatterns.isEmpty {
                HStack(spacing: Spacing.xs) {
                    ForEach(classification.antiPatterns, id: \.self) { pattern in
                        antiPatternPill(pattern)
                    }
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color.hcdBackgroundSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(classification.type.displayName) question: \(classification.text)")
    }

    @ViewBuilder
    private func questionTypePill(_ type: QuestionType) -> some View {
        HStack(spacing: 4) {
            Image(systemName: type.icon)
                .font(.system(size: 9))

            Text(type.displayName)
                .font(Typography.small)
        }
        .foregroundColor(colorForQuestionType(type))
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 3)
        .background(colorForQuestionType(type).opacity(0.12))
        .clipShape(Capsule())
        .accessibilityLabel("Type: \(type.displayName)")
    }

    @ViewBuilder
    private func antiPatternPill(_ pattern: AntiPattern) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 8))

            Text(pattern.displayName)
                .font(.system(size: 9))
        }
        .foregroundColor(.hcdWarning)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.hcdWarning.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityLabel("Anti-pattern: \(pattern.displayName)")
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "text.bubble")
                .font(.system(size: 32))
                .foregroundColor(.hcdTextTertiary)

            Text("No Questions Yet")
                .font(Typography.bodyMedium)
                .foregroundColor(.hcdTextSecondary)

            Text("Interviewer questions will be analyzed and categorized here as the session progresses.")
                .font(Typography.caption)
                .foregroundColor(.hcdTextTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No questions analyzed yet. Interviewer questions will appear here as the session progresses.")
    }

    // MARK: - Compact Toggle

    @ViewBuilder
    private var compactToggle: some View {
        Button(action: {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                isCompact.toggle()
            }
        }) {
            Image(systemName: isCompact ? "chevron.down" : "chevron.up")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.hcdTextTertiary)
                .frame(width: 24, height: 24)
                .background(Color.hcdBackgroundSecondary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCompact ? "Expand question analysis" : "Collapse question analysis")
        .accessibilityHint("Toggles between compact and expanded view")
    }

    // MARK: - Helper Methods

    private func qualityScoreColor(_ score: Double) -> Color {
        if score >= 70 { return .green }
        if score >= 40 { return .orange }
        return .red
    }

    private func colorForQuestionType(_ type: QuestionType) -> Color {
        switch type {
        case .openEnded: return .green
        case .closed: return .blue
        case .leading: return .red
        case .doubleBarreled: return .orange
        case .probing: return .purple
        case .clarifying: return .cyan
        case .hypothetical: return .indigo
        case .notAQuestion: return .gray
        }
    }

    private func formattedTimestamp(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    private var compactAccessibilityLabel: String {
        let stats = analyzer.sessionStats
        var label = "Question analysis: \(stats.totalQuestions) questions"
        if stats.totalQuestions > 0 {
            label += ", quality score \(Int(stats.qualityScore))"
        }
        if !analyzer.currentAntiPatterns.isEmpty {
            label += ", \(analyzer.currentAntiPatterns.count) anti-patterns"
        }
        return label
    }

    // MARK: - Distribution Data

    private struct DistributionEntry {
        let type: QuestionType
        let count: Int
        let fraction: CGFloat
    }

    private func distributionData(stats: QuestionStats, total: Int) -> [DistributionEntry] {
        let counts: [(QuestionType, Int)] = [
            (.openEnded, stats.openEndedCount),
            (.probing, stats.probingCount),
            (.closed, stats.closedCount),
            (.leading, stats.leadingCount),
            (.doubleBarreled, stats.doubleBarreledCount)
        ]

        // Calculate "other" count (clarifying, hypothetical, notAQuestion)
        let knownSum = counts.reduce(0) { $0 + $1.1 }
        let otherCount = total - knownSum

        var entries = counts.map { type, count in
            DistributionEntry(
                type: type,
                count: count,
                fraction: CGFloat(count) / CGFloat(total)
            )
        }

        if otherCount > 0 {
            entries.append(DistributionEntry(
                type: .clarifying,
                count: otherCount,
                fraction: CGFloat(otherCount) / CGFloat(total)
            ))
        }

        return entries
    }
}

// MARK: - Flow Layout

/// Simple horizontal wrapping layout for legend items
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layoutSizes(sizes: sizes, containerWidth: proposal.width ?? .infinity).totalSize
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layoutSizes(sizes: sizes, containerWidth: bounds.width).offsets

        for (index, subview) in subviews.enumerated() {
            if index < offsets.count {
                subview.place(
                    at: CGPoint(
                        x: bounds.minX + offsets[index].x,
                        y: bounds.minY + offsets[index].y
                    ),
                    proposal: .unspecified
                )
            }
        }
    }

    private func layoutSizes(sizes: [CGSize], containerWidth: CGFloat) -> (offsets: [CGPoint], totalSize: CGSize) {
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for size in sizes {
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            offsets.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX)
        }

        return (offsets, CGSize(width: maxWidth, height: currentY + lineHeight))
    }
}

// MARK: - Preview

#if DEBUG
struct QuestionTypeView_Previews: PreviewProvider {
    static var previews: some View {
        let analyzer = QuestionTypeAnalyzer()

        QuestionTypeView(analyzer: analyzer)
            .frame(width: 300, height: 600)
            .background(Color.hcdBackground)
            .previewDisplayName("Question Analysis Panel")
    }
}
#endif
