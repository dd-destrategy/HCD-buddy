# HCD Interview Coach — Feature Evaluation Report

> **Generated**: 2026-02-07
> **Methodology**: Five specialized evaluation agents analyzed the product from distinct professional lenses, then findings were cross-referenced and synthesized into a unified priority list.

## Evaluation Panel

| Agent | Perspective | Focus |
|-------|------------|-------|
| **Project Manager** | Product strategy, market fit, revenue | Competitive gaps, growth levers, lifecycle |
| **Creative Technologist** | Innovation, interaction design, delight | AI/ML opportunities, emerging tech, UX polish |
| **UX Research Specialist** | Practitioner workflow, real-world usage | Pre/during/post interview gaps, coaching quality |
| **Technical Architect** | Platform capabilities, architecture | On-device ML, cost optimization, scalability |
| **Accessibility & Inclusion** | Universal design, neurodiversity, bias | Cognitive load, accommodation, cultural sensitivity |

---

## Executive Summary

The HCD Interview Coach has a **mature, production-ready foundation** with all 16 epics implemented across 96 stories. The product excels at the core in-session experience (transcription, silence-first coaching, topic tracking). However, five consistent themes emerged across all evaluators:

1. **The tool is session-scoped** — no cross-session intelligence, no study-level organization, no compound value over time
2. **Post-session analysis is the biggest workflow gap** — researchers still export to other tools for coding, tagging, and synthesis
3. **The coaching engine can be significantly smarter** — question type detection, talk-time ratio, and follow-up suggestions would transform its value
4. **Cognitive load management is under-addressed** — four simultaneous information streams with no simplified modes
5. **Remote interview support is a market requirement** — BlackHole-only limits the addressable market

---

## Tier 1: Highest-Value Additions (Recommended for v1.1)

These features received the strongest signal across multiple evaluators. Each was independently identified by 3+ agents as critical.

### 1. Interviewer Talk-Time Ratio Monitor
**Cross-agent consensus: 5/5 agents**

| Dimension | Rating |
|-----------|--------|
| User Value | Critical |
| Effort | Small |
| Differentiation | High |

**What**: Real-time percentage showing interviewer vs. participant speaking time. Color-coded indicator (green <30%, yellow 30-40%, red >40%). Post-session trend report.

**Why it's #1**: Identified by every evaluator. The UX Research Specialist called it "the single metric that separates good interviews from bad." The Technical Architect noted it's derivable from existing utterance timestamps with minimal new code. The Creative Technologist sees it as the foundation for an "ambient awareness" dashboard. The Accessibility Specialist noted it as a low-cognitive-load coaching signal.

**Technical approach**: Compute from existing `Utterance` speaker labels and duration. Add rolling window calculation in `CoachingService`. Display as peripheral UI element.

---

### 2. Question Type Analyzer (Open/Closed/Leading Detection)
**Cross-agent consensus: 4/5 agents**

| Dimension | Rating |
|-----------|--------|
| User Value | High |
| Effort | Medium |
| Differentiation | High |

**What**: Real-time classification of interviewer questions as open-ended, closed, leading, or double-barreled. Post-session report showing question quality distribution. Coaching prompts when anti-patterns detected (e.g., 5 consecutive closed questions).

**Why**: The UX Research Specialist identified this as "where AI coaching can truly shine — catching unconscious bias patterns humans miss." The Technical Architect proposed using Core ML Natural Language framework with `NLTagger` for on-device classification with minimal latency. The Creative Technologist sees this feeding into a "Conversation Dynamics Engine." The Accessibility Specialist flagged it as a bias-mitigation tool.

**Technical approach**: Core ML `MLWordTagger` or NLP rules-based classifier on `Utterance` text. Feed results to `CoachingService` for pattern detection.

---

### 3. Cross-Session Analytics & Study Organization
**Cross-agent consensus: 4/5 agents**

| Dimension | Rating |
|-----------|--------|
| User Value | High |
| Effort | Large |
| Differentiation | High |

**What**: Group sessions into Studies. Dashboard showing patterns across sessions: recurring themes, topic coverage trends, coaching prompt patterns, interview quality metrics over time.

**Why**: The Project Manager flagged this as the key to retention ("transforms one-off tool into research intelligence platform"). The Technical Architect proposed adding a `Study` entity above `Session` with aggregation queries. The UX Research Specialist wants cross-session quote search and theme extraction. The Creative Technologist envisions a "Cross-Session Pattern Miner."

**Technical approach**: New SwiftData `Study` entity with one-to-many `Session` relationship. Aggregation queries via SwiftData predicates. Precomputed metrics cache in `DataManager`.

---

### 4. Focus Mode Layouts (Cognitive Load Management)
**Cross-agent consensus: 4/5 agents**

| Dimension | Rating |
|-----------|--------|
| User Value | Critical |
| Effort | Small-Medium |
| Differentiation | Medium |

**What**: Three layout presets — **Interview Mode** (transcript only, full screen), **Coached Mode** (transcript + coaching), **Analysis Mode** (all panels). User-customizable. Keyboard shortcut switching (⌘+Shift+1/2/3).

**Why**: The Accessibility Specialist rated this as "Critical" — four simultaneous information streams overwhelm neurodivergent users. The Creative Technologist proposed an "Ambient Awareness Mode" with similar principles. The UX Research Specialist noted experienced researchers want minimal UI during interviews. The Project Manager sees this as reducing churn from cognitive overload.

**Technical approach**: View state management in existing ViewModels. Panel visibility toggles with smooth transitions respecting `reduceMotion`.

---

### 5. Post-Session Tagging & Coding Interface
**Cross-agent consensus: 4/5 agents**

| Dimension | Rating |
|-----------|--------|
| User Value | Critical |
| Effort | Medium-Large |
| Differentiation | Medium |

**What**: Select transcript segments, apply user-defined tags (hierarchical: Theme → Code → Sub-code). Filter/search by tag. Batch tagging. AI-suggested tags (user-approved). Export tagged segments as CSV/JSON.

**Why**: The UX Research Specialist called this "Critical" — it's the bridge between raw data and insights, and without it researchers export to Dovetail/spreadsheets. The Project Manager sees it as creating switching costs. The Technical Architect proposed a search index via Core Spotlight. The Creative Technologist wants it to feed into automated theme extraction.

**Technical approach**: New `Tag` and `UtteranceTag` SwiftData models. Inline selection UI in `TranscriptView`. Core Spotlight indexing for cross-session search.

---

### 6. AI-Enhanced Session Summary
**Cross-agent consensus: 4/5 agents**

| Dimension | Rating |
|-----------|--------|
| User Value | High |
| Effort | Medium |
| Differentiation | High |

**What**: LLM-generated structured summary: key themes (3-5 bullets), participant pain points, surprising moments (from insight flags), suggested follow-up questions for next interview, gap analysis vs. research questions.

**Why**: The Project Manager calls this "direct time savings — core value prop for Pro tier." The UX Research Specialist wants structured outputs (themes, quotes, gaps) not narratives. The Creative Technologist sees it as the entry point to a "research co-pilot." The Technical Architect notes it leverages the existing OpenAI relationship.

**Technical approach**: Post-session API call using session transcript + insights + topics. Structured prompt engineering. User-editable results stored in `Session`.

---

### 7. Follow-Up Question Suggester
**Cross-agent consensus: 3/5 agents**

| Dimension | Rating |
|-----------|--------|
| User Value | High |
| Effort | Medium |
| Differentiation | High |

**What**: Context-aware follow-up suggestions when participant mentions emotions, states opinions, or describes actions. Methodology-specific (JTBD laddering, usability think-aloud, discovery probing). Displayed in sidebar, not interrupting flow.

**Why**: The UX Research Specialist identified this as "bridging novice to intermediate skill level." The Creative Technologist proposed it as part of the Conversation Dynamics Engine. The Project Manager sees it as a Pro tier differentiator.

**Technical approach**: Extend `CoachingService` with contextual prompt generation. Use existing OpenAI connection for real-time suggestions. Template-specific coaching rules loaded from `InterviewTemplate`.

---

### 8. Demo Mode / Interactive Sample Session
**Cross-agent consensus: 2/5 agents (but rated P0 by Project Manager)**

| Dimension | Rating |
|-----------|--------|
| User Value | High |
| Effort | Small |
| Differentiation | Low |

**What**: Pre-loaded sample session with realistic transcript, insights, and coaching prompts. Users explore the full experience without BlackHole setup or API key.

**Why**: The Project Manager rated this P0 — "reduces time-to-value from ~20 minutes to <2 minutes." Critical for free-to-pro conversion. The Technical Architect noted it's trivially implementable with bundled test data.

**Technical approach**: Bundle sample `Session` data. Bypass `AudioCaptureEngine` and `RealtimeAPIClient` in demo mode. Playback simulation using `AsyncStream`.

---

## Tier 2: High-Value Additions (Recommended for v1.2–v1.5)

### 9. Consent & PII Redaction Engine
| Agent Signal | UX Research (High), Accessibility (High) |
|-------------|------------------------------------------|
| Effort | Medium |

Auto-detect PII (names, emails, companies) in transcripts. Redaction UI with confirm/replace workflow. Consent status tracking per session. Critical for GDPR compliance and ethical research practice.

### 10. Local Whisper Fallback (Cost & Privacy)
| Agent Signal | Technical Architect (High), Creative Technologist (High) |
|-------------|----------------------------------------------------------|
| Effort | Medium |

Embed whisper.cpp for offline transcription when API unavailable or cost-prohibitive. Smart routing: OpenAI for real-time, Whisper for post-session refinement. Reduces API costs 60-80% for non-critical paths. Unlocks privacy-sensitive enterprise markets.

### 11. Conversation Flow Visualization
| Agent Signal | Creative Technologist (5/5 Innovation), UX Research (Medium) |
|-------------|--------------------------------------------------------------|
| Effort | Large |

Interactive node-graph showing topic interconnections during interviews. Animated conversation "journey" playback. Engagement timeline with emotional arc overlay. Transforms stakeholder presentations from transcripts to compelling visual stories.

### 12. Highlight Reel & Quote Library
| Agent Signal | Project Manager (High), UX Research (High) |
|-------------|---------------------------------------------|
| Effort | Medium-Large |

Select transcript segments to create named highlights. Cross-session quote library with search, filter, and tagging. Export as stakeholder-ready formats (slide deck, PDF, audio clips). Viral sharing potential.

### 13. Observer Collaboration Panel
| Agent Signal | UX Research (High), Project Manager (Medium) |
|-------------|-----------------------------------------------|
| Effort | Large |

Live observer mode: view transcript + add timestamped notes. Async question queue (observers suggest follow-ups, interviewer sees in sidebar). Combined notes export. Foundation for Team tier.

### 14. Cultural Sensitivity & AI Bias Controls
| Agent Signal | Accessibility (Critical), UX Research (High) |
|-------------|-----------------------------------------------|
| Effort | Medium |

Cultural context settings (direct vs. high-context cultures) adjusting silence tolerance and question expectations. AI confidence display on all prompts. "Not helpful" feedback with cultural inappropriateness reason. Coaching explanation mode showing reasoning.

### 15. Customizable Coaching Timing & Predictable Mode
| Agent Signal | Accessibility (Critical), UX Research (Low-Medium) |
|-------------|------------------------------------------------------|
| Effort | Small |

Adjustable auto-dismiss duration (5s/10s/15s/30s/manual). Manual coaching mode (AI queues prompts, researcher pulls on demand). Preview mode (see what would trigger without displaying). Coaching history panel for missed prompts. Critical for neurodivergent researchers.

### 16. Calendar Integration
| Agent Signal | Project Manager (Medium), Technical Architect (Low effort) |
|-------------|-------------------------------------------------------------|
| Effort | Small-Medium |

EventKit integration to detect upcoming interviews. Auto-populate session metadata from calendar events. Pre-session reminder with one-click session start. Builds habit loop and reduces activation energy.

### 17. Participant Management System
| Agent Signal | Project Manager (Medium), UX Research (High) |
|-------------|-----------------------------------------------|
| Effort | Medium |

Simple participant database linked to sessions. View participation history. Screener integration. Privacy-first local storage with export for deletion compliance.

### 18. ScreenCaptureKit Integration
| Agent Signal | Technical Architect (High) |
|-------------|---------------------------|
| Effort | High |

Capture participant screen during usability tests, time-synced with transcript. Background H.264 compression. Eliminates separate screen recording tool requirement. Massive value for remote moderated testing.

---

## Tier 3: Innovative Differentiators (v2.0+ / R&D)

### 19. Spatial Audio Coaching
Deliver coaching via directional spatial audio in AirPods — invisible, non-intrusive, magical. *Innovation: 5/5, Feasibility: 4/5*

### 20. Emotional Arc Tracking
On-device sentiment analysis (Core ML) detecting emotional shifts. Plot emotional journey maps showing frustration, delight, disengagement. *Innovation: 4/5, Feasibility: 3/5*

### 21. Cross-Session Theme Extraction
Select 5-20 sessions → AI extracts 5-10 themes with supporting quotes. Export to affinity map format. Saves 8-10 hours per study. *Innovation: 5/5, Feasibility: 3/5*

### 22. Generative Session Posters
After session ends, generate abstract "poster" visualizing the session's unique signature — colors from emotional arc, shapes from conversation flow, key quotes as typography. *Innovation: 4/5, Delight: 5/5*

### 23. Local LLM Privacy Mode
MLX-based local LLMs for zero-data-exfiltration environments (healthcare, defense, finance). *Strategic Value: 5/5, Feasibility: 3/5*

### 24. Vision Pro Companion
Spatial computing for post-session review — transcript fragments in 3D space, topic clusters arranged spatially, emotional arcs as glowing paths. *Innovation: 5/5, Feasibility: 2/5*

### 25. Accessible Consent System
Plain language consent (5th-grade reading level), visual/icon-based forms, multi-language templates, TTS playback, signed consent video support. *Inclusion Impact: High*

---

## Priority Matrix Summary

```
                        LOW EFFORT ←——————————→ HIGH EFFORT
                        │                              │
    HIGH VALUE          │  1. Talk-Time Ratio    ★     │  3. Cross-Session Analytics
                        │  4. Focus Mode Layouts ★     │  5. Tagging & Coding
                        │  8. Demo Mode          ★     │  6. AI Session Summary
                        │  15. Coaching Timing   ★     │  2. Question Type Analyzer
                        │  16. Calendar          ★     │  7. Follow-Up Suggester
                        │                              │
    MEDIUM VALUE        │                              │  11. Conversation Flow Viz
                        │  14. Cultural Controls       │  12. Highlight Reel
                        │                              │  13. Observer Collaboration
                        │                              │  10. Local Whisper
                        │                              │  18. ScreenCaptureKit
                        │                              │
    ★ = Quick wins (ship in v1.1 sprint)
```

---

## Recommended Roadmap

### v1.1 — "Smarter Coaching" (Quick wins, 2-4 weeks)
- [ ] Talk-Time Ratio Monitor (#1)
- [ ] Focus Mode Layouts (#4)
- [ ] Demo Mode (#8)
- [ ] Customizable Coaching Timing (#15)
- [ ] Calendar Integration (#16)

### v1.2 — "Research Intelligence" (Core value expansion, 4-8 weeks)
- [ ] Question Type Analyzer (#2)
- [ ] AI-Enhanced Session Summary (#6)
- [ ] Follow-Up Question Suggester (#7)
- [ ] Session Library with Search & Tags

### v1.3 — "Analysis Powerhouse" (Post-session workflow, 6-8 weeks)
- [ ] Cross-Session Analytics & Study Organization (#3)
- [ ] Post-Session Tagging & Coding (#5)
- [ ] Highlight Reel & Quote Library (#12)
- [ ] Consent & PII Redaction (#9)

### v1.5 — "Team & Enterprise" (Collaboration + scale, 8-12 weeks)
- [ ] Observer Collaboration Panel (#13)
- [ ] Local Whisper Fallback (#10)
- [ ] Cultural Sensitivity Controls (#14)
- [ ] Participant Management (#17)
- [ ] Shared Template Library (Team tier)

### v2.0 — "Research Platform" (Innovation, ongoing)
- [ ] Cross-Session Theme Extraction (#21)
- [ ] Conversation Flow Visualization (#11)
- [ ] Emotional Arc Tracking (#20)
- [ ] ScreenCaptureKit (#18)
- [ ] Local LLM Privacy Mode (#23)

---

## Key Strategic Insight

The product's current strength is the **in-session experience**. The highest-value additions shift the product from a **session tool** to a **research intelligence platform**:

1. **Before the interview**: Discussion guides, calendar integration, demo mode
2. **During the interview**: Smarter coaching (talk-time, question types, follow-ups, focus modes)
3. **After the interview**: Tagging, cross-session analytics, AI summaries, highlight reels
4. **Across the practice**: Study organization, participant management, theme extraction

The five quick wins (Talk-Time Ratio, Focus Modes, Demo Mode, Coaching Timing, Calendar) can ship in a single sprint and dramatically increase both activation rate and daily-use value.

---

*This report synthesizes evaluations from five specialized agents: Product Manager, Creative Technologist, UX Research Specialist, Technical Architect, and Accessibility & Inclusion Specialist.*
