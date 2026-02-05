import SwiftUI

/// Allows users to select the session mode (Full, Transcription Only, or Observer Only)
struct SessionModeSelector: View {
    @Binding var selectedMode: SessionMode

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Session Mode")
                .font(Typography.heading3)

            VStack(spacing: Spacing.sm) {
                ForEach(SessionMode.allCases, id: \.self) { mode in
                    ModeOptionView(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        action: {
                            selectedMode = mode
                        }
                    )
                }
            }
        }
        .padding(Spacing.lg)
        .liquidGlass(
            material: .thin,
            cornerRadius: CornerRadius.large,
            borderStyle: .subtle,
            enableHover: false
        )
    }
}

// MARK: - Mode Option View

private struct ModeOptionView: View {
    let mode: SessionMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Spacing.md) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .accentColor : .secondary)

                // Mode details
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(mode.displayName)
                        .font(Typography.bodyMedium)
                        .foregroundColor(.primary)

                    Text(mode.description)
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(Spacing.md)
            .glassButton(isActive: isSelected, style: isSelected ? .primary : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.displayName)")
        .accessibilityHint(isSelected ? "Currently selected" : "Double-tap to select \(mode.displayName) mode")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedMode: SessionMode = .full

    ZStack {
        // Background to show glass effects
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: Spacing.xl) {
            SessionModeSelector(selectedMode: $selectedMode)
            Text("Selected: \(selectedMode.displayName)")
                .font(Typography.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
