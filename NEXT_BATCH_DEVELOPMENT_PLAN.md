# Next Batch Development Plan — Features 9-16

> **Date**: 2026-02-07
> **Branch**: `claude/deploy-feature-evaluation-agents-g5Nna`
> **Prerequisite**: Batch 1 (Features 1-8) implemented and validated

---

## Batch Selection Rationale

With Batch 1 complete (Talk-Time, Question Analysis, Cross-Session Analytics, Focus Modes, Tagging, Session Summary, Follow-Up Suggestions, Demo Mode), the next 8 features were selected based on:

1. **Completing the v1.1 sprint** — Features #15 and #16 were in the original v1.1 scope but not in the top-8 critical path
2. **Ethical compliance** — PII Redaction (#9) and Accessible Consent (#25) are pre-requisites for enterprise adoption
3. **Deepening existing investments** — Highlight Reel (#12) extends Tagging; Cultural Sensitivity (#14) extends Coaching
4. **New user-facing value** — Participant Management (#17) and Emotional Arc (#20) unlock new workflows
5. **Practical implementability** — All 8 features follow established patterns (Codable + JSON persistence, ObservableObject services, SwiftUI views)

---

## The 8 Features

### Feature A: Customizable Coaching Timing & Predictable Mode (#15)
**Effort: Small | Priority: v1.1 completion**

**What it does:**
- User-configurable auto-dismiss duration (5s / 10s / 15s / 30s / manual dismiss)
- "Pull mode" — AI queues prompts silently, researcher pulls on demand via ⌘+C
- Preview mode — shows what *would* trigger without actually displaying
- Coaching history panel — scroll back through missed/dismissed prompts
- Critical for neurodivergent researchers who need predictable timing

**Integration points:**
- Extends `CoachingPreferences` with `autoDismissPreset`, `isPullModeEnabled`, `isPreviewModeEnabled`
- Extends `CoachingService` with pull-mode queue and preview-mode suppression
- Extends `CoachingThresholds` with new preset `.predictable` (manual dismiss, no auto-dismiss)
- New `CoachingHistoryView` shows prompt log from `CoachingEventTracker`

**Files to create:**
| File | Location | Lines (est.) |
|------|----------|-------------|
| `CoachingTimingSettings.swift` | `Features/Coaching/` | ~180 |
| `CoachingHistoryView.swift` | `Features/Coaching/` | ~280 |
| `CoachingTimingSettingsTests.swift` | `Tests/UnitTests/Features/` | ~150 |

**Files to modify:**
| File | Change |
|------|--------|
| `CoachingPreferences.swift` | Add `autoDismissPreset`, `isPullModeEnabled`, `isPreviewModeEnabled` properties |
| `CoachingService.swift` | Add pull-mode queue logic, preview-mode bypass |
| `CoachingThresholds.swift` | Add `.predictable` preset |
| `ContentView.swift` | Wire coaching history into session toolbar |

---

### Feature B: Calendar Integration (#16)
**Effort: Small-Medium | Priority: v1.1 completion**

**What it does:**
- Reads upcoming events from macOS Calendar via EventKit
- Detects interview-like events (keyword matching: "interview", "user research", "usability", etc.)
- Auto-populates session metadata (participant name, project, time) from calendar event
- Pre-session reminder with one-click "Start Session" from upcoming events list
- Builds habit loop and reduces activation energy

**Integration points:**
- New `CalendarService` wraps `EKEventStore` with permission handling
- New `UpcomingInterviewsView` on the session setup screen
- Feeds `SessionConfiguration` with pre-populated template + participant data
- Respects App Sandbox entitlement `com.apple.security.personal-information.calendars`

**Files to create:**
| File | Location | Lines (est.) |
|------|----------|-------------|
| `CalendarService.swift` | `Features/Session/Services/` | ~250 |
| `UpcomingInterviewsView.swift` | `Features/Session/Views/` | ~320 |
| `CalendarServiceTests.swift` | `Tests/UnitTests/Features/` | ~160 |

**Files to modify:**
| File | Change |
|------|--------|
| `ContentView.swift` | Add upcoming interviews section to setup screen |
| `SessionConfiguration` (in ContentView) | Add optional `calendarEventId` field |

**Entitlement required:** `com.apple.security.personal-information.calendars` (read-only)

---

### Feature C: Consent & PII Redaction Engine (#9)
**Effort: Medium | Priority: Ethical compliance — blocks enterprise adoption**

**What it does:**
- Regex + NLP-based PII detection in transcript utterances (names, emails, phone numbers, company names, addresses)
- Inline redaction UI — detected PII highlighted with one-click redact/keep/replace
- Batch redaction mode — scan entire session, review all detections
- Redaction audit log — tracks what was redacted, when, by whom
- Consent status tracking per session (obtained / verbal / written / declined)
- Export respects redaction — redacted text replaced with `[REDACTED]` in markdown/JSON

**Integration points:**
- New `PIIDetector` service with regex patterns + configurable entity types
- New `RedactionService` manages redaction state, persists via JSON (like Tags)
- Extends `MarkdownExporter` and `JSONExporter` to apply redactions during export
- New `ConsentStatus` enum on `Session` model (or lightweight wrapper)
- New `RedactionReviewView` for batch review workflow

**Files to create:**
| File | Location | Lines (est.) |
|------|----------|-------------|
| `PIIDetector.swift` | `Features/Transcript/` | ~350 |
| `RedactionService.swift` | `Features/Transcript/` | ~300 |
| `RedactionReviewView.swift` | `Features/Transcript/` | ~450 |
| `ConsentTracker.swift` | `Features/Session/Services/` | ~150 |
| `PIIDetectorTests.swift` | `Tests/UnitTests/Features/` | ~200 |
| `RedactionServiceTests.swift` | `Tests/UnitTests/Features/` | ~180 |

**Files to modify:**
| File | Change |
|------|--------|
| `MarkdownExporter.swift` | Apply redactions to utterance text before export |
| `ExportService.swift` | Accept optional `RedactionService` for redaction-aware export |

**PII patterns to detect:**
- Email: `[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}`
- Phone: `\b\d{3}[-.]?\d{3}[-.]?\d{4}\b` (US format)
- SSN: `\b\d{3}-\d{2}-\d{4}\b`
- Names: NLP-based using `NSLinguisticTagger` / custom heuristics
- Companies: Dictionary-based + capitalization heuristics

---

### Feature D: Cultural Sensitivity & AI Bias Controls (#14)
**Effort: Medium | Priority: Inclusion — rated Critical by Accessibility agent**

**What it does:**
- Cultural context presets (Western/Direct, East Asian/High-Context, Latin American/Relational, Middle Eastern/Formal, Custom)
- Each preset adjusts: silence tolerance (5s→15s), question pacing expectations, interruption sensitivity, formality level
- AI confidence display on all coaching prompts — shows why the AI suggested something
- "Not helpful" feedback with structured reasons (culturally inappropriate, wrong timing, irrelevant, confusing)
- Coaching explanation mode — expand any prompt to see the AI's reasoning chain
- Bias alert when question patterns show systematic skew

**Integration points:**
- New `CulturalContext` model (Codable struct, JSON persistence)
- Extends `CoachingThresholds` with cultural modifiers (silence tolerance multiplier, formality level)
- Extends `CoachingService` to apply cultural adjustments to cooldown/speech timing
- Extends `CoachingPrompt` with `explanation: String` and `culturalRelevanceScore: Double`
- New `CulturalSettingsView` for configuration
- Extends `QuestionTypeAnalyzer` (from Batch 1) with bias detection across question patterns

**Files to create:**
| File | Location | Lines (est.) |
|------|----------|-------------|
| `CulturalContext.swift` | `Core/Models/` | ~180 |
| `CulturalSettingsView.swift` | `Features/Coaching/` | ~380 |
| `BiasDetector.swift` | `Features/Coaching/` | ~250 |
| `CulturalContextTests.swift` | `Tests/UnitTests/Features/` | ~160 |
| `BiasDetectorTests.swift` | `Tests/UnitTests/Features/` | ~140 |

**Files to modify:**
| File | Change |
|------|--------|
| `CoachingThresholds.swift` | Add cultural modifier fields |
| `CoachingService.swift` | Apply cultural context to timing decisions |
| `CoachingPreferences.swift` | Add `culturalContext` property |
| `QuestionTypeAnalyzer.swift` | Add `detectBias(in:)` method |

---

### Feature E: Highlight Reel & Quote Library (#12)
**Effort: Medium-Large | Priority: Post-session value — rated High by PM + UX Research agents**

**What it does:**
- Select any transcript segment → save as a named "Highlight" with title, category, and notes
- Cross-session Quote Library — searchable collection of all highlights across all sessions
- Categories: Pain Point, User Need, Delight, Workaround, Feature Request, Key Quote
- Full-text search across all saved highlights
- Export as stakeholder-ready markdown report (grouped by category or theme)
- "Star" system for marking top quotes for presentations

**Integration points:**
- New `Highlight` model (Codable struct, JSON persistence — follows Tag pattern)
- New `HighlightService` manages CRUD + search + cross-session queries
- Extends `TaggingService` (Batch 1) — highlights can reference tags
- Extends `ExportService` with highlight export format
- New `QuoteLibraryView` as standalone screen (like CrossSessionAnalyticsView)
- New `HighlightCreatorView` inline component for transcript

**Files to create:**
| File | Location | Lines (est.) |
|------|----------|-------------|
| `Highlight.swift` | `Core/Models/` | ~120 |
| `HighlightService.swift` | `Features/Transcript/` | ~350 |
| `QuoteLibraryView.swift` | `Features/PostSession/` | ~500 |
| `HighlightCreatorView.swift` | `Features/Transcript/` | ~250 |
| `HighlightServiceTests.swift` | `Tests/UnitTests/Features/` | ~200 |

**Files to modify:**
| File | Change |
|------|--------|
| `ContentView.swift` | Add "Quote Library" entry point alongside Analytics |
| `ExportService.swift` | Add `exportHighlights()` method |

---

### Feature F: Participant Management System (#17)
**Effort: Medium | Priority: Research workflow — rated High by UX Research agent**

**What it does:**
- Local participant database with demographics (role, department, experience level)
- Link participants to sessions — view all sessions for a participant
- Participation history and frequency tracking
- Screener fields (custom key-value metadata per participant)
- Privacy-first: all data local, export for deletion compliance (GDPR right to erasure)
- Auto-suggest participant from Calendar Integration (Feature B) when available

**Integration points:**
- New `Participant` model (Codable struct, JSON persistence)
- New `ParticipantManager` service with CRUD + search + linking
- Extends `Session` conceptually — `ParticipantManager` maps participant IDs to session IDs
- Extends `ContentView` session setup — participant picker/creator
- Integrates with `CalendarService` (Feature B) for auto-population

**Files to create:**
| File | Location | Lines (est.) |
|------|----------|-------------|
| `Participant.swift` | `Core/Models/` | ~130 |
| `ParticipantManager.swift` | `Features/Session/Services/` | ~300 |
| `ParticipantPickerView.swift` | `Features/Session/Views/` | ~350 |
| `ParticipantDetailView.swift` | `Features/Session/Views/` | ~280 |
| `ParticipantManagerTests.swift` | `Tests/UnitTests/Features/` | ~180 |

**Files to modify:**
| File | Change |
|------|--------|
| `ContentView.swift` | Add participant picker to session setup flow |
| `SessionConfiguration` | Add optional `participantId: UUID?` |

---

### Feature G: Emotional Arc Tracking (#20)
**Effort: Medium | Priority: Innovation differentiator — rated 4/5 by Creative Technologist**

**What it does:**
- Rules-based sentiment analysis on each utterance (positive / neutral / negative / mixed)
- Emotional intensity scoring (0.0–1.0) based on keyword density and sentence structure
- Real-time emotional timeline — sparkline showing sentiment flow during interview
- Post-session emotional journey map — visual arc showing highs/lows with linked quotes
- Detect emotional shifts (sentiment change > 0.4 between consecutive utterances) → auto-flag as insight
- Integration with Session Summary — emotional arc summary in generated reports

**Integration points:**
- New `SentimentAnalyzer` service (rules-based, like `QuestionTypeAnalyzer`)
- New `EmotionalArcView` for timeline visualization
- Extends `InsightFlaggingService` — emotional shifts trigger auto-flagging
- Extends `SessionSummaryGenerator` (Batch 1) — includes emotional arc in summary
- Extends `TalkTimeAnalyzer` (Batch 1) — emotional data enriches speaking analysis

**Files to create:**
| File | Location | Lines (est.) |
|------|----------|-------------|
| `SentimentAnalyzer.swift` | `Features/Session/Services/` | ~400 |
| `EmotionalArcView.swift` | `Features/Session/Views/` | ~450 |
| `SentimentAnalyzerTests.swift` | `Tests/UnitTests/Features/` | ~220 |

**Files to modify:**
| File | Change |
|------|--------|
| `SessionSummaryGenerator.swift` | Add emotional arc data to `SessionSummary` |
| `ContentView.swift` | Add emotional arc to analysis mode panels |

**Sentiment lexicon approach (no Core ML dependency):**
- Positive words: ~150 terms (love, great, perfect, helpful, enjoy, appreciate, etc.)
- Negative words: ~150 terms (frustrate, hate, terrible, confuse, difficult, annoying, etc.)
- Intensifiers: very, extremely, absolutely, totally, completely (multiply score by 1.5)
- Negators: not, never, don't, can't, won't (invert polarity)
- Sentence-level aggregation with position weighting (final clause gets 1.3x weight)

---

### Feature H: Accessible Consent System (#25)
**Effort: Medium | Priority: Inclusion — bridges consent tracking (#9) with accessibility**

**What it does:**
- Plain-language consent forms at 5th-grade reading level (Flesch-Kincaid score > 80)
- Visual/icon-based consent flow — each permission explained with icon + one sentence
- Multi-language consent templates (English, Spanish, French, German, Japanese, Chinese)
- TTS playback of consent text (via `NSSpeechSynthesizer`)
- Digital signature capture — participant types name to confirm
- Consent versioning — track which version each participant agreed to
- Consent status persists per session and links to Participant Management (Feature F)

**Integration points:**
- New `ConsentTemplate` model (Codable struct, bundled defaults + user-customizable)
- New `ConsentFlowView` — multi-step wizard with accessibility-first design
- Extends `ConsentTracker` (from Feature C) with template versioning
- Links to `ParticipantManager` (Feature F) — consent records per participant
- Extends `MarkdownExporter` — includes consent status in export metadata

**Files to create:**
| File | Location | Lines (est.) |
|------|----------|-------------|
| `ConsentTemplate.swift` | `Core/Models/` | ~200 |
| `ConsentFlowView.swift` | `Features/Session/Views/` | ~550 |
| `ConsentTemplateTests.swift` | `Tests/UnitTests/Features/` | ~150 |

**Files to modify:**
| File | Change |
|------|--------|
| `ConsentTracker.swift` (Feature C) | Add template versioning and digital signature |
| `ParticipantManager.swift` (Feature F) | Link consent records to participants |
| `MarkdownExporter.swift` | Include consent metadata in export header |
| `ContentView.swift` | Add consent step to session setup flow |

---

## Parallel Build Strategy

Features are grouped by shared integration surfaces to maximize parallel development:

```
┌─────────────────────────────────────────────────────────────┐
│  GROUP 1: Coaching Enhancements (A + D)                     │
│  CoachingTimingSettings + CulturalContext + BiasDetector     │
│  Shared surface: CoachingService, CoachingPreferences,       │
│                  CoachingThresholds                          │
├─────────────────────────────────────────────────────────────┤
│  GROUP 2: Session Lifecycle (B + F)                          │
│  CalendarService + ParticipantManager                        │
│  Shared surface: ContentView session setup,                  │
│                  SessionConfiguration                        │
├─────────────────────────────────────────────────────────────┤
│  GROUP 3: Transcript Intelligence (C + E)                    │
│  PIIDetector + RedactionService + HighlightService           │
│  Shared surface: Transcript utterances, ExportService,       │
│                  TaggingService                              │
├─────────────────────────────────────────────────────────────┤
│  GROUP 4: Experience & Ethics (G + H)                        │
│  SentimentAnalyzer + EmotionalArcView + ConsentFlowView      │
│  Shared surface: Session model, SessionSummaryGenerator,     │
│                  InsightFlaggingService                       │
└─────────────────────────────────────────────────────────────┘
```

### Build Order

**Phase 1 — Parallel build (4 agent groups):**
All 4 groups build simultaneously. Each group creates its source files, view files, and test files independently.

**Phase 2 — Integration wiring:**
After all groups complete, wire everything into `ContentView.swift`:
- Coaching history + cultural settings into session toolbar
- Calendar + participant picker into session setup
- Redaction review + highlight creator into transcript view
- Emotional arc + consent flow into session panels

**Phase 3 — Cross-feature integration tests:**
Verify features work together:
- Calendar → Participant auto-link → Consent flow → Session start
- Transcript → PII detection → Redaction → Highlight → Export
- Coaching with cultural context → Bias detection → Emotional arc
- Quote Library search across sessions with redacted content

---

## File Creation Summary

| Category | New Files | Modified Files | Est. Lines |
|----------|-----------|---------------|------------|
| Feature A (Coaching Timing) | 3 | 4 | ~610 |
| Feature B (Calendar) | 3 | 2 | ~730 |
| Feature C (PII/Redaction) | 6 | 2 | ~1,630 |
| Feature D (Cultural Sensitivity) | 5 | 4 | ~1,110 |
| Feature E (Highlight Reel) | 5 | 2 | ~1,420 |
| Feature F (Participants) | 5 | 2 | ~1,240 |
| Feature G (Emotional Arc) | 3 | 2 | ~1,070 |
| Feature H (Consent System) | 3 | 4 | ~900 |
| **Total** | **33** | **~14 unique** | **~8,710** |

---

## Dependency Graph

```
Feature A (Coaching Timing)  ──── standalone
Feature B (Calendar)         ──── standalone
Feature C (PII/Redaction)    ──── standalone
Feature D (Cultural)         ──── extends A (CoachingThresholds changes)
Feature E (Highlights)       ──── extends Batch 1 Tagging (#5)
Feature F (Participants)     ──── benefits from B (calendar auto-populate)
Feature G (Emotional Arc)    ──── extends Batch 1 Summary (#6) + Insights
Feature H (Consent)          ──── extends C (ConsentTracker) + F (Participants)
```

**Build order constraints:**
- A must complete before D (shared CoachingThresholds modifications)
- C must complete before H (ConsentTracker is created in C, extended in H)
- B should complete before F (calendar auto-populate integration)
- Everything else is independent

**Recommended parallel grouping respecting constraints:**
1. Build A + B + C + E simultaneously (all independent)
2. Build D + F + G + H simultaneously (depends on Phase 1 outputs)

---

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| EventKit permission denied at runtime | Graceful degradation — calendar section hidden when permission unavailable |
| PII regex false positives | Conservative defaults + user confirm/deny on each detection |
| Cultural presets may be reductive | Frame as "starting points" not "cultural rules"; always customizable |
| Emotional sentiment analysis accuracy | Rules-based is inherently limited; show confidence scores, allow user override |
| NSSpeechSynthesizer availability | Check availability before offering TTS; hide option if unavailable |
| ContentView complexity growth | Consider extracting setup flow into `SessionSetupCoordinator` |

---

## Success Criteria

After this batch, the product should:

1. **Complete v1.1 scope** — All originally planned quick wins shipped
2. **Be enterprise-ready** — PII redaction + consent tracking unlocks regulated industries
3. **Support diverse researchers** — Cultural sensitivity + accessible consent + predictable coaching
4. **Deepen post-session value** — Highlight reel + quote library + emotional arc
5. **Reduce activation friction** — Calendar integration + participant management
6. **Total feature count**: 16 features across ~21,400 lines of feature code

---

*Next batch after this: v1.5 features — Observer Collaboration (#13), Local Whisper Fallback (#10), Shared Template Library, Conversation Flow Visualization (#11)*
