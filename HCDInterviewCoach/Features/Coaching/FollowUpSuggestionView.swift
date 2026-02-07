//
//  FollowUpSuggestionView.swift
//  HCD Interview Coach
//
//  SwiftUI sidebar panel for displaying follow-up question suggestions.
//  Shows suggestion cards with category indicators, trigger quotes,
//  and accept/dismiss actions.
//

import SwiftUI

// MARK: - Follow-Up Suggestion View

/// Sidebar panel that displays contextual follow-up question suggestions.
/// Shows 2-3 suggestion cards that the researcher can use or dismiss.
/// Supports both expanded and collapsed states.
struct FollowUpSuggestionView: View {

    // MARK: - Properties

    @ObservedObject var suggester: FollowUpSuggester
    @State private var isCollapsed: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if isCollapsed {
                collapsedContent
            } else {
                expandedContent
            }
        }
        .padding(Spacing.lg)
        .glassPanel(edge: .trailing)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Follow-up question suggestions")
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private var expandedContent: some View {
        // Header
        headerSection

        if suggester.suggestions.isEmpty {
            emptyStateView
        } else {
            // Suggestion cards
            ForEach(suggester.suggestions) { suggestion in
                suggestionCard(suggestion)
            }

            // Dismiss all
            if suggester.suggestions.count > 1 {
                dismissAllButton
            }
        }

        Spacer()

        // Settings row
        settingsRow
    }

    // MARK: - Collapsed Content

    @ViewBuilder
    private var collapsedContent: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "text.bubble")
                .font(.system(size: 14))
                .foregroundColor(.hcdCoaching)

            if !suggester.suggestions.isEmpty {
                Text("\(suggester.suggestions.count)")
                    .font(Typography.bodyMedium)
                    .foregroundColor(.hcdTextPrimary)

                Text("suggestions")
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextSecondary)
            } else {
                Text("Follow-ups")
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextSecondary)
            }

            Spacer()

            // Count badge
            if !suggester.suggestions.isEmpty {
                countBadge
            }

            collapseToggle
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(collapsedAccessibilityLabel)
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Follow-Up Suggestions")
                    .font(Typography.heading3)
                    .foregroundColor(.hcdTextPrimary)

                if suggester.isGenerating {
                    HStack(spacing: Spacing.xs) {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 12, height: 12)

                        Text("Analyzing...")
                            .font(Typography.small)
                            .foregroundColor(.hcdTextTertiary)
                    }
                } else {
                    Text("\(suggester.suggestions.count) suggestion\(suggester.suggestions.count == 1 ? "" : "s")")
                        .font(Typography.caption)
                        .foregroundColor(.hcdTextSecondary)
                }
            }

            Spacer()

            collapseToggle
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Follow-up suggestions: \(suggester.suggestions.count) available")
    }

    // MARK: - Suggestion Card

    @ViewBuilder
    private func suggestionCard(_ suggestion: FollowUpSuggestion) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Category pill
            HStack(spacing: Spacing.sm) {
                categoryPill(suggestion.category)

                Spacer()

                // Dismiss button
                Button(action: {
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                        suggester.dismissSuggestion(suggestion.id)
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.hcdTextTertiary)
                        .frame(width: 20, height: 20)
                        .background(Color.hcdBackgroundSecondary)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss suggestion")
                .accessibilityHint("Removes this suggestion from the list")
            }

            // Suggestion text
            Text(suggestion.text)
                .font(Typography.body)
                .foregroundColor(.hcdTextPrimary)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            // Trigger quote
            if !suggestion.triggerQuote.isEmpty {
                HStack(spacing: Spacing.xs) {
                    Rectangle()
                        .fill(Color.hcdTextTertiary.opacity(0.3))
                        .frame(width: 2)

                    Text(suggestion.triggerQuote)
                        .font(Typography.small)
                        .foregroundColor(.hcdTextTertiary)
                        .lineLimit(2)
                        .italic()
                }
                .padding(.leading, Spacing.xs)
            }

            // Use button
            Button(action: {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                    suggester.acceptSuggestion(suggestion.id)
                }
            }) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 12))

                    Text("Use this")
                        .font(Typography.caption)
                }
                .foregroundColor(.hcdCoaching)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .frame(maxWidth: .infinity)
                .glassButton(isActive: true, style: .primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Use suggestion: \(suggestion.text)")
            .accessibilityHint("Adds this question to your mental queue")
        }
        .padding(Spacing.md)
        .glassCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Suggestion: \(suggestion.category.displayName)")
    }

    // MARK: - Category Pill

    @ViewBuilder
    private func categoryPill(_ category: SuggestionCategory) -> some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.system(size: 10))

            Text(category.displayName)
                .font(Typography.small)
        }
        .foregroundColor(colorForCategory(category))
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 3)
        .background(colorForCategory(category).opacity(0.12))
        .clipShape(Capsule())
        .accessibilityLabel("Category: \(category.displayName)")
    }

    // MARK: - Count Badge

    @ViewBuilder
    private var countBadge: some View {
        Text("\(suggester.suggestions.count)")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 18, height: 18)
            .background(Color.hcdCoaching)
            .clipShape(Circle())
            .accessibilityLabel("\(suggester.suggestions.count) suggestions")
    }

    // MARK: - Dismiss All Button

    @ViewBuilder
    private var dismissAllButton: some View {
        Button(action: {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                suggester.dismissAll()
            }
        }) {
            Text("Dismiss All")
                .font(Typography.caption)
                .foregroundColor(.hcdTextTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Dismiss all suggestions")
        .accessibilityHint("Removes all current suggestions from the list")
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "text.bubble")
                .font(.system(size: 28))
                .foregroundColor(.hcdTextTertiary)

            Text("No Suggestions Yet")
                .font(Typography.bodyMedium)
                .foregroundColor(.hcdTextSecondary)

            Text("Follow-up suggestions will appear here as the participant shares their experience.")
                .font(Typography.caption)
                .foregroundColor(.hcdTextTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No suggestions yet. Follow-up suggestions will appear as the participant speaks.")
    }

    // MARK: - Settings Row

    @ViewBuilder
    private var settingsRow: some View {
        HStack(spacing: Spacing.md) {
            // Auto-generate toggle
            Toggle(isOn: $suggester.autoGenerate) {
                Text("Auto-suggest")
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextSecondary)
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .accessibilityLabel("Auto-suggest follow-up questions")
            .accessibilityHint(suggester.autoGenerate
                ? "Currently enabled. Suggestions generate automatically."
                : "Currently disabled. Tap to enable automatic suggestion generation.")

            Spacer()

            // Enable/disable toggle
            Toggle(isOn: $suggester.isEnabled) {
                Text("Enabled")
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextSecondary)
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .accessibilityLabel("Enable follow-up suggestions")
            .accessibilityHint(suggester.isEnabled
                ? "Suggestions are currently enabled."
                : "Suggestions are currently disabled.")
        }
    }

    // MARK: - Collapse Toggle

    @ViewBuilder
    private var collapseToggle: some View {
        Button(action: {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                isCollapsed.toggle()
            }
        }) {
            Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.hcdTextTertiary)
                .frame(width: 24, height: 24)
                .background(Color.hcdBackgroundSecondary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCollapsed ? "Expand suggestions" : "Collapse suggestions")
        .accessibilityHint("Toggles between collapsed and expanded view")
    }

    // MARK: - Helper Methods

    private func colorForCategory(_ category: SuggestionCategory) -> Color {
        switch category {
        case .probeDeeper: return .purple
        case .emotionExplore: return .pink
        case .clarify: return .cyan
        case .redirectToTopic: return .orange
        case .timelineExplore: return .blue
        case .contrastExplore: return .indigo
        }
    }

    private var collapsedAccessibilityLabel: String {
        if suggester.suggestions.isEmpty {
            return "Follow-up suggestions, no suggestions available"
        }
        return "Follow-up suggestions, \(suggester.suggestions.count) available"
    }
}

// MARK: - Preview

#if DEBUG
struct FollowUpSuggestionView_Previews: PreviewProvider {
    static var previews: some View {
        let suggester = FollowUpSuggester()

        FollowUpSuggestionView(suggester: suggester)
            .frame(width: 300, height: 500)
            .background(Color.hcdBackground)
            .previewDisplayName("Follow-Up Suggestions")
    }
}
#endif
