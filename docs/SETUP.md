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

### Build Errors

**"No such module 'SwiftUI'"**
- Ensure Xcode 15+ is installed
- Select correct SDK: Xcode > Preferences > Locations > Command Line Tools

**Signing Issues**
- Add your Apple ID in Xcode > Preferences > Accounts
- Select your team in project settings

### Audio Issues

**"BlackHole not detected"**
```bash
# Reinstall BlackHole
brew reinstall blackhole-2ch

# Restart CoreAudio
sudo killall coreaudiod
```

**"Multi-Output Device not found"**
1. Open Audio MIDI Setup
2. Delete existing Multi-Output Device
3. Create new one with speakers + BlackHole 2ch

### Test Failures

**"Mock not conforming to protocol"**
- Ensure mock methods match protocol signatures exactly
- Check `Tests/Mocks/` for correct implementations

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
