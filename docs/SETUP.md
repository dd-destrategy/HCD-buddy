# HCD Interview Coach — Local Development Setup

## Prerequisites

### Required
- **macOS 13.0+** (Ventura or later)
- **Xcode 15.0+** with Command Line Tools
- **Git** 2.30+

### Optional (for full functionality)
- **BlackHole 2ch** — Virtual audio driver for system audio capture
- **Homebrew** — For installing dependencies

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/dd-destrategy/HCD-buddy.git
cd HCD-buddy

# 2. Switch to the development branch
git checkout claude/setup-team-framework-dGR9J

# 3. Install SwiftLint (recommended)
brew install swiftlint

# 4. Install BlackHole for audio capture
brew install blackhole-2ch

# 5. Open in Xcode
open HCDInterviewCoach.xcodeproj
```

## Detailed Setup

### 1. System Requirements Check

```bash
# Verify macOS version (must be 13.0+)
sw_vers -productVersion

# Verify Xcode version (must be 15.0+)
xcodebuild -version

# Verify Git
git --version
```

### 2. Clone and Configure

```bash
# Clone repository
git clone https://github.com/dd-destrategy/HCD-buddy.git
cd HCD-buddy

# Checkout development branch
git checkout claude/setup-team-framework-dGR9J

# View project structure
ls -la
```

### 3. Install Dependencies

#### SwiftLint (Code Quality)
```bash
# Install via Homebrew
brew install swiftlint

# Verify installation
swiftlint version

# Run linter manually
swiftlint lint
```

#### BlackHole Virtual Audio Driver
```bash
# Install BlackHole 2ch
brew install blackhole-2ch

# After installation, configure Multi-Output Device:
# 1. Open "Audio MIDI Setup" (Applications > Utilities)
# 2. Click "+" in bottom left > "Create Multi-Output Device"
# 3. Check both your speakers/headphones AND "BlackHole 2ch"
# 4. Set Multi-Output Device as system output (System Settings > Sound)
```

### 4. Xcode Project Setup

```bash
# Open project in Xcode
open HCDInterviewCoach.xcodeproj
```

#### First-Time Setup in Xcode:
1. **Select Team**: Xcode > Preferences > Accounts > Add your Apple ID
2. **Set Signing**: Select project > Signing & Capabilities > Select your team
3. **Set Scheme**: Product > Scheme > HCDInterviewCoach
4. **Build**: ⌘+B
5. **Run**: ⌘+R

### 5. API Key Configuration

The app requires an OpenAI API key for transcription and coaching.

1. Get an API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. Launch the app
3. Go to Settings (⌘+,) > API
4. Enter your API key (stored securely in Keychain)

## Development Workflow

### Building

```bash
# Build from command line
xcodebuild -scheme HCDInterviewCoach -configuration Debug build

# Or in Xcode: ⌘+B
```

### Running Tests

```bash
# Run all tests from command line
xcodebuild test -scheme HCDInterviewCoach -destination 'platform=macOS'

# Or in Xcode: ⌘+U
```

### Linting

```bash
# Run SwiftLint
swiftlint lint

# Auto-fix violations
swiftlint lint --fix
```

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Make changes, then commit
git add -A
git commit -m "Description of changes"

# Push to remote
git push -u origin feature/your-feature-name

# Create PR via GitHub CLI (optional)
gh pr create --title "Your PR Title" --body "Description"
```

## Project Structure

```
HCD-buddy/
├── .github/workflows/      # CI/CD pipelines
├── .swiftlint.yml          # Linting rules
├── config/                 # Entitlements, signing configs
├── Core/
│   ├── Protocols/          # AudioCapturing protocol
│   └── Services/Audio/     # Audio capture implementation
├── Sources/
│   ├── App/                # App entry point
│   ├── Core/API/           # OpenAI Realtime client
│   └── Features/Settings/  # Settings views
├── HCDInterviewCoach/
│   ├── App/                # Main app file
│   ├── Core/               # Models, Services, Utilities
│   ├── DesignSystem/       # Colors, Typography, A11y
│   └── Features/           # Feature modules
│       ├── AudioSetup/     # Setup wizard
│       ├── Coaching/       # Coaching engine
│       ├── Export/         # Export functionality
│       ├── Insights/       # Insight flagging
│       ├── PostSession/    # Summary view
│       ├── Session/        # Session management
│       ├── Topics/         # Topic awareness
│       └── Transcript/     # Transcript display
├── Tests/
│   ├── Mocks/              # Mock services for testing
│   └── UnitTests/          # Unit test suites
└── docs/                   # Documentation
```

## Key Files

| File | Purpose |
|------|---------|
| `HCDInterviewCoach/App/HCDInterviewCoachApp.swift` | App entry point |
| `HCDInterviewCoach/Features/Session/Services/SessionManager.swift` | Session orchestration |
| `HCDInterviewCoach/Features/Coaching/CoachingService.swift` | Coaching logic |
| `Core/Services/Audio/AudioCaptureEngine.swift` | Audio capture |
| `Sources/Core/API/RealtimeAPIClient.swift` | OpenAI WebSocket client |
| `config/HCDInterviewCoach.entitlements` | App capabilities |

## Troubleshooting

This section covers common issues and their solutions. For additional help, see `docs/USER_FAQ.md`.

---

### Build Errors

**"No such module 'SwiftUI'"**
- Ensure Xcode 15+ is installed
- Select correct SDK: Xcode > Preferences > Locations > Command Line Tools

**Signing Issues**
- Add your Apple ID in Xcode > Preferences > Accounts
- Select your team in project settings

**"Swift 6 Concurrency Errors"**
- Ensure `@MainActor` is applied to ObservableObject classes
- Check that async code uses proper task isolation
- Review `Sendable` conformance for types crossing actor boundaries

**"SPM Package Resolution Failed"**
```bash
# Clear package cache
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf .build

# Re-resolve packages in Xcode
File > Packages > Reset Package Caches
```

---

### Audio Issues

**"BlackHole not detected"**

1. **Verify installation:**
   ```bash
   brew list blackhole-2ch
   ```

2. **Reinstall if needed:**
   ```bash
   brew reinstall blackhole-2ch
   ```

3. **Restart CoreAudio:**
   ```bash
   sudo killall coreaudiod
   ```

4. **Check Audio MIDI Setup:**
   - Open Applications > Utilities > Audio MIDI Setup
   - BlackHole 2ch should appear in the device list
   - If not visible, restart your Mac

**"Multi-Output Device not found"**

1. Open Audio MIDI Setup (Applications > Utilities)
2. Delete any existing Multi-Output Device
3. Click **+** > Create Multi-Output Device
4. Check both your speakers/headphones AND BlackHole 2ch
5. Ensure "Drift Correction" is enabled for BlackHole

**"No audio levels showing"**

1. **Check system output:**
   - System Settings > Sound > Output
   - Must be set to your Multi-Output Device

2. **Verify meeting audio:**
   - Ensure video conferencing app is playing audio
   - Check that remote participants are not muted

3. **Test BlackHole capture:**
   - Play audio from any app (e.g., YouTube in browser)
   - The app's audio meter should show activity

**"Audio is distorted or choppy"**

1. **Check sample rate consistency:**
   - Open Audio MIDI Setup
   - Ensure all devices in Multi-Output use the same sample rate (44100 Hz or 48000 Hz)

2. **Reduce system load:**
   - Close unnecessary applications
   - Check Activity Monitor for high CPU usage

3. **Check buffer size:**
   - In some cases, increasing audio buffer size helps
   - This is a system-level setting in Audio MIDI Setup

**"Microphone permission denied"**

1. Go to System Settings > Privacy & Security > Microphone
2. Find HCD Interview Coach in the list
3. Toggle the switch to enable access
4. Restart the app

---

### API Connection Problems

**"Failed to connect to OpenAI API"**

1. **Verify API key:**
   - Settings > API > Check that key is entered
   - Ensure no extra spaces or characters

2. **Check API key validity:**
   - Go to [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
   - Verify the key is active and not expired

3. **Check network connection:**
   - Ensure internet access is available
   - Try accessing `api.openai.com` in a browser

4. **Check firewall/VPN:**
   - Disable VPN temporarily to test
   - Check that corporate firewalls aren't blocking WebSocket connections

**"Connection dropped during session"**

1. **Check connection quality indicator** in the app
2. **Network stability:**
   - Prefer wired connection over Wi-Fi
   - Check for network congestion

3. **Automatic recovery:**
   - The app will attempt to reconnect automatically
   - Session data is preserved during brief disconnections

**"Rate limit exceeded"**

1. Check your OpenAI account usage limits
2. Consider upgrading your OpenAI plan
3. Reduce session frequency or duration temporarily

**"Invalid API key format"**

- OpenAI keys start with `sk-`
- Ensure you copied the complete key
- Keys are case-sensitive

---

### Permission Errors

**"App cannot access microphone"**

```bash
# Check current permissions
tccutil reset Microphone com.hcd.interviewcoach
```

Then re-grant permission when the app requests it.

**"Keychain access denied"**

1. Open Keychain Access app
2. Search for "HCD Interview Coach"
3. Delete any existing entries
4. Re-enter API key in app settings

**"Sandbox violation"**

- Ensure you're running the signed/notarized build
- Debug builds have different sandbox permissions
- Check Console.app for specific sandbox errors

---

### Test Failures

**"Mock not conforming to protocol"**
- Ensure mock methods match protocol signatures exactly
- Check `Tests/Mocks/` for correct implementations
- Verify `@MainActor` annotations match

**"Async test timeout"**
- Increase timeout duration in test
- Check for deadlocks in async code
- Ensure mock continuations are properly yielded

**"SwiftData container error in tests"**
- Use in-memory configuration for test containers
- Ensure schema includes all required models
- Check `IntegrationTestCase.swift` for proper setup

**"Tests pass locally but fail in CI"**
- Check for timing-dependent tests
- Ensure no hardcoded file paths
- Verify all dependencies are in version control

---

### Common Runtime Issues

**"App crashes on launch"**

1. **Check macOS version:** Requires 13.0 (Ventura) or later
2. **Reset preferences:**
   ```bash
   defaults delete com.hcd.interviewcoach
   ```
3. **Check crash logs:**
   - Open Console.app
   - Search for "HCDInterviewCoach"
   - Look for crash reports

**"Session won't start"**

1. API key must be configured (Settings > API)
2. Audio setup must be complete (run setup wizard)
3. No other session currently active
4. Network connection available

**"Export fails"**

1. Check write permissions for destination folder
2. Ensure session has data (not empty)
3. Try a different export format (Markdown vs JSON)

**"Coaching prompts never appear"**

1. Verify coaching is enabled (Settings > Coaching)
2. Check coaching level (Minimal = very few prompts)
3. Prompts require 85%+ confidence
4. Maximum 3 prompts per session
5. 2-minute cooldown between prompts

---

### Getting Debug Information

**Enable verbose logging:**
```bash
# Set environment variable before launching
export HCD_LOG_LEVEL=debug
open /Applications/HCDInterviewCoach.app
```

**View logs:**
```bash
# Stream live logs
log stream --predicate 'subsystem == "com.hcd.interviewcoach"'

# View recent logs
log show --predicate 'subsystem == "com.hcd.interviewcoach"' --last 1h
```

**Generate diagnostic report:**
1. In app: Help > Generate Diagnostic Report
2. This creates a ZIP file with:
   - App version and system info
   - Recent log entries
   - Audio device configuration
   - (No sensitive data like API keys)

## Environment Variables

For CI/CD and testing, these environment variables may be set:

| Variable | Purpose | Default |
|----------|---------|---------|
| `HCD_TEST_API_KEY` | API key for integration tests | None |
| `HCD_LOG_LEVEL` | Logging verbosity | `info` |
| `HCD_SKIP_AUDIO_SETUP` | Skip audio setup in tests | `false` |

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘+R | Start/Stop recording |
| ⌘+P | Pause/Resume |
| ⌘+I | Flag insight |
| ⌘+T | Toggle speaker |
| ⌘+F | Search transcript |
| ⌘+S | Export session |
| ⌘+, | Open settings |
| ⌘+M | Toggle coaching |

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/dd-destrategy/HCD-buddy/issues)
- **Documentation**: See `/docs` folder
- **Architecture**: See `CODEBASE_REVIEW.md`
- **Decisions**: See `APPROVED_DECISIONS.md`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Run `swiftlint lint` and fix violations
5. Run tests with `⌘+U`
6. Submit PR with description

---

**Last Updated**: February 2026
**Branch**: `claude/setup-team-framework-dGR9J`
