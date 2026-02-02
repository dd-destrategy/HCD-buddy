//
//  InsightDetailSheet.swift
//  HCDInterviewCoach
//
//  EPIC E8: Insight Flagging
//  Sheet view for viewing and editing insight details
//

import SwiftUI

// MARK: - Insight Detail Sheet

/// Sheet view for displaying and editing insight details.
/// Shows full quote, allows editing title/notes/tags, and provides navigation to transcript.
///
/// Accessibility:
/// - Full keyboard navigation support
/// - VoiceOver optimized
/// - Focus management for form fields
struct InsightDetailSheet: View {

    // MARK: - Properties

    let insight: Insight
    let onSave: (String, [String]) -> Void
    let onDelete: () -> Void
    let onNavigate: () -> Void
    let onDismiss: () -> Void

    @State private var editedTitle: String
    @State private var editedTags: [String]
    @State private var newTag: String = ""
    @State private var isEditing: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case title
        case newTag
    }

    // MARK: - Initialization

    init(
        insight: Insight,
        onSave: @escaping (String, [String]) -> Void,
        onDelete: @escaping () -> Void,
        onNavigate: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.insight = insight
        self.onSave = onSave
        self.onDelete = onDelete
        self.onNavigate = onNavigate
        self.onDismiss = onDismiss
        self._editedTitle = State(initialValue: insight.theme)
        self._editedTags = State(initialValue: insight.tags)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Metadata section
                    metadataSection

                    // Quote section
                    quoteSection

                    // Title section
                    titleSection

                    // Tags section
                    tagsSection
                }
                .padding(20)
            }

            Divider()

            // Footer with actions
            footerView
        }
        .frame(width: 480, height: 520)
        .background(Color.hcdBackground)
        .alert("Delete Insight?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .onAppear {
            if isEditing {
                focusedField = .title
            }
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            // Source badge
            HStack(spacing: 6) {
                Image(systemName: insight.source.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(insight.source.displayName)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(sourceColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(sourceColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Spacer()

            // Close button
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.hcdTextTertiary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
            .accessibilityLabel("Close")
        }
        .padding(16)
    }

    private var metadataSection: some View {
        HStack(spacing: 24) {
            // Timestamp
            VStack(alignment: .leading, spacing: 4) {
                Text("Timestamp")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.hcdTextTertiary)
                    .textCase(.uppercase)

                Text(insight.formattedTimestamp)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.hcdTextPrimary)
            }

            // Created date
            VStack(alignment: .leading, spacing: 4) {
                Text("Created")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.hcdTextTertiary)
                    .textCase(.uppercase)

                Text(insight.createdAt, style: .date)
                    .font(.system(size: 13))
                    .foregroundColor(Color.hcdTextSecondary)
            }

            Spacer()

            // Navigate button
            Button(action: onNavigate) {
                Label("Go to Transcript", systemImage: "arrow.right.circle")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier(AccessibilityIdentifiers.Insights.navigateButton(id: insight.id.uuidString))
        }
    }

    private var quoteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quote")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.hcdTextTertiary)
                .textCase(.uppercase)

            Text(insight.quote)
                .font(.system(size: 14))
                .foregroundColor(Color.hcdTextPrimary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.hcdBackgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .textSelection(.enabled)
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Title")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.hcdTextTertiary)
                    .textCase(.uppercase)

                Spacer()

                if !isEditing {
                    Button("Edit") {
                        isEditing = true
                        focusedField = .title
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.hcdPrimary)
                }
            }

            if isEditing {
                TextField("Enter insight title", text: $editedTitle)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .title)
                    .onSubmit {
                        focusedField = nil
                    }
            } else {
                Text(editedTitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.hcdTextPrimary)
                    .padding(.vertical, 4)
            }
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.hcdTextTertiary)
                .textCase(.uppercase)

            // Existing tags
            FlowLayout(spacing: 8) {
                ForEach(editedTags, id: \.self) { tag in
                    EditableTagView(
                        text: tag,
                        isEditing: isEditing,
                        onRemove: {
                            editedTags.removeAll { $0 == tag }
                        }
                    )
                }

                // Add tag field (when editing)
                if isEditing {
                    HStack(spacing: 4) {
                        TextField("Add tag", text: $newTag)
                            .textFieldStyle(.plain)
                            .frame(width: 80)
                            .focused($focusedField, equals: .newTag)
                            .onSubmit {
                                addNewTag()
                            }

                        Button(action: addNewTag) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color.hcdPrimary)
                        }
                        .buttonStyle(.plain)
                        .disabled(newTag.isEmpty)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.hcdBackgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            // Suggested tags (when editing)
            if isEditing && !suggestedTags.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Suggestions")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.hcdTextTertiary)

                    HStack(spacing: 6) {
                        ForEach(suggestedTags, id: \.self) { tag in
                            Button(action: { editedTags.append(tag) }) {
                                Text("+ \(tag)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.hcdPrimary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var footerView: some View {
        HStack {
            // Delete button
            Button(action: { showDeleteConfirmation = true }) {
                Label("Delete", systemImage: "trash")
                    .foregroundColor(Color.hcdError)
            }
            .buttonStyle(.plain)

            Spacer()

            // Cancel button (when editing)
            if isEditing {
                Button("Cancel") {
                    editedTitle = insight.theme
                    editedTags = insight.tags
                    isEditing = false
                }
                .keyboardShortcut(.escape, modifiers: [])
            }

            // Save/Done button
            if isEditing {
                Button("Save Changes") {
                    onSave(editedTitle, editedTags)
                    isEditing = false
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(editedTitle.isEmpty)
            } else {
                Button("Done") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(16)
    }

    // MARK: - Computed Properties

    private var sourceColor: Color {
        switch insight.source {
        case .userAdded:
            return Color.hcdPrimary
        case .aiGenerated:
            return Color.hcdInsight
        case .automated:
            return Color.hcdInfo
        }
    }

    private var suggestedTags: [String] {
        let allPossibleTags = ["pain-point", "user-need", "positive", "confusion", "suggestion", "workflow", "quote"]
        return allPossibleTags.filter { !editedTags.contains($0) }.prefix(4).map { $0 }
    }

    // MARK: - Actions

    private func addNewTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty, !editedTags.contains(trimmed) else { return }
        editedTags.append(trimmed)
        newTag = ""
    }
}

// MARK: - Editable Tag View

/// Tag view that can be removed when in edit mode
struct EditableTagView: View {

    let text: String
    let isEditing: Bool
    let onRemove: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.hcdTextSecondary)

            if isEditing {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(isHovered ? Color.hcdError : Color.hcdTextTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.hcdBackgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Flow Layout

/// Simple flow layout for wrapping content
struct FlowLayout: Layout {

    let spacing: CGFloat

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: ProposedViewSize(result.sizes[index]))
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint], sizes: [CGSize]) {
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []

        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        let maxX = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)

            if currentX + size.width > maxX && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX)
        }

        return (
            size: CGSize(width: maxWidth, height: currentY + lineHeight),
            positions: positions,
            sizes: sizes
        )
    }
}

// MARK: - Quick Flag Sheet

/// Simplified sheet for quickly flagging a moment with minimal input
struct QuickFlagSheet: View {

    let timestamp: Double
    let quote: String
    let onFlag: (String) -> Void
    let onDismiss: () -> Void

    @State private var title: String = ""
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(Color.hcdInsight)
                Text("Flag Insight")
                    .font(.headline)
                Spacer()
            }

            // Timestamp
            Text("At \(formattedTimestamp)")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(Color.hcdTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Quote preview
            Text(truncatedQuote)
                .font(.system(size: 13))
                .foregroundColor(Color.hcdTextSecondary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.hcdBackgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            // Title field
            TextField("Title (optional)", text: $title)
                .textFieldStyle(.roundedBorder)
                .focused($isTitleFocused)
                .onSubmit {
                    onFlag(title.isEmpty ? "Key Moment" : title)
                }

            // Actions
            HStack {
                Button("Cancel") {
                    onDismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button("Flag") {
                    onFlag(title.isEmpty ? "Key Moment" : title)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.hcdInsight)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(Color.hcdBackground)
        .onAppear {
            isTitleFocused = true
        }
    }

    private var formattedTimestamp: String {
        let minutes = Int(timestamp) / 60
        let seconds = Int(timestamp) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var truncatedQuote: String {
        if quote.count > 100 {
            return String(quote.prefix(100)) + "..."
        }
        return quote
    }
}

// MARK: - Preview Provider

#if DEBUG
struct InsightDetailSheet_Previews: PreviewProvider {
    static var previews: some View {
        InsightDetailSheet(
            insight: Insight(
                timestampSeconds: 125,
                quote: "I really wish this feature worked differently. It's frustrating when I have to click through multiple screens just to get to what I need. The workflow doesn't match how I actually think about the task.",
                theme: "Pain Point",
                source: .userAdded,
                tags: ["pain-point", "workflow", "navigation"]
            ),
            onSave: { _, _ in },
            onDelete: {},
            onNavigate: {},
            onDismiss: {}
        )
    }
}
#endif
