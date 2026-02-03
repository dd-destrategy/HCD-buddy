# HCD Interview Coach

**Real-time AI support for UX research interviews**

A macOS application that captures system audio, transcribes conversations in real-time, and provides contextual coaching prompts to help researchers conduct better human-centered design interviews.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Features

### Core Functionality
- **Real-time Transcription** — Live speech-to-text with speaker identification
- **Silence-First Coaching** — AI prompts that respect natural conversation flow
- **Topic Awareness** — Track coverage of interview guide topics
- **Insight Flagging** — Mark key moments manually (⌘+I) or automatically
- **Session Export** — Export to Markdown or JSON for analysis
- **Built-in Interview Templates** — Discovery, Usability, Stakeholder, and Contextual templates
- **Liquid Glass UI** — Modern glassmorphism effects for a polished visual experience

### Design Philosophy
> "The best coaching is invisible until needed."

The app stays quiet by default, only surfacing prompts when:
- Confidence exceeds 85%
- 2+ minutes since last prompt
- 5+ seconds of silence after speech
- Fewer than 3 prompts shown this session

### Accessibility
- Full keyboard navigation
- VoiceOver support
- Color-independent indicators
- Reduced motion support
- WCAG 2.1 AA compliance

---

## Screenshots

```
┌─────────────────────────────────────────────────────────────┐
│  HCD Interview Coach                              ⏺ 00:23:45 │
├──────────────────────┬──────────────────────────────────────┤
│                      │                                      │
│  📋 Topics           │  Transcript                          │
│  ───────────         │  ───────────                         │
│  ● Onboarding   ✓    │  [00:21:32] Participant:             │
│  ◐ Pain Points       │  "The biggest challenge is..."       │
│  ○ Workflows         │                                      │
│  ○ Ideal State       │  [00:22:15] Interviewer:             │
│                      │  "Can you tell me more about that?"  │
│  💡 Insights (3)     │                                      │
│  ───────────         │  [00:23:40] Participant:             │
│  • Onboarding gap    │  "Well, when I first started..."     │
│  • Manual workaround │                                      │
│  • Feature request   │                                      │
│                      │                                      │
├──────────────────────┴──────────────────────────────────────┤
│  ⌘+R Start  ⌘+P Pause  ⌘+I Insight  ⌘+M Coaching  ⌘+S Export │
└─────────────────────────────────────────────────────────────┘
```

---

## Requirements

- **macOS 13.0+** (Ventura or later)
- **Xcode 15.0+** (for development)
- **BlackHole 2ch** (virtual audio driver)
- **OpenAI API Key** (for transcription and coaching)

---

## Installation

### Quick Start

```bash
# Clone the repository
git clone https://github.com/dd-destrategy/HCD-buddy.git
cd HCD-buddy

# Install dependencies
brew install swiftlint blackhole-2ch

# Open in Xcode
open HCDInterviewCoach.xcodeproj

# Build and run (⌘+R)
```

### Audio Setup

The app captures system audio via BlackHole virtual driver:

1. Install BlackHole: `brew install blackhole-2ch`
2. Open **Audio MIDI Setup** (Applications → Utilities)
3. Click **+** → **Create Multi-Output Device**
4. Check your speakers/headphones AND **BlackHole 2ch**
5. Set Multi-Output as system output in **System Settings → Sound**

The app includes a setup wizard that guides you through this process.

### API Configuration

1. Get an API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. Launch the app
3. Go to **Settings** (⌘+,) → **API**
4. Enter your API key (stored securely in Keychain)

---

## Usage

### Starting a Session

1. **Select Mode**: Transcription Only or With Coaching
2. **Choose Template**: Select interview guide (optional)
3. **Configure Audio**: Verify Multi-Output device is active
4. **Start Recording**: Press ⌘+R or click Start

### During the Interview

| Action | Shortcut |
|--------|----------|
| Start/Stop | ⌘+R |
| Pause/Resume | ⌘+P |
| Flag Insight | ⌘+I |
| Toggle Speaker | ⌘+T |
| Search Transcript | ⌘+F |
| Toggle Coaching | ⌘+M |
| Export | ⌘+S |
| Settings | ⌘+, |

### After the Session

- Review AI-generated summary
- Edit flagged insights
- Add researcher notes
- Export to Markdown or JSON

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│               SwiftUI Views + ViewModels                     │
├─────────────────────────────────────────────────────────────┤
│                     BUSINESS LAYER                           │
│    SessionManager │ CoachingService │ ExportService          │
├─────────────────────────────────────────────────────────────┤
│                       DATA LAYER                             │
│   SwiftData │ KeychainService │ RealtimeAPIClient            │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Purpose |
|-----------|---------|
| `SessionManager` | Orchestrates recording, transcription, and state |
| `CoachingService` | Implements silence-first coaching logic |
| `RealtimeAPIClient` | WebSocket connection to OpenAI |
| `AudioCaptureEngine` | System audio capture via BlackHole |

---

## Development

### Building

```bash
# Build from command line
xcodebuild -scheme HCDInterviewCoach -configuration Debug build

# Or in Xcode: ⌘+B
```

### Testing

```bash
# Run all tests
xcodebuild test -scheme HCDInterviewCoach -destination 'platform=macOS'

# Or in Xcode: ⌘+U
```

### Linting

```bash
# Check code style
swiftlint lint

# Auto-fix violations
swiftlint lint --fix
```

### Project Structure

```
HCD-buddy/
├── HCDInterviewCoach/
│   ├── Features/          # Feature modules
│   │   ├── AudioSetup/    # Setup wizard
│   │   ├── Coaching/      # Coaching engine
│   │   ├── Export/        # Export functionality
│   │   ├── Insights/      # Insight flagging
│   │   ├── PostSession/   # Summary view
│   │   ├── Session/       # Session management
│   │   ├── Topics/        # Topic tracking
│   │   └── Transcript/    # Transcript display
│   ├── Core/              # Models, services, utilities
│   └── DesignSystem/      # Design tokens and visual effects
│       ├── Typography.swift
│       ├── Spacing.swift
│       ├── CornerRadius.swift
│       ├── Shadows.swift
│       └── LiquidGlass.swift
├── Tests/                 # Unit tests and mocks
├── docs/                  # Documentation
└── .github/workflows/     # CI/CD pipelines
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [SETUP.md](docs/SETUP.md) | Detailed local development setup |
| [CLAUDE.md](CLAUDE.md) | Project context for AI assistants |
| [CODEBASE_REVIEW.md](CODEBASE_REVIEW.md) | Architecture analysis |
| [APPROVED_DECISIONS.md](APPROVED_DECISIONS.md) | Key product decisions |
| [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md) | Feature backlog |

---

## Tech Stack

| Category | Technology |
|----------|------------|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Persistence | SwiftData |
| Audio | AVAudioEngine |
| AI/ML | OpenAI Realtime API |
| Security | macOS Keychain |
| CI/CD | GitHub Actions |
| Updates | Sparkle |
| Design System | Typography, Spacing, CornerRadius, Shadows, LiquidGlass |

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make changes with tests
4. Run linter (`swiftlint lint`)
5. Run tests (`⌘+U`)
6. Commit changes (`git commit -m 'Add amazing feature'`)
7. Push to branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Code Style

- Follow SwiftLint rules (`.swiftlint.yml`)
- Add `@MainActor` to `ObservableObject` classes
- Use `AppLogger` instead of `print()`
- Include accessibility labels on UI elements
- Write tests for new functionality

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- [OpenAI](https://openai.com) — Realtime API for transcription and AI
- [BlackHole](https://existential.audio/blackhole/) — Virtual audio driver
- [SwiftLint](https://github.com/realm/SwiftLint) — Code quality
- [Sparkle](https://sparkle-project.org) — Auto-updates

---

**Built with ❤️ for UX researchers**
