//
//  FocusModePickerView.swift
//  HCD Interview Coach
//
//  EPIC E4: Session Manager
//  Segmented control for switching between focus modes during a session.
//

import SwiftUI

// MARK: - Focus Mode Picker View

/// A segmented-style picker for switching between focus modes.
///
/// Supports two presentation styles:
/// - **Standard**: Full segmented control with mode names and icons
/// - **Compact**: Icon-only variant suitable for toolbar embedding
struct FocusModePickerView: View {

    @ObservedObject var manager: FocusModeManager

    /// Whether to use the compact (icon-only) variant
    var isCompact: Bool = false

    var body: some View {
        if isCompact {
            compactPicker
        } else {
            standardPicker
        }
    }

    // MARK: - Standard Picker

    /// Full segmented control with icons and labels
    private var standardPicker: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(FocusMode.allCases, id: \.self) { mode in
                FocusModeButton(
                    mode: mode,
                    isSelected: manager.currentMode == mode,
                    isCompact: false,
                    action: {
                        manager.setMode(mode)
                    }
                )
            }
        }
        .padding(Spacing.xs)
        .liquidGlass(
            material: .thin,
            cornerRadius: CornerRadius.large,
            borderStyle: .subtle,
            enableHover: false
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Focus mode selector")
        .accessibilityHint("Choose a layout mode for the session view")
    }

    // MARK: - Compact Picker

    /// Icon-only variant for toolbar embedding
    private var compactPicker: some View {
        HStack(spacing: 2) {
            ForEach(FocusMode.allCases, id: \.self) { mode in
                FocusModeButton(
                    mode: mode,
                    isSelected: manager.currentMode == mode,
                    isCompact: true,
                    action: {
                        manager.setMode(mode)
                    }
                )
            }
        }
        .padding(2)
        .background(
            Capsule()
                .fill(Color.secondary.opacity(0.1))
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Focus mode selector")
        .accessibilityHint("Choose a layout mode for the session view")
    }
}

// MARK: - Focus Mode Button

/// Individual button representing a focus mode option in the picker
private struct FocusModeButton: View {

    let mode: FocusMode
    let isSelected: Bool
    let isCompact: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: action) {
            if isCompact {
                compactContent
            } else {
                standardContent
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: AnimationTiming.fast)) {
                isHovered = hovering
            }
        }
        .help("\(mode.displayName): \(mode.description)")
        .accessibilityLabel(mode.displayName)
        .accessibilityHint(isSelected
            ? "Currently selected. \(mode.description)"
            : "Double-tap to switch to \(mode.displayName) mode. \(mode.description)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Standard Content

    /// Full content with icon and label
    private var standardContent: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: mode.icon)
                .font(Typography.caption)

            Text(mode.displayName)
                .font(Typography.caption)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(buttonBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }

    // MARK: - Compact Content

    /// Icon-only content for toolbar embedding
    private var compactContent: some View {
        Image(systemName: mode.icon)
            .font(Typography.caption)
            .frame(width: 28, height: 24)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
    }

    // MARK: - Button Background

    @ViewBuilder
    private var buttonBackground: some View {
        if isSelected {
            Color.accentColor.opacity(colorScheme == .dark ? 0.3 : 0.15)
        } else if isHovered {
            Color.secondary.opacity(0.1)
        } else {
            Color.clear
        }
    }
}

// MARK: - Preview

#if DEBUG
struct FocusModePickerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.xxl) {
                // Standard picker
                FocusModePickerView(
                    manager: previewManager(),
                    isCompact: false
                )

                // Compact picker
                FocusModePickerView(
                    manager: previewManager(),
                    isCompact: true
                )
            }
            .padding()
        }
    }

    @MainActor
    static func previewManager() -> FocusModeManager {
        let manager = FocusModeManager(defaults: UserDefaults(suiteName: "preview")!)
        return manager
    }
}
#endif
