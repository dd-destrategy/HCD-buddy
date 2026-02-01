# HCD Interview Coach
## Product Requirements Document (PRD)

**Version:** 1.1  
**Date:** January 30, 2026  
**Author:** Product Management  
**Status:** Revised based on critical review

---

## Revision Summary (v1.1)

This revision addresses fundamental concerns about user trust, coaching intrusiveness, and adoption barriers identified in critical review. Key changes:

1. **Coaching philosophy rewritten** from "helpful prompts" to "silence-first safety net"
2. **Audio setup elevated** to first-class onboarding experience
3. **Topic tracking softened** from completion-oriented to awareness-oriented
4. **Post-interview summary** moved from P2 to P1
5. **Consent and disclosure** added as explicit requirement
6. **Success metrics reframed** around invisibility, not activity

---

## Executive Summary

HCD Interview Coach is a native macOS application that provides real-time AI support during human-centered design research interviews. It captures audio from video conferencing platforms, tracks topic coverage, and generates synchronized transcripts—while staying quiet unless genuinely needed.

**Positioning:** "The research assistant that knows when to stay quiet"—a safety net for experienced researchers, not training wheels.

**Core Philosophy:** The best outcome is when the researcher forgets the tool is running during the interview, then appreciates it afterward.

**Market Opportunity:** $270-500M UX research software market with no existing real-time coaching solution. Adjacent validation from BrightHire (recruiting) and Gong (sales) proves the model.

**Target Users:** Experienced UX researchers, service designers, and qualitative researchers who want leverage, not guidance.

---

## Problem Statement

### The Core Problem

UX researchers face severe cognitive overload during interviews. They must simultaneously:
- Listen actively and build rapport
- Formulate follow-up questions
- Track coverage of research objectives
- Capture key quotes and insights
- Monitor time and pacing
- Manage technical aspects of the call

This multitasking degrades interview quality. Nielsen Norman Group identifies it as a "key facilitation mistake." Researchers limit themselves to 2 interviews per day due to cognitive fatigue, and critical probing opportunities are missed in real-time.

### Current Workarounds (All Inadequate)

| Workaround | Problem |
|------------|---------|
| Dedicated notetaker | Requires second team member, expensive, inconsistent |
| Printed discussion guide | Static, no adaptation, eyes off participant |
| Record and review later | Delays insight capture, probing moment lost |
| Observer Slack channel | Adds cognitive load, context switching |
| Memory/experience | Unreliable, biased toward recent statements |

### What Researchers Actually Need

Based on user research and critical analysis, researchers need:

1. **A safety net, not a copilot** — Something that catches what they miss, not something that directs them
2. **Confidence in coverage** — Knowing they've touched important topics without checking a list
3. **Reduced post-interview work** — Synthesis that starts during the interview, not after
4. **Nothing that risks the interview** — Any tool that could disrupt rapport is worse than no tool

---

## Product Philosophy

### The Trust Hierarchy

The product must earn trust in this order:

1. **Never make the interview worse** (non-negotiable)
2. **Be invisible when not needed** (default state)
3. **Surface only high-confidence, well-timed signals** (rare)
4. **Provide value after the interview** (safe space for feedback)

### Silence-First Coaching

Traditional approach (rejected):
> "Show helpful prompts when the AI detects opportunities"

Revised approach (adopted):
> "Stay silent unless there's a high-confidence moment the researcher clearly missed"

**Implications:**
- Default state is zero coaching prompts
- Prompts require multiple confidence thresholds
- Timing quality matters more than speed
- A missed opportunity is better than a mistimed interruption

### The Interruption Budget

Every prompt spends from a limited "interruption budget":

| Prompt Quality | Budget Cost | Example |
|----------------|-------------|---------|
| Well-timed, genuinely helpful | Low | Participant shows frustration, researcher didn't follow up |
| Reasonable but researcher was handling it | Medium | Redundant prompt that feels intrusive |
| Poorly timed or wrong | High | Prompt appears mid-sentence or during rapport moment |
| Mistimed during sensitive moment | Critical | Could damage trust permanently |

The system must be conservative because the cost of bad prompts is much higher than the value of good ones.

---

## Solution Overview

### Product Vision

A discreet AI assistant that watches alongside the researcher during interviews. It stays quiet by default, provides a clear picture of topic coverage, captures insights automatically, and offers thoughtful reflection after the interview ends.

### Core Value Propositions

1. **Stay Present:** No more splitting attention between participant and notes
2. **Awareness Without Anxiety:** See topic coverage as soft signals, not checklists
3. **Automatic Capture:** Insights flagged without manual effort
4. **Reflection, Not Direction:** Post-interview summary helps you improve over time
5. **Safety Net Available:** Rare prompts when you've clearly missed something important

### What This Product Is NOT

- ❌ A backseat driver that tells you how to interview
- ❌ Training wheels for junior researchers
- ❌ A replacement for interviewing skill
- ❌ An AI that participates in the conversation
- ❌ Something that makes you dependent on prompts

---

## Target Users

### Primary Persona: Experienced Agency Researcher

**Name:** Sarah, 32  
**Role:** Senior UX Researcher at digital agency  
**Context:** Conducts 8-15 interviews per month across 2-3 concurrent client projects

**Experience Level:** 5+ years, doesn't need coaching on technique

**What she wants:**
- Leverage, not guidance
- Reduced cognitive load
- Faster synthesis
- Confidence she didn't miss anything important

**What would make her stop using it:**
- Prompts that interrupt her flow
- Feeling like the tool is judging her
- Having to manage the tool during interviews
- Unreliable audio capture

**Quote:** "I don't need AI to teach me how to interview. I need it to watch my back."

### Secondary Persona: Research Lead

**Name:** Marcus, 38  
**Role:** UX Research Manager at SaaS company  
**Context:** Conducts 3-5 interviews monthly, coaches junior researchers

**What he wants:**
- Model best-practice for his team
- Data on coverage patterns across interviews
- Transcripts for repository building

**What would make him stop using it:**
- If it changed how junior researchers develop skills
- If team became dependent on prompts
- Privacy or consent concerns

### Non-Target Users (v1)

- Junior researchers who need active guidance (future opportunity)
- Researchers who want AI to run interviews for them
- Users who can't manage basic audio setup
- Teams requiring enterprise procurement (future)

---

## Feature Requirements

### P0: Must Have (MVP)

#### F0: Audio Setup Wizard ⭐ NEW
**Description:** Guided first-run experience that ensures audio capture works before any interview.

**Why P0:** Audio capture failure during a real interview causes immediate churn. This is the biggest adoption risk.

**Requirements:**
- Step-by-step BlackHole installation guide (or detection if already installed)
- Multi-Output Device creation walkthrough with inline visuals
- Audio verification test before first session
- Dual audio level meters (system audio + microphone)
- Clear success/failure indicators
- Troubleshooting guidance for common issues
- Store successful configuration for quick restore

**User Flow:**
```
1. Welcome → Explain what we're setting up and why
2. Install BlackHole → Direct download link or Homebrew command
3. Configure Audio MIDI → Step-by-step with screenshots/GIFs
4. Test Audio → "Play a YouTube video and speak"
5. Verify → Show both audio streams with level meters
6. Success → "You're ready for your first session"
```

**Acceptance Criteria:**
- [ ] New user can complete setup in <10 minutes
- [ ] Audio test shows clear pass/fail state
- [ ] Configuration persists across app restarts
- [ ] Troubleshooting covers top 5 failure modes
- [ ] Can re-run wizard anytime from settings

---

#### F1: Real-Time Transcription
**Description:** Live, streaming transcription of interview audio with speaker identification and timestamps.

**Requirements:**
- Latency <500ms from speech to text display
- Word-level streaming (not sentence batches)
- Speaker diarization (Interviewer vs Participant)
- Timestamp at utterance level [MM:SS]
- Accuracy target: 90%+ for clear audio
- Support for English (US, UK, AU accents)

**Speaker Diarization Approach:**
- Default to manual speaker toggle (⌘+T)
- AI-suggested speaker labels shown in lighter font weight
- One-click correction for misattributed utterances
- Explicit UI copy: "Speaker labels are suggestions. Click to correct."

**Technical Approach:**
- OpenAI GPT Realtime API with gpt-4o-transcribe
- Audio capture via BlackHole virtual audio driver
- 24kHz 16-bit PCM mono, 100ms chunks

**Acceptance Criteria:**
- [ ] Transcription appears within 500ms of speech
- [ ] Speaker correction takes <2 clicks
- [ ] Timestamps accurate within 2 seconds
- [ ] Handles crosstalk gracefully (flags uncertainty)

---

#### F2: Coaching Prompts (REVISED - Silence-First)
**Description:** Rare AI-generated suggestions that appear only when the researcher has clearly missed something significant.

**Philosophy Change:**
| v1.0 Approach | v1.1 Approach |
|---------------|---------------|
| "Show prompts when helpful" | "Stay silent unless critical" |
| Target: useful prompts | Target: invisible most sessions |
| Max 1 per 30 seconds | Default to zero prompts |
| Speed matters | Timing quality matters |

**Prompt Categories:**
| Type | Trigger | Confidence Required |
|------|---------|---------------------|
| Insight | Strong emotion expressed, researcher didn't follow up | HIGH |
| Probe | Explicit frustration or surprise, no follow-up after 10+ seconds | HIGH |
| Silence | Participant clearly thinking, researcher about to interrupt | MEDIUM |

**Removed from v1:**
- "Redirect" prompts (too prescriptive)
- Low-urgency suggestions (noise)
- Time-based prompts (creates anxiety)

**Timing Rules (Critical):**
1. Never prompt while interviewer is speaking
2. Never prompt within 5 seconds of interviewer finishing
3. Prefer participant pauses or natural transitions
4. Accept 5-10 second delay if it means better timing
5. Minimum 2 minutes between any prompts
6. Maximum 3 prompts per 60-minute session (hard cap)

**Requirements:**
- Prompts appear in subtle, non-intrusive location
- Auto-dismiss after 8 seconds
- Manual dismiss with Esc key
- Single visual style (no urgency color coding in v1)
- "Coaching Quiet" indicator when no prompts active
- Mute toggle (⌘+M) persists for session
- Coaching disabled by default for first session (opt-in)

**System Prompt Philosophy:**
```
You are observing, not participating.

Your default state is SILENCE. 

Only call show_nudge when:
1. The participant expressed something significant (strong emotion, 
   explicit frustration, surprising statement)
2. AND the researcher has not already responded to it
3. AND at least 2 minutes have passed since your last prompt
4. AND the interviewer is NOT currently speaking
5. AND at least 5 seconds have passed since the interviewer stopped speaking

When in doubt, do not prompt. 

A missed opportunity is better than a mistimed interruption.
The researcher is skilled. Trust them. Your job is to catch the rare miss, 
not to guide the conversation.
```

**Acceptance Criteria:**
- [ ] Average session has 0-2 prompts (not 5-10)
- [ ] Prompts never appear while interviewer speaking
- [ ] Prompts are contextually relevant when shown
- [ ] Researcher can complete session with coaching muted
- [ ] "Quiet" indicator visible when coaching is listening but silent

---

#### F3: Topic Awareness Tracking (REVISED)
**Description:** Visual signals showing which research areas have been touched during the interview.

**Philosophy Change:**
| v1.0 Approach | v1.1 Approach |
|---------------|---------------|
| "Topic Coverage" | "Topic Awareness" |
| Status: Complete/Incomplete | Status: Touched/Untouched |
| Visual: Progress checkboxes | Visual: Soft signals |
| Goal: Completion | Goal: Awareness |

**Why This Matters:**
- "Completion" creates checklist mentality
- Researchers may chase coverage rather than depth
- Emergent themes don't fit predefined topics
- Junior researchers may treat status as "truth"

**Visual Language:**
```
OLD: ○ Not mentioned → ◐ Mentioned → ◕ Explored → ● Complete
NEW: · Untouched → ~ Touched → ≈ Explored (no "complete" state)
```

**Requirements:**
- Pre-defined topic list per session (from template or manual entry)
- Status levels: Untouched → Touched → Explored
- No "complete" state (research topics are never truly done)
- Subtle visual indicators (muted colors, no bold checkmarks)
- Manual adjustment via click (cycle through states)
- No time-based warnings (creates anxiety)
- Optional: Hide panel during interview if preferred

**Technical Approach:**
- Function: `update_topic(topic_id, status)` (only "touched" and "explored")
- AI monitors transcript for topic relevance
- High confidence threshold before status change
- Never auto-advance to "explored" without substantial discussion

**Acceptance Criteria:**
- [ ] Topics update only with clear relevance
- [ ] No false positives (premature "explored" marking)
- [ ] Researcher can ignore panel without penalty
- [ ] Visual hierarchy doesn't compete with transcript

---

#### F4: Insight Flagging
**Description:** Capture notable moments during the interview for later analysis.

**Requirements:**
- Auto-flag: AI detects significant statements (strong emotion, key quotes)
- Manual flag: Keyboard shortcut (⌘+I) to mark current moment
- Each insight captures: timestamp, quote snippet, suggested theme
- Insights panel shows chronological list
- Click to jump to transcript location
- Conservative auto-flagging (prefer under-flagging to over-flagging)

**Technical Approach:**
- Function: `flag_insight(quote, theme)`
- AI trained on what constitutes "insightful" in HCD context
- Higher threshold for auto-flagging than coaching prompts

**Acceptance Criteria:**
- [ ] Manual flagging works reliably and quickly
- [ ] Auto-flagged insights are 80%+ genuinely notable
- [ ] No more than 5-7 auto-flags per 60-minute session
- [ ] Clicking insight jumps to correct transcript location

---

#### F5: Session Management
**Description:** Start, pause, resume, and end interview sessions.

**Requirements:**
- New Session: Select template or start blank, enter participant name
- Audio Check: Quick verification before starting (shows levels)
- Start Recording: Establish API connection, begin audio capture
- Pause: Stop streaming, maintain transcript state
- Resume: Reconnect and continue
- End Session: Close connection, finalize transcript, show summary

**Acceptance Criteria:**
- [ ] Session starts within 3 seconds of clicking Start
- [ ] Pause/Resume maintains transcript integrity
- [ ] End session triggers post-interview summary (see F8)
- [ ] Failed starts show clear error with recovery steps

---

#### F6: Export
**Description:** Generate shareable documents from completed sessions.

**Formats:**
- Markdown (human-readable, for sharing)
- JSON (structured, for integration)

**Content:**
- Full transcript with speaker labels and timestamps
- Insight markers inline in transcript
- Topic awareness summary
- Session metadata (participant, project, duration, date)
- Coaching log (optional, for personal review)

**Acceptance Criteria:**
- [ ] Export completes within 5 seconds for 60-minute session
- [ ] Markdown renders correctly in common viewers
- [ ] JSON parses without errors
- [ ] Exported transcript matches in-app display

---

#### F7: Consent and Disclosure Templates ⭐ NEW
**Description:** Built-in support for ethical research practices around AI and recording disclosure.

**Why P0:** Consent concerns will come up immediately in enterprise conversations and with conscientious researchers.

**Requirements:**
- Pre-written disclosure language for participants
- Session mode options:
  - Full: Transcription + Coaching + Insights
  - Transcription Only: No AI coaching
  - Observer Only: No recording, topic tracking only
- Clear in-app indicator of current mode
- Ability to switch modes mid-session (with confirmation)

**Default Disclosure Template:**
```
"This interview will be recorded and transcribed using AI assistance. 
The AI helps me stay focused but does not participate in the conversation 
or make any decisions. Your responses will be stored securely and used 
only for research purposes. 

Do you have any questions before we begin?"
```

**Acceptance Criteria:**
- [ ] Researcher can copy disclosure text with one click
- [ ] Session mode is clearly visible throughout
- [ ] Mode switch requires confirmation
- [ ] Export includes disclosure of AI assistance

---

### P1: Should Have (v1.1)

#### F8: Post-Interview Summary ⭐ ELEVATED FROM P2
**Description:** Structured reflection screen shown immediately after session ends.

**Why P1 (elevated):** Post-interview is a safer space for AI feedback than live coaching. This is where trust is built—after the stakes have passed.

**Summary Contents:**
```
┌─────────────────────────────────────────────┐
│         Session Complete                    │
├─────────────────────────────────────────────┤
│                                             │
│  Duration: 47 minutes                       │
│  Participant: [Name]                        │
│                                             │
│  TOPIC AWARENESS                            │
│  ≈ Workflow (explored in depth)             │
│  ≈ Pain points (explored in depth)          │
│  ~ Workarounds (touched briefly)            │
│  · Future aspirations (not reached)         │
│                                             │
│  INSIGHTS CAPTURED: 7                       │
│  • 4 auto-flagged by AI                     │
│  • 3 manually flagged by you                │
│                                             │
│  COACHING ACTIVITY                          │
│  • 2 prompts shown                          │
│  • 1 acknowledged, 1 dismissed              │
│                                             │
│  REFLECTION (AI-generated)                  │
│  "You explored workflow and pain points     │
│  thoroughly. Consider that the participant  │
│  mentioned 'hacks' twice near the end but   │
│  time ran short—this might be worth         │
│  following up in a future session."         │
│                                             │
│  [Export] [View Transcript] [New Session]   │
│                                             │
└─────────────────────────────────────────────┘
```

**Requirements:**
- Auto-generated summary of what was covered
- Honest assessment of gaps (framed constructively)
- No scores or grades (feels like judgment)
- Optional: "What would you do differently?" prompt
- Reflection stored with session for later review

**Acceptance Criteria:**
- [ ] Summary appears immediately after End Session
- [ ] AI reflection is genuinely useful, not generic
- [ ] Tone is supportive, not critical
- [ ] Researcher can skip/dismiss if desired

---

#### F9: Interview Templates
**Description:** Pre-configured session setups for common interview types.

**Built-in Templates:**
- Discovery Interview (60 min)
- Usability Test Debrief (30 min)
- Stakeholder Interview (45 min)
- Jobs-to-be-Done (45 min)
- Customer Feedback (30 min)

**Each Template Includes:**
- Default topics for awareness tracking
- Suggested duration
- Tailored system prompt additions
- Disclosure template variant

---

#### F10: Session History
**Description:** Browse, search, and access past sessions.

**Requirements:**
- List view of all sessions
- Search by participant, project, date
- Filter by date range
- Re-export any past session
- View transcript and insights

---

#### F11: Audio Level Indicator
**Description:** Real-time feedback on audio quality during session.

**Requirements:**
- Dual level meters (system audio + microphone)
- Warning if levels too low/high
- Pre-session audio test option
- Indicator visible but unobtrusive during interview

---

### P2: Nice to Have (v1.2+)

- F12: Custom Coaching Personalities (more/less active)
- F13: Talk-Time Ratio Tracking (percentage of researcher vs participant speech)
- F14: Dovetail/Looppanel Integration
- F15: Team Analytics (patterns across multiple researchers)
- F16: Custom Templates (user-created)

---

## Technical Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                         macOS Application                         │
├──────────────────────────────────────────────────────────────────┤
│  Audio Setup     │  Session Manager      │  SwiftData            │
│  Wizard          │  - State machine      │  - Session            │
│  - Detection     │  - Coordinator        │  - Utterance          │
│  - Verification  │                       │  - Insight            │
├──────────────────────────────────────────────────────────────────┤
│  AudioCapture    │  RealtimeAPIClient    │  CoachingEngine       │
│  Service         │  - WebSocket          │  - Silence-first      │
│  - AVAudioEngine │  - Event handling     │  - Timing rules       │
│  - BlackHole     │  - Reconnection       │  - Threshold gates    │
│  - PCM convert   │  - Auth management    │                       │
└──────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │   OpenAI Realtime API         │
                    │   wss://api.openai.com/v1/    │
                    │   realtime?model=gpt-realtime │
                    └───────────────────────────────┘
```

### Platform Requirements

- macOS 13.0+ (Ventura)
- Apple Silicon or Intel
- BlackHole 2ch virtual audio driver
- OpenAI API key with Realtime API access

### API Integration

**Connection:**
- WebSocket to `wss://api.openai.com/v1/realtime?model=gpt-realtime`
- Bearer token authentication
- Ping every 20 seconds to maintain connection
- Exponential backoff reconnection (max 5 attempts)

**Audio Format:**
- 24kHz sample rate
- 16-bit PCM
- Mono channel
- ~100ms chunks (~20KB base64 per message)

**Function Definitions:**
```json
{
  "session": {
    "tools": [
      {
        "type": "function",
        "name": "show_nudge",
        "description": "Display a rare coaching prompt. Only call when highly confident the researcher missed something significant.",
        "parameters": {
          "type": "object",
          "properties": {
            "text": {"type": "string", "maxLength": 100},
            "reason": {"type": "string", "description": "Internal: why this prompt is warranted"}
          },
          "required": ["text", "reason"]
        }
      },
      {
        "type": "function",
        "name": "flag_insight",
        "description": "Mark a notable moment in the interview",
        "parameters": {
          "type": "object",
          "properties": {
            "quote": {"type": "string"},
            "theme": {"type": "string"}
          },
          "required": ["quote", "theme"]
        }
      },
      {
        "type": "function",
        "name": "update_topic",
        "description": "Update topic awareness status",
        "parameters": {
          "type": "object",
          "properties": {
            "topic_id": {"type": "string"},
            "status": {"enum": ["touched", "explored"]}
          },
          "required": ["topic_id", "status"]
        }
      }
    ]
  }
}
```

### Data Models

```swift
// Session
struct Session {
    let id: UUID
    var participantName: String?
    var projectName: String?
    var templateId: UUID?
    var sessionMode: SessionMode // .full, .transcriptionOnly, .observerOnly
    let startedAt: Date
    var endedAt: Date?
    var utterances: [Utterance]
    var insights: [Insight]
    var topicStatuses: [TopicStatus]
    var coachingLog: [CoachingEvent]
    var postInterviewReflection: String?
}

enum SessionMode: String, Codable {
    case full
    case transcriptionOnly
    case observerOnly
}

// Utterance
struct Utterance {
    let id: UUID
    var speaker: Speaker // .interviewer, .participant, .unknown
    var speakerConfidence: SpeakerConfidence // .aiSuggested, .userConfirmed
    var text: String
    let timestampSeconds: Double
    var confidence: Double
}

enum SpeakerConfidence: String, Codable {
    case aiSuggested
    case userConfirmed
}

// Topic Status (revised)
struct TopicStatus {
    let topicId: UUID
    var topicName: String
    var status: TopicAwareness // .untouched, .touched, .explored (no .completed)
    var lastUpdated: Date
}

enum TopicAwareness: String, Codable {
    case untouched
    case touched
    case explored
    // Note: no "completed" state
}

// Insight
struct Insight {
    let id: UUID
    let timestampSeconds: Double
    var quote: String
    var theme: String
    var source: InsightSource // .ai, .manual
    var notes: String?
}

// Coaching Event (for logging, not display)
struct CoachingEvent {
    let id: UUID
    let timestampSeconds: Double
    let promptText: String
    let reason: String // AI's internal reasoning
    var userResponse: CoachingResponse // .acknowledged, .dismissed, .ignored
}

enum CoachingResponse: String, Codable {
    case acknowledged
    case dismissed
    case ignored // auto-dismissed without interaction
}
```

---

## Cost Analysis

### Per-Session Costs (60-minute interview)

| Component | Calculation | Cost |
|-----------|-------------|------|
| Audio Input (Realtime API) | 36,000 tokens × $0.06/1K | $2.16 |
| Transcription | ~8,000 words × included | $0.00 |
| Text Output (function calls) | ~2,000 tokens × $0.20/1K | $0.40 |
| **Total per interview** | | **~$2.56** |

### User Cost Projections

| Usage Level | Interviews/Month | Monthly API Cost |
|-------------|------------------|------------------|
| Light | 5 | ~$13 |
| Moderate | 15 | ~$38 |
| Heavy | 30 | ~$77 |

### Business Model

**v1.0: BYOK (Bring Your Own Key)**
- User provides OpenAI API key
- App is free or low one-time purchase ($29-49)
- User pays OpenAI directly
- Target audience: Technical/senior researchers comfortable with API keys

**Future: Subscription**
- Layer in after proving value
- Include managed API costs
- Add team features
- Procurement-friendly billing

---

## Success Metrics (Revised)

### North Star Metric

**Sessions Where Coaching Was Invisible**

The goal is not "helpful prompts" but "valuable sessions where the tool stayed out of the way."

Measured as: % of sessions where researcher reports "the tool didn't distract me"

### Primary Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Audio Setup Success | 90%+ first attempt | Users who complete setup without support |
| Session Completion | 95%+ | Sessions ended normally ÷ sessions started |
| Coaching Invisibility | 80%+ | Sessions with ≤2 prompts shown |
| Post-Session Value | 4+/5 | "Was the summary helpful?" rating |
| Return Usage | 70%+ | Users with 3+ sessions in first month |

### Secondary Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Topic Awareness Accuracy | 85%+ | Topics marked explored that user confirms were explored |
| Insight Relevance | 80%+ | Auto-flagged insights user keeps (doesn't delete) |
| Transcript Accuracy | 90%+ | Spot-check sample for WER |
| Export Rate | 80%+ | Sessions exported ÷ sessions completed |

### Anti-Metrics (What We Don't Want)

| Anti-Metric | Warning Sign | Indicates |
|-------------|--------------|-----------|
| Prompts per session increasing | >3 average | Over-coaching |
| Users disabling coaching | >40% | Tool is intrusive |
| Topic completion obsession | Rushing at end | Checklist mentality |
| Dependency on prompts | Users waiting for AI | Wrong value prop |

### Qualitative Success Indicators

- "I forgot the tool was running until the summary"
- "The summary caught something I missed"
- "I felt more present with the participant"
- "My post-interview synthesis was faster"
- "It only spoke up when it really mattered"

---

## Risks and Mitigations (Revised)

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **Audio setup too hard for non-technical users** | HIGH | HIGH | First-class setup wizard, clear failure detection, video guides |
| **Coaching prompts disrupt interview flow** | MEDIUM | CRITICAL | Silence-first philosophy, aggressive thresholds, timing rules |
| **Coaching prompts poorly timed** | MEDIUM | HIGH | Never prompt during interviewer speech, 5-second cooldown |
| **Topic tracking creates checklist mentality** | MEDIUM | MEDIUM | Remove "complete" state, soft visual language |
| **Speaker diarization errors erode trust** | MEDIUM | MEDIUM | Explicit limitations in copy, easy correction, manual toggle |
| **Users become dependent on prompts** | LOW | MEDIUM | Default coaching off for first session, emphasize safety-net positioning |
| **Transcription accuracy insufficient** | MEDIUM | HIGH | Clear audio requirements, easy correction, set expectations |
| **API latency causes lag** | LOW | HIGH | Connection quality indicator, graceful degradation |
| **OpenAI API changes/pricing** | MEDIUM | MEDIUM | Abstract API layer, log raw signals separately |
| **Consent/privacy concerns** | MEDIUM | HIGH | Built-in disclosure templates, session modes, clear data handling |

---

## Launch Plan

### Phase 1: Internal Dogfooding (Weeks 1-8)
- Build MVP with P0 features
- BCM team uses for real interviews
- Focus on: Does audio setup work? Is coaching too intrusive?
- Rapid iteration based on feedback
- Target: 20 internal sessions

### Phase 2: Private Beta (Weeks 9-12)
- Recruit 10-20 external researchers
- Requirement: 5+ years experience (target persona)
- Structured feedback sessions
- Focus on: Trust, invisibility, post-session value
- Target: 100 external sessions

### Phase 3: Public Launch (Week 13+)
- Product Hunt launch
- Position as: "For experienced researchers who want leverage"
- UX research community outreach (ResearchOps, Mixed Methods)
- Content marketing focused on philosophy, not features
- Target: 100 paying users in first quarter

---

## Open Questions (Revised)

1. **First-session coaching default:** Should coaching be OFF by default for the first session to let users experience transcription value first?

2. **Audio alternatives:** Should we invest in ScreenCaptureKit (macOS 13+) as a BlackHole alternative to reduce setup friction?

3. **Post-interview coaching:** Would users value more detailed AI feedback in the post-session summary, even if live coaching stays minimal?

4. **Team features timing:** When should we add the ability to share sessions/templates across a team?

5. **Mobile companion:** Is there value in a simple iOS app that shows session status/topics for researchers who interview on the go?

---

## Appendix

### A. System Prompt (Full Version)

```
You are a research interview observer for an experienced UX researcher. Your role is to watch silently and only intervene when genuinely necessary.

## Your Default State
SILENCE. You are not a participant in this conversation. You are a safety net.

## When to Use show_nudge (Rare)
Only call show_nudge when ALL of the following are true:
1. The participant expressed something significant (strong emotion, explicit frustration, surprising statement, or contradiction)
2. AND the researcher has not already responded to it or acknowledged it
3. AND at least 2 minutes have passed since your last prompt
4. AND the interviewer is NOT currently speaking
5. AND at least 5 seconds have passed since the interviewer stopped speaking
6. AND you have HIGH confidence this is genuinely important

When in doubt, do not prompt. A missed opportunity is better than a mistimed interruption.

## When to Use flag_insight
Flag moments that are genuinely notable:
- Strong emotional statements ("I was so frustrated I almost quit")
- Surprising revelations that contradict assumptions
- Specific stories or examples that illustrate broader patterns
- Explicit unmet needs or desires

Do not flag:
- General statements of satisfaction or dissatisfaction
- Vague or unclear comments
- Things the researcher is already exploring

## When to Use update_topic
Update topic status only when:
- "touched": The participant has mentioned the topic at least once with relevance
- "explored": There has been substantial back-and-forth (3+ exchanges) about the topic

Never:
- Mark a topic as explored just because it was mentioned
- Update topics based on superficial references
- Assume topics are "complete" (that status doesn't exist)

## Your Philosophy
The researcher is skilled. They don't need guidance. Your job is to:
1. Notice what they might have missed
2. Capture insights they might not have time to note
3. Track awareness of topics without creating anxiety
4. Provide useful reflection AFTER the interview

Trust the researcher. Stay quiet. Intervene only when it truly matters.

## Current Research Context
Research Topics: {topics_list}
Session Duration: {planned_duration}
Researcher's Note: {researcher_notes}
```

### B. Audio Setup Troubleshooting Guide

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| No audio levels at all | BlackHole not installed | Re-run installation |
| System audio but no mic | Wrong input selected | Check Audio MIDI Setup |
| Mic but no system audio | Multi-Output not configured | Create Multi-Output device |
| Choppy audio | Sample rate mismatch | Ensure 48kHz on all devices |
| Audio stops after 10 min | System audio routing reset | Re-select Multi-Output as default |

### C. Disclosure Template Variants

**Standard (Full AI):**
```
"This interview will be recorded and transcribed using AI assistance. 
The AI helps me stay focused but does not participate in the conversation. 
Your responses will be stored securely and used only for research purposes."
```

**Minimal (Transcription Only):**
```
"This interview will be recorded and transcribed. 
The transcript helps me ensure I capture your thoughts accurately."
```

**Research Study (IRB-appropriate):**
```
"This session will be recorded and transcribed using [Service Name] AI transcription. 
The AI processes audio in real-time but does not store data beyond the session. 
Transcripts will be stored securely on [platform] and retained for [period]. 
You may request deletion of your data at any time."
```

---

**Document Status:** Ready for development  
**Key Changes:** Silence-first coaching, audio setup as P0, softened topic tracking, post-interview summary elevated  
**Next Step:** Update project plan to reflect revised priorities
