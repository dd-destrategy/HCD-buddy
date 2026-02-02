//
//  AIReflectionView.swift
//  HCD Interview Coach
//
//  EPIC E10: Post-Session Summary
//  Displays AI-generated session reflection with loading states
//

import SwiftUI

// MARK: - AI Reflection View

/// Displays the AI-generated reflection on the interview session
struct AIReflectionView: View {
    @ObservedObject var viewModel: PostSessionViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with expand/collapse
            Button(action: { toggleExpanded() }) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(.purple)
                        .symbolRenderingMode(.multicolor)

                    Text("AI Reflection")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    if viewModel.reflectionState.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint(isExpanded ? "Collapse section" : "Expand section")

            if isExpanded {
                contentView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            if viewModel.reflectionState == .idle {
                Task {
                    await viewModel.generateReflection()
                }
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.reflectionState {
        case .idle:
            idleView

        case .generating:
            loadingView

        case .completed(let reflection):
            completedView(reflection: reflection)

        case .failed(let error):
            errorView(error: error)
        }
    }

    // MARK: - State Views

    private var idleView: some View {
        VStack(spacing: 12) {
            Text("Generate an AI-powered reflection on your interview session.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { Task { await viewModel.generateReflection() } }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Generate Reflection")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                LoadingSparkles()

                Text("Analyzing interview...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Animated loading placeholders
            VStack(alignment: .leading, spacing: 8) {
                LoadingPlaceholderLine(width: 1.0)
                LoadingPlaceholderLine(width: 0.9)
                LoadingPlaceholderLine(width: 0.85)

                Spacer().frame(height: 8)

                LoadingPlaceholderLine(width: 0.95)
                LoadingPlaceholderLine(width: 0.88)
                LoadingPlaceholderLine(width: 0.6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func completedView(reflection: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Reflection text with paragraph styling
            Text(reflection)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
                .textSelection(.enabled)

            // Actions
            HStack {
                Button(action: copyReflection) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button(action: { Task { await viewModel.retryReflection() } }) {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()
            }
        }
    }

    private func errorView(error: String) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)

                Text("Unable to generate reflection")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { Task { await viewModel.retryReflection() } }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Actions

    private func toggleExpanded() {
        if reduceMotion {
            isExpanded.toggle()
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }

    private func copyReflection() {
        guard let reflection = viewModel.reflectionState.reflection else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(reflection, forType: .string)
    }
}

// MARK: - Loading Sparkles Animation

/// Animated sparkles icon for loading state
private struct LoadingSparkles: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isAnimating = false

    var body: some View {
        Image(systemName: "sparkles")
            .font(.title2)
            .foregroundColor(.purple)
            .symbolRenderingMode(.multicolor)
            .opacity(opacityValue)
            .scaleEffect(scaleValue)
            .onAppear {
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                }
            }
    }

    private var opacityValue: Double {
        reduceMotion ? 1.0 : (isAnimating ? 0.5 : 1.0)
    }

    private var scaleValue: CGFloat {
        reduceMotion ? 1.0 : (isAnimating ? 1.1 : 0.9)
    }
}

// MARK: - Loading Placeholder Line

/// Animated placeholder line for loading state
private struct LoadingPlaceholderLine: View {
    let width: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(opacityValue))
                .frame(width: geometry.size.width * width, height: 12)
        }
        .frame(height: 12)
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
    }

    private var opacityValue: Double {
        reduceMotion ? 0.3 : (isAnimating ? 0.15 : 0.3)
    }
}

// MARK: - Standalone Reflection Card

/// Standalone reflection display for use outside the summary view
struct ReflectionCard: View {
    let reflection: String
    var onCopy: (() -> Void)?
    var onRegenerate: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(.purple)
                    .symbolRenderingMode(.multicolor)

                Text("AI Reflection")
                    .font(.headline)

                Spacer()
            }

            Text(reflection)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
                .textSelection(.enabled)

            if onCopy != nil || onRegenerate != nil {
                HStack {
                    if let onCopy = onCopy {
                        Button(action: onCopy) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    if let onRegenerate = onRegenerate {
                        Button(action: onRegenerate) {
                            Label("Regenerate", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("AI Reflection View") {
    let session = Session(
        participantName: "Test User",
        projectName: "Demo Project",
        sessionMode: .full
    )

    let viewModel = PostSessionViewModel(session: session)

    return VStack(spacing: 20) {
        AIReflectionView(viewModel: viewModel)

        Divider()

        ReflectionCard(
            reflection: "This 30-minute interview with Test User yielded 5 notable insights. The predominant theme that emerged was 'user frustration', followed by 'feature requests' and 'workflow improvements'.\n\nKey moments worth revisiting include when the participant shared their struggles with the current onboarding process. There was a healthy balance of speaking time with the participant leading the conversation.\n\nFor follow-up, consider exploring the topics that weren't fully addressed: advanced features, integration needs. The insight about 'user frustration' particularly warrants deeper investigation in future sessions.",
            onCopy: { print("Copy tapped") },
            onRegenerate: { print("Regenerate tapped") }
        )
    }
    .padding()
    .frame(width: 500)
}
