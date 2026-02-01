# HCD Interview Coach — Product Backlog

**Version:** 1.0
**Date:** February 1, 2026
**Status:** Ready for Agent Review

---

## Backlog Overview

### Epic Summary

| Epic | Name | Stories | Priority | Parallel Track |
|------|------|---------|----------|----------------|
| E0 | Foundation & Setup | 8 | P0 | Track A |
| E1 | Audio Capture System | 7 | P0 | Track B |
| E2 | Audio Setup Wizard | 6 | P0 | Track C (needs E1) |
| E3 | OpenAI Integration | 8 | P0 | Track B |
| E4 | Session Management | 7 | P0 | Track D (needs E1, E3) |
| E5 | Transcript Display | 6 | P0 | Track E (needs E4) |
| E6 | Coaching Engine | 8 | P0 | Track F (needs E4) |
| E7 | Topic Awareness | 5 | P0 | Track F (needs E4) |
| E8 | Insight Flagging | 5 | P0 | Track E (needs E5) |
| E9 | Export System | 5 | P0 | Track G (needs E4) |
| E10 | Post-Session Summary | 5 | P1 | Track G (needs E4, E6) |
| E11 | Settings & Preferences | 5 | P1 | Track H |
| E12 | Consent & Templates | 4 | P0 | Track H |
| E13 | Accessibility | 6 | P0 | Track I (cross-cutting) |
| E14 | Testing & Quality | 6 | P0 | Track J (cross-cutting) |
| E15 | Distribution & CI/CD | 5 | P0 | Track A |

**Total Stories:** 96
**Total Parallel Tracks:** 10

---

## Dependency Graph

```
Track A: Foundation ──────────────────────────────────────────────────►
         E0, E15

Track B: Audio + API ─────────────────────────────────────────────────►
         E1 ──► E3

Track C: Setup Wizard ────────────────────────────────────────────────►
              E1 ──► E2

Track D: Session Core ────────────────────────────────────────────────►
                   E1 + E3 ──► E4

Track E: Transcript ──────────────────────────────────────────────────►
                            E4 ──► E5 ──► E8

Track F: Coaching + Topics ───────────────────────────────────────────►
                            E4 ──► E6, E7

Track G: Export + Summary ────────────────────────────────────────────►
                            E4 ──► E9, E10

Track H: Settings ────────────────────────────────────────────────────►
         E11, E12

Track I: Accessibility ───────────────────────────────────────────────►
         E13 (cross-cutting, continuous)

Track J: Testing ─────────────────────────────────────────────────────►
         E14 (cross-cutting, continuous)
```

---

# EPIC E0: Foundation & Setup

**Owner:** Engineer, DevOps
**Track:** A (No dependencies)
**Priority:** P0 — Must complete first

## Stories

### E0-S1: Create Xcode Project Structure
**As a** developer
**I want** a well-organized Xcode project
**So that** the codebase is maintainable from day one

**Acceptance Criteria:**
- [ ] Xcode project created with app target
- [ ] Folder structure matches approved architecture
- [ ] App builds and runs (empty shell)
- [ ] Bundle identifier set correctly
- [ ] Deployment target: macOS 13.0+
- [ ] Swift version: 5.9+

**Tasks:**
- Create Xcode project
- Set up folder structure (App/, Features/, Core/, DesignSystem/, Resources/, Tests/)
- Configure build settings
- Add .gitignore for Xcode

**Estimate:** 2 hours

---

### E0-S2: Configure SwiftLint
**As a** developer
**I want** automated code style enforcement
**So that** code quality is consistent

**Acceptance Criteria:**
- [ ] SwiftLint installed via Homebrew or SPM
- [ ] .swiftlint.yml configured with team rules
- [ ] Build phase runs SwiftLint
- [ ] Warnings appear in Xcode for violations

**Tasks:**
- Add SwiftLint configuration
- Configure rules (line length, naming, etc.)
- Add build phase script
- Document rule decisions

**Estimate:** 1 hour

---

### E0-S3: Set Up SwiftData Container
**As a** developer
**I want** a configured persistence layer
**So that** session data persists correctly

**Acceptance Criteria:**
- [ ] ModelContainer configured with custom location
- [ ] All model types registered
- [ ] Container injected via environment
- [ ] Data persists across app restarts
- [ ] Unit tests verify persistence

**Tasks:**
- Create DataManager class
- Configure ModelContainer with custom URL
- Register all model types
- Create container injection
- Write persistence tests

**Estimate:** 4 hours

---

### E0-S4: Create SwiftData Models
**As a** developer
**I want** all data models defined
**So that** I can persist sessions and related data

**Acceptance Criteria:**
- [ ] Session model with all properties
- [ ] Utterance model with relationships
- [ ] Insight model with relationships
- [ ] TopicStatus model
- [ ] CoachingEvent model
- [ ] All enums defined (SessionMode, Speaker, etc.)
- [ ] Unit tests for model creation

**Tasks:**
- Create Session.swift
- Create Utterance.swift
- Create Insight.swift
- Create TopicStatus.swift
- Create CoachingEvent.swift
- Create supporting enums
- Write model tests

**Estimate:** 4 hours

---

### E0-S5: Create KeychainService
**As a** developer
**I want** secure API key storage
**So that** user credentials are protected

**Acceptance Criteria:**
- [ ] KeychainService protocol defined
- [ ] Implementation using Security framework
- [ ] Save, retrieve, delete operations
- [ ] Error handling for Keychain failures
- [ ] Unit tests with mock Keychain

**Tasks:**
- Define KeychainService protocol
- Implement KeychainServiceImpl
- Add error types
- Write unit tests
- Document usage

**Estimate:** 3 hours

---

### E0-S6: Create Design System Foundation
**As a** developer
**I want** design tokens in code
**So that** UI is consistent

**Acceptance Criteria:**
- [ ] Colors.swift with semantic colors
- [ ] Typography.swift with font styles
- [ ] Spacing.swift with spacing scale
- [ ] All tokens support light/dark mode
- [ ] Preview catalog for tokens

**Tasks:**
- Create DesignSystem/ folder
- Implement Colors.swift
- Implement Typography.swift
- Implement Spacing.swift
- Create preview views

**Estimate:** 3 hours

---

### E0-S7: Add SwiftOpenAI Package
**As a** developer
**I want** the OpenAI SDK integrated
**So that** I can build API features

**Acceptance Criteria:**
- [ ] SwiftOpenAI added to Package.swift
- [ ] Package resolves and builds
- [ ] Import works in code files
- [ ] Basic connection test passes

**Tasks:**
- Add package dependency
- Verify build
- Create test file to verify import
- Document version used

**Estimate:** 1 hour

---

### E0-S8: Create App Entry Point
**As a** developer
**I want** the app shell working
**So that** features can be added incrementally

**Acceptance Criteria:**
- [ ] App struct configured
- [ ] Main window displays
- [ ] Environment objects injected
- [ ] Menu bar configured
- [ ] App icon placeholder added

**Tasks:**
- Configure HCDInterviewCoachApp.swift
- Set up WindowGroup
- Inject ModelContainer
- Configure app menu
- Add placeholder icon

**Estimate:** 2 hours

---

# EPIC E1: Audio Capture System

**Owner:** Engineer
**Track:** B (No dependencies)
**Priority:** P0

## Stories

### E1-S1: Define Audio Protocols
**As a** developer
**I want** clear audio interfaces
**So that** audio components are testable

**Acceptance Criteria:**
- [ ] AudioCapturing protocol defined
- [ ] AudioChunk data type defined
- [ ] AudioLevels data type defined
- [ ] ConnectionQuality enum defined
- [ ] Protocols support async/await

**Tasks:**
- Create AudioCapturing protocol
- Define AudioChunk struct
- Define AudioLevels struct
- Create mock implementation for testing

**Estimate:** 2 hours

---

### E1-S2: Implement BlackHole Detection
**As a** user
**I want** the app to detect if BlackHole is installed
**So that** I know if setup is needed

**Acceptance Criteria:**
- [ ] Detects BlackHole 2ch device
- [ ] Detects BlackHole 16ch device
- [ ] Returns installation status
- [ ] Works on Apple Silicon and Intel
- [ ] Unit tests with mocked audio devices

**Tasks:**
- Query CoreAudio for devices
- Check for BlackHole device names
- Return detection result
- Handle edge cases
- Write tests

**Estimate:** 4 hours

---

### E1-S3: Implement Multi-Output Device Detection
**As a** user
**I want** the app to detect if Multi-Output Device is configured
**So that** I know if audio routing is ready

**Acceptance Criteria:**
- [ ] Detects existing Multi-Output devices
- [ ] Verifies BlackHole is included in Multi-Output
- [ ] Verifies speakers are included
- [ ] Returns configuration status
- [ ] Handles multiple Multi-Output devices

**Tasks:**
- Query aggregate devices
- Check sub-device composition
- Verify correct configuration
- Return detailed status
- Write tests

**Estimate:** 4 hours

---

### E1-S4: Implement Audio Capture Engine
**As a** developer
**I want** to capture system audio and microphone
**So that** I can stream to the API

**Acceptance Criteria:**
- [ ] Captures from Multi-Output Device
- [ ] Captures from microphone
- [ ] Mixes to mono channel
- [ ] Outputs 24kHz 16-bit PCM
- [ ] Provides async stream of audio chunks
- [ ] Handles device changes gracefully

**Tasks:**
- Set up AVAudioEngine
- Configure input nodes
- Implement format conversion
- Create audio chunk streaming
- Handle interruptions
- Write integration tests

**Estimate:** 8 hours

---

### E1-S5: Implement Audio Level Metering
**As a** user
**I want** to see audio levels in real-time
**So that** I know audio is being captured

**Acceptance Criteria:**
- [ ] System audio level (0.0 - 1.0)
- [ ] Microphone level (0.0 - 1.0)
- [ ] Updates at 10Hz minimum
- [ ] Accurate peak detection
- [ ] Low CPU overhead

**Tasks:**
- Tap audio nodes for levels
- Calculate RMS and peak
- Publish levels via Combine
- Optimize for performance
- Write tests

**Estimate:** 4 hours

---

### E1-S6: Implement Audio Capture Service
**As a** developer
**I want** a high-level audio service
**So that** session management is simple

**Acceptance Criteria:**
- [ ] Implements AudioCapturing protocol
- [ ] Start/stop/pause/resume operations
- [ ] Exposes audioStream as AsyncStream
- [ ] Exposes audioLevels for UI
- [ ] Handles errors gracefully
- [ ] 80%+ test coverage

**Tasks:**
- Create AudioCaptureService class
- Implement protocol methods
- Wire up capture engine
- Add error handling
- Write comprehensive tests

**Estimate:** 6 hours

---

### E1-S7: Create Audio Capture Tests
**As a** developer
**I want** thorough audio tests
**So that** audio capture is reliable

**Acceptance Criteria:**
- [ ] Unit tests for detection logic
- [ ] Unit tests for format conversion
- [ ] Integration test with real audio (manual)
- [ ] Mock audio source for automated tests
- [ ] 80%+ coverage on audio module

**Tasks:**
- Write detection tests
- Write conversion tests
- Create mock audio source
- Write service tests
- Document manual test procedure

**Estimate:** 4 hours

---

# EPIC E2: Audio Setup Wizard

**Owner:** Engineer, Frontend
**Track:** C (Depends on E1)
**Priority:** P0

## Stories

### E2-S1: Create Wizard Container View
**As a** user
**I want** a step-by-step setup flow
**So that** audio setup is manageable

**Acceptance Criteria:**
- [ ] Multi-step wizard UI
- [ ] Progress indicator (step X of Y)
- [ ] Back/Next navigation
- [ ] Can be dismissed
- [ ] Remembers progress if dismissed

**Tasks:**
- Create AudioSetupWizardView
- Implement step navigation
- Add progress indicator
- Handle dismissal
- Write UI tests

**Estimate:** 4 hours

---

### E2-S2: Implement Welcome Step
**As a** user
**I want** to understand what setup involves
**So that** I'm prepared for the process

**Acceptance Criteria:**
- [ ] Explains why setup is needed
- [ ] Sets time expectation (~5 min)
- [ ] Shows what will happen
- [ ] Has "Get Started" button
- [ ] Can skip if already configured

**Tasks:**
- Create WelcomeStepView
- Write copy
- Add skip detection logic
- Style according to design system

**Estimate:** 2 hours

---

### E2-S3: Implement BlackHole Installation Step
**As a** user
**I want** guidance installing BlackHole
**So that** I can complete it successfully

**Acceptance Criteria:**
- [ ] Detects if already installed (skip if yes)
- [ ] Provides download link
- [ ] Provides Homebrew command
- [ ] Shows installation instructions
- [ ] Verifies installation before proceeding

**Tasks:**
- Create BlackHoleInstallStepView
- Integrate detection from E1-S2
- Add download/Homebrew options
- Show verification status
- Write tests

**Estimate:** 4 hours

---

### E2-S4: Implement Multi-Output Configuration Step
**As a** user
**I want** help configuring Audio MIDI Setup
**So that** audio routing works

**Acceptance Criteria:**
- [ ] Detects if already configured (skip if yes)
- [ ] Step-by-step instructions with images
- [ ] "Open Audio MIDI Setup" button
- [ ] Verifies configuration before proceeding
- [ ] Troubleshooting tips for common issues

**Tasks:**
- Create MultiOutputStepView
- Integrate detection from E1-S3
- Add instructional content
- Implement verification polling
- Add troubleshooting content

**Estimate:** 6 hours

---

### E2-S5: Implement Audio Verification Step
**As a** user
**I want** to test that audio capture works
**So that** I'm confident before my first interview

**Acceptance Criteria:**
- [ ] Dual audio level meters
- [ ] Instructions to play audio and speak
- [ ] Clear pass/fail indication
- [ ] Can retry if failed
- [ ] Stores successful configuration

**Tasks:**
- Create VerificationStepView
- Integrate audio levels from E1-S5
- Add pass/fail logic
- Store configuration on success
- Write tests

**Estimate:** 4 hours

---

### E2-S6: Implement Success Step
**As a** user
**I want** confirmation that setup is complete
**So that** I know I'm ready

**Acceptance Criteria:**
- [ ] Congratulations message
- [ ] Summary of what was configured
- [ ] "Start First Session" button
- [ ] Option to view help docs
- [ ] Marks setup as complete in preferences

**Tasks:**
- Create SuccessStepView
- Add summary content
- Link to first session flow
- Store completion status
- Write tests

**Estimate:** 2 hours

---

# EPIC E3: OpenAI Integration

**Owner:** Engineer
**Track:** B (parallel with E1)
**Priority:** P0

## Stories

### E3-S1: Define API Protocols
**As a** developer
**I want** clear API interfaces
**So that** the client is testable

**Acceptance Criteria:**
- [ ] RealtimeAPIConnecting protocol defined
- [ ] SessionConfig data type defined
- [ ] TranscriptionEvent data type defined
- [ ] FunctionCallEvent data type defined
- [ ] ConnectionState enum defined

**Tasks:**
- Create RealtimeAPIConnecting protocol
- Define all event types
- Define configuration types
- Create mock implementation

**Estimate:** 3 hours

---

### E3-S2: Implement API Client Wrapper
**As a** developer
**I want** a wrapper around SwiftOpenAI
**So that** I can customize behavior

**Acceptance Criteria:**
- [ ] Wraps SwiftOpenAI Realtime client
- [ ] Implements RealtimeAPIConnecting
- [ ] Handles authentication
- [ ] Handles reconnection
- [ ] Exposes typed event streams

**Tasks:**
- Create RealtimeAPIClient class
- Wrap SwiftOpenAI client
- Implement protocol methods
- Add event stream mapping
- Write tests

**Estimate:** 6 hours

---

### E3-S3: Implement Session Configuration
**As a** developer
**I want** to configure API sessions
**So that** coaching behaves correctly

**Acceptance Criteria:**
- [ ] System prompt configurable
- [ ] Function definitions sent
- [ ] Voice activity detection configured
- [ ] Input/output formats set correctly
- [ ] Session config logged for debugging

**Tasks:**
- Create SessionConfigBuilder
- Define function schemas (show_nudge, flag_insight, update_topic)
- Set VAD configuration
- Set audio formats
- Write tests

**Estimate:** 4 hours

---

### E3-S4: Implement Audio Streaming
**As a** developer
**I want** to stream audio to the API
**So that** transcription works

**Acceptance Criteria:**
- [ ] Accepts AudioChunk stream
- [ ] Converts to API format (base64)
- [ ] Sends at correct rate
- [ ] Handles backpressure
- [ ] Handles connection interruptions

**Tasks:**
- Create audio sending pipeline
- Implement base64 conversion
- Add rate limiting
- Handle errors
- Write tests

**Estimate:** 4 hours

---

### E3-S5: Implement Transcription Event Handling
**As a** developer
**I want** to receive transcription events
**So that** I can display the transcript

**Acceptance Criteria:**
- [ ] Parses transcript delta events
- [ ] Parses transcript complete events
- [ ] Extracts speaker information
- [ ] Extracts timestamps
- [ ] Exposes as typed AsyncStream

**Tasks:**
- Create TranscriptionEventParser
- Parse all event types
- Extract metadata
- Create typed stream
- Write tests

**Estimate:** 4 hours

---

### E3-S6: Implement Function Call Handling
**As a** developer
**I want** to receive function calls from the API
**So that** coaching and insights work

**Acceptance Criteria:**
- [ ] Parses show_nudge calls
- [ ] Parses flag_insight calls
- [ ] Parses update_topic calls
- [ ] Handles malformed calls gracefully
- [ ] Logs all function calls

**Tasks:**
- Create FunctionCallParser
- Parse each function type
- Add fallback for errors
- Add logging
- Write tests

**Estimate:** 4 hours

---

### E3-S7: Implement Connection Management
**As a** developer
**I want** robust connection handling
**So that** sessions are reliable

**Acceptance Criteria:**
- [ ] Automatic reconnection on disconnect
- [ ] Exponential backoff (max 5 attempts)
- [ ] Connection state observable
- [ ] Graceful degradation on failure
- [ ] Ping/keepalive handling

**Tasks:**
- Implement reconnection logic
- Add exponential backoff
- Publish connection state
- Handle max retry failure
- Write tests

**Estimate:** 4 hours

---

### E3-S8: Create API Integration Tests
**As a** developer
**I want** API tests with mocks
**So that** integration is reliable

**Acceptance Criteria:**
- [ ] Mock API server for testing
- [ ] Tests for all event types
- [ ] Tests for error conditions
- [ ] Tests for reconnection
- [ ] 80%+ coverage on API module

**Tasks:**
- Create mock API server
- Write event tests
- Write error tests
- Write reconnection tests
- Document manual testing

**Estimate:** 6 hours

---

# EPIC E4: Session Management

**Owner:** Engineer
**Track:** D (Depends on E1, E3)
**Priority:** P0

## Stories

### E4-S1: Define Session Protocols
**As a** developer
**I want** clear session interfaces
**So that** state management is clean

**Acceptance Criteria:**
- [ ] SessionManaging protocol defined
- [ ] SessionState enum defined
- [ ] SessionSummary data type defined
- [ ] All state transitions documented

**Tasks:**
- Create SessionManaging protocol
- Define SessionState enum
- Define SessionSummary type
- Document state machine

**Estimate:** 2 hours

---

### E4-S2: Implement Session State Machine
**As a** developer
**I want** a robust state machine
**So that** sessions are predictable

**Acceptance Criteria:**
- [ ] All states: idle, setup, connecting, ready, streaming, paused, reconnecting, ending, ended, failed
- [ ] Valid transitions enforced
- [ ] Invalid transitions logged
- [ ] State observable for UI
- [ ] Unit tests for all transitions

**Tasks:**
- Create SessionStateMachine
- Implement state transitions
- Add validation
- Publish state changes
- Write comprehensive tests

**Estimate:** 6 hours

---

### E4-S3: Implement SessionManager
**As a** developer
**I want** a coordinator for sessions
**So that** all components work together

**Acceptance Criteria:**
- [ ] Implements SessionManaging protocol
- [ ] Coordinates audio and API services
- [ ] Manages session lifecycle
- [ ] Persists sessions to SwiftData
- [ ] Handles errors from all components

**Tasks:**
- Create SessionManager class
- Wire audio and API services
- Implement lifecycle methods
- Add persistence
- Write tests

**Estimate:** 8 hours

---

### E4-S4: Implement Session Creation Flow
**As a** user
**I want** to create a new session
**So that** I can start an interview

**Acceptance Criteria:**
- [ ] Enter participant name (optional)
- [ ] Select project (optional)
- [ ] Choose template (optional)
- [ ] Select session mode
- [ ] Audio check before start

**Tasks:**
- Create SessionSetupView
- Implement form fields
- Add template selector
- Add mode selector
- Integrate audio check

**Estimate:** 6 hours

---

### E4-S5: Implement Session Controls
**As a** user
**I want** to control the session
**So that** I can pause and resume as needed

**Acceptance Criteria:**
- [ ] Start button begins recording
- [ ] Pause button pauses (maintains connection)
- [ ] Resume button continues
- [ ] End button stops and shows summary
- [ ] Keyboard shortcuts work

**Tasks:**
- Create SessionControlsView
- Wire to SessionManager
- Add keyboard shortcuts
- Handle state transitions
- Write UI tests

**Estimate:** 4 hours

---

### E4-S6: Implement Connection Status Display
**As a** user
**I want** to see connection status
**So that** I know if everything is working

**Acceptance Criteria:**
- [ ] Shows connected/disconnected state
- [ ] Shows reconnecting state
- [ ] Shows latency indicator
- [ ] Non-intrusive placement
- [ ] Accessible to screen readers

**Tasks:**
- Create ConnectionStatusView
- Subscribe to connection state
- Add latency display
- Style appropriately
- Add accessibility labels

**Estimate:** 3 hours

---

### E4-S7: Implement Session Persistence
**As a** user
**I want** my sessions saved automatically
**So that** I don't lose data

**Acceptance Criteria:**
- [ ] Session saved on creation
- [ ] Utterances saved as received
- [ ] Insights saved immediately
- [ ] Session updated on end
- [ ] Recovers from crash (partial data saved)

**Tasks:**
- Implement continuous save
- Add crash recovery logic
- Test data integrity
- Optimize save frequency
- Write tests

**Estimate:** 4 hours

---

# EPIC E5: Transcript Display

**Owner:** Frontend
**Track:** E (Depends on E4)
**Priority:** P0

## Stories

### E5-S1: Create Transcript Container View
**As a** user
**I want** to see the transcript
**So that** I can follow the conversation

**Acceptance Criteria:**
- [ ] Scrollable list of utterances
- [ ] Auto-scrolls to latest
- [ ] Manual scroll pauses auto-scroll
- [ ] Returns to auto-scroll at bottom
- [ ] Smooth performance with 1000+ items

**Tasks:**
- Create TranscriptView
- Implement scroll behavior
- Optimize for large lists
- Write UI tests

**Estimate:** 6 hours

---

### E5-S2: Create Utterance Row View
**As a** user
**I want** to see each utterance clearly
**So that** I can read the transcript

**Acceptance Criteria:**
- [ ] Shows speaker label
- [ ] Shows timestamp
- [ ] Shows text content
- [ ] Differentiates interviewer/participant
- [ ] Highlights insights

**Tasks:**
- Create UtteranceRowView
- Style speaker labels
- Add timestamp formatting
- Add insight highlighting
- Write tests

**Estimate:** 4 hours

---

### E5-S3: Implement Speaker Toggle
**As a** user
**I want** to correct speaker attribution
**So that** the transcript is accurate

**Acceptance Criteria:**
- [ ] Click speaker label to toggle
- [ ] Keyboard shortcut (⌘+Option+T)
- [ ] Shows AI confidence indicator
- [ ] Saves correction immediately
- [ ] Accessible via keyboard

**Tasks:**
- Add toggle interaction
- Implement keyboard shortcut
- Show confidence
- Save to model
- Write tests

**Estimate:** 3 hours

---

### E5-S4: Implement Transcript Search
**As a** user
**I want** to search the transcript
**So that** I can find specific content

**Acceptance Criteria:**
- [ ] Search field in toolbar
- [ ] Highlights matching text
- [ ] Navigate between matches
- [ ] Shows match count
- [ ] Keyboard shortcut (⌘+F)

**Tasks:**
- Add search field
- Implement search logic
- Add highlighting
- Add navigation
- Write tests

**Estimate:** 4 hours

---

### E5-S5: Implement Timestamp Navigation
**As a** user
**I want** to click timestamps
**So that** I can jump to specific moments

**Acceptance Criteria:**
- [ ] Timestamps are clickable
- [ ] Shows time in MM:SS format
- [ ] Click scrolls to that position
- [ ] Works with search results
- [ ] Works with insight links

**Tasks:**
- Make timestamps interactive
- Implement scroll-to logic
- Format timestamps
- Write tests

**Estimate:** 2 hours

---

### E5-S6: Create Transcript Accessibility
**As a** user using assistive technology
**I want** the transcript to be accessible
**So that** I can use the app

**Acceptance Criteria:**
- [ ] All utterances have accessibility labels
- [ ] Speaker changes announced
- [ ] New utterances announced (live region)
- [ ] Keyboard navigation works
- [ ] Focus management correct

**Tasks:**
- Add accessibility labels
- Configure live regions
- Test with VoiceOver
- Fix navigation issues
- Write accessibility tests

**Estimate:** 4 hours

---

# EPIC E6: Coaching Engine

**Owner:** Engineer, AI/ML
**Track:** F (Depends on E4)
**Priority:** P0

## Stories

### E6-S1: Define Coaching Protocols
**As a** developer
**I want** clear coaching interfaces
**So that** coaching logic is testable

**Acceptance Criteria:**
- [ ] CoachingEngine protocol defined
- [ ] CoachingPrompt data type defined
- [ ] CoachingDecision enum defined
- [ ] SuppressionReason enum defined

**Tasks:**
- Create CoachingEngine protocol
- Define data types
- Create mock implementation
- Document behavior

**Estimate:** 2 hours

---

### E6-S2: Implement Coaching Thresholds
**As a** developer
**I want** configurable thresholds
**So that** coaching behavior can be tuned

**Acceptance Criteria:**
- [ ] Minimum confidence threshold (0.85)
- [ ] Cooldown period (120 seconds)
- [ ] Post-speech delay (5 seconds)
- [ ] Max prompts per session (3)
- [ ] Auto-dismiss time (8 seconds)
- [ ] All thresholds in configuration

**Tasks:**
- Create CoachingConfig
- Define threshold values
- Make configurable via settings
- Document each threshold

**Estimate:** 2 hours

---

### E6-S3: Implement Timing Rules
**As a** developer
**I want** strict timing enforcement
**So that** prompts never interrupt

**Acceptance Criteria:**
- [ ] Never prompt while interviewer speaking
- [ ] Wait 5 seconds after interviewer stops
- [ ] Minimum 2 minutes between prompts
- [ ] Detect speech state accurately
- [ ] Log all timing decisions

**Tasks:**
- Implement speech detection
- Implement cooldown tracking
- Add timing gate logic
- Add logging
- Write tests

**Estimate:** 4 hours

---

### E6-S4: Implement Coaching Decision Engine
**As a** developer
**I want** to evaluate coaching decisions
**So that** only appropriate prompts show

**Acceptance Criteria:**
- [ ] Receives function calls from API
- [ ] Applies all timing rules
- [ ] Applies confidence threshold
- [ ] Returns show/suppress decision
- [ ] Logs suppressed prompts with reasons

**Tasks:**
- Create CoachingDecisionEngine
- Implement decision logic
- Add suppression logging
- Wire to API events
- Write comprehensive tests

**Estimate:** 6 hours

---

### E6-S5: Create Coaching Prompt View
**As a** user
**I want** to see coaching prompts
**So that** I can benefit from suggestions

**Acceptance Criteria:**
- [ ] Floating overlay window
- [ ] Subtle entrance animation
- [ ] Auto-dismiss countdown
- [ ] Manual dismiss with Escape
- [ ] Non-intrusive position

**Tasks:**
- Create CoachingPromptWindow
- Implement overlay positioning
- Add animations
- Add dismiss handling
- Write UI tests

**Estimate:** 6 hours

---

### E6-S6: Implement Coaching Toggle
**As a** user
**I want** to enable/disable coaching
**So that** I control my experience

**Acceptance Criteria:**
- [ ] Toggle in session view
- [ ] Keyboard shortcut (⌘+Shift+M)
- [ ] Persists for session
- [ ] Shows "quiet" indicator when off
- [ ] First session defaults to OFF

**Tasks:**
- Add toggle control
- Implement shortcut
- Add quiet indicator
- Implement first-session logic
- Write tests

**Estimate:** 3 hours

---

### E6-S7: Implement Coaching Event Logging
**As a** developer
**I want** to log all coaching events
**So that** we can analyze and improve

**Acceptance Criteria:**
- [ ] Log prompt shown events
- [ ] Log prompt dismissed events
- [ ] Log suppressed prompts with reasons
- [ ] Store in CoachingEvent model
- [ ] Include in session export

**Tasks:**
- Create logging infrastructure
- Log all event types
- Store in SwiftData
- Add to export
- Write tests

**Estimate:** 3 hours

---

### E6-S8: Create Coaching Tests
**As a** developer
**I want** thorough coaching tests
**So that** coaching is reliable

**Acceptance Criteria:**
- [ ] Unit tests for decision logic
- [ ] Tests for timing rules
- [ ] Tests for threshold enforcement
- [ ] Mock function calls for testing
- [ ] 80%+ coverage on coaching module

**Tasks:**
- Write decision tests
- Write timing tests
- Create mock events
- Achieve coverage target
- Document edge cases

**Estimate:** 4 hours

---

# EPIC E7: Topic Awareness

**Owner:** Engineer, Frontend
**Track:** F (Depends on E4)
**Priority:** P0

## Stories

### E7-S1: Create Topic Panel View
**As a** user
**I want** to see topic coverage
**So that** I'm aware of what's been discussed

**Acceptance Criteria:**
- [ ] List of topics for session
- [ ] Visual status indicators
- [ ] Icons alongside colors (accessibility)
- [ ] Collapsible panel
- [ ] Non-intrusive design

**Tasks:**
- Create TopicPanelView
- Implement status indicators
- Add collapse functionality
- Style appropriately
- Write UI tests

**Estimate:** 4 hours

---

### E7-S2: Implement Topic Status Display
**As a** user
**I want** to see topic status clearly
**So that** I understand coverage at a glance

**Acceptance Criteria:**
- [ ] Untouched: Gray + ○
- [ ] Touched: Light blue + ◐
- [ ] Explored: Blue + ●
- [ ] No "complete" state
- [ ] Subtle transitions between states

**Tasks:**
- Create TopicStatusView
- Implement status styling
- Add animations
- Ensure accessibility
- Write tests

**Estimate:** 3 hours

---

### E7-S3: Implement Topic Update Handling
**As a** developer
**I want** to process topic updates from API
**So that** status reflects conversation

**Acceptance Criteria:**
- [ ] Receives update_topic function calls
- [ ] Applies confidence threshold
- [ ] Updates TopicStatus model
- [ ] Triggers UI update
- [ ] Logs all updates

**Tasks:**
- Create TopicUpdateHandler
- Process API events
- Update SwiftData model
- Add logging
- Write tests

**Estimate:** 4 hours

---

### E7-S4: Implement Manual Topic Adjustment
**As a** user
**I want** to adjust topic status manually
**So that** I can correct the AI

**Acceptance Criteria:**
- [ ] Click topic to cycle status
- [ ] Untouched → Touched → Explored → Untouched
- [ ] Immediate visual feedback
- [ ] Saves to model
- [ ] Keyboard accessible

**Tasks:**
- Add click handler
- Implement cycle logic
- Save to model
- Add keyboard support
- Write tests

**Estimate:** 2 hours

---

### E7-S5: Create Topic Configuration
**As a** user
**I want** to define session topics
**So that** tracking is relevant to my research

**Acceptance Criteria:**
- [ ] Add topics during session setup
- [ ] Load from template if selected
- [ ] Edit topics during session
- [ ] Delete topics
- [ ] Reorder topics

**Tasks:**
- Add topic editor to setup
- Implement template loading
- Add edit/delete/reorder
- Save to session model
- Write tests

**Estimate:** 4 hours

---

# EPIC E8: Insight Flagging

**Owner:** Engineer, Frontend
**Track:** E (Depends on E5)
**Priority:** P0

## Stories

### E8-S1: Create Insights Panel View
**As a** user
**I want** to see flagged insights
**So that** I can review notable moments

**Acceptance Criteria:**
- [ ] List of insights chronologically
- [ ] Shows quote snippet
- [ ] Shows suggested theme
- [ ] Shows source (AI/manual)
- [ ] Click navigates to transcript

**Tasks:**
- Create InsightsPanelView
- Display insight data
- Add navigation
- Style appropriately
- Write UI tests

**Estimate:** 4 hours

---

### E8-S2: Implement Auto-Flagging
**As a** developer
**I want** to process AI insight flags
**So that** notable moments are captured

**Acceptance Criteria:**
- [ ] Receives flag_insight function calls
- [ ] Applies confidence threshold
- [ ] Creates Insight model
- [ ] Limits to 5-7 per session
- [ ] Logs all flags

**Tasks:**
- Create InsightFlagHandler
- Process API events
- Create model instances
- Add rate limiting
- Write tests

**Estimate:** 4 hours

---

### E8-S3: Implement Manual Flagging
**As a** user
**I want** to flag insights manually
**So that** I capture what matters to me

**Acceptance Criteria:**
- [ ] Keyboard shortcut (⌘+I)
- [ ] Flags current moment
- [ ] Prompts for optional note
- [ ] Shows confirmation
- [ ] Works during active session

**Tasks:**
- Implement shortcut
- Create flag flow
- Add note prompt
- Show confirmation
- Write tests

**Estimate:** 3 hours

---

### E8-S4: Implement Insight Navigation
**As a** user
**I want** to jump to insights in transcript
**So that** I can review context

**Acceptance Criteria:**
- [ ] Click insight to scroll transcript
- [ ] Highlight relevant utterance
- [ ] Clear highlight after 3 seconds
- [ ] Works from insights panel
- [ ] Works from export

**Tasks:**
- Add click handler
- Implement scroll-to
- Add highlighting
- Clear after timeout
- Write tests

**Estimate:** 3 hours

---

### E8-S5: Implement Insight Editing
**As a** user
**I want** to edit insights
**So that** I can add my own notes

**Acceptance Criteria:**
- [ ] Edit theme label
- [ ] Add/edit notes
- [ ] Delete insight
- [ ] Changes save immediately
- [ ] Accessible interface

**Tasks:**
- Add edit interface
- Implement save logic
- Add delete confirmation
- Ensure accessibility
- Write tests

**Estimate:** 3 hours

---

# EPIC E9: Export System

**Owner:** Engineer
**Track:** G (Depends on E4)
**Priority:** P0

## Stories

### E9-S1: Define Export Protocols
**As a** developer
**I want** clear export interfaces
**So that** formats are extensible

**Acceptance Criteria:**
- [ ] SessionExporter protocol defined
- [ ] ExportFormat enum (markdown, json)
- [ ] ExportOptions configuration
- [ ] Supports async export

**Tasks:**
- Create SessionExporter protocol
- Define export types
- Create options structure
- Document extension points

**Estimate:** 2 hours

---

### E9-S2: Implement Markdown Export
**As a** user
**I want** to export as Markdown
**So that** I can share readable transcripts

**Acceptance Criteria:**
- [ ] Full transcript with speaker labels
- [ ] Timestamps inline
- [ ] Insights marked with emoji
- [ ] Topic summary at top
- [ ] Session metadata included

**Tasks:**
- Create MarkdownExporter
- Format transcript
- Add insight markers
- Add topic summary
- Write tests

**Estimate:** 4 hours

---

### E9-S3: Implement JSON Export
**As a** user
**I want** to export as JSON
**So that** I can process data programmatically

**Acceptance Criteria:**
- [ ] Full structured data
- [ ] All utterances with metadata
- [ ] All insights with context
- [ ] All topic statuses
- [ ] Valid JSON output

**Tasks:**
- Create JSONExporter
- Define JSON schema
- Implement serialization
- Validate output
- Write tests

**Estimate:** 3 hours

---

### E9-S4: Create Export UI
**As a** user
**I want** an export dialog
**So that** I can choose format and location

**Acceptance Criteria:**
- [ ] Format selector
- [ ] Save location picker
- [ ] Include options (coaching log, etc.)
- [ ] Progress indicator
- [ ] Success confirmation

**Tasks:**
- Create ExportView
- Add format picker
- Add save panel
- Add options
- Write UI tests

**Estimate:** 3 hours

---

### E9-S5: Implement Export from History
**As a** user
**I want** to export past sessions
**So that** I can access old data

**Acceptance Criteria:**
- [ ] Export button in session history
- [ ] Works for any past session
- [ ] Same options as current session
- [ ] Handles missing data gracefully

**Tasks:**
- Add export to history view
- Handle all session states
- Test with various sessions
- Write tests

**Estimate:** 2 hours

---

# EPIC E10: Post-Session Summary

**Owner:** Engineer, Frontend
**Track:** G (Depends on E4, E6)
**Priority:** P1

## Stories

### E10-S1: Create Summary View
**As a** user
**I want** a session summary
**So that** I can review what happened

**Acceptance Criteria:**
- [ ] Shows immediately after session ends
- [ ] Duration and participant info
- [ ] Topic coverage summary
- [ ] Insights count
- [ ] Coaching activity summary

**Tasks:**
- Create PostSessionSummaryView
- Calculate summary statistics
- Display all sections
- Style according to design
- Write UI tests

**Estimate:** 6 hours

---

### E10-S2: Implement AI Reflection
**As a** user
**I want** AI-generated reflection
**So that** I get actionable feedback

**Acceptance Criteria:**
- [ ] Generated after session ends
- [ ] Notes what was explored well
- [ ] Suggests missed opportunities
- [ ] Constructive tone
- [ ] Can be dismissed/hidden

**Tasks:**
- Create reflection prompt
- Generate via API
- Display in summary
- Add dismiss option
- Write tests

**Estimate:** 4 hours

---

### E10-S3: Implement Summary Actions
**As a** user
**I want** quick actions from summary
**So that** I can take next steps

**Acceptance Criteria:**
- [ ] Export button
- [ ] View full transcript button
- [ ] Start new session button
- [ ] Close/dismiss button
- [ ] Keyboard navigation

**Tasks:**
- Add action buttons
- Wire to respective flows
- Add keyboard shortcuts
- Write tests

**Estimate:** 2 hours

---

### E10-S4: Implement Summary Persistence
**As a** developer
**I want** to save summaries
**So that** users can review later

**Acceptance Criteria:**
- [ ] AI reflection saved to session
- [ ] Summary viewable from history
- [ ] Persists across app restarts
- [ ] Included in export

**Tasks:**
- Add reflection to Session model
- Save on generation
- Display in history
- Add to export
- Write tests

**Estimate:** 2 hours

---

### E10-S5: Create Coaching Opt-In Prompt
**As a** user
**I want** to be offered coaching after first session
**So that** I can try it when ready

**Acceptance Criteria:**
- [ ] Shows only after first session
- [ ] Explains coaching briefly
- [ ] Enable/Not now options
- [ ] Respects user choice
- [ ] Non-intrusive design

**Tasks:**
- Detect first session
- Create prompt UI
- Save preference
- Write tests

**Estimate:** 3 hours

---

# EPIC E11: Settings & Preferences

**Owner:** Frontend
**Track:** H (No dependencies)
**Priority:** P1

## Stories

### E11-S1: Create Settings Window
**As a** user
**I want** a settings interface
**So that** I can configure the app

**Acceptance Criteria:**
- [ ] Accessible via menu (⌘+,)
- [ ] Tabbed interface
- [ ] General, Audio, Coaching, Privacy tabs
- [ ] Changes save immediately
- [ ] Native macOS feel

**Tasks:**
- Create SettingsWindow
- Implement tab navigation
- Style appropriately
- Add menu item
- Write UI tests

**Estimate:** 4 hours

---

### E11-S2: Implement General Settings
**As a** user
**I want** general preferences
**So that** the app works how I want

**Acceptance Criteria:**
- [ ] Default session mode
- [ ] Default template
- [ ] Startup behavior
- [ ] Keyboard shortcut reference
- [ ] Check for updates toggle

**Tasks:**
- Create GeneralSettingsView
- Implement preferences
- Save to UserDefaults
- Write tests

**Estimate:** 3 hours

---

### E11-S3: Implement Audio Settings
**As a** user
**I want** audio preferences
**So that** I can adjust audio behavior

**Acceptance Criteria:**
- [ ] Input device selector
- [ ] Re-run audio setup wizard
- [ ] Audio level test
- [ ] Sample rate display
- [ ] Troubleshooting link

**Tasks:**
- Create AudioSettingsView
- Implement device selection
- Add test functionality
- Write tests

**Estimate:** 3 hours

---

### E11-S4: Implement Coaching Settings
**As a** user
**I want** coaching preferences
**So that** I can tune coaching behavior

**Acceptance Criteria:**
- [ ] Coaching enabled toggle
- [ ] Auto-dismiss time slider
- [ ] Prompt position selector
- [ ] Reset to defaults button
- [ ] Preview prompt button

**Tasks:**
- Create CoachingSettingsView
- Implement preferences
- Add preview
- Write tests

**Estimate:** 3 hours

---

### E11-S5: Implement API Key Management
**As a** user
**I want** to manage my API key
**So that** I can update or remove it

**Acceptance Criteria:**
- [ ] Shows masked current key
- [ ] Update key option
- [ ] Remove key option
- [ ] Test key button
- [ ] Link to OpenAI console

**Tasks:**
- Create APIKeySettingsView
- Implement key management
- Add test functionality
- Write tests

**Estimate:** 3 hours

---

# EPIC E12: Consent & Templates

**Owner:** Frontend
**Track:** H (No dependencies)
**Priority:** P0

## Stories

### E12-S1: Create Template System
**As a** developer
**I want** a template infrastructure
**So that** users can use predefined setups

**Acceptance Criteria:**
- [ ] Template model defined
- [ ] Built-in templates bundled
- [ ] Template selector in session setup
- [ ] Template preview
- [ ] Custom templates (future)

**Tasks:**
- Create Template model
- Define built-in templates
- Implement selector
- Add preview
- Write tests

**Estimate:** 4 hours

---

### E12-S2: Create Built-In Templates
**As a** user
**I want** interview templates
**So that** I can start quickly

**Acceptance Criteria:**
- [ ] Discovery Interview (60 min)
- [ ] Usability Debrief (30 min)
- [ ] Stakeholder Interview (45 min)
- [ ] JTBD Interview (45 min)
- [ ] Custom/Blank option

**Tasks:**
- Define template content
- Create topic lists
- Set default durations
- Add descriptions
- Write tests

**Estimate:** 3 hours

---

### E12-S3: Implement Consent Template Display
**As a** user
**I want** to see consent templates
**So that** I can disclose AI usage properly

**Acceptance Criteria:**
- [ ] Consent text for selected mode
- [ ] Copy to clipboard button
- [ ] View before session starts
- [ ] Customizable (future)
- [ ] Different variants available

**Tasks:**
- Create ConsentTemplateView
- Display based on mode
- Add copy functionality
- Write tests

**Estimate:** 3 hours

---

### E12-S4: Implement Session Mode Selector
**As a** user
**I want** to choose session mode
**So that** I control what AI does

**Acceptance Criteria:**
- [ ] Full: Transcription + Coaching + Insights
- [ ] Transcription Only: No AI coaching
- [ ] Observer Only: No recording
- [ ] Clear descriptions
- [ ] Mode indicator during session

**Tasks:**
- Create ModeSelector
- Display mode descriptions
- Save to session
- Show indicator
- Write tests

**Estimate:** 3 hours

---

# EPIC E13: Accessibility

**Owner:** A11y, Frontend
**Track:** I (Cross-cutting)
**Priority:** P0

## Stories

### E13-S1: Implement Keyboard Navigation
**As a** user who doesn't use a mouse
**I want** full keyboard access
**So that** I can use all features

**Acceptance Criteria:**
- [ ] Tab navigates all elements
- [ ] Arrow keys work in lists
- [ ] Enter activates buttons
- [ ] Escape closes modals
- [ ] No keyboard traps

**Tasks:**
- Audit all views
- Add focusable modifiers
- Implement key handlers
- Test navigation
- Write tests

**Estimate:** 6 hours

---

### E13-S2: Implement VoiceOver Support
**As a** user using VoiceOver
**I want** proper announcements
**So that** I understand the interface

**Acceptance Criteria:**
- [ ] All elements have labels
- [ ] Dynamic content announced
- [ ] Hints for complex interactions
- [ ] Reading order logical
- [ ] No unlabeled images

**Tasks:**
- Add accessibility labels
- Configure live regions
- Add hints
- Test with VoiceOver
- Fix issues found

**Estimate:** 6 hours

---

### E13-S3: Implement Focus Indicators
**As a** user navigating with keyboard
**I want** to see where focus is
**So that** I know what's selected

**Acceptance Criteria:**
- [ ] Visible focus ring on all elements
- [ ] 3:1 contrast ratio minimum
- [ ] Consistent style throughout
- [ ] Works in light and dark mode

**Tasks:**
- Create focus style
- Apply to all interactive elements
- Verify contrast
- Test in both modes
- Write tests

**Estimate:** 3 hours

---

### E13-S4: Implement Color Independence
**As a** user who is color blind
**I want** non-color indicators
**So that** I can understand status

**Acceptance Criteria:**
- [ ] Topics have icons + colors
- [ ] Connection status has text + color
- [ ] Audio levels have numeric + color
- [ ] Insights have icon + color
- [ ] No information conveyed by color alone

**Tasks:**
- Audit color usage
- Add secondary indicators
- Test with color blindness simulator
- Write tests

**Estimate:** 3 hours

---

### E13-S5: Implement Reduced Motion
**As a** user with motion sensitivity
**I want** reduced animations
**So that** the app doesn't cause discomfort

**Acceptance Criteria:**
- [ ] Respects system preference
- [ ] Removes/reduces all animations
- [ ] Functionality unchanged
- [ ] Tested with preference on

**Tasks:**
- Check accessibilityReduceMotion
- Conditionally disable animations
- Test all views
- Write tests

**Estimate:** 2 hours

---

### E13-S6: Accessibility Audit
**As a** product owner
**I want** WCAG 2.1 AA compliance
**So that** all users can use the app

**Acceptance Criteria:**
- [ ] Full audit completed
- [ ] All issues documented
- [ ] Critical issues fixed
- [ ] Audit report generated
- [ ] Compliance statement

**Tasks:**
- Run accessibility audit
- Document findings
- Fix critical issues
- Generate report
- Plan remaining fixes

**Estimate:** 8 hours

---

# EPIC E14: Testing & Quality

**Owner:** QA, Engineer
**Track:** J (Cross-cutting)
**Priority:** P0

## Stories

### E14-S1: Set Up Unit Testing
**As a** developer
**I want** unit test infrastructure
**So that** I can test in isolation

**Acceptance Criteria:**
- [ ] XCTest configured
- [ ] Test target created
- [ ] Mocks for all protocols
- [ ] Coverage reporting enabled
- [ ] Tests run in CI

**Tasks:**
- Create test target
- Configure coverage
- Create mock factory
- Document patterns
- Verify CI integration

**Estimate:** 3 hours

---

### E14-S2: Set Up Integration Testing
**As a** developer
**I want** integration tests
**So that** components work together

**Acceptance Criteria:**
- [ ] Integration test target
- [ ] Mock API server
- [ ] Mock audio source
- [ ] Test real flows
- [ ] Isolated from unit tests

**Tasks:**
- Create integration target
- Build mock server
- Build mock audio
- Write flow tests
- Document approach

**Estimate:** 6 hours

---

### E14-S3: Set Up UI Testing
**As a** developer
**I want** UI tests
**So that** the interface works correctly

**Acceptance Criteria:**
- [ ] XCUITest configured
- [ ] Critical paths covered
- [ ] Tests run in CI
- [ ] Screenshots on failure
- [ ] Reasonable speed

**Tasks:**
- Create UI test target
- Write critical path tests
- Configure CI
- Add screenshot capture
- Optimize test speed

**Estimate:** 6 hours

---

### E14-S4: Create Smoke Test Suite
**As a** developer
**I want** quick verification tests
**So that** I can validate before commit

**Acceptance Criteria:**
- [ ] Runs in < 2 minutes
- [ ] Covers critical functionality
- [ ] Clear pass/fail output
- [ ] Can run locally
- [ ] Runs in CI

**Tasks:**
- Identify critical tests
- Create smoke test scheme
- Optimize for speed
- Document usage
- Add to CI

**Estimate:** 2 hours

---

### E14-S5: Implement Test Coverage Reporting
**As a** developer
**I want** coverage metrics
**So that** I know test quality

**Acceptance Criteria:**
- [ ] Coverage report generated
- [ ] Per-module breakdown
- [ ] 70% target enforced
- [ ] Visible in CI
- [ ] Trend tracking

**Tasks:**
- Configure coverage collection
- Generate reports
- Add CI reporting
- Set up enforcement
- Document thresholds

**Estimate:** 2 hours

---

### E14-S6: Create Test Documentation
**As a** developer
**I want** testing guidelines
**So that** tests are consistent

**Acceptance Criteria:**
- [ ] Testing strategy document
- [ ] Mock patterns documented
- [ ] Naming conventions
- [ ] When to write which test type
- [ ] Examples for each pattern

**Tasks:**
- Write strategy doc
- Document patterns
- Create examples
- Review with team

**Estimate:** 3 hours

---

# EPIC E15: Distribution & CI/CD

**Owner:** DevOps
**Track:** A (No dependencies)
**Priority:** P0

## Stories

### E15-S1: Set Up GitHub Actions
**As a** developer
**I want** automated CI
**So that** every commit is validated

**Acceptance Criteria:**
- [ ] Workflow runs on push/PR
- [ ] SwiftLint check
- [ ] Build verification
- [ ] Test execution
- [ ] Status checks on PR

**Tasks:**
- Create workflow file
- Configure runners
- Add all jobs
- Test workflow
- Document usage

**Estimate:** 4 hours

---

### E15-S2: Configure Code Signing
**As a** developer
**I want** proper code signing
**So that** the app can be distributed

**Acceptance Criteria:**
- [ ] Developer ID certificate configured
- [ ] Provisioning profile set up
- [ ] Hardened Runtime enabled
- [ ] Entitlements configured
- [ ] Local signing works

**Tasks:**
- Set up certificates
- Configure entitlements
- Enable Hardened Runtime
- Test local signing
- Document process

**Estimate:** 4 hours

---

### E15-S3: Implement Notarization
**As a** developer
**I want** notarized builds
**So that** users can install without warnings

**Acceptance Criteria:**
- [ ] Notarization in CI
- [ ] Stapled ticket
- [ ] Verified installation
- [ ] Automated process
- [ ] Error handling

**Tasks:**
- Configure notarytool
- Add to CI workflow
- Implement stapling
- Test installation
- Handle failures

**Estimate:** 4 hours

---

### E15-S4: Set Up Sparkle Updates
**As a** developer
**I want** auto-updates
**So that** users get new versions easily

**Acceptance Criteria:**
- [ ] Sparkle framework integrated
- [ ] Appcast feed configured
- [ ] Update check on launch
- [ ] User-initiated check
- [ ] Update installation works

**Tasks:**
- Add Sparkle dependency
- Configure appcast
- Implement update check
- Test update flow
- Document release process

**Estimate:** 4 hours

---

### E15-S5: Create Release Workflow
**As a** developer
**I want** automated releases
**So that** shipping is easy

**Acceptance Criteria:**
- [ ] Triggered by version tag
- [ ] Builds release archive
- [ ] Notarizes and staples
- [ ] Creates GitHub release
- [ ] Updates appcast

**Tasks:**
- Create release workflow
- Add all steps
- Test with test release
- Document process
- Create release checklist

**Estimate:** 4 hours

---

# BACKLOG SUMMARY

## Story Count by Epic

| Epic | Stories | Points (Est.) |
|------|---------|---------------|
| E0: Foundation | 8 | 20 |
| E1: Audio Capture | 7 | 32 |
| E2: Audio Setup Wizard | 6 | 22 |
| E3: OpenAI Integration | 8 | 35 |
| E4: Session Management | 7 | 33 |
| E5: Transcript Display | 6 | 23 |
| E6: Coaching Engine | 8 | 30 |
| E7: Topic Awareness | 5 | 17 |
| E8: Insight Flagging | 5 | 17 |
| E9: Export System | 5 | 14 |
| E10: Post-Session Summary | 5 | 17 |
| E11: Settings & Preferences | 5 | 16 |
| E12: Consent & Templates | 4 | 13 |
| E13: Accessibility | 6 | 28 |
| E14: Testing & Quality | 6 | 22 |
| E15: Distribution & CI/CD | 5 | 20 |
| **TOTAL** | **96** | **359** |

## Parallel Track Summary

| Track | Epics | Can Start | Dependencies |
|-------|-------|-----------|--------------|
| A | E0, E15 | Day 1 | None |
| B | E1, E3 | Day 1 | None |
| C | E2 | After E1 | E1 |
| D | E4 | After E1, E3 | E1, E3 |
| E | E5, E8 | After E4 | E4 |
| F | E6, E7 | After E4 | E4 |
| G | E9, E10 | After E4 | E4 |
| H | E11, E12 | Day 1 | None |
| I | E13 | Continuous | Cross-cutting |
| J | E14 | Continuous | Cross-cutting |

## Agent Assignment Recommendations

| Track | Recommended Agent | Skills Needed |
|-------|-------------------|---------------|
| A | DevOps Agent | Xcode, CI/CD, signing |
| B | Backend Agent | Audio, networking, async |
| C | Frontend Agent | SwiftUI, UX flows |
| D | Architect Agent | State machines, coordination |
| E | Frontend Agent | SwiftUI, lists, navigation |
| F | AI/ML Agent | Prompts, thresholds, timing |
| G | Engineer Agent | Data formatting, export |
| H | Frontend Agent | SwiftUI, forms, preferences |
| I | A11y Agent | Accessibility, VoiceOver |
| J | QA Agent | Testing, coverage, automation |

---

**BACKLOG READY FOR AGENT REVIEW**
