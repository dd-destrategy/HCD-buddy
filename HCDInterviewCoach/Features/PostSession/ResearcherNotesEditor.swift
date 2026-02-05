//
//  ResearcherNotesEditor.swift
//  HCD Interview Coach
//
//  EPIC E10: Post-Session Summary
//  Rich text editor for researcher notes with formatting support
//

import SwiftUI

// MARK: - Researcher Notes Editor

/// Editor for adding and editing researcher notes after a session
struct ResearcherNotesEditor: View {
    @Binding var notes: String

    @FocusState private var isFocused: Bool

    @State private var isExpanded: Bool = true
    @State private var showFormatting: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            Button(action: { toggleExpanded() }) {
                HStack {
                    Image(systemName: "pencil.and.outline")
                        .font(.title3)
                        .foregroundColor(.blue)

                    Text("Researcher Notes")
                        .font(Typography.heading3)
                        .foregroundColor(.primary)

                    Spacer()

                    if !notes.isEmpty {
                        Text("\(wordCount) words")
                            .font(Typography.caption)
                            .foregroundColor(.secondary)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint(isExpanded ? "Collapse notes editor" : "Expand notes editor")

            if isExpanded {
                VStack(spacing: 0) {
                    // Formatting toolbar
                    if showFormatting {
                        formattingToolbar
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Text editor
                    TextEditor(text: $notes)
                        .font(Typography.body)
                        .frame(minHeight: 120, maxHeight: 300)
                        .scrollContentBackground(.hidden)
                        .padding(Spacing.md)
                        .liquidGlass(
                            material: .ultraThin,
                            cornerRadius: CornerRadius.medium,
                            borderStyle: isFocused ? .accent(.accentColor) : .subtle,
                            enableHover: false
                        )
                        .focused($isFocused)
                        .accessibilityLabel("Researcher notes text editor")
                        .accessibilityHint("Enter your notes and observations from the session")

                    // Footer with actions
                    HStack(spacing: Spacing.sm) {
                        Button(action: { toggleFormatting() }) {
                            Label("Format", systemImage: "textformat")
                                .font(Typography.caption)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                        }
                        .buttonStyle(.plain)
                        .glassButton(style: .secondary)

                        Button(action: insertTimestamp) {
                            Label("Timestamp", systemImage: "clock")
                                .font(Typography.caption)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                        }
                        .buttonStyle(.plain)
                        .glassButton(style: .secondary)

                        Spacer()

                        if !notes.isEmpty {
                            Button(action: clearNotes) {
                                Label("Clear", systemImage: "trash")
                                    .font(Typography.caption)
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.vertical, Spacing.sm)
                            }
                            .buttonStyle(.plain)
                            .glassButton(style: .destructive)
                        }
                    }
                    .padding(.top, Spacing.sm)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Quick templates
            if isExpanded && notes.isEmpty {
                quickTemplatesView
            }
        }
        .padding(Spacing.lg)
        .glassCard(accentColor: .blue)
    }

    // MARK: - Subviews

    private var formattingToolbar: some View {
        HStack(spacing: Spacing.sm) {
            FormatButton(icon: "bold", action: { insertFormatting("**", "**") })
            FormatButton(icon: "italic", action: { insertFormatting("_", "_") })
            FormatButton(icon: "list.bullet", action: { insertPrefix("- ") })
            FormatButton(icon: "list.number", action: { insertPrefix("1. ") })
            FormatButton(icon: "text.quote", action: { insertPrefix("> ") })

            Divider()
                .frame(height: 20)

            FormatButton(icon: "headphones", action: { insertPrefix("[Audio Note] ") })
            FormatButton(icon: "eye", action: { insertPrefix("[Observation] ") })
            FormatButton(icon: "questionmark.circle", action: { insertPrefix("[Follow-up] ") })
        }
        .padding(Spacing.sm)
        .liquidGlass(
            material: .ultraThin,
            cornerRadius: CornerRadius.medium,
            borderStyle: .subtle,
            enableHover: false
        )
        .padding(.bottom, Spacing.sm)
    }

    private var quickTemplatesView: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick Templates")
                .font(Typography.caption)
                .foregroundColor(.secondary)

            HStack(spacing: Spacing.sm) {
                TemplateButton(label: "Key Findings", action: {
                    applyTemplate(keyFindingsTemplate)
                })

                TemplateButton(label: "Next Steps", action: {
                    applyTemplate(nextStepsTemplate)
                })

                TemplateButton(label: "Quotes", action: {
                    applyTemplate(quotesTemplate)
                })
            }
        }
        .padding(.top, Spacing.sm)
    }

    // MARK: - Computed Properties

    private var wordCount: Int {
        notes.split(separator: " ").count
    }

    // MARK: - Templates

    private var keyFindingsTemplate: String {
        """
        ## Key Findings

        ### Main Insights
        -

        ### Unexpected Discoveries
        -

        ### Patterns Observed
        -

        """
    }

    private var nextStepsTemplate: String {
        """
        ## Next Steps

        ### Immediate Actions
        - [ ]

        ### Follow-up Questions
        -

        ### Hypotheses to Test
        -

        """
    }

    private var quotesTemplate: String {
        """
        ## Notable Quotes

        > "Quote 1"
        Context:

        > "Quote 2"
        Context:

        """
    }

    // MARK: - Actions

    private func toggleExpanded() {
        if reduceMotion {
            isExpanded.toggle()
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }

    private func toggleFormatting() {
        if reduceMotion {
            showFormatting.toggle()
        } else {
            withAnimation(.easeInOut(duration: 0.15)) {
                showFormatting.toggle()
            }
        }
    }

    private func insertTimestamp() {
        let timestamp = "[\(TimeFormatting.timeFormatter.string(from: Date()))] "
        notes.append(notes.isEmpty ? timestamp : "\n\(timestamp)")
    }

    private func clearNotes() {
        notes = ""
    }

    private func insertFormatting(_ prefix: String, _ suffix: String) {
        // In a real implementation, this would wrap selected text
        notes.append("\(prefix)text\(suffix)")
    }

    private func insertPrefix(_ prefix: String) {
        notes.append(notes.isEmpty ? prefix : "\n\(prefix)")
    }

    private func applyTemplate(_ template: String) {
        notes = template
    }
}

// MARK: - Format Button

/// Small formatting button for the toolbar
private struct FormatButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(Typography.caption)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .glassButton(style: .ghost)
    }
}

// MARK: - Template Button

/// Quick template button
private struct TemplateButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Typography.caption)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
        .glassButton(style: .secondary)
    }
}

// MARK: - Insight Editor

/// Editor for modifying a single insight
struct InsightEditor: View {
    let insight: EditableInsight
    var onSave: (String, String, [String]) -> Void
    var onCancel: () -> Void
    var onDelete: () -> Void

    @State private var quote: String = ""
    @State private var theme: String = ""
    @State private var tagsText: String = ""

    @FocusState private var focusedField: Field?

    enum Field {
        case quote, theme, tags
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                Text("Edit Insight")
                    .font(Typography.heading3)

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(Spacing.sm)
                }
                .buttonStyle(.plain)
                .glassButton(style: .destructive)
                .accessibilityLabel("Delete insight")
            }

            // Quote field
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Quote")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)

                TextEditor(text: $quote)
                    .font(Typography.body)
                    .frame(minHeight: 60, maxHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(Spacing.sm)
                    .liquidGlass(
                        material: .ultraThin,
                        cornerRadius: CornerRadius.medium,
                        borderStyle: focusedField == .quote ? .accent(.accentColor) : .subtle,
                        enableHover: false
                    )
                    .focused($focusedField, equals: .quote)
            }

            // Theme field
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Theme")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)

                TextField("e.g., User Frustration", text: $theme)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .theme)
            }

            // Tags field
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Tags (comma separated)")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)

                TextField("e.g., pain-point, onboarding, priority", text: $tagsText)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .tags)
            }

            // Actions
            HStack {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(Typography.bodyMedium)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.plain)
                .glassButton(style: .secondary)

                Spacer()

                Button(action: saveInsight) {
                    Text("Save")
                        .font(Typography.bodyMedium)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.plain)
                .glassButton(isActive: true, style: .primary)
                .disabled(quote.isEmpty || theme.isEmpty)
            }
        }
        .padding(Spacing.lg)
        .glassFloating(isActive: true)
        .onAppear {
            quote = insight.quote
            theme = insight.theme
            tagsText = insight.tags.joined(separator: ", ")
        }
    }

    private func saveInsight() {
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        onSave(quote, theme, tags)
    }
}

// MARK: - Insights List View

/// View for displaying and editing all insights
struct InsightsListView: View {
    @ObservedObject var viewModel: PostSessionViewModel

    @State private var editingInsightId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title3)
                    .foregroundColor(.orange)

                Text("Insights (\(viewModel.editableInsights.count))")
                    .font(Typography.heading3)

                Spacer()

                if viewModel.editableInsights.contains(where: { $0.isModified }) {
                    Text("Modified")
                        .font(Typography.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(CornerRadius.small)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            if viewModel.editableInsights.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(viewModel.editableInsights) { insight in
                        if editingInsightId == insight.id {
                            InsightEditor(
                                insight: insight,
                                onSave: { quote, theme, tags in
                                    viewModel.updateInsight(id: insight.id, quote: quote, theme: theme, tags: tags)
                                    editingInsightId = nil
                                },
                                onCancel: { editingInsightId = nil },
                                onDelete: {
                                    viewModel.deleteInsight(id: insight.id)
                                    editingInsightId = nil
                                }
                            )
                        } else {
                            InsightRow(
                                insight: insight,
                                onTap: { editingInsightId = insight.id }
                            )
                        }
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .glassCard(accentColor: .orange)
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "lightbulb")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No Insights Captured")
                .font(Typography.body)
                .foregroundColor(.secondary)

            Text("No insights were flagged during this session.")
                .font(Typography.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }
}

// MARK: - Insight Row

/// Display row for a single insight
struct InsightRow: View {
    let insight: EditableInsight
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Theme and modified indicator
                HStack {
                    Text(insight.theme)
                        .font(Typography.bodyMedium)
                        .foregroundColor(.primary)

                    if insight.isModified {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                    }

                    Spacer()

                    Image(systemName: "pencil")
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                }

                // Quote
                Text("\"\(insight.quote)\"")
                    .font(Typography.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .italic()

                // Tags
                if !insight.tags.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        ForEach(insight.tags, id: \.self) { tag in
                            Text(tag)
                                .font(Typography.small)
                                .foregroundColor(.blue)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(CornerRadius.small)
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .liquidGlass(
                material: .ultraThin,
                cornerRadius: CornerRadius.medium,
                borderStyle: .subtle,
                enableHover: true,
                enablePress: true
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insight.theme): \(insight.quote)")
        .accessibilityHint("Tap to edit insight")
    }
}

// MARK: - Preview

#Preview("Researcher Notes Editor") {
    @Previewable @State var notes = ""

    VStack(spacing: 20) {
        ResearcherNotesEditor(notes: $notes)

        Divider()

        Text("Notes content: \(notes)")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
    .frame(width: 500)
}

#Preview("Insight Editor") {
    let insight = EditableInsight(
        from: Insight(
            timestampSeconds: 123,
            quote: "I really struggle with the onboarding process",
            theme: "User Frustration",
            source: .aiGenerated,
            tags: ["pain-point", "onboarding"]
        )
    )

    return InsightEditor(
        insight: insight,
        onSave: { _, _, _ in },
        onCancel: { },
        onDelete: { }
    )
    .padding()
    .frame(width: 400)
}
