//
//  TalkTimeIndicatorView.swift
//  HCD Interview Coach
//
//  EPIC E4: Session Manager
//  Compact SwiftUI indicator showing real-time talk-time ratio
//  between interviewer and participant.
//

import SwiftUI

// MARK: - Talk Time Indicator View

/// A compact indicator displaying the interviewer-to-participant talk-time ratio.
///
/// Supports two display modes:
/// - **Compact**: Horizontal ratio bar only, suitable for toolbar embedding
/// - **Expanded**: Full bar with percentage labels, health icon, and description
struct TalkTimeIndicatorView: View {

    @ObservedObject var analyzer: TalkTimeAnalyzer

    /// Whether to show the expanded view with labels and description
    var isExpanded: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if isExpanded {
            expandedView
        } else {
            compactView
        }
    }

    // MARK: - Compact View

    /// Minimal horizontal bar showing the talk-time ratio
    private var compactView: some View {
        ratioBar
            .frame(height: 6)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityDescription)
            .accessibilityHint("Talk-time ratio between interviewer and participant")
    }

    // MARK: - Expanded View

    /// Full view with bar, labels, health icon, and description
    private var expandedView: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header row: title + health icon
            HStack(spacing: Spacing.sm) {
                Text("Talk-Time Ratio")
                    .font(Typography.bodyMedium)
                    .foregroundColor(.primary)

                Spacer()

                healthBadge
            }

            // Ratio bar
            ratioBar
                .frame(height: 8)

            // Percentage labels
            HStack {
                Label {
                    Text("Interviewer \(interviewerPercent)%")
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                } icon: {
                    Circle()
                        .fill(interviewerColor)
                        .frame(width: 8, height: 8)
                }

                Spacer()

                Label {
                    Text("Participant \(participantPercent)%")
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                } icon: {
                    Circle()
                        .fill(participantColor)
                        .frame(width: 8, height: 8)
                }
            }

            // Health description (only when not good)
            if analyzer.healthStatus != .good {
                Text(analyzer.healthStatus.description)
                    .font(Typography.small)
                    .foregroundColor(analyzer.healthStatus.color)
                    .transition(.opacity)
            }
        }
        .padding(Spacing.md)
        .liquidGlass(
            material: .thin,
            cornerRadius: CornerRadius.large,
            borderStyle: .subtle,
            enableHover: false
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Talk-time ratio between interviewer and participant")
    }

    // MARK: - Ratio Bar

    /// The horizontal bar visualizing the talk-time ratio
    private var ratioBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: CornerRadius.pill)
                    .fill(Color.secondary.opacity(0.15))

                // Filled portion
                if analyzer.totalSpeakingTime > 0 {
                    HStack(spacing: 0) {
                        // Interviewer segment
                        RoundedRectangle(cornerRadius: CornerRadius.pill)
                            .fill(interviewerColor)
                            .frame(width: max(0, geometry.size.width * analyzer.interviewerRatio))

                        // Participant segment fills the rest
                        RoundedRectangle(cornerRadius: CornerRadius.pill)
                            .fill(participantColor)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: AnimationTiming.normal),
                        value: analyzer.interviewerRatio
                    )
                }
            }
        }
    }

    // MARK: - Health Badge

    /// Badge showing the current health status icon and color
    private var healthBadge: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: analyzer.healthStatus.icon)
                .font(Typography.caption)
                .foregroundColor(analyzer.healthStatus.color)

            Text(analyzer.healthStatus.rawValue.capitalized)
                .font(Typography.caption)
                .foregroundColor(analyzer.healthStatus.color)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(
            Capsule()
                .fill(analyzer.healthStatus.color.opacity(0.12))
        )
        .accessibilityLabel("Status: \(analyzer.healthStatus.rawValue)")
        .accessibilityHint(analyzer.healthStatus.description)
    }

    // MARK: - Colors

    /// Color representing interviewer talk time
    private var interviewerColor: Color {
        .blue
    }

    /// Color representing participant talk time
    private var participantColor: Color {
        .green
    }

    // MARK: - Computed Helpers

    /// Interviewer percentage as an integer for display
    private var interviewerPercent: Int {
        Int(round(analyzer.interviewerRatio * 100))
    }

    /// Participant percentage as an integer for display
    private var participantPercent: Int {
        Int(round(analyzer.participantRatio * 100))
    }

    /// Full accessibility description of the current ratio state
    private var accessibilityDescription: String {
        if analyzer.totalSpeakingTime == 0 {
            return "Talk-time ratio: no speech detected yet"
        }
        return "Interviewer speaking \(interviewerPercent)%, participant \(participantPercent)%, status \(analyzer.healthStatus.rawValue)"
    }
}

// MARK: - Preview

#if DEBUG
struct TalkTimeIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                // Expanded view
                TalkTimeIndicatorView(
                    analyzer: previewAnalyzer(interviewer: 25, participant: 75),
                    isExpanded: true
                )

                // Compact view
                TalkTimeIndicatorView(
                    analyzer: previewAnalyzer(interviewer: 35, participant: 65),
                    isExpanded: false
                )
                .frame(width: 200)

                // Warning state
                TalkTimeIndicatorView(
                    analyzer: previewAnalyzer(interviewer: 55, participant: 45),
                    isExpanded: true
                )
            }
            .padding()
        }
    }

    @MainActor
    static func previewAnalyzer(interviewer: Int, participant: Int) -> TalkTimeAnalyzer {
        let analyzer = TalkTimeAnalyzer()
        // Create utterances to achieve the desired ratio
        for _ in 0..<interviewer {
            let utterance = Utterance(
                speaker: .interviewer,
                text: "word word word word word",
                timestampSeconds: 0.0
            )
            analyzer.processUtterance(utterance)
        }
        for _ in 0..<participant {
            let utterance = Utterance(
                speaker: .participant,
                text: "word word word word word",
                timestampSeconds: 0.0
            )
            analyzer.processUtterance(utterance)
        }
        return analyzer
    }
}
#endif
