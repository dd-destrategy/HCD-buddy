//
//  TranscriptSearchView.swift
//  HCDInterviewCoach
//
//  EPIC E5: Transcript Display
//  Search functionality for finding content within the transcript
//

import SwiftUI

// MARK: - Transcript Search View

/// Search bar and results navigation for the transcript.
/// Supports keyboard shortcuts and VoiceOver.
struct TranscriptSearchView: View {

    // MARK: - Properties

    /// Binding to the search query
    @Binding var searchQuery: String

    /// Search results
    let results: [SearchResult]

    /// Current result index
    @Binding var currentResultIndex: Int

    /// Whether search is loading
    var isLoading: Bool = false

    /// Callback for navigating to previous result
    var onPrevious: (() -> Void)?

    /// Callback for navigating to next result
    var onNext: (() -> Void)?

    /// Callback to close search
    var onClose: (() -> Void)?

    // MARK: - State

    @FocusState private var isSearchFieldFocused: Bool
    @State private var showFilterPopover: Bool = false

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            // Search field
            searchField

            // Results indicator
            if !searchQuery.isEmpty {
                resultsIndicator
            }

            // Navigation buttons
            if hasResults {
                navigationButtons
            }

            // Close button
            closeButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(searchBarBackground)
        .onAppear {
            isSearchFieldFocused = true
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Transcript search")
    }

    // MARK: - Components

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            TextField("Search transcript...", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.system(.body))
                .focused($isSearchFieldFocused)
                .onSubmit {
                    if hasResults {
                        onNext?()
                    }
                }
                .accessibilityLabel("Search transcript")
                .accessibilityHint("Type to search within the transcript")

            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else if !searchQuery.isEmpty {
                Button(action: clearSearch) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(fieldBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(
                    isSearchFieldFocused ? Color.accentColor : Color.clear,
                    lineWidth: 2
                )
        )
    }

    private var resultsIndicator: some View {
        Text(resultsText)
            .font(.system(.caption, design: .default))
            .foregroundColor(hasResults ? .secondary : .orange)
            .monospacedDigit()
            .accessibilityLabel(resultsAccessibilityText)
    }

    private var navigationButtons: some View {
        HStack(spacing: 2) {
            Button(action: { onPrevious?() }) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .disabled(!hasResults)
            .keyboardShortcut(.upArrow, modifiers: .command)
            .help("Previous match (Cmd+Up)")
            .accessibilityLabel("Previous match")

            Button(action: { onNext?() }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .disabled(!hasResults)
            .keyboardShortcut(.downArrow, modifiers: .command)
            .help("Next match (Cmd+Down)")
            .accessibilityLabel("Next match")
        }
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(buttonBackgroundColor)
        )
    }

    private var closeButton: some View {
        Button(action: { onClose?() }) {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.escape, modifiers: [])
        .help("Close search (Escape)")
        .accessibilityLabel("Close search")
    }

    private var searchBarBackground: some View {
        Rectangle()
            .fill(backgroundMaterial)
            .overlay(
                Rectangle()
                    .fill(Color(nsColor: .separatorColor))
                    .frame(height: 1),
                alignment: .bottom
            )
    }

    // MARK: - Computed Properties

    private var hasResults: Bool {
        !results.isEmpty
    }

    private var resultsText: String {
        if searchQuery.isEmpty {
            return ""
        } else if results.isEmpty {
            return "No matches"
        } else {
            return "\(currentResultIndex + 1) of \(results.count)"
        }
    }

    private var resultsAccessibilityText: String {
        if searchQuery.isEmpty {
            return ""
        } else if results.isEmpty {
            return "No matches found"
        } else {
            return "Match \(currentResultIndex + 1) of \(results.count)"
        }
    }

    // MARK: - Colors

    private var fieldBackgroundColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color.black.opacity(0.03)
    }

    private var buttonBackgroundColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color.black.opacity(0.03)
    }

    private var backgroundMaterial: Color {
        Color(nsColor: .windowBackgroundColor)
    }

    // MARK: - Actions

    private func clearSearch() {
        searchQuery = ""
    }
}

// MARK: - Search Results List View

/// Displays search results in a list format for quick navigation
struct SearchResultsListView: View {

    // MARK: - Properties

    let results: [SearchResult]
    let currentIndex: Int
    var onSelectResult: ((Int) -> Void)?

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            List(Array(results.enumerated()), id: \.element.id) { index, result in
                SearchResultRow(
                    result: result,
                    isSelected: index == currentIndex,
                    onSelect: { onSelectResult?(index) }
                )
                .id(result.id)
            }
            .listStyle(.plain)
            .onChange(of: currentIndex) { _, newIndex in
                if newIndex >= 0 && newIndex < results.count {
                    withAnimation {
                        proxy.scrollTo(results[newIndex].id, anchor: .center)
                    }
                }
            }
        }
    }
}

// MARK: - Search Result Row

/// Individual search result row
struct SearchResultRow: View {

    let result: SearchResult
    var isSelected: Bool = false
    var onSelect: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: { onSelect?() }) {
            HStack(alignment: .top, spacing: 8) {
                // Timestamp
                Text(result.formattedTimestamp)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 45, alignment: .trailing)

                // Context with highlighted match
                Text(highlightedContext)
                    .font(.system(.body))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? selectionColor : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Match at \(result.formattedTimestamp)")
        .accessibilityValue(result.context)
        .accessibilityHint("Double tap to navigate to this match")
    }

    private var highlightedContext: AttributedString {
        var attributedString = AttributedString(result.context)

        if let attrStart = AttributedString.Index(result.matchRange.lowerBound, within: attributedString),
           let attrEnd = AttributedString.Index(result.matchRange.upperBound, within: attributedString) {
            attributedString[attrStart..<attrEnd].backgroundColor = .yellow.opacity(0.4)
            attributedString[attrStart..<attrEnd].foregroundColor = .black
        }

        return attributedString
    }

    private var selectionColor: Color {
        Color.accentColor.opacity(colorScheme == .dark ? 0.2 : 0.1)
    }
}

// MARK: - Search Filter Options

/// Filter options for search
struct SearchFilterOptions {
    var speakerFilter: Speaker?
    var caseSensitive: Bool = false
    var wholeWord: Bool = false

    static let `default` = SearchFilterOptions()
}

// MARK: - Search Filter Popover

/// Popover for configuring search filters
struct SearchFilterPopover: View {

    @Binding var options: SearchFilterOptions

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Options")
                .font(.headline)

            Divider()

            // Speaker filter
            VStack(alignment: .leading, spacing: 4) {
                Text("Speaker")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("Speaker", selection: $options.speakerFilter) {
                    Text("All").tag(Speaker?.none)
                    Text("Interviewer").tag(Speaker?.some(.interviewer))
                    Text("Participant").tag(Speaker?.some(.participant))
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Divider()

            // Match options
            Toggle("Case sensitive", isOn: $options.caseSensitive)
            Toggle("Whole word only", isOn: $options.wholeWord)
        }
        .padding()
        .frame(width: 220)
    }
}

// MARK: - Preview

#if DEBUG
struct TranscriptSearchView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Empty search
            TranscriptSearchView(
                searchQuery: .constant(""),
                results: [],
                currentResultIndex: .constant(0)
            )

            // With query and results
            TranscriptSearchView(
                searchQuery: .constant("navigation"),
                results: [
                    SearchResult(
                        utteranceId: UUID(),
                        matchRange: "navigation".startIndex..<"navigation".endIndex,
                        context: "The navigation is really confusing",
                        timestamp: 132
                    ),
                    SearchResult(
                        utteranceId: UUID(),
                        matchRange: "navigation".startIndex..<"navigation".endIndex,
                        context: "I can't find the navigation menu",
                        timestamp: 245
                    )
                ],
                currentResultIndex: .constant(0)
            )

            // No results
            TranscriptSearchView(
                searchQuery: .constant("foobar"),
                results: [],
                currentResultIndex: .constant(0)
            )

            // Loading
            TranscriptSearchView(
                searchQuery: .constant("searching..."),
                results: [],
                currentResultIndex: .constant(0),
                isLoading: true
            )
        }
        .frame(width: 500)
        .padding()
    }
}
#endif
