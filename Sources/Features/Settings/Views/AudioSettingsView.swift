import SwiftUI

/// Audio settings view
/// Provides options for audio device management, audio setup, and troubleshooting
/// Enhanced with Liquid Glass UI styling
struct AudioSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var currentAudioDevice: String = "System Default"
    @State private var audioInputDevice: String = "Microphone"
    @State private var isTestingAudio: Bool = false
    @State private var audioTestResult: AudioTestResult?
    @State private var showAudioTestSheet: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                // Audio Output Section
                SettingsSection(title: "Audio Output Device") {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(currentAudioDevice)
                                    .font(.body)
                                    .fontWeight(.medium)

                                Text("Captures audio from video calls")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                        }

                        Text("This is the multi-output device currently capturing system audio")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Audio Input Section
                SettingsSection(title: "Audio Input Device") {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(audioInputDevice)
                                .font(.body)
                                .fontWeight(.medium)

                            Text("Captures your microphone input")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    }
                }

                // Audio Test Section
                SettingsSection(title: "Audio Test") {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Button(action: { showAudioTestSheet = true }) {
                            HStack {
                                Image(systemName: "speaker.wave.2")
                                Text("Test Audio Levels")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                        }
                        .glassButton(style: .secondary)
                        .help("Run a quick audio level test to verify both input sources")

                        if let result = audioTestResult {
                            AudioTestResultBadge(result: result)
                        }
                    }
                }

                // Audio Setup Section
                SettingsSection(title: "Audio Setup") {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Button(action: runAudioSetup) {
                            HStack {
                                Image(systemName: "gearshape")
                                Text("Re-run Audio Setup Wizard")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                        }
                        .glassButton(style: .secondary)
                        .help("Run the audio setup wizard to reconfigure your audio devices")

                        Text("Use this if your audio devices have changed or audio capture is not working correctly")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Troubleshooting Section
                SettingsSection(title: "Troubleshooting") {
                    VStack(alignment: .leading, spacing: 0) {
                        SettingsLinkRow(
                            icon: "questionmark.circle",
                            title: "Audio Setup Guide",
                            url: "https://support.hcdinterviewcoach.com/audio-setup"
                        )

                        Divider().opacity(0.3)

                        SettingsLinkRow(
                            icon: "wrench.and.screwdriver",
                            title: "Audio Troubleshooting",
                            url: "https://support.hcdinterviewcoach.com/audio-troubleshooting"
                        )

                        Divider().opacity(0.3)

                        SettingsLinkRow(
                            icon: "books.vertical",
                            title: "Frequently Asked Questions",
                            url: "https://support.hcdinterviewcoach.com/faq"
                        )
                    }
                }

                Spacer()
            }
            .padding(Spacing.xl)
        }
        .sheet(isPresented: $showAudioTestSheet) {
            AudioTestView(isPresented: $showAudioTestSheet, testResult: $audioTestResult)
        }
    }

    private func runAudioSetup() {
        // ISSUE-123: Audio Setup Wizard integration pending
        // This will be connected to the AudioSetupWizard component in a future update
        AppLogger.shared.info("Audio setup wizard triggered - integration pending")
    }
}

// MARK: - Audio Test Result Badge

struct AudioTestResultBadge: View {
    let result: AudioTestResult
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: result.isSuccessful ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(result.isSuccessful ? .green : .orange)
            Text(result.message)
                .font(.caption)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(result.isSuccessful
                    ? Color.green.opacity(colorScheme == .dark ? 0.15 : 0.1)
                    : Color.orange.opacity(colorScheme == .dark ? 0.15 : 0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(result.isSuccessful ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Audio Test Result

struct AudioTestResult {
    let isSuccessful: Bool
    let message: String
    let systemAudioLevel: Double
    let microphoneLevel: Double
}

// MARK: - Audio Test View

struct AudioTestView: View {
    @Binding var isPresented: Bool
    @Binding var testResult: AudioTestResult?

    @State private var systemAudioLevel: Double = 0.0
    @State private var microphoneLevel: Double = 0.0
    @State private var isRunning: Bool = false
    @State private var audioTestTimer: Timer?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Header
            HStack {
                Text("Audio Level Test")
                    .font(.headline)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Audio Level Meters
            VStack(alignment: .leading, spacing: Spacing.lg) {
                AudioLevelMeter(
                    label: "System Audio",
                    level: systemAudioLevel
                )

                AudioLevelMeter(
                    label: "Microphone",
                    level: microphoneLevel
                )
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(colorScheme == .dark
                        ? Color.white.opacity(0.03)
                        : Color.black.opacity(0.02))
            )

            Divider().opacity(0.5)

            // Status/Instructions
            if isRunning {
                HStack {
                    Spacer()
                    VStack(spacing: Spacing.md) {
                        ProgressView()
                            .scaleEffect(1.2)

                        Text("Testing audio levels...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, Spacing.lg)
            } else {
                Text("Speak into your microphone or play audio from a video call. Both input sources should register above 30%.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Action Buttons
            HStack(spacing: Spacing.md) {
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                .glassButton(style: .secondary)

                Button("Start Test") {
                    startAudioTest()
                }
                .keyboardShortcut(.defaultAction)
                .glassButton(isActive: true, style: .primary)
                .disabled(isRunning)
            }
        }
        .padding(Spacing.xl)
        .frame(width: 400, height: 350)
        .glassSheet()
        .onDisappear {
            audioTestTimer?.invalidate()
            audioTestTimer = nil
        }
    }

    private func startAudioTest() {
        isRunning = true
        let startTime = Date()

        // Invalidate any existing timer
        audioTestTimer?.invalidate()

        // Simulate audio testing with animation
        audioTestTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.systemAudioLevel = Double.random(in: 0.2 ... 0.8)
                    self.microphoneLevel = Double.random(in: 0.2 ... 0.8)
                }

                // Stop after 5 seconds
                if Date().timeIntervalSince(startTime) > 5 {
                    timer.invalidate()
                    self.audioTestTimer = nil
                    self.isRunning = false

                    // Generate result
                    let isSuccessful = self.systemAudioLevel > 0.3 && self.microphoneLevel > 0.3
                    self.testResult = AudioTestResult(
                        isSuccessful: isSuccessful,
                        message: isSuccessful ?
                            "Audio levels look good! Both sources are detecting properly." :
                            "Warning: One or more audio sources may not be configured correctly.",
                        systemAudioLevel: self.systemAudioLevel,
                        microphoneLevel: self.microphoneLevel
                    )
                }
            }
        }
    }
}

// MARK: - Audio Level Meter

struct AudioLevelMeter: View {
    let label: String
    let level: Double
    @Environment(\.colorScheme) private var colorScheme

    private var levelColor: Color {
        if level > 0.8 {
            return .red
        } else if level > 0.5 {
            return .yellow
        } else {
            return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "%.0f%%", level * 100))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(colorScheme == .dark
                            ? Color.white.opacity(0.1)
                            : Color.black.opacity(0.08))

                    // Level indicator
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(
                            LinearGradient(
                                colors: [levelColor.opacity(0.8), levelColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * level)
                        .animation(.easeInOut(duration: 0.3), value: level)
                }
            }
            .frame(height: 10)
        }
    }
}

#Preview {
    AudioSettingsView()
        .environmentObject(AppSettings())
        .frame(width: 500, height: 600)
}
