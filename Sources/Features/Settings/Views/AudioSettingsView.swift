import SwiftUI

/// Audio settings view
/// Provides options for audio device management, audio setup, and troubleshooting
struct AudioSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var currentAudioDevice: String = "System Default"
    @State private var audioInputDevice: String = "Microphone"
    @State private var isTestingAudio: Bool = false
    @State private var audioTestResult: AudioTestResult?
    @State private var showAudioTestSheet: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Audio Output Device")
                        .font(.headline)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentAudioDevice)
                                .font(.body)

                            Text("Captures audio from video calls")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .padding(12)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(6)

                    Text("This is the multi-output device currently capturing system audio")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Audio Input Device")
                        .font(.headline)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(audioInputDevice)
                                .font(.body)

                            Text("Captures your microphone input")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .padding(12)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(6)
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Button(action: { showAudioTestSheet = true }) {
                        HStack {
                            Image(systemName: "speaker.wave.2")
                            Text("Test Audio Levels")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .help("Run a quick audio level test to verify both input sources")

                    if let result = audioTestResult {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: result.isSuccessful ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                    .foregroundColor(result.isSuccessful ? .green : .orange)
                                Text(result.message)
                                    .font(.caption)
                            }
                        }
                        .padding(12)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Button(action: runAudioSetup) {
                        HStack {
                            Image(systemName: "gearshape")
                            Text("Re-run Audio Setup Wizard")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .help("Run the audio setup wizard to reconfigure your audio devices")

                    Text("Use this if your audio devices have changed or audio capture is not working correctly")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Troubleshooting")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        Link(destination: URL(string: "https://support.hcdinterviewcoach.com/audio-setup")!) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                Text("Audio Setup Guide")
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                        }

                        Divider()

                        Link(destination: URL(string: "https://support.hcdinterviewcoach.com/audio-troubleshooting")!) {
                            HStack {
                                Image(systemName: "wrench.and.screwdriver")
                                Text("Audio Troubleshooting")
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                        }

                        Divider()

                        Link(destination: URL(string: "https://support.hcdinterviewcoach.com/faq")!) {
                            HStack {
                                Image(systemName: "books.vertical")
                                Text("Frequently Asked Questions")
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(24)
        }
        .sheet(isPresented: $showAudioTestSheet) {
            AudioTestView(isPresented: $showAudioTestSheet, testResult: $audioTestResult)
        }
    }

    private func runAudioSetup() {
        // TODO: Trigger the Audio Setup Wizard
        print("Running audio setup wizard...")
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

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("System Audio")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.0f%%", systemAudioLevel * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.controlBackgroundColor))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    systemAudioLevel > 0.8 ? Color.red :
                                        systemAudioLevel > 0.5 ? Color.yellow :
                                            Color.green
                                )
                                .frame(width: geometry.size.width * systemAudioLevel)
                        }
                    }
                    .frame(height: 8)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Microphone")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.0f%%", microphoneLevel * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.controlBackgroundColor))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    microphoneLevel > 0.8 ? Color.red :
                                        microphoneLevel > 0.5 ? Color.yellow :
                                            Color.green
                                )
                                .frame(width: geometry.size.width * microphoneLevel)
                        }
                    }
                    .frame(height: 8)
                }
            }

            Divider()

            if isRunning {
                VStack(alignment: .center, spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)

                    Text("Testing audio levels...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
            } else {
                Text("Speak into your microphone or play audio from a video call. Both input sources should register above 30%.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Start Test") {
                    startAudioTest()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 400, height: 300)
    }

    private func startAudioTest() {
        isRunning = true

        // Simulate audio testing with animation
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            withAnimation {
                systemAudioLevel = Double.random(in: 0.2 ... 0.8)
                microphoneLevel = Double.random(in: 0.2 ... 0.8)
            }

            // Stop after 5 seconds
            if Date().timeIntervalSince(Date()) > 5 {
                timer.invalidate()
                isRunning = false

                // Generate result
                let isSuccessful = systemAudioLevel > 0.3 && microphoneLevel > 0.3
                testResult = AudioTestResult(
                    isSuccessful: isSuccessful,
                    message: isSuccessful ?
                        "Audio levels look good! Both sources are detecting properly." :
                        "Warning: One or more audio sources may not be configured correctly.",
                    systemAudioLevel: systemAudioLevel,
                    microphoneLevel: microphoneLevel
                )
            }
        }
    }
}

#Preview {
    AudioSettingsView()
        .environmentObject(AppSettings())
}
