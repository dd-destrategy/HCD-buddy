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
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: { toggleExpanded() }) {
                HStack {
                    Image(systemName: "pencil.and.outline")
                        .font(.title3)
                        .foregroundColor(.blue)

                    Text("Researcher Notes")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    if !notes.isEmpty {
                        Text("\(wordCount) words")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
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
                        .font(.body)
                        .frame(minHeight: 120, maxHeight: 300)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isFocused ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .focused($isFocused)
                        .accessibilityLabel("Researcher notes text editor")
                        .accessibilityHint("Enter your notes and observations from the session")

                    // Footer with actions
                    HStack {
                        Button(action: { toggleFormatting() }) {
                            Label("Format", systemImage: "textformat")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button(action: insertTimestamp) {
                            Label("Timestamp", systemImage: "clock")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Spacer()

                        if !notes.isEmpty {
                            Button(action: clearNotes) {
                                Label("Clear", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(.red)
                        }
                    }
                    .padding(.top, 8)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Quick templates
            if isExpanded && notes.isEmpty {
                quickTemplatesView
            }
        }
        .padding(16)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Subviews

    private var formattingToolbar: some View {
        HStack(spacing: 8) {
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
        .padding(8)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(6)
        .padding(.bottom, 8)
    }

    private var quickTemplatesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Templates")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
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
        .padding(.top, 8)
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
                .font(.caption)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
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
                .font(.caption)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
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
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Edit Insight")
                    .font(.headline)

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete insight")
            }

            // Quote field
            VStack(alignment: .leading, spacing: 4) {
                Text("Quote")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextEditor(text: $quote)
                    .font(.body)
                    .frame(minHeight: 60, maxHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(focusedField == .quote ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .focused($focusedField, equals: .quote)
            }

            // Theme field
            VStack(alignment: .leading, spacing: 4) {
                Text("Theme")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("e.g., User Frustration", text: $theme)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .theme)
            }

            // Tags field
            VStack(alignment: .leading, spacing: 4) {
                Text("Tags (comma separated)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("e.g., pain-point, onboarding, priority", text: $tagsText)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .tags)
            }

            // Actions
            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)

                Spacer()

                Button("Save", action: saveInsight)
                    .buttonStyle(.borderedProminent)
                    .disabled(quote.isEmpty || theme.isEmpty)
            }
        }
        .padding(16)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
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
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title3)
                    .foregroundColor(.orange)

                Text("Insights (\(viewModel.editableInsights.count))")
                    .font(.headline)

                Spacer()

                if viewModel.editableInsights.contains(where: { $0.isModified }) {
                    Text("Modified")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            if viewModel.editableInsights.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 8) {
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
        .padding(16)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "lightbulb")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No Insights Captured")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("No insights were flagged during this session.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - Insight Row

/// Display row for a single insight
struct InsightRow: View {
    let insight: EditableInsight
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                // Theme and modified indicator
                HStack {
                    Text(insight.theme)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    if insight.isModified {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                    }

                    Spacer()

                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Quote
                Text("\"\(insight.quote)\"")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .italic()

                // Tags
                if !insight.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(insight.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)
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
