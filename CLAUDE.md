# HCD Interview Coach

## Project Overview

HCD Interview Coach is a macOS application that provides real-time AI-powered support during UX research interviews. It captures system audio, transcribes conversations, and offers contextual coaching prompts to help researchers conduct better interviews.

**Key Philosophy**: "Silence-first" — The AI assistant stays quiet unless genuinely needed, respecting the natural flow of human conversation.

## Tech Stack

| Component | Technology |
|-----------|------------|
| Platform | macOS 13+ (Ventura) |
| Language | Swift 5.9+ |
| UI | SwiftUI |
| Persistence | SwiftData |
| Audio | AVAudioEngine + BlackHole virtual driver |
| AI | OpenAI Realtime API (WebSocket) |
| Security | macOS Keychain for API keys |

## Architecture

Three-layer architecture with MVVM in the presentation layer:

```
Presentation (SwiftUI Views + ViewModels)
    ↓
Business (Services: SessionManager, CoachingService, ExportService)
    ↓
Data (SwiftData Models + KeychainService + RealtimeAPIClient)
```

### Key Services

- **SessionManager** (`HCDInterviewCoach/Features/Session/Services/SessionManager.swift`) — Orchestrates session lifecycle, coordinates audio capture and API connections
- **CoachingService** (`HCDInterviewCoach/Features/Coaching/CoachingService.swift`) — Implements silence-first coaching logic
- **RealtimeAPIClient** (`Sources/Core/API/RealtimeAPIClient.swift`) — WebSocket connection to OpenAI
- **AudioCaptureEngine** (`Core/Services/Audio/AudioCaptureEngine.swift`) — System audio capture via BlackHole

### Core Models

All SwiftData models are in `HCDInterviewCoach/Core/Models/`:
- `Session` — Main entity with relationships to utterances, insights, topics
- `Utterance` — Individual speech segments with timestamps and speaker
- `Insight` — Flagged moments (manual via ⌘+I or auto-detected)
- `TopicStatus` — Topic coverage tracking
- `CoachingEvent` — History of coaching prompts shown

## Key Design Decisions

### Coaching Behavior
- **DEFAULT OFF** for first session — user must explicitly enable
- 85% minimum confidence before showing prompt
- 2-minute cooldown between prompts
- 5-second delay after any speech before showing
- Maximum 3 prompts per session
- Auto-dismiss after 8 seconds

### Audio Capture
- Requires BlackHole 2ch virtual audio driver
- User creates Multi-Output Device (speakers + BlackHole)
- App captures from BlackHole input
- 6-screen setup wizard guides configuration

### Security
- API keys stored in macOS Keychain (never UserDefaults)
- App Sandbox enabled with specific entitlements
- Local-only data storage (no cloud sync)

## Project Structure

```
HCDInterviewCoach/
├── Features/           # Feature modules (MVVM)
│   ├── AudioSetup/     # 6-screen setup wizard
│   ├── Coaching/       # Coaching engine + UI
│   ├── Export/         # Markdown/JSON export
│   ├── Insights/       # Insight flagging
│   ├── PostSession/    # Summary view
│   ├── Session/        # Session management
│   ├── Topics/         # Topic awareness
│   └── Transcript/     # Real-time transcript
├── Core/
│   ├── Models/         # SwiftData models
│   ├── Services/       # DataManager, Keychain, Templates
│   ├── Accessibility/  # Keyboard nav, VoiceOver utilities
│   └── Utilities/      # Logger, Error types
└── DesignSystem/       # Colors, typography, a11y helpers
```

## Coding Conventions

### Swift Style
- SwiftLint enforced (see `.swiftlint.yml`)
- Protocol-oriented design for testability
- `@MainActor` on all `ObservableObject` classes
- Async/await with `AsyncStream` for real-time data
- No force unwraps (`!`) in production code

### Accessibility
- WCAG 2.1 AA compliance target
- All interactive elements need `.accessibilityLabel` and `.accessibilityHint`
- Keyboard navigation via `KeyboardNavigationModifiers`
- Color-independent indicators (shapes + colors)
- Respect `accessibilityReduceMotion`

### Error Handling
- Use `HCDError` hierarchy for domain errors
- All errors must have `LocalizedError` conformance
- Log errors via `AppLogger`, not `print()`
- Implement graceful degradation where possible

### Testing
- 70% coverage target
- Mocks in `Tests/Mocks/` for all protocols
- Use dependency injection via factories
- Test file naming: `{ServiceName}Tests.swift`

## Common Tasks

### Adding a New Feature
1. Create folder in `HCDInterviewCoach/Features/{FeatureName}/`
2. Add Views, ViewModels, and Services subfolders
3. Create protocol for service (for testability)
4. Add mock in `Tests/Mocks/`
5. Add tests in `Tests/UnitTests/`

### Adding a New Model
1. Create in `HCDInterviewCoach/Core/Models/`
2. Add `@Model` macro for SwiftData
3. Define relationships with other models
4. Register in `DataManager` schema

### Modifying Coaching Behavior
- Thresholds in `CoachingThresholds.swift`
- Logic in `CoachingService.swift`
- Update tests in `CoachingServiceTests.swift`

## Important Files

| File | Purpose |
|------|---------|
| `SessionManager.swift` | Session state machine and orchestration |
| `CoachingService.swift` | Silence-first coaching logic |
| `RealtimeAPIClient.swift` | OpenAI WebSocket connection |
| `AudioCaptureEngine.swift` | System audio capture |
| `KeyboardNavigationModifiers.swift` | Keyboard accessibility |
| `HCDError.swift` | Error type hierarchy |
| `AppLogger.swift` | Logging utility |

## State Machine

Session states flow:
```
idle → configuring → ready → running ⇄ paused → ending → ended
                         ↘ error (recoverable) ↗
                         ↘ failed (unrecoverable) → ended
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘+R | Start/Stop session |
| ⌘+P | Pause/Resume |
| ⌘+I | Flag insight |
| ⌘+T | Toggle speaker |
| ⌘+F | Search transcript |
| ⌘+S | Export session |
| ⌘+, | Settings |
| ⌘+M | Toggle coaching |

## Dependencies

- **SwiftOpenAI** — OpenAI API client (SPM)
- **Sparkle** — Auto-updates (SPM)
- **BlackHole** — Virtual audio driver (user installs via Homebrew)

## CI/CD

GitHub Actions workflows in `.github/workflows/`:
- `ci.yml` — Lint → Build → Test on every push
- `release.yml` — Notarization and Sparkle updates

## Documentation

- `docs/SETUP.md` — Local development setup
- `CODEBASE_REVIEW.md` — Architecture analysis
- `APPROVED_DECISIONS.md` — Key product decisions
- `PRODUCT_BACKLOG.md` — Feature backlog with epics
- `DEV_JOURNAL.md` — Auto-generated development activity log

## Development Journal

A hook at `.claude/hooks/journal-action.sh` automatically tracks key development actions:
- File modifications (Write/Edit)
- Build commands (xcodebuild, swift, swiftlint)
- Git commits and pushes
- Agent tasks

Check `DEV_JOURNAL.md` for recent activity and context.

## Branch

Main development: `claude/setup-team-framework-dGR9J`
