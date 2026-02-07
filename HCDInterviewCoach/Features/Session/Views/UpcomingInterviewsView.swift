//
//  UpcomingInterviewsView.swift
//  HCD Interview Coach
//
//  Feature B: Calendar Integration
//  Displays upcoming interview events detected from the macOS Calendar,
//  grouped by date, with one-tap session start.
//

import SwiftUI

// MARK: - Upcoming Interviews View

/// Displays detected upcoming interviews from the user's calendar.
///
/// Shows a permission request if calendar access hasn't been granted,
/// a loading state while fetching, and a grouped list of interview cards
/// with "Start Now" buttons.
struct UpcomingInterviewsView: View {

    @ObservedObject var calendarService: CalendarService
    var onStartSession: ((UpcomingInterview) -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            Divider()
            contentView
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Upcoming interviews")
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Upcoming Interviews")
                    .font(Typography.heading2)
                    .foregroundColor(.hcdTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text("Detected from your calendar")
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextSecondary)
            }

            Spacer()

            if calendarService.authorizationStatus == .authorized {
                Button(action: {
                    Task {
                        await calendarService.fetchUpcomingInterviews()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(Typography.body)
                        .padding(Spacing.sm)
                }
                .buttonStyle(.plain)
                .glassButton(style: .ghost)
                .disabled(calendarService.isLoading)
                .accessibilityLabel("Refresh")
                .accessibilityHint("Fetch the latest upcoming interviews from your calendar")
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        switch calendarService.authorizationStatus {
        case .notDetermined:
            permissionRequestView
        case .denied, .restricted:
            permissionDeniedView
        case .authorized:
            authorizedContentView
        }
    }

    // MARK: - Permission Request

    private var permissionRequestView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.hcdTextSecondary)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.sm) {
                Text("Connect Your Calendar")
                    .font(Typography.heading3)
                    .foregroundColor(.hcdTextPrimary)

                Text("HCD Interview Coach can detect upcoming research sessions from your calendar and help you prepare.")
                    .font(Typography.body)
                    .foregroundColor(.hcdTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: {
                Task {
                    await calendarService.requestAccess()
                }
            }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "calendar")
                    Text("Allow Calendar Access")
                }
                .font(Typography.bodyMedium)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .glassButton(isActive: true, style: .primary)
            .accessibilityLabel("Allow Calendar Access")
            .accessibilityHint("Grant permission to read your calendar events to detect upcoming interviews")
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Permission Denied

    private var permissionDeniedView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.hcdWarning)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.sm) {
                Text("Calendar Access Required")
                    .font(Typography.heading3)
                    .foregroundColor(.hcdTextPrimary)

                Text("Calendar access was denied. To enable it, open System Settings > Privacy & Security > Calendars and allow access for HCD Interview Coach.")
                    .font(Typography.body)
                    .foregroundColor(.hcdTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: openSystemPreferences) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "gear")
                    Text("Open System Settings")
                }
                .font(Typography.bodyMedium)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .glassButton(style: .secondary)
            .accessibilityLabel("Open System Settings")
            .accessibilityHint("Opens Privacy and Security settings to grant calendar access")
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Authorized Content

    @ViewBuilder
    private var authorizedContentView: some View {
        if calendarService.isLoading {
            loadingView
        } else if let errorMessage = calendarService.lastError {
            errorView(message: errorMessage)
        } else if calendarService.upcomingInterviews.isEmpty {
            emptyStateView
        } else {
            interviewListView
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Scanning calendar...")
                .font(Typography.caption)
                .foregroundColor(.hcdTextSecondary)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading upcoming interviews")
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.hcdError)
                .accessibilityHidden(true)

            Text("Unable to load calendar events")
                .font(Typography.heading3)
                .foregroundColor(.hcdTextPrimary)

            Text(message)
                .font(Typography.caption)
                .foregroundColor(.hcdTextSecondary)
                .multilineTextAlignment(.center)

            Button(action: {
                Task {
                    await calendarService.fetchUpcomingInterviews()
                }
            }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(Typography.bodyMedium)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .glassButton(style: .secondary)
            .accessibilityLabel("Retry")
            .accessibilityHint("Try fetching calendar events again")
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "calendar")
                .font(.system(size: 32))
                .foregroundColor(.hcdTextSecondary)
                .accessibilityHidden(true)

            Text("No Upcoming Interviews")
                .font(Typography.heading3)
                .foregroundColor(.hcdTextPrimary)

            Text("No interview or research sessions were found in your calendar for the next 7 days. Events with keywords like \"interview\", \"user research\", or \"usability\" will appear here.")
                .font(Typography.caption)
                .foregroundColor(.hcdTextSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No upcoming interviews found in the next 7 days")
    }

    // MARK: - Interview List

    private var interviewListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(groupedInterviews, id: \.key) { dateLabel, interviews in
                    Section {
                        ForEach(interviews) { interview in
                            InterviewCardView(
                                interview: interview,
                                onStartSession: onStartSession
                            )
                        }
                    } header: {
                        dateSectionHeader(dateLabel)
                    }
                }
            }
            .padding(Spacing.lg)
        }
    }

    // MARK: - Grouped Interviews

    /// Groups interviews by their formatted date label
    private var groupedInterviews: [(key: String, value: [UpcomingInterview])] {
        let grouped = Dictionary(grouping: calendarService.upcomingInterviews) { interview in
            interview.formattedDate
        }

        // Sort groups: Today first, Tomorrow second, then chronological
        let sortOrder: [String: Int] = ["Today": 0, "Tomorrow": 1]
        return grouped.sorted { lhs, rhs in
            let lhsOrder = sortOrder[lhs.key] ?? 2
            let rhsOrder = sortOrder[rhs.key] ?? 2
            if lhsOrder != rhsOrder {
                return lhsOrder < rhsOrder
            }
            // For same priority, sort by the first event's start date
            let lhsDate = lhs.value.first?.startDate ?? .distantFuture
            let rhsDate = rhs.value.first?.startDate ?? .distantFuture
            return lhsDate < rhsDate
        }
    }

    // MARK: - Date Section Header

    private func dateSectionHeader(_ label: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(label)
                .font(Typography.bodyMedium)
                .foregroundColor(label == "Today" ? .hcdPrimary : .hcdTextSecondary)

            Rectangle()
                .fill(Color.hcdDivider)
                .frame(height: 1)
        }
        .padding(.top, Spacing.sm)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel("\(label) interviews")
    }

    // MARK: - Helpers

    private func openSystemPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Interview Card View

/// A card displaying a single upcoming interview with metadata and a start button.
private struct InterviewCardView: View {

    let interview: UpcomingInterview
    var onStartSession: ((UpcomingInterview) -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Calendar color dot and time
            VStack(spacing: Spacing.xs) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)

                Text(interview.formattedTime)
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextSecondary)
            }
            .frame(width: 44)
            .padding(.top, 2)

            // Interview details
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(interview.title)
                    .font(Typography.bodyMedium)
                    .foregroundColor(.hcdTextPrimary)
                    .lineLimit(2)

                Text(interview.formattedTimeRange)
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextSecondary)

                // Metadata pills
                HStack(spacing: Spacing.sm) {
                    if let participant = interview.participantName {
                        metadataPill(
                            icon: "person.fill",
                            text: participant
                        )
                    }

                    if let project = interview.projectName {
                        metadataPill(
                            icon: "folder.fill",
                            text: project
                        )
                    }

                    if let location = interview.location, !location.isEmpty {
                        metadataPill(
                            icon: "location.fill",
                            text: location
                        )
                    }
                }

                // Duration badge
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "clock")
                        .font(Typography.small)
                    Text("\(interview.durationMinutes) min")
                        .font(Typography.small)
                }
                .foregroundColor(.hcdTextTertiary)
            }

            Spacer()

            // Start session button
            if interview.isToday {
                Button(action: {
                    onStartSession?(interview)
                }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "play.fill")
                            .font(Typography.small)
                        Text("Start")
                            .font(Typography.caption)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.plain)
                .glassButton(isActive: true, style: .primary)
                .accessibilityLabel("Start session")
                .accessibilityHint("Begin an interview session for \(interview.title)")
            }
        }
        .padding(Spacing.md)
        .glassCard(isSelected: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(cardAccessibilityLabel)
        .accessibilityHint(interview.isToday
            ? "Double-tap to start this interview session"
            : "Scheduled for \(interview.formattedDate)")
    }

    // MARK: - Metadata Pill

    private func metadataPill(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(Typography.small)
            Text(text)
                .font(Typography.caption)
                .lineLimit(1)
        }
        .foregroundColor(.hcdTextSecondary)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(colorScheme == .dark
                    ? Color.white.opacity(0.06)
                    : Color.black.opacity(0.04))
        )
    }

    // MARK: - Accessibility

    private var cardAccessibilityLabel: String {
        var parts = [interview.title, interview.formattedTimeRange]
        if let participant = interview.participantName {
            parts.append("with \(participant)")
        }
        if let project = interview.projectName {
            parts.append("project \(project)")
        }
        parts.append("\(interview.durationMinutes) minutes")
        return parts.joined(separator: ", ")
    }
}

// MARK: - Preview

#if DEBUG
struct UpcomingInterviewsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            UpcomingInterviewsView(
                calendarService: previewService(),
                onStartSession: { interview in
                    print("Starting session for: \(interview.title)")
                }
            )
            .frame(width: 400, height: 600)
            .glassCard()
        }
    }

    @MainActor
    static func previewService() -> CalendarService {
        let service = CalendarService()
        return service
    }
}
#endif
