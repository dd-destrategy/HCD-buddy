//
//  ParticipantPickerView.swift
//  HCDInterviewCoach
//
//  FEATURE F: Participant Management System
//  Sheet/inline view for selecting or creating a participant before starting a session.
//  Supports search, selection, and inline creation with full accessibility.
//

import SwiftUI

// MARK: - Participant Picker View

/// A picker view for selecting an existing participant or creating a new one
/// before starting an interview session.
///
/// Presents a searchable list of existing participants with inline creation
/// capability. Calls `onSelect` with the chosen participant, or nil if skipped.
struct ParticipantPickerView: View {

    @ObservedObject var participantManager: ParticipantManager

    /// Callback invoked when a participant is selected, created, or the picker is skipped
    var onSelect: ((Participant?) -> Void)

    @Environment(\.colorScheme) private var colorScheme

    @State private var isCreating: Bool = false
    @State private var selectedParticipantId: UUID?
    @State private var localSearchQuery: String = ""

    // Creation form fields
    @State private var newName: String = ""
    @State private var newEmail: String = ""
    @State private var newRole: String = ""
    @State private var newDepartment: String = ""
    @State private var newOrganization: String = ""
    @State private var newExperienceLevel: ExperienceLevel?
    @State private var newNotes: String = ""
    @State private var metadataEntries: [MetadataEntry] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            Divider()

            if isCreating {
                creationFormView
            } else {
                selectionView
            }

            Divider()
            footerView
        }
        .frame(minWidth: 420, idealWidth: 480, minHeight: 400, idealHeight: 560)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Participant picker")
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(isCreating ? "New Participant" : "Select Participant")
                    .font(Typography.heading2)
                    .foregroundColor(.hcdTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text(isCreating
                     ? "Enter participant details"
                     : "Choose an existing participant or create a new one")
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextSecondary)
            }

            Spacer()

            if isCreating {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCreating = false
                    }
                }) {
                    Text("Back to List")
                        .font(Typography.caption)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.plain)
                .glassButton(style: .ghost)
                .accessibilityLabel("Back to participant list")
                .accessibilityHint("Return to the participant selection list")
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Selection View

    private var selectionView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search bar
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(Typography.body)
                    .foregroundColor(.hcdTextSecondary)
                    .accessibilityHidden(true)

                TextField("Search participants...", text: $localSearchQuery)
                    .font(Typography.body)
                    .textFieldStyle(.plain)
                    .accessibilityLabel("Search participants")
                    .accessibilityHint("Type to filter the participant list by name, email, role, or organization")

                if !localSearchQuery.isEmpty {
                    Button(action: { localSearchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(Typography.caption)
                            .foregroundColor(.hcdTextTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.06)
                          : Color.black.opacity(0.04))
            )
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)

            // New Participant button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCreating = true
                }
            }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(Typography.body)
                        .foregroundColor(.accentColor)

                    Text("New Participant")
                        .font(Typography.bodyMedium)
                        .foregroundColor(.accentColor)

                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            .accessibilityLabel("New Participant")
            .accessibilityHint("Switch to the creation form to add a new participant")

            // Participant list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.sm) {
                    let filtered = filteredResults
                    if filtered.isEmpty {
                        emptySearchView
                    } else {
                        ForEach(filtered) { participant in
                            participantRow(participant)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
            }
        }
    }

    // MARK: - Participant Row

    private func participantRow(_ participant: Participant) -> some View {
        let isSelected = selectedParticipantId == participant.id

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                if selectedParticipantId == participant.id {
                    selectedParticipantId = nil
                } else {
                    selectedParticipantId = participant.id
                }
            }
        }) {
            HStack(spacing: Spacing.md) {
                // Avatar circle
                ZStack {
                    Circle()
                        .fill(colorScheme == .dark
                              ? Color.white.opacity(0.1)
                              : Color.black.opacity(0.06))
                        .frame(width: 36, height: 36)

                    Text(participantInitials(participant.name))
                        .font(Typography.caption)
                        .foregroundColor(.hcdTextSecondary)
                }
                .accessibilityHidden(true)

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(participant.name)
                        .font(Typography.bodyMedium)
                        .foregroundColor(.hcdTextPrimary)
                        .lineLimit(1)

                    HStack(spacing: Spacing.sm) {
                        if let role = participant.role, !role.isEmpty {
                            Text(role)
                                .font(Typography.caption)
                                .foregroundColor(.hcdTextSecondary)
                                .lineLimit(1)
                        }

                        if let org = participant.organization, !org.isEmpty {
                            if participant.role != nil {
                                Text("at")
                                    .font(Typography.caption)
                                    .foregroundColor(.hcdTextTertiary)
                            }
                            Text(org)
                                .font(Typography.caption)
                                .foregroundColor(.hcdTextSecondary)
                                .lineLimit(1)
                        }
                    }

                    if participant.sessionCount > 0 {
                        Text("\(participant.sessionCount) session\(participant.sessionCount == 1 ? "" : "s")")
                            .font(Typography.small)
                            .foregroundColor(.hcdTextTertiary)
                    }
                }

                Spacer()

                // Selection checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Typography.heading3)
                        .foregroundColor(.accentColor)
                        .accessibilityHidden(true)
                }
            }
            .padding(Spacing.sm)
            .glassCard(isSelected: isSelected, accentColor: .accentColor)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(participant.name)\(participant.role.map { ", \($0)" } ?? "")\(participant.organization.map { " at \($0)" } ?? "")")
        .accessibilityHint(isSelected
                           ? "Currently selected. Double-tap to deselect"
                           : "Double-tap to select this participant")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Empty Search View

    private var emptySearchView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 32))
                .foregroundColor(.hcdTextTertiary)
                .accessibilityHidden(true)

            Text("No participants found")
                .font(Typography.bodyMedium)
                .foregroundColor(.hcdTextSecondary)

            if !localSearchQuery.isEmpty {
                Text("Try a different search or create a new participant.")
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No participants found")
    }

    // MARK: - Creation Form

    private var creationFormView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Name (required)
                formField(label: "Name", required: true) {
                    TextField("Full name", text: $newName)
                        .font(Typography.body)
                        .textFieldStyle(.plain)
                        .accessibilityLabel("Participant name")
                        .accessibilityHint("Required. Enter the participant's full name")
                }

                // Email
                formField(label: "Email") {
                    TextField("email@example.com", text: $newEmail)
                        .font(Typography.body)
                        .textFieldStyle(.plain)
                        .accessibilityLabel("Email address")
                }

                // Role
                formField(label: "Role") {
                    TextField("Job title or role", text: $newRole)
                        .font(Typography.body)
                        .textFieldStyle(.plain)
                        .accessibilityLabel("Role or job title")
                }

                // Department
                formField(label: "Department") {
                    TextField("Department", text: $newDepartment)
                        .font(Typography.body)
                        .textFieldStyle(.plain)
                        .accessibilityLabel("Department")
                }

                // Organization
                formField(label: "Organization") {
                    TextField("Company or organization", text: $newOrganization)
                        .font(Typography.body)
                        .textFieldStyle(.plain)
                        .accessibilityLabel("Organization")
                }

                // Experience Level
                formField(label: "Experience Level") {
                    Picker("Experience Level", selection: $newExperienceLevel) {
                        Text("Not specified")
                            .tag(nil as ExperienceLevel?)
                        ForEach(ExperienceLevel.allCases, id: \.self) { level in
                            Text(level.displayName)
                                .tag(level as ExperienceLevel?)
                        }
                    }
                    .labelsHidden()
                    .accessibilityLabel("Experience level")
                    .accessibilityHint("Select the participant's experience level")
                }

                // Notes
                formField(label: "Notes") {
                    TextEditor(text: $newNotes)
                        .font(Typography.body)
                        .frame(minHeight: 60, maxHeight: 100)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .accessibilityLabel("Notes")
                        .accessibilityHint("Optional notes about the participant")
                }

                // Custom Metadata
                metadataSection
            }
            .padding(Spacing.lg)
        }
    }

    // MARK: - Form Field Helper

    private func formField<Content: View>(
        label: String,
        required: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Text(label)
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextSecondary)

                if required {
                    Text("*")
                        .font(Typography.caption)
                        .foregroundColor(.hcdError)
                        .accessibilityLabel("required")
                }
            }

            content()
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .fill(colorScheme == .dark
                              ? Color.white.opacity(0.06)
                              : Color.black.opacity(0.04))
                )
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Custom Fields")
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextSecondary)

                Spacer()

                Button(action: {
                    metadataEntries.append(MetadataEntry())
                }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus")
                            .font(Typography.small)
                        Text("Add Field")
                            .font(Typography.caption)
                    }
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add custom field")
                .accessibilityHint("Add a new key-value metadata field")
            }

            ForEach($metadataEntries) { $entry in
                HStack(spacing: Spacing.sm) {
                    TextField("Key", text: $entry.key)
                        .font(Typography.caption)
                        .textFieldStyle(.plain)
                        .frame(maxWidth: 120)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                                .fill(colorScheme == .dark
                                      ? Color.white.opacity(0.06)
                                      : Color.black.opacity(0.04))
                        )
                        .accessibilityLabel("Field name")

                    TextField("Value", text: $entry.value)
                        .font(Typography.caption)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                                .fill(colorScheme == .dark
                                      ? Color.white.opacity(0.06)
                                      : Color.black.opacity(0.04))
                        )
                        .accessibilityLabel("Field value")

                    Button(action: {
                        metadataEntries.removeAll { $0.id == entry.id }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(Typography.body)
                            .foregroundColor(.hcdError)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove field")
                    .accessibilityHint("Remove this custom metadata field")
                }
            }
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack(spacing: Spacing.md) {
            Button(action: {
                onSelect(nil)
            }) {
                Text("Skip")
                    .font(Typography.bodyMedium)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .glassButton(style: .ghost)
            .accessibilityLabel("Skip participant selection")
            .accessibilityHint("Continue without selecting a participant")

            Spacer()

            if isCreating {
                Button(action: createAndSelect) {
                    Text("Create & Select")
                        .font(Typography.bodyMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.plain)
                .glassButton(isActive: true, style: .primary)
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Create and select participant")
                .accessibilityHint("Create the new participant and select them for the session")
            } else {
                Button(action: confirmSelection) {
                    Text("Select")
                        .font(Typography.bodyMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.plain)
                .glassButton(isActive: true, style: .primary)
                .disabled(selectedParticipantId == nil)
                .accessibilityLabel("Select participant")
                .accessibilityHint("Confirm selection of the highlighted participant")
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Actions

    private func confirmSelection() {
        guard let id = selectedParticipantId,
              let participant = participantManager.participant(byId: id)
        else {
            return
        }
        onSelect(participant)
    }

    private func createAndSelect() {
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        var metadata: [String: String] = [:]
        for entry in metadataEntries {
            let key = entry.key.trimmingCharacters(in: .whitespaces)
            let value = entry.value.trimmingCharacters(in: .whitespaces)
            if !key.isEmpty && !value.isEmpty {
                metadata[key] = value
            }
        }

        let participant = participantManager.createParticipant(
            name: trimmedName,
            email: newEmail.isEmpty ? nil : newEmail.trimmingCharacters(in: .whitespaces),
            role: newRole.isEmpty ? nil : newRole.trimmingCharacters(in: .whitespaces),
            department: newDepartment.isEmpty ? nil : newDepartment.trimmingCharacters(in: .whitespaces),
            organization: newOrganization.isEmpty ? nil : newOrganization.trimmingCharacters(in: .whitespaces),
            experienceLevel: newExperienceLevel,
            notes: newNotes.trimmingCharacters(in: .whitespaces),
            metadata: metadata
        )

        onSelect(participant)
    }

    // MARK: - Helpers

    private var filteredResults: [Participant] {
        participantManager.searchParticipants(query: localSearchQuery)
    }

    private func participantInitials(_ name: String) -> String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
}

// MARK: - Metadata Entry

/// A single key-value metadata entry for the creation form
private struct MetadataEntry: Identifiable {
    let id = UUID()
    var key: String = ""
    var value: String = ""
}

// MARK: - Preview

#if DEBUG
struct ParticipantPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ParticipantPickerView(
                participantManager: previewManager(),
                onSelect: { participant in
                    if let p = participant {
                        print("Selected: \(p.name)")
                    } else {
                        print("Skipped")
                    }
                }
            )
            .glassSheet()
        }
    }

    @MainActor
    static func previewManager() -> ParticipantManager {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("preview_participants.json")
        let manager = ParticipantManager(storageURL: url)
        manager.createParticipant(
            name: "Jane Doe",
            email: "jane@example.com",
            role: "Product Manager",
            organization: "Acme Corp"
        )
        manager.createParticipant(
            name: "John Smith",
            role: "Developer",
            department: "Engineering",
            organization: "TechCo"
        )
        return manager
    }
}
#endif
