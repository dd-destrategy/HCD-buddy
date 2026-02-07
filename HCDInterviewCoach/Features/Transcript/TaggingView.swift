//
//  TaggingView.swift
//  HCDInterviewCoach
//
//  FEATURE 5: Post-Session Tagging & Coding
//  SwiftUI panel providing the tagging workflow for transcript coding.
//

import SwiftUI

// MARK: - Tagging Panel View

/// A panel providing the full tagging workflow for coding transcript segments.
///
/// Layout:
/// - Tag palette (colored pills for available tags, click to select active tag)
/// - Create new tag inline form
/// - Tag filter (filter transcript by tag)
/// - Tag summary (counts per tag for current session)
/// - Bulk tag mode (select multiple utterances, apply tag)
struct TaggingView: View {

    // MARK: - Dependencies

    @ObservedObject var taggingService: TaggingService

    /// The ID of the session being tagged
    let sessionId: UUID

    /// All utterances in the current session
    let utterances: [Utterance]

    /// Callback when the user taps an utterance to navigate to it
    var onNavigateToUtterance: ((UUID) -> Void)?

    // MARK: - State

    @State private var isCreatingTag: Bool = false
    @State private var newTagName: String = ""
    @State private var newTagColor: Color = .blue
    @State private var filterTagId: UUID?
    @State private var isBulkMode: Bool = false
    @State private var bulkSelectedUtteranceIds: Set<UUID> = []

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            headerSection
            tagPalette
            Divider()
            tagFilterSection
            Divider()
            tagSummarySection

            if isBulkMode {
                Divider()
                bulkTagSection
            }
        }
        .padding(Spacing.lg)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tagging panel for coding transcript segments")
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("Tags")
                .font(Typography.heading2)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Toggle("Bulk Mode", isOn: $isBulkMode)
                .toggleStyle(.switch)
                .controlSize(.small)
                .accessibilityLabel("Bulk tagging mode")
                .accessibilityHint("When enabled, select multiple utterances then apply a tag to all of them")
                .onChange(of: isBulkMode) { _, newValue in
                    if !newValue {
                        bulkSelectedUtteranceIds.removeAll()
                    }
                }
        }
    }

    // MARK: - Tag Palette

    private var tagPalette: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Tag Palette")
                .font(Typography.bodyMedium)
                .foregroundColor(.secondary)
                .accessibilityAddTraits(.isHeader)

            FlowLayout(spacing: Spacing.sm) {
                ForEach(taggingService.tags) { tag in
                    TagPill(
                        tag: tag,
                        isSelected: taggingService.selectedTagId == tag.id,
                        onTap: {
                            if taggingService.selectedTagId == tag.id {
                                taggingService.selectedTagId = nil
                            } else {
                                taggingService.selectedTagId = tag.id
                            }
                        },
                        onDelete: {
                            taggingService.deleteTag(tag.id)
                        }
                    )
                }

                // Add tag button
                Button(action: {
                    isCreatingTag.toggle()
                }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                        Text("New Tag")
                            .font(Typography.caption)
                    }
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        Capsule()
                            .stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Create new tag")
                .accessibilityHint("Opens a form to create a custom tag")
            }

            if isCreatingTag {
                createTagForm
            }
        }
    }

    // MARK: - Create Tag Form

    private var createTagForm: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                TextField("Tag name", text: $newTagName)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 180)
                    .accessibilityLabel("New tag name")

                ColorPicker("Color", selection: $newTagColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 30)
                    .accessibilityLabel("Tag color picker")

                Button("Add") {
                    guard !newTagName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let hexColor = newTagColor.toHexString()
                    taggingService.createTag(name: newTagName, colorHex: hexColor)
                    newTagName = ""
                    isCreatingTag = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Add tag")
                .accessibilityHint("Creates the new tag with the entered name and selected color")

                Button("Cancel") {
                    newTagName = ""
                    isCreatingTag = false
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel("Cancel tag creation")
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .fill(Color.secondary.opacity(0.05))
        )
    }

    // MARK: - Tag Filter Section

    private var tagFilterSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Filter by Tag")
                .font(Typography.bodyMedium)
                .foregroundColor(.secondary)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: Spacing.sm) {
                FilterChip(
                    label: "All",
                    isSelected: filterTagId == nil,
                    onTap: { filterTagId = nil }
                )

                ForEach(taggingService.tags) { tag in
                    FilterChip(
                        label: tag.name,
                        colorHex: tag.colorHex,
                        isSelected: filterTagId == tag.id,
                        onTap: {
                            filterTagId = filterTagId == tag.id ? nil : tag.id
                        }
                    )
                }
            }

            // Filtered utterance list
            if let filterId = filterTagId {
                filteredUtterancesList(tagId: filterId)
            }
        }
    }

    // MARK: - Filtered Utterances List

    private func filteredUtterancesList(tagId: UUID) -> some View {
        let tagAssignments = taggingService.getAssignments(forTag: tagId)
            .filter { $0.sessionId == sessionId }
        let taggedUtteranceIds = Set(tagAssignments.map { $0.utteranceId })
        let filteredUtterances = utterances.filter { taggedUtteranceIds.contains($0.id) }
            .sorted { $0.timestampSeconds < $1.timestampSeconds }

        return Group {
            if filteredUtterances.isEmpty {
                Text("No utterances tagged with this tag.")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, Spacing.sm)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Spacing.xs) {
                        ForEach(filteredUtterances, id: \.id) { utterance in
                            FilteredUtteranceRow(
                                utterance: utterance,
                                onTap: { onNavigateToUtterance?(utterance.id) }
                            )
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
    }

    // MARK: - Tag Summary Section

    private var tagSummarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Tag Summary")
                .font(Typography.bodyMedium)
                .foregroundColor(.secondary)
                .accessibilityAddTraits(.isHeader)

            let sessionAssignments = taggingService.getAssignments(forSession: sessionId)

            if sessionAssignments.isEmpty {
                Text("No tags applied to this session yet.")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
            } else {
                let tagCounts = computeTagCounts(from: sessionAssignments)
                ForEach(tagCounts, id: \.tag.id) { entry in
                    HStack(spacing: Spacing.sm) {
                        Circle()
                            .fill(Color(hex: entry.tag.colorHex))
                            .frame(width: 10, height: 10)
                            .accessibilityHidden(true)

                        Text(entry.tag.name)
                            .font(Typography.body)
                            .foregroundColor(.primary)

                        Spacer()

                        Text("\(entry.count)")
                            .font(Typography.bodyMedium)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(entry.tag.name): \(entry.count) tagged segments")
                }
            }
        }
    }

    // MARK: - Bulk Tag Section

    private var bulkTagSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Bulk Tagging")
                .font(Typography.bodyMedium)
                .foregroundColor(.secondary)
                .accessibilityAddTraits(.isHeader)

            Text("\(bulkSelectedUtteranceIds.count) utterance(s) selected")
                .font(Typography.caption)
                .foregroundColor(.secondary)

            // List utterances as selectable rows
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(utterances, id: \.id) { utterance in
                        BulkSelectRow(
                            utterance: utterance,
                            isSelected: bulkSelectedUtteranceIds.contains(utterance.id),
                            onToggle: {
                                if bulkSelectedUtteranceIds.contains(utterance.id) {
                                    bulkSelectedUtteranceIds.remove(utterance.id)
                                } else {
                                    bulkSelectedUtteranceIds.insert(utterance.id)
                                }
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 200)

            HStack(spacing: Spacing.sm) {
                Button("Apply Selected Tag") {
                    applyBulkTag()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(taggingService.selectedTagId == nil || bulkSelectedUtteranceIds.isEmpty)
                .accessibilityLabel("Apply selected tag to all selected utterances")
                .accessibilityHint(
                    taggingService.selectedTagId == nil
                        ? "Select a tag from the palette first"
                        : "Applies the active tag to \(bulkSelectedUtteranceIds.count) utterances"
                )

                Button("Clear Selection") {
                    bulkSelectedUtteranceIds.removeAll()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(bulkSelectedUtteranceIds.isEmpty)
                .accessibilityLabel("Clear utterance selection")
            }
        }
    }

    // MARK: - Helpers

    private struct TagCountEntry {
        let tag: Tag
        let count: Int
    }

    private func computeTagCounts(from sessionAssignments: [UtteranceTagAssignment]) -> [TagCountEntry] {
        var countsByTagId: [UUID: Int] = [:]
        for assignment in sessionAssignments {
            countsByTagId[assignment.tagId, default: 0] += 1
        }

        let tagLookup = Dictionary(uniqueKeysWithValues: taggingService.tags.map { ($0.id, $0) })

        return countsByTagId.compactMap { tagId, count in
            guard let tag = tagLookup[tagId] else { return nil }
            return TagCountEntry(tag: tag, count: count)
        }
        .sorted { $0.count > $1.count }
    }

    private func applyBulkTag() {
        guard let tagId = taggingService.selectedTagId else { return }

        for utteranceId in bulkSelectedUtteranceIds {
            taggingService.assignTag(tagId, to: utteranceId, sessionId: sessionId)
        }

        bulkSelectedUtteranceIds.removeAll()
        AppLogger.shared.info("Applied bulk tag \(tagId) to \(bulkSelectedUtteranceIds.count) utterances")
    }
}

// MARK: - Tag Pill

/// A colored pill representing a single tag. Tap to select, long-press context menu for delete.
struct TagPill: View {

    let tag: Tag
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.xs) {
                Circle()
                    .fill(Color(hex: tag.colorHex))
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)

                Text(tag.name)
                    .font(Typography.caption)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected
                        ? Color(hex: tag.colorHex)
                        : Color(hex: tag.colorHex).opacity(0.15))
            )
            .overlay(
                Capsule()
                    .stroke(Color(hex: tag.colorHex).opacity(0.5), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Tag", systemImage: "trash")
            }
        }
        .accessibilityLabel("\(tag.name) tag")
        .accessibilityHint(isSelected
            ? "Currently selected. Tap to deselect."
            : "Tap to select this tag for applying to utterances.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Tagged Utterance Indicator

/// Small colored dots shown next to tagged utterances in the transcript.
struct TaggedUtteranceIndicator: View {

    let tags: [Tag]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(tags.prefix(5)) { tag in
                Circle()
                    .fill(Color(hex: tag.colorHex))
                    .frame(width: 6, height: 6)
            }

            if tags.count > 5 {
                Text("+\(tags.count - 5)")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(tagAccessibilityLabel)
    }

    private var tagAccessibilityLabel: String {
        let names = tags.map { $0.name }.joined(separator: ", ")
        return "Tagged with: \(names)"
    }
}

// MARK: - Filter Chip

/// A small chip used for tag filtering, with optional color dot.
private struct FilterChip: View {

    let label: String
    var colorHex: String?
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.xs) {
                if let hex = colorHex {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                }

                Text(label)
                    .font(Typography.caption)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected
                        ? Color.accentColor
                        : (colorScheme == .dark
                            ? Color.white.opacity(0.08)
                            : Color.black.opacity(0.05)))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Filter by \(label)")
        .accessibilityHint(isSelected ? "Currently active. Tap to remove filter." : "Tap to filter by this tag.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Filtered Utterance Row

/// A compact utterance row shown in the filtered view.
private struct FilteredUtteranceRow: View {

    let utterance: Utterance
    let onTap: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                Text(utterance.formattedTimestamp)
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 48, alignment: .trailing)

                Text(utterance.speaker.displayName)
                    .font(Typography.caption)
                    .foregroundColor(.accentColor)
                    .frame(width: 80, alignment: .leading)

                Text(utterance.text)
                    .font(Typography.caption)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, Spacing.xs)
            .padding(.horizontal, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(isHovering
                        ? Color.accentColor.opacity(0.08)
                        : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel("\(utterance.formattedTimestamp), \(utterance.speaker.displayName): \(utterance.text)")
        .accessibilityHint("Tap to navigate to this utterance in the transcript")
    }
}

// MARK: - Bulk Select Row

/// A selectable utterance row for bulk tagging mode.
private struct BulkSelectRow: View {

    let utterance: Utterance
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .accessibilityHidden(true)

                Text(utterance.formattedTimestamp)
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 48, alignment: .trailing)

                Text(utterance.text)
                    .font(Typography.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, Spacing.xs)
            .padding(.horizontal, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(isSelected
                        ? Color.accentColor.opacity(0.08)
                        : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(utterance.formattedTimestamp): \(utterance.text)"
        )
        .accessibilityHint(isSelected ? "Selected. Tap to deselect." : "Tap to select for bulk tagging.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Flow Layout

/// A simple horizontal flow layout that wraps children to the next line when needed.
private struct FlowLayout: Layout {

    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layoutSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layoutSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            guard index < subviews.count else { break }
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private struct LayoutResult {
        var size: CGSize
        var positions: [CGPoint]
    }

    private func layoutSubviews(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
            totalHeight = currentY + lineHeight
        }

        return LayoutResult(
            size: CGSize(width: totalWidth, height: totalHeight),
            positions: positions
        )
    }
}

// MARK: - Color Extensions

extension Color {
    /// Creates a SwiftUI Color from a hex string (e.g., "#E74C3C" or "E74C3C").
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hex.count {
        case 3:
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }

        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }

    /// Converts a SwiftUI Color to a hex string (e.g., "#E74C3C").
    func toHexString() -> String {
        guard let components = NSColor(self).cgColor.components else {
            return "#000000"
        }

        let r = components.count > 0 ? components[0] : 0
        let g = components.count > 1 ? components[1] : 0
        let b = components.count > 2 ? components[2] : 0

        return String(
            format: "#%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
    }
}

// MARK: - Preview

#if DEBUG
struct TaggingView_Previews: PreviewProvider {
    static var previews: some View {
        TaggingView(
            taggingService: TaggingService(),
            sessionId: UUID(),
            utterances: []
        )
        .frame(width: 360, height: 600)
    }
}
#endif
