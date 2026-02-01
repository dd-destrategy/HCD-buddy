# Agent Swarm Deployment Plan

**Strategy:** Maximum parallelism with coordinated waves
**Total Agents:** Up to 15 concurrent (one per epic)
**Coordination:** Dependency-based wave execution

---

## Swarm Architecture

```
                            WAVE 1 (Day 1 - No Dependencies)
    ┌─────────────────────────────────────────────────────────────────┐
    │                                                                 │
    │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐            │
    │  │ Agent   │  │ Agent   │  │ Agent   │  │ Agent   │            │
    │  │   E0    │  │   E1    │  │   E3    │  │  E11    │            │
    │  │Foundation│ │ Audio   │  │  API    │  │Settings │            │
    │  └────┬────┘  └────┬────┘  └────┬────┘  └─────────┘            │
    │       │            │            │                               │
    │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐            │
    │  │ Agent   │  │ Agent   │  │ Agent   │  │ Agent   │            │
    │  │  E12    │  │  E14    │  │  E15    │  │  E13    │            │
    │  │Templates│  │ Testing │  │  CI/CD  │  │  A11y   │            │
    │  └─────────┘  └─────────┘  └─────────┘  └─────────┘            │
    │                                                                 │
    └─────────────────────────────────────────────────────────────────┘
                          │            │
                          ▼            ▼
                    WAVE 2 (After E1 + E3 complete)
    ┌─────────────────────────────────────────────────────────────────┐
    │                                                                 │
    │  ┌─────────┐  ┌─────────┐                                      │
    │  │ Agent   │  │ Agent   │                                      │
    │  │   E2    │  │   E4    │                                      │
    │  │ Wizard  │  │ Session │                                      │
    │  └─────────┘  └────┬────┘                                      │
    │                    │                                            │
    └────────────────────┼────────────────────────────────────────────┘
                         │
                         ▼
                    WAVE 3 (After E4 completes)
    ┌─────────────────────────────────────────────────────────────────┐
    │                                                                 │
    │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐            │
    │  │ Agent   │  │ Agent   │  │ Agent   │  │ Agent   │            │
    │  │   E5    │  │   E6    │  │   E7    │  │   E8    │            │
    │  │Transcript│ │Coaching │  │ Topics  │  │Insights │            │
    │  └─────────┘  └─────────┘  └─────────┘  └─────────┘            │
    │                                                                 │
    │  ┌─────────┐  ┌─────────┐                                      │
    │  │ Agent   │  │ Agent   │                                      │
    │  │   E9    │  │  E10    │                                      │
    │  │ Export  │  │ Summary │                                      │
    │  └─────────┘  └─────────┘                                      │
    │                                                                 │
    └─────────────────────────────────────────────────────────────────┘
```

---

## Wave Definitions

### Wave 1: Foundation (8 Agents)
**Start:** Immediately
**Dependencies:** None

| Agent ID | Epic | Focus | Stories |
|----------|------|-------|---------|
| `agent-e0` | E0: Foundation | Project setup, models, design system | 14 |
| `agent-e1` | E1: Audio Capture | Audio protocols, detection, capture | 8 |
| `agent-e3` | E3: OpenAI Integration | API client, streaming, events | 10 |
| `agent-e11` | E11: Settings | Settings UI, preferences | 5 |
| `agent-e12` | E12: Consent & Templates | Template system, consent | 4 |
| `agent-e14` | E14: Testing | Test infrastructure | 8 |
| `agent-e15` | E15: CI/CD | GitHub Actions, signing | 7 |
| `agent-e13` | E13: Accessibility | A11y infrastructure | 6 |

**Total Stories:** 62
**Parallel Agents:** 8

---

### Wave 2: Core Systems (2 Agents)
**Start:** When E1 completes (for E2) and E1+E3 complete (for E4)
**Trigger:** Wave 1 blocking epics done

| Agent ID | Epic | Focus | Blocked By | Stories |
|----------|------|-------|------------|---------|
| `agent-e2` | E2: Audio Setup Wizard | Setup UI, verification | E1 | 6 |
| `agent-e4` | E4: Session Management | State machine, lifecycle | E1, E3 | 8 |

**Total Stories:** 14
**Parallel Agents:** 2 (joins existing Wave 1 agents still running)

---

### Wave 3: Features (6 Agents)
**Start:** When E4 completes
**Trigger:** Session management ready

| Agent ID | Epic | Focus | Blocked By | Stories |
|----------|------|-------|------------|---------|
| `agent-e5` | E5: Transcript Display | Transcript UI, search | E4 | 7 |
| `agent-e6` | E6: Coaching Engine | Timing, prompts, thresholds | E4 | 11 |
| `agent-e7` | E7: Topic Awareness | Topic tracking UI | E4 | 5 |
| `agent-e8` | E8: Insight Flagging | Insight capture, UI | E4 | 5 |
| `agent-e9` | E9: Export System | Markdown, JSON export | E4 | 5 |
| `agent-e10` | E10: Post-Session Summary | Summary UI, reflection | E4 | 5 |

**Total Stories:** 38
**Parallel Agents:** 6

---

## Agent Specifications

### Agent Template

Each agent receives:
1. **Epic assignment** — Which epic to complete
2. **Story list** — All stories in the epic
3. **Acceptance criteria** — Per-story requirements
4. **Dependencies** — What must exist before starting
5. **Interfaces** — Protocols/types to implement or consume
6. **Test requirements** — Coverage and test types needed

### Agent Prompts

#### Wave 1 Agents

```yaml
agent-e0:
  type: "Architect + Engineer"
  epic: "E0: Foundation & Setup"
  goal: "Set up project structure, models, and design system"
  stories: [E0-S1 through E0-S14]
  outputs:
    - Xcode project with folder structure
    - SwiftData models
    - Design system tokens
    - Keychain service
    - Logging infrastructure
    - Error types
  test_coverage: 80%

agent-e1:
  type: "Engineer (Audio)"
  epic: "E1: Audio Capture System"
  goal: "Implement audio capture from system and microphone"
  stories: [E1-S0 through E1-S7]
  outputs:
    - AudioCapturing protocol
    - BlackHole detection
    - Multi-Output detection
    - Audio capture engine
    - Level metering
  test_coverage: 80%

agent-e3:
  type: "Engineer (Backend)"
  epic: "E3: OpenAI Integration"
  goal: "Implement OpenAI Realtime API client"
  stories: [E3-S0 through E3-S9]
  outputs:
    - RealtimeAPIConnecting protocol
    - API client wrapper
    - Audio streaming
    - Event handling
    - Function call parsing
  test_coverage: 80%

agent-e11:
  type: "Frontend"
  epic: "E11: Settings & Preferences"
  goal: "Build settings interface"
  stories: [E11-S1 through E11-S5]
  outputs:
    - Settings window
    - All preference panes
    - API key management
  test_coverage: 60%

agent-e12:
  type: "Frontend"
  epic: "E12: Consent & Templates"
  goal: "Build template and consent system"
  stories: [E12-S1 through E12-S4]
  outputs:
    - Template model and built-ins
    - Consent template display
    - Mode selector
  test_coverage: 60%

agent-e14:
  type: "QA"
  epic: "E14: Testing & Quality"
  goal: "Set up test infrastructure"
  stories: [E14-S1 through E14-S8]
  outputs:
    - Unit test target
    - Integration test target
    - UI test target
    - Mock API server
    - Coverage reporting
  test_coverage: N/A (meta)

agent-e15:
  type: "DevOps"
  epic: "E15: Distribution & CI/CD"
  goal: "Set up CI/CD pipeline"
  stories: [E15-S1 through E15-S7]
  outputs:
    - GitHub Actions workflow
    - Code signing configuration
    - Notarization setup
    - Sparkle integration
  test_coverage: N/A (infrastructure)

agent-e13:
  type: "A11y"
  epic: "E13: Accessibility"
  goal: "Implement accessibility infrastructure"
  stories: [E13-S1 through E13-S6]
  outputs:
    - Keyboard navigation patterns
    - VoiceOver utilities
    - Focus management
    - Accessibility audit
  test_coverage: 70%
```

#### Wave 2 Agents

```yaml
agent-e2:
  type: "Frontend"
  epic: "E2: Audio Setup Wizard"
  goal: "Build audio setup wizard"
  depends_on: [agent-e1]
  consumes:
    - AudioCapturing protocol from E1
    - Detection functions from E1
  stories: [E2-S1 through E2-S6]
  outputs:
    - 6-step wizard UI
    - Verification flow
    - Configuration storage
  test_coverage: 60%

agent-e4:
  type: "Architect"
  epic: "E4: Session Management"
  goal: "Build session state machine and manager"
  depends_on: [agent-e1, agent-e3]
  consumes:
    - AudioCapturing from E1
    - RealtimeAPIConnecting from E3
  stories: [E4-S1 through E4-S8]
  outputs:
    - SessionManaging protocol
    - State machine
    - SessionManager implementation
    - Session UI components
  test_coverage: 70%
```

#### Wave 3 Agents

```yaml
agent-e5:
  type: "Frontend"
  epic: "E5: Transcript Display"
  goal: "Build transcript view"
  depends_on: [agent-e4]
  consumes:
    - Session model from E4
    - Utterance stream from E4
  stories: [E5-S1 through E5-S7]
  outputs:
    - TranscriptView
    - UtteranceRowView
    - Speaker toggle
    - Search functionality
  test_coverage: 60%

agent-e6:
  type: "AI/ML + Frontend"
  epic: "E6: Coaching Engine"
  goal: "Build silence-first coaching system"
  depends_on: [agent-e4]
  consumes:
    - Session state from E4
    - Function calls from E3
  stories: [E6-S1 through E6-S11]
  outputs:
    - CoachingEngine
    - Timing rules
    - Coaching prompt UI
    - Shadow logging
  test_coverage: 80%

agent-e7:
  type: "Frontend"
  epic: "E7: Topic Awareness"
  goal: "Build topic tracking UI"
  depends_on: [agent-e4]
  consumes:
    - Session model from E4
    - Topic updates from E3
  stories: [E7-S1 through E7-S5]
  outputs:
    - TopicPanelView
    - Status display
    - Manual adjustment
  test_coverage: 70%

agent-e8:
  type: "Frontend"
  epic: "E8: Insight Flagging"
  goal: "Build insight capture system"
  depends_on: [agent-e4]
  consumes:
    - Session model from E4
    - Insight events from E3
  stories: [E8-S1 through E8-S5]
  outputs:
    - InsightsPanelView
    - Auto-flagging handler
    - Manual flagging
  test_coverage: 70%

agent-e9:
  type: "Engineer"
  epic: "E9: Export System"
  goal: "Build export functionality"
  depends_on: [agent-e4]
  consumes:
    - Session model from E4
  stories: [E9-S1 through E9-S5]
  outputs:
    - SessionExporter protocol
    - Markdown exporter
    - JSON exporter
    - Export UI
  test_coverage: 70%

agent-e10:
  type: "Frontend + AI/ML"
  epic: "E10: Post-Session Summary"
  goal: "Build post-session summary"
  depends_on: [agent-e4, agent-e6]
  consumes:
    - Session model from E4
    - Coaching data from E6
  stories: [E10-S1 through E10-S5]
  outputs:
    - PostSessionSummaryView
    - AI reflection generation
    - Summary persistence
  test_coverage: 60%
```

---

## Coordination Protocol

### Interface Contracts

Before Wave 2 agents start, Wave 1 agents must publish:

```swift
// From agent-e1 (Audio)
protocol AudioCapturing {
    var audioStream: AsyncStream<AudioChunk> { get }
    var audioLevels: AudioLevels { get }
    func start() throws
    func stop()
    func pause()
    func resume()
}

func detectBlackHole() -> BlackHoleStatus
func detectMultiOutputDevice() -> MultiOutputStatus

// From agent-e3 (API)
protocol RealtimeAPIConnecting {
    var connectionState: ConnectionState { get }
    var transcriptionStream: AsyncStream<TranscriptionEvent> { get }
    var functionCallStream: AsyncStream<FunctionCallEvent> { get }
    func connect(with config: SessionConfig) async throws
    func send(audio: AudioChunk) async throws
    func disconnect() async
}
```

Before Wave 3 agents start, Wave 2 agents must publish:

```swift
// From agent-e4 (Session)
protocol SessionManaging {
    var currentSession: Session? { get }
    var state: SessionState { get }
    var utteranceStream: AsyncStream<Utterance> { get }
    func createSession(config: SessionConfig) async throws -> Session
    func startSession() async throws
    func pauseSession() async
    func resumeSession() async
    func endSession() async throws -> SessionSummary
}
```

### Handoff Protocol

```
1. Agent completes epic
2. Agent pushes to feature branch: epic/E{N}-{name}
3. Agent creates PR with:
   - Summary of implemented stories
   - Interface documentation
   - Test coverage report
   - Known limitations
4. Coordinator merges to main
5. Dependent agents pull latest main
6. Dependent agents begin work
```

### Communication Channels

```
Shared Context:
- /Core/Protocols/ — All interface definitions
- /Core/Models/ — All data models
- /DesignSystem/ — All UI tokens
- /Tests/Mocks/ — All mock implementations

Handoff Artifacts:
- INTERFACE_E{N}.md — Protocol documentation
- COVERAGE_E{N}.md — Test coverage report
- KNOWN_ISSUES_E{N}.md — Limitations and TODOs
```

---

## Execution Timeline

### Parallel Execution View

```
Day 1-2:
├── agent-e0:  [████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░]
├── agent-e1:  [████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░]
├── agent-e3:  [████████████████░░░░░░░░░░░░░░░░░░░░░░░░]
├── agent-e11: [████████████████████░░░░░░░░░░░░░░░░░░░░]
├── agent-e12: [████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░]
├── agent-e14: [████████████████████░░░░░░░░░░░░░░░░░░░░]
├── agent-e15: [████████████████░░░░░░░░░░░░░░░░░░░░░░░░]
└── agent-e13: [████████████████████████░░░░░░░░░░░░░░░░]

Day 3-4 (E1 completes, E2 starts):
├── agent-e0:  [░░░░░░░░████████████░░░░░░░░░░░░░░░░░░░░] (finishing)
├── agent-e1:  [░░░░░░░░░░░░████████] DONE → handoff
├── agent-e2:  [                    ████████████████░░░░] STARTED
├── agent-e3:  [░░░░░░░░░░░░░░░░████████████░░░░░░░░░░░░]
├── agent-e4:  [                    ████████████████████] STARTED (after E1+E3)
└── ... (others continue)

Day 5-6 (E4 completes, Wave 3 starts):
├── agent-e4:  [░░░░░░░░░░░░░░░░░░░░████████████████████] DONE → handoff
├── agent-e5:  [                                        ████████████████]
├── agent-e6:  [                                        ████████████████████]
├── agent-e7:  [                                        ████████████]
├── agent-e8:  [                                        ████████████]
├── agent-e9:  [                                        ████████████]
└── agent-e10: [                                        ████████████████]

Day 7-8 (All agents completing):
├── All Wave 3 agents finishing
├── Integration testing begins
└── Merge all feature branches
```

### Story Velocity

| Wave | Agents | Stories | Hours | Parallel Days |
|------|--------|---------|-------|---------------|
| Wave 1 | 8 | 62 | 250 | 3-4 |
| Wave 2 | 2 | 14 | 56 | 2-3 |
| Wave 3 | 6 | 38 | 110 | 2-3 |
| **Total** | **15** | **114** | **416** | **~8 days** |

**With swarm parallelism: ~8 working days vs ~10 weeks sequential**

---

## Launch Commands

### Deploy Wave 1 (8 Agents Simultaneously)

```bash
# Launch all Wave 1 agents in parallel
claude-agent launch --parallel \
  --agent agent-e0 --epic E0 --prompt "prompts/e0-foundation.md" \
  --agent agent-e1 --epic E1 --prompt "prompts/e1-audio.md" \
  --agent agent-e3 --epic E3 --prompt "prompts/e3-api.md" \
  --agent agent-e11 --epic E11 --prompt "prompts/e11-settings.md" \
  --agent agent-e12 --epic E12 --prompt "prompts/e12-templates.md" \
  --agent agent-e14 --epic E14 --prompt "prompts/e14-testing.md" \
  --agent agent-e15 --epic E15 --prompt "prompts/e15-cicd.md" \
  --agent agent-e13 --epic E13 --prompt "prompts/e13-a11y.md"
```

### Deploy Wave 2 (After E1 + E3 Complete)

```bash
# Launch Wave 2 agents
claude-agent launch --parallel \
  --agent agent-e2 --epic E2 --prompt "prompts/e2-wizard.md" --after agent-e1 \
  --agent agent-e4 --epic E4 --prompt "prompts/e4-session.md" --after agent-e1,agent-e3
```

### Deploy Wave 3 (After E4 Completes)

```bash
# Launch all Wave 3 agents
claude-agent launch --parallel \
  --agent agent-e5 --epic E5 --prompt "prompts/e5-transcript.md" --after agent-e4 \
  --agent agent-e6 --epic E6 --prompt "prompts/e6-coaching.md" --after agent-e4 \
  --agent agent-e7 --epic E7 --prompt "prompts/e7-topics.md" --after agent-e4 \
  --agent agent-e8 --epic E8 --prompt "prompts/e8-insights.md" --after agent-e4 \
  --agent agent-e9 --epic E9 --prompt "prompts/e9-export.md" --after agent-e4 \
  --agent agent-e10 --epic E10 --prompt "prompts/e10-summary.md" --after agent-e4,agent-e6
```

---

## Agent Swarm Configuration

### Recommended Agent Types

| Agent ID | Subagent Type | Model | Rationale |
|----------|---------------|-------|-----------|
| agent-e0 | general-purpose | sonnet | Complex multi-file setup |
| agent-e1 | general-purpose | sonnet | Audio requires exploration |
| agent-e3 | general-purpose | sonnet | API integration complexity |
| agent-e11 | general-purpose | haiku | Straightforward UI |
| agent-e12 | general-purpose | haiku | Simple content |
| agent-e14 | general-purpose | sonnet | Test infrastructure |
| agent-e15 | Bash | sonnet | CI/CD scripting |
| agent-e13 | general-purpose | sonnet | A11y requires attention |
| agent-e2 | general-purpose | sonnet | UI + integration |
| agent-e4 | general-purpose | opus | Critical architecture |
| agent-e5 | general-purpose | sonnet | UI complexity |
| agent-e6 | general-purpose | opus | AI integration critical |
| agent-e7 | general-purpose | haiku | Simpler UI |
| agent-e8 | general-purpose | haiku | Simpler UI |
| agent-e9 | general-purpose | sonnet | Export logic |
| agent-e10 | general-purpose | sonnet | AI + UI |

---

## Success Criteria

### Per-Agent Success

Each agent must deliver:
- [ ] All stories in epic completed
- [ ] Acceptance criteria met
- [ ] Test coverage achieved
- [ ] Interface contracts honored
- [ ] PR created with documentation

### Swarm Success

Overall deployment succeeds when:
- [ ] All 15 agents complete their epics
- [ ] All PRs merged successfully
- [ ] Integration tests pass
- [ ] App builds and runs
- [ ] Core user journey works end-to-end

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Interface mismatch between agents | Define protocols in E0 first, all agents consume |
| Agent blocks on dependency | Wave structure ensures dependencies complete first |
| Merge conflicts | Each agent works in epic-specific files |
| Test failures on integration | E14 agent provides mock implementations |
| Agent produces low quality | Review gate before merge |

---

## Summary

**Swarm Size:** 15 agents (max concurrent: 8 in Wave 1)
**Execution Time:** ~8 working days (vs 10+ weeks sequential)
**Stories Completed:** 114
**Parallelism Factor:** 8x in Wave 1, 6x in Wave 3

**Ready to deploy swarm on your command.**
