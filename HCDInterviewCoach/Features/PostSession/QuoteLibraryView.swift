//
//  QuoteLibraryView.swift
//  HCDInterviewCoach
//
//  FEATURE E: Highlight Reel & Quote Library
//  Full-screen view for browsing the cross-session quote library.
//

import SwiftUI

// MARK: - Quote Library View

/// Full-screen view for browsing, searching, filtering, and exporting highlights
/// across all interview sessions.
///
/// Features:
/// - Search bar for filtering by title, quote text, notes, or speaker
/// - Category filter chips with horizontal scrolling
/// - Star filter toggle
/// - Sort options (newest, oldest, alphabetical, by category)
/// - Expandable highlight cards with edit options
/// - Export filtered results as Markdown
///
/// Accessibility:
/// - Full keyboard navigation support
/// - VoiceOver labels on all interactive elements
/// - Focus management for search and editing
struct QuoteLibraryView: View {

    // MARK: - Properties

    @ObservedObject var highlightService: HighlightService
    let onDismiss: () -> Void

    @State private var expandedHighlightId: UUID?
    @State private var editingTitle: String = ""
    @State private var editingNotes: String = ""
    @State private var editingCategory: HighlightCategory = .uncategorized
    @State private var showDeleteConfirmation: Bool = false
    @State private var highlightToDelete: UUID?
    @State private var showExportResult: Bool = false
    @State private var exportedMarkdown: String = ""

    @FocusState private var isSearchFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Filters
            filtersSection

            Divider()

            // Content
            if highlightService.highlights.isEmpty {
                emptyStateView
            } else if highlightService.filteredHighlights.isEmpty {
                noMatchesView
            } else {
                highlightListView
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color.hcdBackground)
        .alert("Delete Highlight?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                highlightToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let id = highlightToDelete {
                    highlightService.deleteHighlight(id)
                    if expandedHighlightId == id {
                        expandedHighlightId = nil
                    }
                    highlightToDelete = nil
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(isPresented: $showExportResult) {
            exportResultSheet
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Quote Library")
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Quote Library")
                    .font(Typography.heading1)
                    .foregroundColor(Color.hcdTextPrimary)

                HStack(spacing: Spacing.md) {
                    Label("\(highlightService.totalCount) highlights", systemImage: "quote.opening")
                        .font(Typography.caption)
                        .foregroundColor(Color.hcdTextSecondary)

                    if highlightService.starredCount > 0 {
                        Label("\(highlightService.starredCount) starred", systemImage: "star.fill")
                            .font(Typography.caption)
                            .foregroundColor(Color.hcdWarning)
                    }
                }
            }

            Spacer()

            // Export button
            Button(action: exportFilteredHighlights) {
                Label("Export", systemImage: "square.and.arrow.up")
                    .font(Typography.bodyMedium)
            }
            .glassButton(style: .secondary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .disabled(highlightService.filteredHighlights.isEmpty)
            .accessibilityLabel("Export highlights as Markdown")
            .accessibilityHint("Exports the currently filtered highlights to a Markdown document")

            // Close button
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.hcdTextTertiary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
            .accessibilityLabel("Close Quote Library")
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.lg)
    }

    // MARK: - Filters Section

    private var filtersSection: some View {
        VStack(spacing: Spacing.sm) {
            // Search bar
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.hcdTextTertiary)

                TextField("Search highlights...", text: $highlightService.searchQuery)
                    .textFieldStyle(.plain)
                    .font(Typography.body)
                    .focused($isSearchFocused)
                    .accessibilityLabel("Search highlights")
                    .accessibilityHint("Type to filter highlights by title, quote, notes, or speaker")

                if !highlightService.searchQuery.isEmpty {
                    Button(action: { highlightService.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.hcdTextTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.hcdBackgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))

            // Category filter chips + star toggle + sort
            HStack(spacing: Spacing.sm) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        // "All" chip
                        categoryChip(label: "All", isSelected: highlightService.selectedCategory == nil) {
                            highlightService.selectedCategory = nil
                        }

                        ForEach(HighlightCategory.allCases, id: \.self) { category in
                            categoryChip(
                                label: category.displayName,
                                icon: category.icon,
                                isSelected: highlightService.selectedCategory == category
                            ) {
                                if highlightService.selectedCategory == category {
                                    highlightService.selectedCategory = nil
                                } else {
                                    highlightService.selectedCategory = category
                                }
                            }
                        }
                    }
                }

                Divider()
                    .frame(height: 20)

                // Star filter toggle
                Button(action: {
                    highlightService.showStarredOnly.toggle()
                }) {
                    Image(systemName: highlightService.showStarredOnly ? "star.fill" : "star")
                        .foregroundColor(highlightService.showStarredOnly ? Color.hcdWarning : Color.hcdTextTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(highlightService.showStarredOnly ? "Show all highlights" : "Show starred only")
                .accessibilityHint("Toggles the star filter")

                // Sort picker
                Menu {
                    ForEach(HighlightSortOrder.allCases, id: \.self) { order in
                        Button(action: { highlightService.sortOrder = order }) {
                            HStack {
                                Text(order.displayName)
                                if highlightService.sortOrder == order {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundColor(Color.hcdTextTertiary)
                }
                .accessibilityLabel("Sort order: \(highlightService.sortOrder.displayName)")
                .accessibilityHint("Opens sort options menu")
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Category Chip

    private func categoryChip(
        label: String,
        icon: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }
                Text(label)
                    .font(Typography.caption)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .foregroundColor(isSelected ? Color.white : Color.hcdTextSecondary)
            .background(isSelected ? Color.hcdPrimary : Color.hcdBackgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) filter")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Highlight List View

    private var highlightListView: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(highlightService.filteredHighlights) { highlight in
                    highlightCard(highlight)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.lg)
        }
    }

    // MARK: - Highlight Card

    private func highlightCard(_ highlight: Highlight) -> some View {
        let isExpanded = expandedHighlightId == highlight.id
        let categoryColor = Color(nsColor: NSColor(hex: highlight.category.colorHex))

        return VStack(alignment: .leading, spacing: Spacing.md) {
            // Card header
            HStack(spacing: Spacing.sm) {
                // Category indicator
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 8, height: 8)
                    Image(systemName: highlight.category.icon)
                        .font(.system(size: 11))
                        .foregroundColor(categoryColor)
                }

                // Title
                Text(highlight.title)
                    .font(Typography.bodyMedium)
                    .foregroundColor(Color.hcdTextPrimary)
                    .lineLimit(isExpanded ? nil : 1)

                Spacer()

                // Star button
                Button(action: { highlightService.toggleStar(highlight.id) }) {
                    Image(systemName: highlight.isStarred ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundColor(highlight.isStarred ? Color.hcdWarning : Color.hcdTextTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(highlight.isStarred ? "Remove star" : "Add star")
                .accessibilityHint("Toggles star status for this highlight")
            }

            // Quote text
            Text(highlight.quoteText)
                .font(Typography.body)
                .italic()
                .foregroundColor(Color.hcdTextSecondary)
                .lineLimit(isExpanded ? nil : 2)
                .textSelection(.enabled)

            // Speaker + timestamp
            HStack(spacing: Spacing.md) {
                Label(highlight.speaker, systemImage: "person.fill")
                    .font(Typography.caption)
                    .foregroundColor(Color.hcdTextTertiary)

                Label(highlight.formattedTimestamp, systemImage: "clock")
                    .font(Typography.caption)
                    .foregroundColor(Color.hcdTextTertiary)

                if !highlight.notes.isEmpty && !isExpanded {
                    Label("Has notes", systemImage: "note.text")
                        .font(Typography.caption)
                        .foregroundColor(Color.hcdTextTertiary)
                }

                Spacer()

                // Category badge
                Text(highlight.category.displayName)
                    .font(Typography.small)
                    .foregroundColor(categoryColor)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 2)
                    .background(categoryColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
            }

            // Expanded edit section
            if isExpanded {
                expandedEditSection(highlight)
            }
        }
        .padding(Spacing.lg)
        .glassCard(isSelected: isExpanded, accentColor: categoryColor)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isExpanded {
                    expandedHighlightId = nil
                } else {
                    expandedHighlightId = highlight.id
                    editingTitle = highlight.title
                    editingNotes = highlight.notes
                    editingCategory = highlight.category
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(highlight.title). \(highlight.category.displayName). \(highlight.speaker) at \(highlight.formattedTimestamp)")
        .accessibilityHint(isExpanded ? "Tap to collapse" : "Tap to expand and edit")
    }

    // MARK: - Expanded Edit Section

    private func expandedEditSection(_ highlight: Highlight) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Divider()

            // Title editing
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Title")
                    .font(Typography.caption)
                    .foregroundColor(Color.hcdTextTertiary)
                    .textCase(.uppercase)

                TextField("Highlight title", text: $editingTitle)
                    .textFieldStyle(.roundedBorder)
                    .font(Typography.body)
                    .accessibilityLabel("Highlight title")
            }

            // Category editing
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Category")
                    .font(Typography.caption)
                    .foregroundColor(Color.hcdTextTertiary)
                    .textCase(.uppercase)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(HighlightCategory.allCases, id: \.self) { category in
                            let catColor = Color(nsColor: NSColor(hex: category.colorHex))
                            Button(action: { editingCategory = category }) {
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: category.icon)
                                        .font(.system(size: 10))
                                    Text(category.displayName)
                                        .font(Typography.caption)
                                }
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                                .foregroundColor(editingCategory == category ? Color.white : catColor)
                                .background(editingCategory == category ? catColor : catColor.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(category.displayName) category")
                            .accessibilityAddTraits(editingCategory == category ? .isSelected : [])
                        }
                    }
                }
            }

            // Notes editing
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Notes")
                    .font(Typography.caption)
                    .foregroundColor(Color.hcdTextTertiary)
                    .textCase(.uppercase)

                TextField("Add notes...", text: $editingNotes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .font(Typography.body)
                    .lineLimit(3...6)
                    .accessibilityLabel("Highlight notes")
            }

            // Action buttons
            HStack {
                // Delete button
                Button(action: {
                    highlightToDelete = highlight.id
                    showDeleteConfirmation = true
                }) {
                    Label("Delete", systemImage: "trash")
                        .font(Typography.caption)
                        .foregroundColor(Color.hcdError)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete highlight")
                .accessibilityHint("Permanently removes this highlight")

                Spacer()

                // Save button
                Button(action: {
                    highlightService.updateHighlight(
                        highlight.id,
                        title: editingTitle,
                        category: editingCategory,
                        notes: editingNotes
                    )
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedHighlightId = nil
                    }
                }) {
                    Label("Save", systemImage: "checkmark.circle.fill")
                        .font(Typography.bodyMedium)
                }
                .glassButton(isActive: true, style: .primary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .disabled(editingTitle.isEmpty)
                .accessibilityLabel("Save changes")
            }
        }
    }

    // MARK: - Empty States

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "quote.opening")
                .font(.system(size: 48))
                .foregroundColor(Color.hcdTextTertiary)

            Text("No Highlights Yet")
                .font(Typography.heading2)
                .foregroundColor(Color.hcdTextPrimary)

            Text("Select text in a transcript and save it as a highlight to build your quote library.")
                .font(Typography.body)
                .foregroundColor(Color.hcdTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No highlights yet. Select text in a transcript and save it as a highlight to build your quote library.")
    }

    private var noMatchesView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(Color.hcdTextTertiary)

            Text("No Matches Found")
                .font(Typography.heading2)
                .foregroundColor(Color.hcdTextPrimary)

            Text("Try adjusting your search or filters to find highlights.")
                .font(Typography.body)
                .foregroundColor(Color.hcdTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            Button(action: clearFilters) {
                Text("Clear Filters")
                    .font(Typography.bodyMedium)
            }
            .glassButton(style: .secondary)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .accessibilityLabel("Clear all filters")
            .accessibilityHint("Removes search query, category filter, and star filter")

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("No matches found for current filters")
    }

    // MARK: - Export Result Sheet

    private var exportResultSheet: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Text("Exported Highlights")
                    .font(Typography.heading2)
                    .foregroundColor(Color.hcdTextPrimary)

                Spacer()

                Button(action: { showExportResult = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.hcdTextTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close export")
            }

            ScrollView {
                Text(exportedMarkdown)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color.hcdTextPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Spacer()

                Button(action: copyExportToClipboard) {
                    Label("Copy to Clipboard", systemImage: "doc.on.doc")
                        .font(Typography.bodyMedium)
                }
                .glassButton(isActive: true, style: .primary)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .accessibilityLabel("Copy exported Markdown to clipboard")
            }
        }
        .padding(Spacing.xl)
        .frame(width: 500, height: 400)
        .background(Color.hcdBackground)
    }

    // MARK: - Actions

    private func exportFilteredHighlights() {
        if highlightService.showStarredOnly {
            exportedMarkdown = highlightService.exportStarredAsMarkdown()
        } else {
            exportedMarkdown = highlightService.exportAsMarkdown()
        }
        showExportResult = true
    }

    private func copyExportToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(exportedMarkdown, forType: .string)
    }

    private func clearFilters() {
        highlightService.searchQuery = ""
        highlightService.selectedCategory = nil
        highlightService.showStarredOnly = false
    }
}

// MARK: - Preview Provider

#if DEBUG
struct QuoteLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        QuoteLibraryView(
            highlightService: HighlightService(
                storageURL: FileManager.default.temporaryDirectory
                    .appendingPathComponent("preview_highlights.json")
            ),
            onDismiss: {}
        )
    }
}
#endif
