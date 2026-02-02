//
//  FocusManager.swift
//  HCDInterviewCoach
//
//  Created by Agent E13
//  EPIC E13: Accessibility - Focus Management
//

import SwiftUI
import Combine

/// Focus state manager for application-wide keyboard navigation
/// Manages focus areas and transitions between major interface sections
@MainActor
final class FocusManager: ObservableObject {

    // MARK: - Published Properties

    /// The currently focused area of the interface
    @Published var currentFocus: FocusArea?

    /// The previously focused area (for restoration)
    @Published var previousFocus: FocusArea?

    /// Whether focus cycling is enabled
    @Published var enableFocusCycling: Bool = true

    // MARK: - Focus Areas

    /// Major focusable areas in the application
    enum FocusArea: Hashable, CaseIterable {
        case transcript
        case topics
        case insights
        case controls
        case search
        case settings
        case coachingPrompt

        var accessibilityLabel: String {
            switch self {
            case .transcript:
                return "Transcript panel"
            case .topics:
                return "Topics panel"
            case .insights:
                return "Insights panel"
            case .controls:
                return "Session controls"
            case .search:
                return "Search field"
            case .settings:
                return "Settings"
            case .coachingPrompt:
                return "Coaching prompt"
            }
        }

        var accessibilityHint: String {
            switch self {
            case .transcript:
                return "View and edit conversation transcript"
            case .topics:
                return "View topic coverage status"
            case .insights:
                return "Review flagged insights"
            case .controls:
                return "Control session recording"
            case .search:
                return "Search transcript content"
            case .settings:
                return "Adjust application settings"
            case .coachingPrompt:
                return "View coaching suggestion"
            }
        }
    }

    // MARK: - Initialization

    init() {
        // Default to controls on launch
        self.currentFocus = .controls
    }

    // MARK: - Focus Management

    /// Move focus to the specified area
    func moveFocus(to area: FocusArea) {
        previousFocus = currentFocus
        currentFocus = area

        // Announce focus change for VoiceOver
        announceAccessibility("Focus moved to \(area.accessibilityLabel)")
    }

    /// Restore focus to the previous area
    func restorePreviousFocus() {
        if let previous = previousFocus {
            currentFocus = previous
            previousFocus = nil

            announceAccessibility("Focus restored to \(previous.accessibilityLabel)")
        }
    }

    /// Move focus to the next area in the cycle
    func focusNext() {
        guard enableFocusCycling, let current = currentFocus else { return }

        let areas = FocusArea.allCases
        guard let currentIndex = areas.firstIndex(of: current) else { return }

        let nextIndex = (currentIndex + 1) % areas.count
        moveFocus(to: areas[nextIndex])
    }

    /// Move focus to the previous area in the cycle
    func focusPrevious() {
        guard enableFocusCycling, let current = currentFocus else { return }

        let areas = FocusArea.allCases
        guard let currentIndex = areas.firstIndex(of: current) else { return }

        let previousIndex = currentIndex > 0 ? currentIndex - 1 : areas.count - 1
        moveFocus(to: areas[previousIndex])
    }

    /// Clear current focus
    func clearFocus() {
        previousFocus = currentFocus
        currentFocus = nil
    }

    // MARK: - Accessibility Announcement

    private func announceAccessibility(_ message: String) {
        #if os(macOS)
        NSAccessibility.post(
            element: NSApp.mainWindow as Any,
            notification: .announcementRequested,
            userInfo: [.announcement: message, .priority: NSAccessibilityPriorityLevel.high]
        )
        #endif
    }
}

// MARK: - Focus State Field

/// Field-level focus states for form controls and interactive elements
enum FocusField: Hashable {
    case participantName
    case projectName
    case templateSelector
    case topicEditor(id: UUID)
    case insightNote(id: UUID)
    case searchQuery
    case apiKey

    var accessibilityIdentifier: String {
        switch self {
        case .participantName:
            return "participantNameField"
        case .projectName:
            return "projectNameField"
        case .templateSelector:
            return "templateSelector"
        case .topicEditor(let id):
            return "topicEditor-\(id.uuidString)"
        case .insightNote(let id):
            return "insightNote-\(id.uuidString)"
        case .searchQuery:
            return "searchQueryField"
        case .apiKey:
            return "apiKeyField"
        }
    }
}
