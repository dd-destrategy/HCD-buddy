//
//  HighlightCreatorView.swift
//  HCDInterviewCoach
//
//  FEATURE E: Highlight Reel & Quote Library
//  Inline/sheet view for creating a new highlight from selected transcript text.
//

import SwiftUI

// MARK: - Highlight Creator View

/// Sheet view for creating a new highlight from a selected transcript utterance.
///
/// Pre-fills the quote text from the selected utterance and auto-suggests a title
/// from the first few words. The user can choose a category, add notes, and star
/// the highlight before saving.
///
/// Accessibility:
/// - Full keyboard navigation support
/// - VoiceOver labels on all interactive elements
/// - Focus management for form fields
struct HighlightCreatorView: View {

    // MARK: - Properties

    @ObservedObject var highlightService: HighlightService

    let utteranceId: UUID
    let sessionId: UUID
    let quoteText: String
    let speaker: String
    let timestampSeconds: Double
    let onDismiss: () -> Void

    @State private var title: String = ""
    @State private var selectedCategory: HighlightCategory = .uncategorized
    @State private var notes: String = ""
    @State private var isStarred: Bool = false

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case title
        case notes
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Quote preview
                    quotePreviewSection

                    // Title field
                    titleSection

                    // Category picker
                    categorySection

                    // Notes field
                    notesSection

                    // Star toggle
                    starSection
                }
                .padding(Spacing.xl)
            }

            Divider()

            // Footer with actions
            footerView
        }
        .frame(width: 480, height: 520)
        .background(Color.hcdBackground)
        .onAppear {
            title = suggestedTitle
            focusedField = .title
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Create Highlight")
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            Image(systemName: "quote.opening")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.hcdPrimary)

            Text("Save Highlight")
                .font(Typography.heading2)
                .foregroundColor(Color.hcdTextPrimary)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.hcdTextTertiary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
            .accessibilityLabel("Cancel")
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.lg)
    }

    // MARK: - Quote Preview Section

    private var quotePreviewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Quote")
                    .font(Typography.caption)
                    .foregroundColor(Color.hcdTextTertiary)
                    .textCase(.uppercase)

                Spacer()

                // Metadata
                HStack(spacing: Spacing.sm) {
                    Label(speaker, systemImage: "person.fill")
                        .font(Typography.caption)
                        .foregroundColor(Color.hcdTextTertiary)

                    Label(formattedTimestamp, systemImage: "clock")
                        .font(Typography.caption)
                        .foregroundColor(Color.hcdTextTertiary)
                }
            }

            Text(quoteText)
                .font(Typography.body)
                .italic()
                .foregroundColor(Color.hcdTextPrimary)
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.hcdBackgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                .textSelection(.enabled)
                .accessibilityLabel("Selected quote: \(quoteText)")
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Title")
                .font(Typography.caption)
                .foregroundColor(Color.hcdTextTertiary)
                .textCase(.uppercase)

            TextField("Enter a title for this highlight", text: $title)
                .textFieldStyle(.roundedBorder)
                .font(Typography.body)
                .focused($focusedField, equals: .title)
                .onSubmit {
                    focusedField = .notes
                }
                .accessibilityLabel("Highlight title")
                .accessibilityHint("Enter a short descriptive title")
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Category")
                .font(Typography.caption)
                .foregroundColor(Color.hcdTextTertiary)
                .textCase(.uppercase)

            // Category grid
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: Spacing.sm
            ) {
                ForEach(HighlightCategory.allCases, id: \.self) { category in
                    categoryButton(category)
                }
            }
        }
    }

    private func categoryButton(_ category: HighlightCategory) -> some View {
        let isSelected = selectedCategory == category
        let categoryColor = Color(nsColor: NSColor(hex: category.colorHex))

        return Button(action: { selectedCategory = category }) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: 11))
                Text(category.displayName)
                    .font(Typography.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.xs)
            .foregroundColor(isSelected ? Color.white : categoryColor)
            .background(isSelected ? categoryColor : categoryColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.displayName) category")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Tap to select this category")
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Notes")
                .font(Typography.caption)
                .foregroundColor(Color.hcdTextTertiary)
                .textCase(.uppercase)

            TextField("Add researcher notes (optional)...", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .font(Typography.body)
                .lineLimit(3...5)
                .focused($focusedField, equals: .notes)
                .accessibilityLabel("Researcher notes")
                .accessibilityHint("Optional notes about this highlight")
        }
    }

    // MARK: - Star Section

    private var starSection: some View {
        HStack {
            Button(action: { isStarred.toggle() }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .font(.system(size: 16))
                        .foregroundColor(isStarred ? Color.hcdWarning : Color.hcdTextTertiary)

                    Text(isStarred ? "Starred" : "Add to starred")
                        .font(Typography.body)
                        .foregroundColor(isStarred ? Color.hcdWarning : Color.hcdTextSecondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isStarred ? "Starred" : "Not starred")
            .accessibilityHint("Tap to toggle star status")

            Spacer()
        }
    }

    // MARK: - Footer View

    private var footerView: some View {
        HStack {
            Button("Cancel") {
                onDismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
            .accessibilityLabel("Cancel")

            Spacer()

            Button(action: saveHighlight) {
                Label("Save Highlight", systemImage: "checkmark.circle.fill")
                    .font(Typography.bodyMedium)
            }
            .glassButton(isActive: true, style: .primary)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Save highlight")
            .accessibilityHint("Saves this highlight to the quote library")
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.lg)
    }

    // MARK: - Computed Properties

    /// Auto-suggested title from the first few words of the quote
    private var suggestedTitle: String {
        let words = quoteText.split(separator: " ")
        let prefix = words.prefix(6).joined(separator: " ")
        if words.count > 6 {
            return prefix + "..."
        }
        return prefix
    }

    /// Formatted timestamp string (MM:SS)
    private var formattedTimestamp: String {
        let minutes = Int(timestampSeconds) / 60
        let seconds = Int(timestampSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Actions

    private func saveHighlight() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let highlight = highlightService.createHighlight(
            title: trimmedTitle,
            quoteText: quoteText,
            speaker: speaker,
            category: selectedCategory,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            utteranceId: utteranceId,
            sessionId: sessionId,
            timestampSeconds: timestampSeconds
        )

        if isStarred {
            highlightService.toggleStar(highlight.id)
        }

        onDismiss()
    }
}

// MARK: - Preview Provider

#if DEBUG
struct HighlightCreatorView_Previews: PreviewProvider {
    static var previews: some View {
        HighlightCreatorView(
            highlightService: HighlightService(
                storageURL: FileManager.default.temporaryDirectory
                    .appendingPathComponent("preview_highlights.json")
            ),
            utteranceId: UUID(),
            sessionId: UUID(),
            quoteText: "I really struggle with the navigation. It takes me way too many clicks to get to where I need to go, and I often get lost in the menus.",
            speaker: "Participant",
            timestampSeconds: 125,
            onDismiss: {}
        )
    }
}
#endif
