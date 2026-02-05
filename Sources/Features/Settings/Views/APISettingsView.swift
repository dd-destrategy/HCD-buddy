import SwiftUI

/// API settings view
/// Provides options for managing OpenAI API keys
/// Enhanced with Liquid Glass UI styling
struct APISettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var showUpdateKeySheet: Bool = false
    @State private var showRemoveConfirmation: Bool = false
    @State private var showTestResult: Bool = false
    @State private var isTestingKey: Bool = false
    @State private var testResultMessage: String = ""
    @State private var testResultIsSuccess: Bool = false
    @State private var errorMessage: String?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                // API Key Status Section
                SettingsSection(title: "API Key Status") {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            if settings.isAPIKeyConfigured {
                                HStack(spacing: Spacing.sm) {
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
                                HStack(spacing: Spacing.sm) {
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
                }

                // API Key Management Section
                SettingsSection(title: "OpenAI API Key") {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Your API key is encrypted and stored securely in your system Keychain")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: Spacing.md) {
                            Button(action: { showUpdateKeySheet = true }) {
                                HStack {
                                    Image(systemName: "key")
                                    Text(settings.isAPIKeyConfigured ? "Update Key" : "Add Key")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.sm)
                            }
                            .glassButton(isActive: !settings.isAPIKeyConfigured, style: .primary)
                            .help("Add or update your OpenAI API key")

                            if settings.isAPIKeyConfigured {
                                Button(action: { showRemoveConfirmation = true }) {
                                    Image(systemName: "trash")
                                        .padding(.horizontal, Spacing.sm)
                                        .padding(.vertical, Spacing.sm)
                                }
                                .glassButton(style: .destructive)
                                .help("Remove your API key")
                            }
                        }
                    }
                }

                // Test API Key Section
                if settings.isAPIKeyConfigured {
                    SettingsSection(title: "Test Connection") {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Button(action: testAPIKey) {
                                HStack {
                                    if isTestingKey {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "checkmark.circle")
                                    }
                                    Text(isTestingKey ? "Testing..." : "Test API Key")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.sm)
                            }
                            .glassButton(style: .secondary)
                            .help("Verify that your API key is valid and has the necessary permissions")
                            .disabled(isTestingKey)

                            if showTestResult {
                                APITestResultView(
                                    isSuccess: testResultIsSuccess,
                                    message: testResultMessage
                                )
                            }
                        }
                    }
                }

                // Learn More Section
                SettingsSection(title: "Learn More") {
                    VStack(alignment: .leading, spacing: 0) {
                        SettingsLinkRow(
                            icon: "key.horizontal",
                            title: "OpenAI API Keys Console",
                            url: "https://platform.openai.com/account/api-keys"
                        )

                        Divider().opacity(0.3)

                        SettingsLinkRow(
                            icon: "questionmark.circle",
                            title: "API Key Setup Guide",
                            url: "https://support.hcdinterviewcoach.com/api-setup"
                        )

                        Divider().opacity(0.3)

                        SettingsLinkRow(
                            icon: "books.vertical",
                            title: "OpenAI Realtime API Documentation",
                            url: "https://platform.openai.com/docs/guides/realtime"
                        )
                    }
                }

                // Error Message
                if let error = errorMessage {
                    ErrorMessageView(message: error, onDismiss: { errorMessage = nil })
                }

                Spacer()
            }
            .padding(Spacing.xl)
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
        return String(repeating: "*", count: 37) + settings.apiKeyLastFourCharacters
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

// MARK: - API Test Result View

struct APITestResultView: View {
    let isSuccess: Bool
    let message: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(isSuccess ? .green : .red)
            Text(message)
                .font(.caption)
                .lineLimit(nil)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(isSuccess
                    ? Color.green.opacity(colorScheme == .dark ? 0.15 : 0.1)
                    : Color.red.opacity(colorScheme == .dark ? 0.15 : 0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(isSuccess ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Settings Link Row

struct SettingsLinkRow: View {
    let icon: String
    let title: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .frame(width: 24)
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Spacing.sm)
        }
    }
}

// MARK: - Error Message View

struct ErrorMessageView: View {
    let message: String
    let onDismiss: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Error")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(message)
                        .font(.caption)
                        .lineLimit(nil)
                }
            }

            Button("Dismiss", action: onDismiss)
                .frame(maxWidth: .infinity)
                .glassButton(style: .secondary)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.15 : 0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - API Key Input View

struct APIKeyInputView: View {
    @Binding var isPresented: Bool
    var onSave: (String) -> Void

    @State private var apiKey: String = ""
    @State private var showKey: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Header
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

            // API Key Input
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("OpenAI API Key")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: Spacing.sm) {
                    Group {
                        if showKey {
                            TextField("sk-...", text: $apiKey)
                        } else {
                            SecureField("sk-...", text: $apiKey)
                        }
                    }
                    .textFieldStyle(.plain)
                    .padding(Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .fill(colorScheme == .dark
                                ? Color.white.opacity(0.05)
                                : Color.black.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                    )

                    Button(action: { showKey.toggle() }) {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(Spacing.sm)
                    }
                    .glassButton(style: .ghost)
                }

                Text("Your API key will be encrypted and stored securely in your Keychain")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Instructions
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("How to get your API key:")
                    .font(.caption)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    InstructionRow(step: "1", text: "Go to platform.openai.com/account/api-keys")
                    InstructionRow(step: "2", text: "Click \"Create new secret key\"")
                    InstructionRow(step: "3", text: "Copy the key and paste it above")
                }
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .fill(colorScheme == .dark
                            ? Color.white.opacity(0.03)
                            : Color.black.opacity(0.02))
                )
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

                Button("Save Key") {
                    onSave(apiKey)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .glassButton(isActive: true, style: .primary)
                .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(Spacing.xl)
        .frame(width: 450, height: 450)
        .glassSheet()
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let step: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text(step + ".")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16, alignment: .leading)
            Text(text)
                .font(.caption)
        }
    }
}

#Preview {
    APISettingsView()
        .environmentObject(AppSettings())
        .frame(width: 500, height: 600)
}
