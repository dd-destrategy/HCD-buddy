import SwiftUI

/// Allows users to select the session mode (Full, Transcription Only, or Observer Only)
struct SessionModeSelector: View {
    @Binding var selectedMode: SessionMode

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Mode")
                .font(.headline)

            VStack(spacing: 10) {
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
        .padding(16)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Mode Option View

private struct ModeOptionView: View {
    let mode: SessionMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .secondary)

                // Mode details
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.controlBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isSelected ? Color.blue : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedMode: SessionMode = .full

    VStack(spacing: 20) {
        SessionModeSelector(selectedMode: $selectedMode)
        Text("Selected: \(selectedMode.displayName)")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}
