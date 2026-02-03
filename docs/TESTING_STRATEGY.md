# HCD Interview Coach — Testing Strategy

This document describes the testing approach, organization, patterns, and practices for the HCD Interview Coach project.

---

## Table of Contents

1. [Overview](#overview)
2. [Test Organization](#test-organization)
3. [Coverage Targets](#coverage-targets)
4. [Mock Patterns](#mock-patterns)
5. [Running Tests](#running-tests)
6. [Writing Tests](#writing-tests)
7. [Integration Tests](#integration-tests)
8. [Accessibility Testing](#accessibility-testing)
9. [CI/CD Integration](#cicd-integration)

---

## Overview

### Testing Philosophy

We follow a pragmatic testing approach that balances quality with development velocity:

- **Focus on critical paths:** Session lifecycle, audio capture, API communication, and data persistence
- **Behavior-driven tests:** Test what the code does, not how it does it
- **Mock external dependencies:** Isolate units under test from network, audio hardware, and system services
- **Fast feedback loops:** Unit tests should run in seconds, not minutes

### Test Pyramid

```
         /\
        /  \      E2E Tests (manual)
       /----\
      /      \    Integration Tests (~15%)
     /--------\
    /          \  Unit Tests (~85%)
   /--------------\
```

---

## Test Organization

### Directory Structure

```
Tests/
├── Mocks/                          # Shared mock implementations
│   ├── MockAudioCaptureService.swift
│   ├── MockKeychainService.swift
│   ├── MockRealtimeAPIClient.swift
│   ├── MockRealtimeAPIServer.swift
│   └── MockSessionManager.swift
│
├── UnitTests/                      # Unit test suites
│   ├── Services/                   # Service layer tests
│   │   ├── AudioCaptureServiceTests.swift
│   │   ├── CoachingServiceTests.swift
│   │   ├── DataManagerTests.swift
│   │   ├── KeychainServiceTests.swift
│   │   ├── SessionManagerTests.swift
│   │   ├── SessionCoordinatorTests.swift
│   │   ├── SessionRecoveryServiceTests.swift
│   │   ├── TemplateManagerTests.swift
│   │   └── ...
│   │
│   ├── ViewModels/                 # ViewModel tests
│   │   ├── AudioSetupViewModelTests.swift
│   │   ├── ExportViewModelTests.swift
│   │   ├── InsightsViewModelTests.swift
│   │   ├── PostSessionViewModelTests.swift
│   │   ├── TopicAwarenessViewModelTests.swift
│   │   └── TranscriptViewModelTests.swift
│   │
│   ├── API/                        # API client tests
│   │   ├── AudioStreamingServiceTests.swift
│   │   ├── CertificatePinningTests.swift
│   │   ├── RealtimeAPIClientTests.swift
│   │   ├── SessionConfigBuilderTests.swift
│   │   └── TranscriptionEventHandlerTests.swift
│   │
│   ├── Accessibility/              # Accessibility tests
│   │   ├── ColorIndependenceTests.swift
│   │   ├── FocusManagerTests.swift
│   │   ├── KeyboardNavigationTests.swift
│   │   └── VoiceOverUtilitiesTests.swift
│   │
│   └── Export/                     # Export functionality tests
│       ├── ExportServiceTests.swift
│       ├── JSONExporterTests.swift
│       └── MarkdownExporterTests.swift
│
└── IntegrationTests/               # Integration test suites
    ├── TestHelpers/
    │   └── IntegrationTestCase.swift   # Base class for integration tests
    ├── AudioAPIIntegrationTests.swift
    ├── CoachingIntegrationTests.swift
    └── SessionIntegrationTests.swift
```

### Naming Conventions

| Pattern | Example | Purpose |
|---------|---------|---------|
| `{ServiceName}Tests.swift` | `CoachingServiceTests.swift` | Service unit tests |
| `{ViewModel}Tests.swift` | `TranscriptViewModelTests.swift` | ViewModel unit tests |
| `{Feature}IntegrationTests.swift` | `SessionIntegrationTests.swift` | Integration tests |
| `Mock{Protocol}.swift` | `MockAudioCaptureService.swift` | Mock implementations |

---

## Coverage Targets

### Overall Target: 70%

We target 70% code coverage as a balance between quality and velocity:

| Component | Target | Rationale |
|-----------|--------|-----------|
| Services | 80% | Core business logic, high value |
| ViewModels | 70% | Presentation logic, UI-adjacent |
| API Layer | 80% | Critical for app functionality |
| Utilities | 60% | Often simple, low-risk code |
| Views | 40% | UI testing has diminishing returns |

### Critical Path Coverage: 90%+

These paths must have high coverage:

- Session state machine transitions
- Audio capture start/stop/pause/resume
- API connection and reconnection logic
- Data persistence (SwiftData operations)
- Keychain operations (API key storage)
- Coaching prompt logic (silence-first rules)

### Measuring Coverage

```bash
# Generate coverage report via Xcode
xcodebuild test \
  -scheme HCDInterviewCoach \
  -destination 'platform=macOS' \
  -enableCodeCoverage YES

# View in Xcode: Product > Show Code Coverage
```

---

## Mock Patterns

### Protocol-Based Mocking

All external dependencies are abstracted behind protocols, enabling easy mocking:

```swift
// Protocol definition
protocol AudioCapturing {
    var isRunning: Bool { get }
    var audioLevels: AudioLevels { get }
    var audioStream: AsyncStream<AudioChunk> { get }

    func start() throws
    func stop()
    func pause()
    func resume()
}

// Production implementation
final class AudioCaptureEngine: AudioCapturing { ... }

// Mock implementation
@MainActor
final class MockAudioCaptureService: AudioCapturing {
    var isRunning = false
    var shouldThrowOnStart = false
    var errorToThrow: AudioCaptureError?
    var startCallCount = 0

    func start() throws {
        startCallCount += 1
        if shouldThrowOnStart, let error = errorToThrow {
            throw error
        }
        isRunning = true
    }
    // ...
}
```

### Mock Design Principles

1. **Track call counts:** Record how many times methods were called
2. **Capture arguments:** Store passed arguments for assertions
3. **Configurable behavior:** Allow tests to set up success/failure scenarios
4. **Provide reset method:** Clean slate between tests
5. **Include test helpers:** Factory methods for common test data

### Common Mock Patterns

#### Call Tracking Pattern
```swift
var startCallCount = 0
var stopCallCount = 0

func start() throws {
    startCallCount += 1
    // ...
}
```

#### Configurable Error Pattern
```swift
var shouldThrowOnStart = false
var errorToThrow: AudioCaptureError?

func start() throws {
    if shouldThrowOnStart, let error = errorToThrow {
        throw error
    }
    // ...
}
```

#### Simulation Pattern
```swift
func simulateAudioLevels(system: Float, microphone: Float) {
    _audioLevels = AudioLevels(systemLevel: system, microphoneLevel: microphone)
}

func simulateTranscription(_ event: TranscriptionEvent) {
    transcriptionContinuation.yield(event)
}
```

#### Reset Pattern
```swift
func reset() {
    startCallCount = 0
    stopCallCount = 0
    isRunning = false
    shouldThrowOnStart = false
    errorToThrow = nil
}
```

---

## Running Tests

### Command Line

```bash
# Run all tests
xcodebuild test \
  -scheme HCDInterviewCoach \
  -destination 'platform=macOS'

# Run specific test class
xcodebuild test \
  -scheme HCDInterviewCoach \
  -destination 'platform=macOS' \
  -only-testing:HCDInterviewCoachTests/CoachingServiceTests

# Run with coverage
xcodebuild test \
  -scheme HCDInterviewCoach \
  -destination 'platform=macOS' \
  -enableCodeCoverage YES

# Run tests in parallel (faster)
xcodebuild test \
  -scheme HCDInterviewCoach \
  -destination 'platform=macOS' \
  -parallel-testing-enabled YES
```

### Xcode

- **Run all tests:** `Cmd+U`
- **Run current test:** Place cursor in test method, `Ctrl+Option+Cmd+U`
- **Run test file:** Right-click test file in navigator, select "Run Tests"
- **View coverage:** After running tests, `Product > Show Code Coverage`

### Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `HCD_TEST_API_KEY` | API key for integration tests requiring real API | None |
| `HCD_LOG_LEVEL` | Logging verbosity during tests | `info` |
| `HCD_SKIP_AUDIO_SETUP` | Skip audio setup wizard in tests | `false` |

---

## Writing Tests

### Test Structure (Arrange-Act-Assert)

```swift
func testConfidenceThreshold_rejectsLowConfidence() {
    // Arrange (Given)
    preferences.isCoachingEnabled = true
    preferences.hasCompletedOnboarding = true
    coachingService.startSession(testSession)

    // Act (When)
    let lowConfidenceEvent = createTestFunctionCallEvent(confidence: "0.80")
    coachingService.processFunctionCall(lowConfidenceEvent)

    // Assert (Then)
    XCTAssertNil(coachingService.currentPrompt)
    XCTAssertEqual(coachingService.promptCount, 0)
}
```

### Async Test Patterns

```swift
// Using async/await
func testSessionWithTranscription() async throws {
    // Setup
    try await sessionManager.configure(with: config)
    try await sessionManager.start()

    // Simulate events
    await mockAPIClient.simulateTranscription(event)

    // Wait for condition
    try await waitForCondition(timeout: 2.0) {
        !sessionManager.recentTranscriptions.isEmpty
    }

    // Assert
    XCTAssertFalse(sessionManager.recentTranscriptions.isEmpty)
}

// Using expectations
func testAutoDismiss_dismissesAfter8Seconds() async throws {
    preferences.customAutoDismissDuration = 0.5  // Short for testing

    coachingService.processFunctionCall(event)
    XCTAssertNotNil(coachingService.currentPrompt)

    try await Task.sleep(nanoseconds: 600_000_000)  // 0.6 seconds

    XCTAssertNil(coachingService.currentPrompt)
}
```

### Test Helper Extensions

```swift
extension CoachingPreferences {
    @MainActor
    func setupForTesting(
        enabled: Bool = false,
        onboardingComplete: Bool = false,
        level: CoachingLevel = .balanced
    ) {
        self.isCoachingEnabled = enabled
        self.hasCompletedOnboarding = onboardingComplete
        self.coachingLevel = level
    }
}
```

### Factory Methods for Test Data

```swift
private func createTestFunctionCallEvent(
    name: String = "suggest_follow_up",
    text: String = "Consider asking about this",
    confidence: String = "0.90",
    timestamp: TimeInterval = 0.0
) -> FunctionCallEvent {
    return FunctionCallEvent(
        name: name,
        arguments: [
            "text": text,
            "reason": "Test reason",
            "confidence": confidence
        ],
        timestamp: timestamp
    )
}
```

---

## Integration Tests

### IntegrationTestCase Base Class

All integration tests inherit from `IntegrationTestCase`, which provides:

- In-memory SwiftData container (isolated from production data)
- Pre-configured mocks for audio and API
- Test data factories
- Async helpers (wait for conditions, timeouts)
- Common assertions

```swift
@MainActor
final class SessionIntegrationTests: IntegrationTestCase {

    var sessionManager: SessionManager!

    override func setUp() async throws {
        try await super.setUp()
        sessionManager = createTestSessionManager()
    }

    func testFullSessionLifecycle() async throws {
        // Test uses inherited mocks and helpers
        assertSessionState(sessionManager, is: .idle)

        try await sessionManager.configure(with: createTestConfig())
        assertSessionState(sessionManager, is: .ready)

        try await sessionManager.start()
        assertSessionState(sessionManager, is: .running)
        assertAudioCaptureIsRunning()

        try await sessionManager.end()
        assertSessionState(sessionManager, is: .ended)
    }
}
```

### Integration Test Categories

| Category | Tests | Purpose |
|----------|-------|---------|
| Session Lifecycle | `SessionIntegrationTests` | Full session flow, state transitions |
| Audio + API | `AudioAPIIntegrationTests` | Audio capture with API connection |
| Coaching Flow | `CoachingIntegrationTests` | Coaching prompts during sessions |

### Key Integration Test Scenarios

1. **Full session lifecycle:** idle -> configure -> ready -> start -> running -> end -> ended
2. **Pause/resume cycles:** Multiple pause and resume operations
3. **Error recovery:** Connection loss and reconnection
4. **Transcription flow:** Events from API to UI
5. **Export flow:** Session ending and export generation

---

## Accessibility Testing

### Test Categories

```
Tests/UnitTests/Accessibility/
├── ColorIndependenceTests.swift    # Color-blind accessibility
├── FocusManagerTests.swift         # Focus management
├── KeyboardNavigationTests.swift   # Keyboard shortcuts
└── VoiceOverUtilitiesTests.swift   # Screen reader support
```

### What We Test

- **Keyboard navigation:** All features accessible via keyboard
- **Focus indicators:** Visible focus states
- **Color independence:** Information not conveyed by color alone
- **VoiceOver labels:** Meaningful labels for screen readers
- **Reduced motion:** Respect user's motion preferences

### Example Accessibility Test

```swift
func testKeyboardShortcuts_flagInsight() {
    // Verify Cmd+I triggers insight flagging
    let shortcut = KeyboardShortcut(.i, modifiers: .command)
    XCTAssertEqual(shortcut.action, .flagInsight)
}
```

---

## CI/CD Integration

### GitHub Actions Workflow

Tests run automatically on every push via `.github/workflows/ci.yml`:

```yaml
test:
  runs-on: macos-14
  steps:
    - uses: actions/checkout@v4

    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_15.2.app

    - name: Run Tests
      run: |
        xcodebuild test \
          -scheme HCDInterviewCoach \
          -destination 'platform=macOS' \
          -enableCodeCoverage YES

    - name: Upload Coverage
      uses: codecov/codecov-action@v3
```

### Pre-commit Checks

Before committing, developers should:

1. Run `swiftlint lint` (or `swiftlint lint --fix`)
2. Run unit tests: `Cmd+U`
3. Verify no failing tests

### Pull Request Requirements

- All tests must pass
- No decrease in coverage (for critical paths)
- SwiftLint passes with no errors

---

## Best Practices

### Do

- Write tests before or alongside implementation
- Use descriptive test names: `testConfidenceThreshold_rejectsLowConfidence`
- Test edge cases and error conditions
- Keep tests independent (no shared state between tests)
- Use `@MainActor` for tests involving UI or main-thread code
- Reset mocks in `tearDown`

### Don't

- Test private methods directly (test through public API)
- Use real network calls in unit tests
- Share state between tests
- Write flaky tests (tests that sometimes pass, sometimes fail)
- Skip error case testing
- Ignore async behavior (use proper async testing patterns)

---

## Adding New Tests

### For a New Service

1. Create `Tests/UnitTests/Services/{ServiceName}Tests.swift`
2. Create mock if service has protocol: `Tests/Mocks/Mock{Protocol}.swift`
3. Follow existing test patterns (see `CoachingServiceTests.swift`)
4. Target 80% coverage for services

### For a New ViewModel

1. Create `Tests/UnitTests/ViewModels/{ViewModel}Tests.swift`
2. Test all published properties and methods
3. Mock any injected dependencies
4. Target 70% coverage for ViewModels

### For a New Feature

1. Add unit tests for all services and ViewModels
2. Add integration test if feature involves multiple components
3. Add accessibility tests if feature has UI
4. Update this document if new patterns emerge

---

**Last Updated:** February 2026
