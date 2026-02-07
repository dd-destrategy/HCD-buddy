//
//  ParticipantDetailView.swift
//  HCDInterviewCoach
//
//  FEATURE F: Participant Management System
//  Detail view showing a single participant's profile with edit, export,
//  and delete capabilities. Supports GDPR data export and right-to-erasure.
//

import SwiftUI

// MARK: - Participant Detail View

/// Displays a single participant's full profile with edit, export, and delete capabilities.
///
/// Shows personal information, session history, custom metadata, and notes.
/// Supports toggling between view and edit modes, GDPR data export, and
/// participant deletion with confirmation.
struct ParticipantDetailView: View {

    @ObservedObject var participantManager: ParticipantManager

    /// The UUID of the participant to display
    let participantId: UUID

    /// Callback invoked when the view should be dismissed
    var onDismiss: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    @State private var isEditing: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showExportSheet: Bool = false
    @State private var exportedData: String = ""

    // Edit form state
    @State private var editName: String = ""
    @State private var editEmail: String = ""
    @State private var editRole: String = ""
    @State private var editDepartment: String = ""
    @State private var editOrganization: String = ""
    @State private var editExperienceLevel: ExperienceLevel?
    @State private var editNotes: String = ""
    @State private var editMetadata: [EditableMetadataEntry] = []

    var body: some View {
        Group {
            if let participant = participantManager.participant(byId: participantId) {
                participantContent(participant)
            } else {
                notFoundView
            }
        }
        .frame(minWidth: 400, idealWidth: 480, minHeight: 500, idealHeight: 640)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Participant detail")
    }

    // MARK: - Not Found

    private var notFoundView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.hcdTextTertiary)
                .accessibilityHidden(true)

            Text("Participant Not Found")
                .font(Typography.heading2)
                .foregroundColor(.hcdTextPrimary)

            Text("This participant may have been deleted.")
                .font(Typography.body)
                .foregroundColor(.hcdTextSecondary)

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Text("Close")
                        .font(Typography.bodyMedium)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.plain)
                .glassButton(style: .secondary)
                .accessibilityLabel("Close")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Content

    private func participantContent(_ participant: Participant) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            detailHeader(participant)

            Divider()

            // Body
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if isEditing {
                        editFormContent
                    } else {
                        viewContent(participant)
                    }
                }
                .padding(Spacing.lg)
            }

            Divider()

            // Footer actions
            detailFooter(participant)
        }
        .onAppear {
            populateEditFields(from: participant)
        }
        .sheet(isPresented: $showExportSheet) {
            exportSheetView
        }
    }

    // MARK: - Header

    private func detailHeader(_ participant: Participant) -> some View {
        HStack(spacing: Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.1)
                          : Color.black.opacity(0.06))
                    .frame(width: 48, height: 48)

                Text(participantInitials(participant.name))
                    .font(Typography.heading3)
                    .foregroundColor(.hcdTextSecondary)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(participant.name)
                    .font(Typography.heading2)
                    .foregroundColor(.hcdTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                HStack(spacing: Spacing.sm) {
                    if let role = participant.role, !role.isEmpty {
                        Text(role)
                            .font(Typography.body)
                            .foregroundColor(.hcdTextSecondary)
                    }

                    if let org = participant.organization, !org.isEmpty {
                        if participant.role != nil && !participant.role!.isEmpty {
                            Text("at")
                                .font(Typography.body)
                                .foregroundColor(.hcdTextTertiary)
                        }
                        Text(org)
                            .font(Typography.body)
                            .foregroundColor(.hcdTextSecondary)
                    }
                }
            }

            Spacer()

            // Edit toggle
            Button(action: {
                if isEditing {
                    saveEdits()
                } else {
                    populateEditFields(from: participant)
                }
                withAnimation(.easeInOut(duration: 0.2)) {
                    isEditing.toggle()
                }
            }) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: isEditing ? "checkmark" : "pencil")
                        .font(Typography.caption)
                    Text(isEditing ? "Save" : "Edit")
                        .font(Typography.caption)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .glassButton(isActive: isEditing, style: isEditing ? .primary : .secondary)
            .accessibilityLabel(isEditing ? "Save changes" : "Edit participant")
            .accessibilityHint(isEditing
                               ? "Save the changes you made to this participant"
                               : "Switch to edit mode to modify participant details")
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - View Content

    private func viewContent(_ participant: Participant) -> some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Info section
            infoSection(participant)

            // Session history
            sessionHistorySection(participant)

            // Custom metadata
            metadataViewSection(participant)

            // Notes
            notesViewSection(participant)
        }
    }

    private func infoSection(_ participant: Participant) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Information")

            VStack(alignment: .leading, spacing: Spacing.sm) {
                infoRow(icon: "envelope", label: "Email", value: participant.email ?? "Not provided")
                infoRow(icon: "building.2", label: "Department", value: participant.department ?? "Not provided")
                infoRow(icon: "chart.bar", label: "Experience", value: participant.experienceLevel?.displayName ?? "Not specified")
            }
            .padding(Spacing.md)
            .glassCard()
        }
        .accessibilityElement(children: .contain)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(Typography.body)
                .foregroundColor(.hcdTextTertiary)
                .frame(width: 20)
                .accessibilityHidden(true)

            Text(label)
                .font(Typography.caption)
                .foregroundColor(.hcdTextSecondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(Typography.body)
                .foregroundColor(value == "Not provided" || value == "Not specified"
                                 ? .hcdTextTertiary
                                 : .hcdTextPrimary)

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func sessionHistorySection(_ participant: Participant) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Session History")

            if participant.sessionIds.isEmpty {
                Text("No linked sessions.")
                    .font(Typography.body)
                    .foregroundColor(.hcdTextTertiary)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()
            } else {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(participant.sessionIds, id: \.self) { sessionId in
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "record.circle")
                                .font(Typography.small)
                                .foregroundColor(.hcdTextTertiary)
                                .accessibilityHidden(true)

                            Text("Session \(sessionId.uuidString.prefix(8))...")
                                .font(Typography.caption)
                                .foregroundColor(.hcdTextPrimary)
                                .lineLimit(1)

                            Spacer()
                        }
                        .padding(.vertical, Spacing.xs)
                        .accessibilityLabel("Session \(sessionId.uuidString)")
                    }
                }
                .padding(Spacing.md)
                .glassCard()
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func metadataViewSection(_ participant: Participant) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Custom Metadata")

            if participant.metadata.isEmpty {
                Text("No custom metadata.")
                    .font(Typography.body)
                    .foregroundColor(.hcdTextTertiary)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()
            } else {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(participant.metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack(spacing: Spacing.md) {
                            Text(key)
                                .font(Typography.caption)
                                .foregroundColor(.hcdTextSecondary)
                                .frame(minWidth: 80, alignment: .leading)

                            Text(value)
                                .font(Typography.body)
                                .foregroundColor(.hcdTextPrimary)

                            Spacer()
                        }
                        .padding(.vertical, Spacing.xs)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(key): \(value)")
                    }
                }
                .padding(Spacing.md)
                .glassCard()
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func notesViewSection(_ participant: Participant) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Notes")

            Text(participant.notes.isEmpty ? "No notes." : participant.notes)
                .font(Typography.body)
                .foregroundColor(participant.notes.isEmpty ? .hcdTextTertiary : .hcdTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
                .glassCard()
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Edit Form Content

    private var editFormContent: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            editField(label: "Name", text: $editName, placeholder: "Full name")
            editField(label: "Email", text: $editEmail, placeholder: "email@example.com")
            editField(label: "Role", text: $editRole, placeholder: "Job title or role")
            editField(label: "Department", text: $editDepartment, placeholder: "Department")
            editField(label: "Organization", text: $editOrganization, placeholder: "Company or organization")

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Experience Level")
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextSecondary)

                Picker("Experience Level", selection: $editExperienceLevel) {
                    Text("Not specified")
                        .tag(nil as ExperienceLevel?)
                    ForEach(ExperienceLevel.allCases, id: \.self) { level in
                        Text(level.displayName)
                            .tag(level as ExperienceLevel?)
                    }
                }
                .labelsHidden()
                .accessibilityLabel("Experience level")
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Notes")
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextSecondary)

                TextEditor(text: $editNotes)
                    .font(Typography.body)
                    .frame(minHeight: 60, maxHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                            .fill(colorScheme == .dark
                                  ? Color.white.opacity(0.06)
                                  : Color.black.opacity(0.04))
                    )
                    .accessibilityLabel("Notes")
            }

            editMetadataSection
        }
    }

    private func editField(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(Typography.caption)
                .foregroundColor(.hcdTextSecondary)

            TextField(placeholder, text: text)
                .font(Typography.body)
                .textFieldStyle(.plain)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .fill(colorScheme == .dark
                              ? Color.white.opacity(0.06)
                              : Color.black.opacity(0.04))
                )
                .accessibilityLabel(label)
        }
    }

    private var editMetadataSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Custom Fields")
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextSecondary)

                Spacer()

                Button(action: {
                    editMetadata.append(EditableMetadataEntry())
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
            }

            ForEach($editMetadata) { $entry in
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
                        editMetadata.removeAll { $0.id == entry.id }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(Typography.body)
                            .foregroundColor(.hcdError)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove field")
                }
            }
        }
    }

    // MARK: - Footer

    private func detailFooter(_ participant: Participant) -> some View {
        HStack(spacing: Spacing.md) {
            // Export Data button
            Button(action: {
                exportedData = participantManager.exportParticipantData(participantId)
                showExportSheet = true
            }) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "square.and.arrow.up")
                        .font(Typography.caption)
                    Text("Export Data")
                        .font(Typography.caption)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .glassButton(style: .secondary)
            .accessibilityLabel("Export participant data")
            .accessibilityHint("Export all data for this participant in Markdown format for GDPR compliance")

            // Delete button
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "trash")
                        .font(Typography.caption)
                    Text("Delete")
                        .font(Typography.caption)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .glassButton(style: .destructive)
            .accessibilityLabel("Delete participant")
            .accessibilityHint("Permanently delete this participant and all associated data")
            .alert("Delete Participant?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    participantManager.deleteParticipantAndData(participantId)
                    onDismiss?()
                }
            } message: {
                Text("This will permanently delete \(participant.name) and unlink all associated sessions. This action cannot be undone.")
            }

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Text("Close")
                        .font(Typography.bodyMedium)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.plain)
                .glassButton(style: .secondary)
                .accessibilityLabel("Close")
                .accessibilityHint("Close the participant detail view")
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Export Sheet

    private var exportSheetView: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Participant Data Export")
                    .font(Typography.heading2)
                    .foregroundColor(.hcdTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button(action: { showExportSheet = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(Typography.heading3)
                        .foregroundColor(.hcdTextTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close export")
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)

            ScrollView {
                Text(exportedData)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.hcdTextPrimary)
                    .textSelection(.enabled)
                    .padding(Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Spacer()

                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(exportedData, forType: .string)
                }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "doc.on.doc")
                            .font(Typography.caption)
                        Text("Copy to Clipboard")
                            .font(Typography.bodyMedium)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.plain)
                .glassButton(isActive: true, style: .primary)
                .accessibilityLabel("Copy to clipboard")
                .accessibilityHint("Copy the exported data to the system clipboard")
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
        .frame(minWidth: 500, minHeight: 400)
    }

    // MARK: - Section Header Helper

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Typography.heading3)
            .foregroundColor(.hcdTextPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Edit Helpers

    private func populateEditFields(from participant: Participant) {
        editName = participant.name
        editEmail = participant.email ?? ""
        editRole = participant.role ?? ""
        editDepartment = participant.department ?? ""
        editOrganization = participant.organization ?? ""
        editExperienceLevel = participant.experienceLevel
        editNotes = participant.notes
        editMetadata = participant.metadata
            .sorted(by: { $0.key < $1.key })
            .map { EditableMetadataEntry(key: $0.key, value: $0.value) }
    }

    private func saveEdits() {
        var metadata: [String: String] = [:]
        for entry in editMetadata {
            let key = entry.key.trimmingCharacters(in: .whitespaces)
            let value = entry.value.trimmingCharacters(in: .whitespaces)
            if !key.isEmpty && !value.isEmpty {
                metadata[key] = value
            }
        }

        participantManager.updateParticipant(
            participantId,
            name: editName.trimmingCharacters(in: .whitespaces),
            email: editEmail.isEmpty ? nil : editEmail.trimmingCharacters(in: .whitespaces),
            role: editRole.isEmpty ? nil : editRole.trimmingCharacters(in: .whitespaces),
            department: editDepartment.isEmpty ? nil : editDepartment.trimmingCharacters(in: .whitespaces),
            organization: editOrganization.isEmpty ? nil : editOrganization.trimmingCharacters(in: .whitespaces),
            experienceLevel: editExperienceLevel,
            notes: editNotes.trimmingCharacters(in: .whitespaces),
            metadata: metadata
        )
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

// MARK: - Editable Metadata Entry

/// A single key-value metadata entry for the edit form
private struct EditableMetadataEntry: Identifiable {
    let id = UUID()
    var key: String = ""
    var value: String = ""
}

// MARK: - Preview

#if DEBUG
struct ParticipantDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ParticipantDetailView(
                participantManager: previewManager().0,
                participantId: previewManager().1,
                onDismiss: { print("Dismissed") }
            )
            .glassSheet()
        }
    }

    @MainActor
    static func previewManager() -> (ParticipantManager, UUID) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("preview_detail_participants.json")
        let manager = ParticipantManager(storageURL: url)
        let participant = manager.createParticipant(
            name: "Jane Doe",
            email: "jane@example.com",
            role: "Product Manager",
            department: "Product",
            organization: "Acme Corp",
            experienceLevel: .intermediate,
            notes: "Very insightful participant. Has extensive experience with onboarding flows.",
            metadata: ["Screening Score": "85", "Recruitment Source": "UserTesting.com"]
        )
        return (manager, participant.id)
    }
}
#endif
