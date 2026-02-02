//
//  InsightRowView.swift
//  HCDInterviewCoach
//
//  EPIC E8: Insight Flagging
//  View for displaying individual insights in the list
//

import SwiftUI

// MARK: - Insight Row View

/// Displays a single insight in the insights list.
/// Shows theme, quote preview, timestamp, source indicator, and tags.
///
/// Accessibility:
/// - Full VoiceOver support with semantic labels
/// - Keyboard navigable
/// - Focus indicator for keyboard navigation
struct InsightRowView: View {

    // MARK: - Properties

    let insight: Insight
    let isSelected: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Source indicator
            sourceIndicator

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Header row: theme and timestamp
                headerRow

                // Quote preview
                quotePreview

                // Tags
                if !insight.tags.isEmpty {
                    tagsRow
                }
            }

            Spacer(minLength: 0)

            // Action buttons (visible on hover/selection)
            if isHovered || isSelected {
                actionButtons
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(backgroundView)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(AccessibilityIdentifiers.Insights.insightRow(id: insight.id.uuidString))
    }

    // MARK: - Subviews

    private var sourceIndicator: some View {
        ZStack {
            Circle()
                .fill(sourceBackgroundColor)
                .frame(width: 28, height: 28)

            Image(systemName: insight.source.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(sourceIconColor)
        }
        .accessibilityHidden(true)
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            // Theme/title
            Text(insight.theme)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.hcdTextPrimary)
                .lineLimit(1)

            Spacer()

            // Timestamp
            Text(insight.formattedTimestamp)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Color.hcdTextSecondary)
        }
    }

    private var quotePreview: some View {
        Text(truncatedQuote)
            .font(.system(size: 12))
            .foregroundColor(Color.hcdTextSecondary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }

    private var tagsRow: some View {
        HStack(spacing: 6) {
            ForEach(insight.tags.prefix(3), id: \.self) { tag in
                TagBadge(text: tag)
            }

            if insight.tags.count > 3 {
                Text("+\(insight.tags.count - 3)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.hcdTextTertiary)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 4) {
            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.hcdTextSecondary)
                    .frame(width: 24, height: 24)
                    .background(Color.hcdBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit insight")
            .accessibilityIdentifier(AccessibilityIdentifiers.Insights.editButton(id: insight.id.uuidString))

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.hcdError)
                    .frame(width: 24, height: 24)
                    .background(Color.hcdErrorLight.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete insight")
            .accessibilityIdentifier(AccessibilityIdentifiers.Insights.deleteButton(id: insight.id.uuidString))
        }
        .transition(.opacity.combined(with: .scale(scale: 0.8)))
    }

    private var backgroundView: some View {
        Group {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.hcdInsightHighlight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.hcdInsight, lineWidth: 2)
                    )
            } else if isHovered {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.hcdBackgroundSecondary)
            } else {
                Color.clear
            }
        }
    }

    // MARK: - Computed Properties

    private var truncatedQuote: String {
        let maxLength = 120
        if insight.quote.count > maxLength {
            return String(insight.quote.prefix(maxLength)) + "..."
        }
        return insight.quote
    }

    private var sourceBackgroundColor: Color {
        switch insight.source {
        case .userAdded:
            return Color.hcdPrimaryLight.opacity(0.2)
        case .aiGenerated:
            return Color.hcdInsight.opacity(0.2)
        case .automated:
            return Color.hcdInfo.opacity(0.2)
        }
    }

    private var sourceIconColor: Color {
        switch insight.source {
        case .userAdded:
            return Color.hcdPrimary
        case .aiGenerated:
            return Color.hcdInsight
        case .automated:
            return Color.hcdInfo
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        let sourceType = insight.isUserAdded ? "Manual" : "Automatic"
        return "\(sourceType) insight: \(insight.theme)"
    }

    private var accessibilityValue: String {
        "At \(insight.formattedTimestamp). \(insight.quote)"
    }

    private var accessibilityHint: String {
        "Double tap to navigate to transcript. Use context menu for more options."
    }
}

// MARK: - Tag Badge

/// Small badge for displaying insight tags
struct TagBadge: View {

    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(Color.hcdTextSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.hcdBackgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Compact Insight Row

/// A more compact version of InsightRowView for use in smaller panels
struct CompactInsightRowView: View {

    let insight: Insight
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Source indicator with shape differentiation for WCAG 1.4.1 compliance
            // User-added: filled circle, AI-generated: stroked circle
            Group {
                if insight.isUserAdded {
                    Circle()
                        .fill(Color.hcdPrimary)
                } else {
                    Circle()
                        .strokeBorder(Color.hcdInsight, lineWidth: 2)
                }
            }
            .frame(width: 8, height: 8)
            .accessibilityHidden(true)

            // Theme
            Text(insight.theme)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.hcdTextPrimary)
                .lineLimit(1)

            Spacer()

            // Timestamp
            Text(insight.formattedTimestamp)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(Color.hcdTextTertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isSelected ? Color.hcdInsightHighlight : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insight.theme), at \(insight.formattedTimestamp)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Empty State View

/// View shown when there are no insights
struct InsightsEmptyStateView: View {

    let onFlagCurrentMoment: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lightbulb")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(Color.hcdTextTertiary)

            VStack(spacing: 8) {
                Text("No Insights Yet")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.hcdTextPrimary)

                Text("Flag key moments during the interview using")
                    .font(.system(size: 13))
                    .foregroundColor(Color.hcdTextSecondary)

                HStack(spacing: 4) {
                    KeyboardShortcutBadge(key: "I", modifiers: [.command])
                    Text("or click the flag button")
                        .font(.system(size: 13))
                        .foregroundColor(Color.hcdTextSecondary)
                }
            }

            Button(action: onFlagCurrentMoment) {
                Label("Flag Current Moment", systemImage: "flag.fill")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.hcdInsight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No insights yet. Press Command I to flag the current moment.")
    }
}

// MARK: - Keyboard Shortcut Badge

/// Displays a keyboard shortcut in a styled badge
struct KeyboardShortcutBadge: View {

    let key: String
    let modifiers: [KeyboardModifier]

    enum KeyboardModifier {
        case command
        case option
        case shift
        case control

        var symbol: String {
            switch self {
            case .command: return "\u{2318}"
            case .option: return "\u{2325}"
            case .shift: return "\u{21E7}"
            case .control: return "\u{2303}"
            }
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(modifiers, id: \.self) { modifier in
                Text(modifier.symbol)
            }
            Text(key)
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundColor(Color.hcdTextSecondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.hcdBackgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.hcdBorderLight, lineWidth: 1)
        )
    }
}

// MARK: - Preview Provider

#if DEBUG
struct InsightRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            InsightRowView(
                insight: previewInsight(source: .userAdded),
                isSelected: false,
                onTap: {},
                onDoubleTap: {},
                onEdit: {},
                onDelete: {}
            )

            InsightRowView(
                insight: previewInsight(source: .aiGenerated),
                isSelected: true,
                onTap: {},
                onDoubleTap: {},
                onEdit: {},
                onDelete: {}
            )

            CompactInsightRowView(
                insight: previewInsight(source: .userAdded),
                isSelected: false,
                onTap: {}
            )

            InsightsEmptyStateView(onFlagCurrentMoment: {})
        }
        .padding()
        .frame(width: 400)
        .background(Color.hcdBackground)
    }

    static func previewInsight(source: InsightSource) -> Insight {
        Insight(
            timestampSeconds: 125,
            quote: "I really wish this feature worked differently. It's frustrating when I have to click through multiple screens just to get to what I need.",
            theme: "Pain Point",
            source: source,
            tags: ["pain-point", "workflow", "navigation"]
        )
    }
}
#endif
