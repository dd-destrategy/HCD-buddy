//
//  RedactionReviewView.swift
//  HCDInterviewCoach
//
//  FEATURE C: Consent & PII Redaction Engine
//  SwiftUI view for reviewing and managing PII detections, redaction actions, and consent status.
//

import SwiftUI

// MARK: - Redaction Review View

/// Main panel view for reviewing PII detections and managing redaction decisions.
///
/// Displays a summary header with detection counts, a consent status picker,
/// PII type filters, and a list of detections grouped by utterance with action buttons.
struct RedactionReviewView: View {

    // MARK: - Properties

    @ObservedObject var redactionService: RedactionService
    let utterances: [Utterance]
    let sessionId: UUID

    @State private var selectedFilterType: PIIType?
    @State private var consentStatus: ConsentStatus = .notObtained
    @State private var consentNotes: String = ""
    @State private var showingReplaceAlert: Bool = false
    @State private var replaceText: String = ""
    @State private var detectionToReplace: PIIDetection?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            headerSection

            Divider()
                .foregroundColor(.hcdDivider)

            consentSection

            Divider()
                .foregroundColor(.hcdDivider)

            if redactionService.detections.isEmpty && !redactionService.isScanning {
                emptyStateView
            } else {
                filterSection

                detectionsListSection
            }

            Spacer(minLength: 0)

            footerSection
        }
        .padding(Spacing.lg)
        .glassPanel(edge: .trailing)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("PII redaction review panel")
        .onAppear {
            loadConsentStatus()
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .font(Typography.heading2)
                    .foregroundColor(.hcdPrimary)

                Text("PII Redaction")
                    .font(Typography.heading2)
                    .foregroundColor(.hcdTextPrimary)

                Spacer()

                if redactionService.isScanning {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel("Scanning for PII")
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("PII Redaction panel header")

            // Summary stats
            if !redactionService.detections.isEmpty {
                summaryStatsView
            }
        }
    }

    @ViewBuilder
    private var summaryStatsView: some View {
        let counts = redactionService.detectionCounts()
        let totalCount = redactionService.detections.count
        let unresolvedCount = redactionService.unresolvedDetections().count

        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.md) {
                statBadge(
                    label: "Total",
                    count: totalCount,
                    color: .hcdTextSecondary
                )

                statBadge(
                    label: "Unresolved",
                    count: unresolvedCount,
                    color: unresolvedCount > 0 ? .hcdWarning : .hcdSuccess
                )
            }

            // Per-type breakdown
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(PIIType.allCases, id: \.self) { type in
                        if let count = counts[type], count > 0 {
                            piiTypeBadge(type: type, count: count)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("PII summary: \(totalCount) total detections, \(unresolvedCount) unresolved")
    }

    private func statBadge(label: String, count: Int, color: Color) -> some View {
        HStack(spacing: Spacing.xs) {
            Text("\(count)")
                .font(Typography.bodyMedium)
                .foregroundColor(color)
            Text(label)
                .font(Typography.caption)
                .foregroundColor(.hcdTextSecondary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
    }

    private func piiTypeBadge(type: PIIType, count: Int) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: type.icon)
                .font(Typography.small)
            Text("\(count)")
                .font(Typography.small)
        }
        .foregroundColor(colorForSeverity(type.severity))
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(colorForSeverity(type.severity).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous))
        .accessibilityLabel("\(count) \(type.displayName) detections")
    }

    // MARK: - Consent Section

    @ViewBuilder
    private var consentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Consent Status")
                .font(Typography.bodyMedium)
                .foregroundColor(.hcdTextPrimary)

            HStack(spacing: Spacing.sm) {
                ForEach(ConsentStatus.allCases, id: \.self) { status in
                    consentButton(status: status)
                }
            }

            if consentStatus == .verbalConsent || consentStatus == .writtenConsent {
                TextField("Consent notes (optional)", text: $consentNotes)
                    .textFieldStyle(.plain)
                    .font(Typography.caption)
                    .padding(Spacing.sm)
                    .background(Color.hcdBackgroundSecondary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                    .accessibilityLabel("Consent notes")
                    .accessibilityHint("Enter optional notes about how consent was obtained")
                    .onChange(of: consentNotes) { _ in
                        redactionService.setConsentStatus(consentStatus, for: sessionId, notes: consentNotes.isEmpty ? nil : consentNotes)
                    }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Consent status section")
    }

    private func consentButton(status: ConsentStatus) -> some View {
        let isSelected = consentStatus == status

        return Button {
            consentStatus = status
            redactionService.setConsentStatus(status, for: sessionId, notes: consentNotes.isEmpty ? nil : consentNotes)
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: status.icon)
                    .font(Typography.small)
                Text(status.displayName)
                    .font(Typography.small)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(.plain)
        .glassButton(isActive: isSelected, style: isSelected ? .primary : .secondary)
        .accessibilityLabel("\(status.displayName) consent")
        .accessibilityHint(isSelected ? "Currently selected" : "Tap to select \(status.displayName)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Filter Section

    @ViewBuilder
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                filterChip(label: "All", type: nil)

                ForEach(PIIType.allCases, id: \.self) { type in
                    let count = redactionService.detectionCounts()[type] ?? 0
                    if count > 0 {
                        filterChip(label: type.displayName, type: type)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("PII type filter")
    }

    private func filterChip(label: String, type: PIIType?) -> some View {
        let isSelected = selectedFilterType == type

        return Button {
            selectedFilterType = type
        } label: {
            Text(label)
                .font(Typography.caption)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .hcdPrimary : .hcdTextSecondary)
        .background(isSelected ? Color.hcdPrimary.opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous)
                .stroke(isSelected ? Color.hcdPrimary.opacity(0.3) : Color.hcdBorderLight, lineWidth: 1)
        )
        .accessibilityLabel("Filter by \(label)")
        .accessibilityHint(isSelected ? "Currently active filter" : "Tap to filter by \(label)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Detections List

    @ViewBuilder
    private var detectionsListSection: some View {
        let filteredDetections = filteredDetections()

        if filteredDetections.isEmpty {
            Text("No detections match the selected filter.")
                .font(Typography.caption)
                .foregroundColor(.hcdTextSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, Spacing.lg)
                .accessibilityLabel("No detections match the selected filter")
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(filteredDetections) { detection in
                        detectionRow(detection)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func detectionRow(_ detection: PIIDetection) -> some View {
        let existingAction = redactionService.actions.first { $0.detectionId == detection.id }
        let isResolved = existingAction != nil

        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Type badge and confidence
            HStack {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: detection.type.icon)
                        .font(Typography.small)
                    Text(detection.type.displayName)
                        .font(Typography.caption)
                }
                .foregroundColor(colorForSeverity(detection.type.severity))
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 2)
                .background(colorForSeverity(detection.type.severity).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous))

                Spacer()

                // Confidence percentage
                Text("\(Int(detection.confidence * 100))%")
                    .font(Typography.small)
                    .foregroundColor(.hcdTextSecondary)

                // Severity indicator
                Circle()
                    .fill(colorForSeverity(detection.type.severity))
                    .frame(width: 8, height: 8)
                    .accessibilityLabel("Severity: \(detection.type.severity.displayName)")
            }

            // Matched text with highlight
            HStack(spacing: Spacing.xs) {
                Text(detection.matchedText)
                    .font(Typography.body)
                    .foregroundColor(.hcdTextPrimary)
                    .padding(Spacing.sm)
                    .background(
                        isResolved
                            ? Color.hcdSuccess.opacity(0.1)
                            : colorForSeverity(detection.type.severity).opacity(0.08)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                            .stroke(
                                isResolved
                                    ? Color.hcdSuccess.opacity(0.3)
                                    : colorForSeverity(detection.type.severity).opacity(0.2),
                                lineWidth: 1
                            )
                    )

                Spacer()
            }

            // Resolution status or action buttons
            if let action = existingAction {
                resolvedBadge(action: action)
            } else {
                actionButtons(for: detection)
            }
        }
        .padding(Spacing.md)
        .glassCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(detection.type.displayName) detection: \(detection.matchedText), confidence \(Int(detection.confidence * 100)) percent, \(isResolved ? "resolved" : "unresolved")")
    }

    @ViewBuilder
    private func resolvedBadge(action: RedactionAction) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: action.action == .keep ? "checkmark.circle" : "eye.slash.circle")
                .font(Typography.small)
            Text(action.action == .keep ? "Kept" : "Redacted as: \(action.replacement)")
                .font(Typography.caption)
        }
        .foregroundColor(.hcdSuccess)
        .accessibilityLabel("Resolved: \(action.action == .keep ? "kept original" : "redacted as \(action.replacement)")")
    }

    @ViewBuilder
    private func actionButtons(for detection: PIIDetection) -> some View {
        HStack(spacing: Spacing.sm) {
            // Redact button
            Button {
                redactionService.applyRedaction(.redact, for: detection)
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "eye.slash")
                        .font(Typography.small)
                    Text("Redact")
                        .font(Typography.caption)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
            }
            .buttonStyle(.plain)
            .glassButton(style: .destructive)
            .accessibilityLabel("Redact \(detection.matchedText)")
            .accessibilityHint("Replace with \(detection.type.redactionLabel)")

            // Keep button
            Button {
                redactionService.applyRedaction(.keep, for: detection)
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark")
                        .font(Typography.small)
                    Text("Keep")
                        .font(Typography.caption)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
            }
            .buttonStyle(.plain)
            .glassButton(style: .secondary)
            .accessibilityLabel("Keep \(detection.matchedText)")
            .accessibilityHint("Keep the original text unchanged")

            // Replace button
            Button {
                detectionToReplace = detection
                replaceText = ""
                showingReplaceAlert = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "pencil")
                        .font(Typography.small)
                    Text("Replace")
                        .font(Typography.caption)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
            }
            .buttonStyle(.plain)
            .glassButton(style: .secondary)
            .accessibilityLabel("Replace \(detection.matchedText)")
            .accessibilityHint("Enter custom replacement text")
        }
        .alert("Replace PII", isPresented: $showingReplaceAlert) {
            TextField("Replacement text", text: $replaceText)
            Button("Replace") {
                if let detection = detectionToReplace, !replaceText.isEmpty {
                    redactionService.applyRedaction(.replace, for: detection, replacement: replaceText)
                }
                detectionToReplace = nil
            }
            Button("Cancel", role: .cancel) {
                detectionToReplace = nil
            }
        } message: {
            if let detection = detectionToReplace {
                Text("Enter replacement text for \"\(detection.matchedText)\"")
            }
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 40))
                .foregroundColor(.hcdSuccess)
                .accessibilityHidden(true)

            Text("No PII Detected")
                .font(Typography.heading3)
                .foregroundColor(.hcdTextPrimary)

            Text("This session appears clean. No personally identifiable information was found.")
                .font(Typography.caption)
                .foregroundColor(.hcdTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No PII detected. This session appears clean.")
    }

    // MARK: - Footer Section

    @ViewBuilder
    private var footerSection: some View {
        VStack(spacing: Spacing.sm) {
            // Scan button
            Button {
                Task {
                    await redactionService.scanSession(utterances: utterances, sessionId: sessionId)
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                    Text(redactionService.detections.isEmpty ? "Scan Session" : "Rescan Session")
                        .font(Typography.bodyMedium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .glassButton(isActive: true, style: .primary)
            .disabled(redactionService.isScanning)
            .accessibilityLabel(redactionService.detections.isEmpty ? "Scan session for PII" : "Rescan session for PII")
            .accessibilityHint("Analyzes all utterances for personally identifiable information")

            // Batch redact buttons (per type) when there are unresolved detections
            if !redactionService.unresolvedDetections().isEmpty {
                batchRedactSection
            }
        }
    }

    @ViewBuilder
    private var batchRedactSection: some View {
        let counts = redactionService.detectionCounts()
        let unresolvedIds = Set(redactionService.unresolvedDetections().map { $0.id })

        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Batch Redact")
                .font(Typography.caption)
                .foregroundColor(.hcdTextSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(PIIType.allCases, id: \.self) { type in
                        let typeUnresolved = redactionService.detections.filter {
                            $0.type == type && unresolvedIds.contains($0.id)
                        }.count

                        if typeUnresolved > 0 {
                            Button {
                                redactionService.batchRedact(type: type)
                            } label: {
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: "eye.slash")
                                        .font(Typography.small)
                                    Text("All \(type.displayName) (\(typeUnresolved))")
                                        .font(Typography.small)
                                }
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                            }
                            .buttonStyle(.plain)
                            .glassButton(style: .destructive)
                            .accessibilityLabel("Batch redact all \(type.displayName) detections")
                            .accessibilityHint("Redacts \(typeUnresolved) unresolved \(type.displayName) detections")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Returns detections filtered by the currently selected PII type.
    private func filteredDetections() -> [PIIDetection] {
        if let filterType = selectedFilterType {
            return redactionService.detections.filter { $0.type == filterType }
        }
        return redactionService.detections
    }

    /// Loads the consent status for the current session from the redaction service.
    private func loadConsentStatus() {
        if let record = redactionService.consentRecord(for: sessionId) {
            consentStatus = record.status
            consentNotes = record.notes ?? ""
        }
    }

    /// Maps a PII severity level to a semantic color.
    private func colorForSeverity(_ severity: PIISeverity) -> Color {
        switch severity {
        case .low: return .hcdInfo
        case .medium: return .hcdWarning
        case .high: return .hcdError
        case .critical: return .hcdError
        }
    }
}

// MARK: - Preview

#if DEBUG
struct RedactionReviewView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RedactionReviewView(
                redactionService: RedactionService(),
                utterances: [],
                sessionId: UUID()
            )
            .frame(width: 380, height: 700)
        }
        .preferredColorScheme(.dark)
    }
}
#endif
