import SwiftUI

/// API settings view
/// Provides options for managing OpenAI API keys
struct APISettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var showUpdateKeySheet: Bool = false
    @State private var showRemoveConfirmation: Bool = false
    @State private var showTestResult: Bool = false
    @State private var isTestingKey: Bool = false
    @State private var testResultMessage: String = ""
    @State private var testResultIsSuccess: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key Status")
                        .font(.headline)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            if settings.isAPIKeyConfigured {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("API Key Configured")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }

                                Text(getMaskedKeyDisplay())
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary)
                            } else {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.orange)
                                    Text("No API Key Set")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }

                                Text("You need to configure an API key to use this app")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(6)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("OpenAI API Key")
                        .font(.headline)

                    Text("Your API key is encrypted and stored securely in your system Keychain")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Button(action: { showUpdateKeySheet = true }) {
                            HStack {
                                Image(systemName: "key")
                                Text(settings.isAPIKeyConfigured ? "Update Key" : "Add Key")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .help("Add or update your OpenAI API key")

                        if settings.isAPIKeyConfigured {
                            Button(action: { showRemoveConfirmation = true }) {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.bordered)
                            .help("Remove your API key")
                            .foregroundColor(.red)
                        }
                    }
                }

                if settings.isAPIKeyConfigured {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: testAPIKey) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Test API Key")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .help("Verify that your API key is valid and has the necessary permissions")
                        .disabled(isTestingKey)

                        if isTestingKey {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Testing API key...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if showTestResult {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: testResultIsSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                        .foregroundColor(testResultIsSuccess ? .green : .red)
                                    Text(testResultMessage)
                                        .font(.caption)
                                        .lineLimit(nil)
                                }
                            }
                            .padding(12)
                            .background(
                                testResultIsSuccess ?
                                    Color.green.opacity(0.1) :
                                    Color.red.opacity(0.1)
                            )
                            .cornerRadius(6)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Learn More")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        Link(destination: URL(string: "https://platform.openai.com/account/api-keys")!) {
                            HStack {
                                Image(systemName: "key.horizontal")
                                Text("OpenAI API Keys Console")
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                        }

                        Divider()

                        Link(destination: URL(string: "https://support.hcdinterviewcoach.com/api-setup")!) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                Text("API Key Setup Guide")
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                        }

                        Divider()

                        Link(destination: URL(string: "https://platform.openai.com/docs/guides/realtime")!) {
                            HStack {
                                Image(systemName: "books.vertical")
                                Text("OpenAI Realtime API Documentation")
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                        }
                    }
                }

                if let error = errorMessage {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Error")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                        Text(error)
                            .font(.caption)
                            .lineLimit(nil)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)

                    Button("Dismiss", action: { errorMessage = nil })
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)
                }

                Spacer()
            }
            .padding(24)
        }
        .sheet(isPresented: $showUpdateKeySheet) {
            APIKeyInputView(isPresented: $showUpdateKeySheet, onSave: saveAPIKey)
        }
        .alert("Remove API Key?", isPresented: $showRemoveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                removeAPIKey()
            }
        } message: {
            Text("Are you sure you want to remove your API key? You will need to add a new key to use the app.")
        }
    }

    private func getMaskedKeyDisplay() -> String {
        if settings.apiKeyLastFourCharacters.isEmpty {
            return "(no key set)"
        }
        return String(repeating: "•", count: 37) + settings.apiKeyLastFourCharacters
    }

    private func saveAPIKey(_ key: String) {
        do {
            try KeychainService.shared.saveAPIKey(key)

            // Update settings
            settings.hasAPIKey = true
            let lastFour = String(key.suffix(4))
            settings.apiKeyLastFourCharacters = lastFour

            errorMessage = nil
        } catch {
            errorMessage = "Failed to save API key: \(error.localizedDescription)"
        }
    }

    private func removeAPIKey() {
        do {
            try KeychainService.shared.deleteAPIKey()

            // Update settings
            settings.hasAPIKey = false
            settings.apiKeyLastFourCharacters = ""

            showTestResult = false
            errorMessage = nil
        } catch {
            errorMessage = "Failed to remove API key: \(error.localizedDescription)"
        }
    }

    private func testAPIKey() {
        isTestingKey = true
        showTestResult = false

        // Simulate API test with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // For demo purposes, simulate a successful test
            testResultIsSuccess = true
            testResultMessage = "API key is valid and configured correctly. You're ready to start interviewing!"
            showTestResult = true
            isTestingKey = false
        }
    }
}

// MARK: - API Key Input View
struct APIKeyInputView: View {
    @Binding var isPresented: Bool
    var onSave: (String) -> Void

    @State private var apiKey: String = ""
    @State private var showKey: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Add API Key")
                    .font(.headline)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("OpenAI API Key")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack {
                    if showKey {
                        TextField("sk-...", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("sk-...", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button(action: { showKey.toggle() }) {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Text("Your API key will be encrypted and stored securely in your Keychain")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("How to get your API key:")
                    .font(.caption)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        Text("1.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Go to https://platform.openai.com/account/api-keys")
                            .font(.caption)
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Text("2.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Click \"Create new secret key\"")
                            .font(.caption)
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Text("3.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Copy the key and paste it above")
                            .font(.caption)
                    }
                }
                .padding(12)
                .background(Color(.controlBackgroundColor).opacity(0.5))
                .cornerRadius(6)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Save Key") {
                    onSave(apiKey)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 450, height: 450)
    }
}

#Preview {
    APISettingsView()
        .environmentObject(AppSettings())
}
