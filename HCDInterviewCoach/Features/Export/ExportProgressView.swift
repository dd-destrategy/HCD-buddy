//
//  ExportProgressView.swift
//  HCD Interview Coach
//
//  EPIC E9: Export System
//  Progress indicator for export operations
//

import SwiftUI

/// Displays export progress with animated indicators
struct ExportProgressView: View {
    // MARK: - Properties

    let progress: ExportProgress
    let onCancel: () -> Void

    @State private var animatingPhase = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // Title
            Text("Exporting Session")
                .font(.title2)
                .fontWeight(.semibold)

            // Progress indicator
            VStack(spacing: 16) {
                // Circular progress
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 100, height: 100)

                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progress.progress)
                        .stroke(
                            progressColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(reduceMotion ? nil : .easeInOut(duration: AnimationTiming.normal), value: progress.progress)

                    // Phase icon
                    phaseIcon
                        .font(.system(size: 32))
                        .foregroundColor(progressColor)
                        .scaleEffect(reduceMotion ? 1.0 : (animatingPhase ? 1.1 : 1.0))
                        .animation(
                            reduceMotion ? nil : .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                            value: animatingPhase
                        )
                }

                // Percentage
                Text("\(Int(progress.progress * 100))%")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(progressColor)
                    .monospacedDigit()

                // Status message
                Text(progress.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Phase steps
            phaseStepsView

            Spacer()

            // Cancel button
            if progress.phase != .completed && progress.phase != .failed {
                Button(action: onCancel) {
                    Text("Cancel")
                        .frame(minWidth: 100)
                }
                .buttonStyle(.bordered)
            } else if progress.phase == .completed {
                Button(action: onCancel) {
                    Text("Done")
                        .frame(minWidth: 100)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(action: onCancel) {
                    Text("Close")
                        .frame(minWidth: 100)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(32)
        .frame(width: 350, height: 450)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            if !reduceMotion {
                animatingPhase = true
            }
        }
    }

    // MARK: - Phase Icon

    @ViewBuilder
    private var phaseIcon: some View {
        switch progress.phase {
        case .preparing:
            Image(systemName: "gear")
        case .generatingTranscript:
            Image(systemName: "text.bubble")
        case .generatingInsights:
            Image(systemName: "lightbulb")
        case .encodingData:
            Image(systemName: "doc.text")
        case .writingFile:
            Image(systemName: "arrow.down.doc")
        case .completed:
            Image(systemName: "checkmark.circle.fill")
        case .failed:
            Image(systemName: "xmark.circle.fill")
        }
    }

    // MARK: - Progress Color

    private var progressColor: Color {
        switch progress.phase {
        case .completed:
            return .green
        case .failed:
            return .red
        default:
            return .accentColor
        }
    }

    // MARK: - Phase Steps View

    private var phaseStepsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            phaseStepRow(.preparing, label: "Preparing")
            phaseStepRow(.generatingTranscript, label: "Generating Transcript")
            phaseStepRow(.generatingInsights, label: "Processing Insights")
            phaseStepRow(.encodingData, label: "Encoding Data")
            phaseStepRow(.writingFile, label: "Writing File")
        }
        .padding(16)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }

    private func phaseStepRow(_ phase: ExportProgress.Phase, label: String) -> some View {
        HStack(spacing: 12) {
            // Status indicator
            phaseStatusIcon(for: phase)
                .frame(width: 20)

            // Label
            Text(label)
                .font(.subheadline)
                .foregroundColor(phaseTextColor(for: phase))

            Spacer()
        }
    }

    @ViewBuilder
    private func phaseStatusIcon(for phase: ExportProgress.Phase) -> some View {
        if isPhaseCompleted(phase) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        } else if isPhaseActive(phase) {
            ProgressView()
                .scaleEffect(0.7)
        } else {
            Image(systemName: "circle")
                .foregroundColor(.gray.opacity(0.5))
        }
    }

    private func phaseTextColor(for phase: ExportProgress.Phase) -> Color {
        if isPhaseCompleted(phase) {
            return .primary
        } else if isPhaseActive(phase) {
            return .primary
        } else {
            return .secondary
        }
    }

    private func isPhaseCompleted(_ phase: ExportProgress.Phase) -> Bool {
        let phaseOrder: [ExportProgress.Phase] = [
            .preparing,
            .generatingTranscript,
            .generatingInsights,
            .encodingData,
            .writingFile,
            .completed
        ]

        guard let currentIndex = phaseOrder.firstIndex(of: progress.phase),
              let checkIndex = phaseOrder.firstIndex(of: phase) else {
            return false
        }

        return checkIndex < currentIndex || progress.phase == .completed
    }

    private func isPhaseActive(_ phase: ExportProgress.Phase) -> Bool {
        return progress.phase == phase && progress.phase != .completed && progress.phase != .failed
    }
}

// MARK: - Compact Progress View

/// A compact inline progress indicator for export operations
struct ExportProgressIndicator: View {
    let progress: ExportProgress
    let compact: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(progress: ExportProgress, compact: Bool = false) {
        self.progress = progress
        self.compact = compact
    }

    var body: some View {
        if compact {
            compactView
        } else {
            standardView
        }
    }

    private var compactView: some View {
        HStack(spacing: 8) {
            if progress.phase == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if progress.phase == .failed {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            } else {
                ProgressView()
                    .scaleEffect(0.7)
            }

            Text(progress.message)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }

    private var standardView: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progress.progress)
                        .animation(reduceMotion ? nil : .easeInOut(duration: AnimationTiming.normal), value: progress.progress)
                }
            }
            .frame(height: 8)

            // Status
            HStack {
                Text(progress.message)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(progress.progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
        }
    }

    private var progressColor: Color {
        switch progress.phase {
        case .completed:
            return .green
        case .failed:
            return .red
        default:
            return .accentColor
        }
    }
}

// MARK: - Preview

#Preview("Export Progress - In Progress") {
    ExportProgressView(
        progress: .generatingTranscript(progress: 0.45),
        onCancel: { }
    )
}

#Preview("Export Progress - Completed") {
    ExportProgressView(
        progress: .completed,
        onCancel: { }
    )
}

#Preview("Export Progress - Failed") {
    ExportProgressView(
        progress: .failed("Connection error"),
        onCancel: { }
    )
}

#Preview("Compact Progress Indicator") {
    VStack(spacing: 20) {
        ExportProgressIndicator(
            progress: .generatingTranscript(progress: 0.45),
            compact: true
        )

        ExportProgressIndicator(
            progress: .generatingTranscript(progress: 0.45),
            compact: false
        )
        .frame(width: 300)
    }
    .padding()
}
