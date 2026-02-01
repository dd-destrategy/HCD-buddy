# Product Backlog — Agent Review

**Date:** February 1, 2026
**Reviewers:** PM, Architect, Engineer, QA, Frontend, DevOps, A11y, AI/ML
**Purpose:** Validate backlog completeness, estimates, and parallel execution plan

---

## Review Summary

| Agent | Verdict | Key Feedback |
|-------|---------|--------------|
| 🎯 PM | ✅ Approved | Add prioritization within epics |
| 🏗️ Architect | ✅ Approved | Add explicit interface stories |
| 💻 Engineer | ✅ Approved | Some estimates are optimistic |
| 🧪 QA | ✅ Approved | Testing should start earlier |
| 🌐 Frontend | ✅ Approved | Add design review gates |
| 📦 DevOps | ✅ Approved | CI must be first |
| ♿ A11y | ✅ Approved | Integrate into every epic |
| 🤖 AI/ML | ✅ Approved | Add prompt tuning stories |

**Overall Verdict: ✅ APPROVED with refinements**

---

## 🎯 PM Review

### Completeness Check

| Requirement | Covered? | Stories |
|-------------|----------|---------|
| Audio Setup Wizard | ✅ | E2-S1 through E2-S6 |
| Real-Time Transcription | ✅ | E3, E5 |
| Coaching Prompts | ✅ | E6-S1 through E6-S8 |
| Topic Awareness | ✅ | E7-S1 through E7-S5 |
| Insight Flagging | ✅ | E8-S1 through E8-S5 |
| Session Management | ✅ | E4-S1 through E4-S7 |
| Export | ✅ | E9-S1 through E9-S5 |
| Consent Templates | ✅ | E12-S1 through E12-S4 |
| Post-Session Summary | ✅ | E10-S1 through E10-S5 |

**All P0 features are covered. ✅**

### Feedback

1. **Add MoSCoW prioritization within epics.** Not all stories are equal — some are must-have for MVP, others can slip.

2. **Add story for first-run experience.** The flow from install to first session needs explicit attention.

3. **Add story for error messaging.** User-facing error messages need design and copy.

### Proposed Additions

```
E0-S9: Implement First-Run Detection
- Detect first launch
- Route to appropriate flow (setup wizard vs main)
- Track onboarding completion

E4-S8: Implement Error Messaging System
- Define error message patterns
- Create error display component
- Map errors to user-friendly messages
```

### Verdict: ✅ Approved with additions

---

## 🏗️ Architect Review

### Architecture Alignment Check

| Pattern | Implemented? | Stories |
|---------|--------------|---------|
| Protocol-first design | ✅ | E1-S1, E3-S1, E4-S1, E6-S1, E9-S1 |
| State machine | ✅ | E4-S2 |
| Dependency injection | ⚠️ Implicit | Add explicit story |
| Error handling | ⚠️ Implicit | Add explicit story |
| Logging architecture | ⚠️ Implicit | Add explicit story |

### Feedback

1. **Add explicit DI setup story.** How services are injected affects testability.

2. **Add logging infrastructure story.** Consistent logging is critical for debugging.

3. **Add explicit error type story.** Error handling architecture should be in E0.

4. **Dependency graph is correct.** The parallel tracks are well-designed.

### Proposed Additions

```
E0-S10: Implement Dependency Container
- Create ServiceContainer
- Register all services
- Inject via environment
- Support test overrides

E0-S11: Implement Logging Infrastructure
- Create Logger protocol
- Implement OSLog-based logger
- Add log levels
- Add structured logging

E0-S12: Define Error Types
- Create HCDError enum
- Define all error categories
- Add user-facing message mapping
- Add recovery suggestions
```

### Verdict: ✅ Approved with additions

---

## 💻 Engineer Review

### Estimate Review

| Epic | Estimated | Realistic? | Notes |
|------|-----------|------------|-------|
| E0 | 20h | ✅ Yes | Foundational, well-scoped |
| E1 | 32h | ⚠️ Optimistic | Audio is tricky, add 20% buffer |
| E2 | 22h | ✅ Yes | Straightforward UI |
| E3 | 35h | ⚠️ Optimistic | API integration has unknowns |
| E4 | 33h | ✅ Yes | Complex but well-defined |
| E5 | 23h | ✅ Yes | Standard SwiftUI |
| E6 | 30h | ✅ Yes | Logic-heavy, testable |
| E7 | 17h | ✅ Yes | Simpler than E6 |
| E8 | 17h | ✅ Yes | Similar to E7 |
| E9 | 14h | ✅ Yes | Straightforward |
| E10 | 17h | ✅ Yes | Depends on API |
| E11 | 16h | ✅ Yes | Standard settings |
| E12 | 13h | ✅ Yes | Mostly static content |
| E13 | 28h | ⚠️ Optimistic | A11y always takes longer |
| E14 | 22h | ✅ Yes | Infrastructure |
| E15 | 20h | ⚠️ Optimistic | Signing can be tricky |

**Total Estimate:** 359 hours
**With 20% buffer on flagged items:** ~400 hours
**At 40 hours/week:** ~10 weeks of coding

### Feedback

1. **E1 and E3 should have spike stories.** Unknown complexity warrants exploration first.

2. **Add buffer stories.** Each epic should have a "polish and bug fixes" buffer.

3. **Some stories are too large.** E1-S4 (8 hours) should be split.

### Proposed Changes

```
E1-S0: Audio Capture Spike (NEW)
- Explore AVAudioEngine with BlackHole
- Document findings
- Identify risks
Estimate: 4 hours

E3-S0: API Integration Spike (NEW)
- Test SwiftOpenAI with Realtime API
- Document event flow
- Identify edge cases
Estimate: 4 hours

Split E1-S4 into:
- E1-S4a: Set up AVAudioEngine (4h)
- E1-S4b: Implement format conversion (4h)
```

### Verdict: ✅ Approved with changes

---

## 🧪 QA Review

### Test Coverage Analysis

| Epic | Test Stories | Coverage Goal | Achievable? |
|------|--------------|---------------|-------------|
| E0 | E0-S3, E0-S5 tests mentioned | 80% | ✅ Yes |
| E1 | E1-S7 dedicated | 80% | ✅ Yes |
| E2 | UI tests mentioned | 60% | ✅ Yes |
| E3 | E3-S8 dedicated | 80% | ✅ Yes |
| E4 | Tests mentioned | 70% | ✅ Yes |
| E5 | UI tests mentioned | 60% | ✅ Yes |
| E6 | E6-S8 dedicated | 80% | ✅ Yes |
| E7 | Tests mentioned | 70% | ✅ Yes |
| E8 | Tests mentioned | 70% | ✅ Yes |
| E9 | Tests mentioned | 70% | ✅ Yes |
| E10 | Tests mentioned | 60% | ✅ Yes |
| E11 | Tests mentioned | 60% | ✅ Yes |
| E12 | Tests mentioned | 60% | ✅ Yes |

### Feedback

1. **E14 should start on Day 1.** Test infrastructure is foundational.

2. **Add acceptance test story for each epic.** E2E tests that verify epic completion.

3. **Add regression test story.** Tests that run before each release.

4. **Mock API server should be in E0.** It's foundational for all API tests.

### Proposed Additions

```
E0-S13: Create Mock API Server
- WebSocket mock server
- Configurable responses
- Supports all event types
- Usable in tests

E14-S7: Create Epic Acceptance Tests
- One E2E test per epic
- Verifies happy path
- Runs in CI

E14-S8: Create Release Regression Suite
- All critical paths
- Runs before release
- < 10 minute runtime
```

### Verdict: ✅ Approved with additions

---

## 🌐 Frontend Review

### UI Story Analysis

| Epic | UI Stories | Design Dependency | Notes |
|------|------------|-------------------|-------|
| E0 | E0-S6, E0-S8 | Design system | Foundational |
| E2 | All | Wizard design | Needs mockups |
| E4 | E4-S4, E4-S5, E4-S6 | Session UI | Needs mockups |
| E5 | All | Transcript design | Needs mockups |
| E6 | E6-S5, E6-S6 | Prompt design | Needs mockups |
| E7 | E7-S1, E7-S2 | Topic panel | Needs mockups |
| E8 | E8-S1, E8-S5 | Insight panel | Needs mockups |
| E10 | E10-S1, E10-S3 | Summary design | Needs mockups |
| E11 | All | Settings design | Standard |

### Feedback

1. **Add design review gates.** Each UI epic should have design approval before coding.

2. **E0-S6 needs more detail.** Design tokens need specification beyond just files.

3. **Add component documentation.** Each component should have preview and docs.

4. **View model stories missing.** Some views will need complex state — add VM stories.

### Proposed Additions

```
E0-S14: Create Component Preview Catalog
- Preview for each component
- All states shown
- Accessible via Xcode

E5-S7: Create TranscriptViewModel
- Manages scroll state
- Handles search
- Manages speaker edits
Estimate: 4 hours

E6-S9: Create CoachingViewModel
- Manages prompt state
- Handles timing
- Coordinates with service
Estimate: 3 hours
```

### Design Gates

| Epic | Gate | Approval Needed |
|------|------|-----------------|
| E2 | Wizard mockups approved | Before E2-S1 |
| E4 | Session UI mockups approved | Before E4-S4 |
| E5 | Transcript mockups approved | Before E5-S1 |
| E6 | Coaching prompt mockups approved | Before E6-S5 |
| E10 | Summary mockups approved | Before E10-S1 |

### Verdict: ✅ Approved with gates

---

## 📦 DevOps Review

### CI/CD Analysis

| Story | Blocks Others? | Priority |
|-------|----------------|----------|
| E15-S1: GitHub Actions | Yes | CRITICAL - Day 1 |
| E15-S2: Code Signing | No | Week 8 |
| E15-S3: Notarization | No | Week 8 |
| E15-S4: Sparkle | No | Week 9 |
| E15-S5: Release Workflow | No | Week 9 |

### Feedback

1. **E15-S1 must be Day 1.** CI is foundational — every other story depends on it.

2. **Add secrets management story.** API keys in CI need secure handling.

3. **Add branch protection story.** Main branch should require passing CI.

4. **Reorder E15.** Only E15-S1 is Phase 0; rest is Phase 3+.

### Proposed Reordering

```
Phase 0 (Week 1):
- E15-S1: GitHub Actions (Day 1)
- E15-S6: Branch Protection (NEW)
- E15-S7: Secrets Management (NEW)

Phase 3 (Week 8-9):
- E15-S2: Code Signing
- E15-S3: Notarization
- E15-S4: Sparkle
- E15-S5: Release Workflow
```

### Proposed Additions

```
E15-S6: Configure Branch Protection
- Require CI pass
- Require review (if team)
- Prevent force push to main
Estimate: 1 hour

E15-S7: Configure Secrets Management
- Store signing certificates
- Store notarization credentials
- Document rotation process
Estimate: 2 hours
```

### Verdict: ✅ Approved with reordering

---

## ♿ A11y Review

### Accessibility Coverage

| Epic | A11y Stories | Integrated? | Notes |
|------|--------------|-------------|-------|
| E0 | None | ❌ | Need design token a11y |
| E2 | None explicit | ❌ | Wizard needs a11y |
| E4 | E4-S6 mentions a11y | ⚠️ Partial | |
| E5 | E5-S6 dedicated | ✅ | Good |
| E6 | E6-S5 mentions | ⚠️ Partial | |
| E7 | None explicit | ❌ | Topic panel needs a11y |
| E8 | E8-S5 mentions | ⚠️ Partial | |
| E10 | None explicit | ❌ | Summary needs a11y |
| E11 | None explicit | ❌ | Settings needs a11y |
| E13 | All | ✅ | Dedicated epic |

### Feedback

1. **A11y must be integrated, not separate.** Every UI story should include a11y acceptance criteria.

2. **E13 should be parallel, not sequential.** A11y work should happen alongside UI work.

3. **Add a11y acceptance criteria to every UI story.** Not as separate stories.

### Proposed Changes

Add to every UI story's acceptance criteria:
```
Accessibility:
- [ ] Keyboard navigable
- [ ] VoiceOver labels present
- [ ] Focus indicators visible
- [ ] No color-only information
```

### Updated UI Stories (Examples)

```
E2-S1: Create Wizard Container View
Acceptance Criteria:
...existing criteria...
Accessibility:
- [ ] Tab navigates between steps
- [ ] Progress announced to VoiceOver
- [ ] Focus moves to first element on step change
- [ ] Escape dismisses with confirmation

E5-S1: Create Transcript Container View
Acceptance Criteria:
...existing criteria...
Accessibility:
- [ ] Arrow keys navigate utterances
- [ ] New utterances announced
- [ ] Scroll position announced
- [ ] No keyboard traps
```

### Verdict: ✅ Approved with integrated criteria

---

## 🤖 AI/ML Review

### AI Integration Coverage

| Feature | Stories | Complete? |
|---------|---------|-----------|
| System prompt | E3-S3 | ✅ |
| Function definitions | E3-S3 | ✅ |
| Transcription handling | E3-S5 | ✅ |
| Coaching timing | E6-S3 | ✅ |
| Coaching thresholds | E6-S2 | ✅ |
| Topic updates | E7-S3 | ✅ |
| Insight flagging | E8-S2 | ✅ |
| Post-session reflection | E10-S2 | ✅ |

### Feedback

1. **Add prompt versioning story.** System prompts need version control.

2. **Add threshold tuning story.** Thresholds need iteration based on testing.

3. **Add shadow logging story.** Log what AI would have done (suppressed prompts).

4. **Add A/B testing infrastructure.** Future prompt testing needs foundation.

### Proposed Additions

```
E6-S10: Implement Prompt Versioning
- Version string in prompt
- Log version per session
- Support multiple versions
Estimate: 2 hours

E6-S11: Implement Shadow Logging
- Log suppressed prompts
- Include suppression reason
- Include what would have been shown
- Queryable for analysis
Estimate: 3 hours

E3-S9: Create Prompt Configuration System
- System prompts in config file
- Runtime prompt selection
- Validation of prompt format
Estimate: 3 hours
```

### Threshold Tuning Plan

| Threshold | Initial | How to Tune |
|-----------|---------|-------------|
| Confidence | 0.85 | Review suppressed prompts |
| Cooldown | 120s | User feedback on frequency |
| Post-speech delay | 5s | Timing feedback |
| Max prompts | 3 | Session-level feedback |

### Verdict: ✅ Approved with additions

---

## Consolidated Additions

### New Stories to Add

| ID | Story | Epic | Estimate |
|----|-------|------|----------|
| E0-S9 | First-Run Detection | E0 | 2h |
| E0-S10 | Dependency Container | E0 | 3h |
| E0-S11 | Logging Infrastructure | E0 | 3h |
| E0-S12 | Error Types | E0 | 2h |
| E0-S13 | Mock API Server | E0 | 4h |
| E0-S14 | Component Preview Catalog | E0 | 3h |
| E1-S0 | Audio Capture Spike | E1 | 4h |
| E3-S0 | API Integration Spike | E3 | 4h |
| E3-S9 | Prompt Configuration | E3 | 3h |
| E4-S8 | Error Messaging System | E4 | 4h |
| E5-S7 | TranscriptViewModel | E5 | 4h |
| E6-S9 | CoachingViewModel | E6 | 3h |
| E6-S10 | Prompt Versioning | E6 | 2h |
| E6-S11 | Shadow Logging | E6 | 3h |
| E14-S7 | Epic Acceptance Tests | E14 | 6h |
| E14-S8 | Release Regression Suite | E14 | 4h |
| E15-S6 | Branch Protection | E15 | 1h |
| E15-S7 | Secrets Management | E15 | 2h |

**Total New Estimates:** 57 hours
**Revised Total:** 359 + 57 = **416 hours**

### Stories to Split

| Original | Split Into |
|----------|------------|
| E1-S4 (8h) | E1-S4a (4h), E1-S4b (4h) |

### Acceptance Criteria Updates

Add accessibility criteria to all UI stories:
- E2-S1 through E2-S6
- E4-S4 through E4-S6
- E5-S1 through E5-S5
- E6-S5, E6-S6
- E7-S1, E7-S2, E7-S4
- E8-S1, E8-S4, E8-S5
- E10-S1, E10-S3
- E11-S1 through E11-S5

### Design Gates Required

| Gate | Before Story | Deliverable |
|------|--------------|-------------|
| DG-1 | E2-S1 | Wizard mockups |
| DG-2 | E4-S4 | Session UI mockups |
| DG-3 | E5-S1 | Transcript mockups |
| DG-4 | E6-S5 | Coaching prompt mockups |
| DG-5 | E7-S1 | Topic panel mockups |
| DG-6 | E8-S1 | Insight panel mockups |
| DG-7 | E10-S1 | Summary mockups |

---

## Final Parallel Track Assignment

| Track | Epics | Agent Type | Can Start |
|-------|-------|------------|-----------|
| **A: Foundation** | E0, E15 (partial) | DevOps + Engineer | Day 1 |
| **B: Audio** | E1 | Engineer (Audio) | Day 1 |
| **C: API** | E3 | Engineer (Backend) | Day 1 |
| **D: Wizard** | E2 | Frontend | After E1 |
| **E: Session** | E4 | Architect | After E1 + E3 |
| **F: Transcript** | E5, E8 | Frontend | After E4 |
| **G: Coaching** | E6, E7 | AI/ML + Frontend | After E4 |
| **H: Export** | E9, E10 | Engineer | After E4 |
| **I: Settings** | E11, E12 | Frontend | Day 1 |
| **J: Quality** | E14 | QA | Day 1 (parallel) |
| **K: A11y** | E13 | A11y | Continuous |

### Week 1 Parallel Execution

```
Day 1:
├── Track A: E0-S1 (Project), E0-S2 (SwiftLint), E15-S1 (CI)
├── Track B: E1-S0 (Spike), E1-S1 (Protocols)
├── Track C: E3-S0 (Spike), E3-S1 (Protocols)
├── Track I: E11-S1 (Settings Window), E12-S1 (Template System)
└── Track J: E14-S1 (Unit Testing Setup)

Day 2-3:
├── Track A: E0-S3 (SwiftData), E0-S4 (Models), E0-S5 (Keychain)
├── Track B: E1-S2 (BlackHole Detection), E1-S3 (Multi-Output Detection)
├── Track C: E3-S2 (API Client), E3-S3 (Session Config)
├── Track I: E12-S2 (Built-in Templates), E12-S3 (Consent Templates)
└── Track J: E14-S2 (Integration Testing Setup)

Day 4-5:
├── Track A: E0-S6 (Design System), E0-S7 (SwiftOpenAI), E0-S8 (App Entry)
├── Track B: E1-S4a (AVAudioEngine), E1-S4b (Format Conversion)
├── Track C: E3-S4 (Audio Streaming), E3-S5 (Transcription Events)
├── Track I: E11-S2 (General Settings), E12-S4 (Mode Selector)
└── Track J: E14-S3 (UI Testing Setup)
```

---

## Backlog Metrics

| Metric | Value |
|--------|-------|
| Total Epics | 15 |
| Total Stories | 114 (96 original + 18 new) |
| Total Estimate | 416 hours |
| Parallel Tracks | 11 |
| Design Gates | 7 |
| Critical Path | E0 → E1/E3 → E4 → E5/E6 → E10 |

---

## Review Verdict

**All agents approve the backlog with the proposed additions and changes.**

| Agent | Approved | Additions Required |
|-------|----------|-------------------|
| 🎯 PM | ✅ | 2 stories |
| 🏗️ Architect | ✅ | 3 stories |
| 💻 Engineer | ✅ | 3 stories (+ splits) |
| 🧪 QA | ✅ | 3 stories |
| 🌐 Frontend | ✅ | 3 stories + gates |
| 📦 DevOps | ✅ | 2 stories + reorder |
| ♿ A11y | ✅ | Criteria updates |
| 🤖 AI/ML | ✅ | 4 stories |

---

**BACKLOG APPROVED. READY FOR PARALLEL AGENT DEPLOYMENT.**
