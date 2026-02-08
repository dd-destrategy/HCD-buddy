# Web Architecture Evaluation: HCD Interview Coach

> **Date:** 2026-02-08
> **Context:** Evaluating the feasibility and trade-offs of pivoting the native macOS app to a web-based platform.

## Executive Summary

A phased web migration is recommended over a full rewrite. The native macOS app should continue serving power users while a web layer expands market reach 4-5x. The key insight: **stop trying to capture system audio in a browser** — use meeting bots for remote interviews and `getUserMedia` for in-person sessions.

---

## 1. What We Gain

| Gain | Impact |
|------|--------|
| **4-5x market reach** | No longer limited to macOS users (~15% desktop market) |
| **Instant deployment** | No app downloads, no notarization, no Sparkle updates |
| **Zero setup friction** | Eliminates BlackHole virtual audio driver installation + 6-screen wizard |
| **Natural collaboration** | Real-time sharing of transcripts, highlights, and insights across team members |
| **Cross-device access** | Researchers can review sessions on any device, anywhere |
| **Faster iteration** | Web deploys in minutes vs. macOS build → notarize → distribute pipeline |
| **Easier onboarding** | "Open a link" vs. "Download app, install BlackHole, configure Multi-Output Device" |

## 2. What We Lose

| Loss | Severity | Mitigation |
|------|----------|------------|
| **System audio capture** | High | Meeting bot (Recall.ai) for remote; getUserMedia for in-person |
| **Offline capability** | Medium | Service Worker + IndexedDB for post-session review; live sessions need connectivity anyway |
| **Native OS integrations** | Medium | Keychain → encrypted cookies/server-side secrets; EventKit → Google Calendar API |
| **Performance for real-time audio** | Medium | WebSocket relay + Web Audio API; latency ~50-100ms higher than native |
| **App Store distribution** | Low | Web doesn't need it; Tauri wrapper for "app-like" experience if desired |
| **SwiftData local persistence** | Low | PostgreSQL + Drizzle ORM; IndexedDB for offline cache |

## 3. Recommended Technology Stack

```
┌─────────────────────────────────────────────────┐
│                   Frontend                       │
│  Next.js 15+ (App Router)                       │
│  React 19 + TypeScript                          │
│  Zustand (state management)                     │
│  Radix UI + Tailwind CSS (component library)    │
│  Web Audio API (local audio processing)         │
└──────────────────┬──────────────────────────────┘
                   │ WebSocket + REST
┌──────────────────▼──────────────────────────────┐
│                   Backend                        │
│  Node.js + Hono/Fastify                         │
│  WebSocket relay (real-time transcription)       │
│  OpenAI Realtime API proxy                      │
│  Meeting Bot integration (Recall.ai)            │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│                   Data Layer                     │
│  PostgreSQL + Drizzle ORM                       │
│  Redis (session state, WebSocket pub/sub)       │
│  S3-compatible storage (audio recordings)       │
│  Auth: Clerk or NextAuth.js                     │
└─────────────────────────────────────────────────┘
```

### Why These Choices

- **Next.js 15+**: Server components reduce bundle size; App Router for nested layouts matching our sidebar/panel UI
- **Zustand**: Lightweight alternative to Redux; maps cleanly to our `@StateObject` / `ObservableObject` pattern
- **Radix UI + Tailwind**: Accessible primitives (mirrors our WCAG 2.1 AA target) + utility-first styling
- **Drizzle ORM**: Type-safe SQL that maps well from SwiftData's declarative model style
- **Hono/Fastify**: Lightweight, WebSocket-friendly server frameworks

## 4. Audio Capture Strategy

### The Core Problem

Browsers cannot capture system audio the way macOS + BlackHole can. The Web Audio API's `getDisplayMedia` with `audio: true` is unreliable across browsers and requires user interaction every time.

### The Solution: Meeting Bots

| Scenario | Solution | How It Works |
|----------|----------|--------------|
| **Remote interviews** (Zoom, Meet, Teams) | Meeting Bot (Recall.ai or custom) | Bot joins the call as a participant, captures audio server-side, streams transcription via WebSocket |
| **In-person interviews** | `getUserMedia` | Browser captures microphone audio directly; works reliably across all browsers |
| **Hybrid** | Both | Detect context and offer appropriate capture method |

**Why Recall.ai?**
- Supports Zoom, Google Meet, Microsoft Teams, Webex
- Handles recording consent notices automatically
- Provides real-time audio streams (not just post-call recordings)
- Eliminates the "install BlackHole + configure Multi-Output Device" friction entirely

### Alternative: Tauri Shell

For users who need native audio capture (e.g., capturing audio from specialized software), a Tauri wrapper provides:
- Native system audio access via platform APIs
- Web UI rendered in a lightweight WebView
- ~10MB binary vs. ~100MB+ Electron
- Rust backend for audio processing

## 5. Code Portability Analysis

### What Ports Directly (~40-50% of business logic)

| Swift Service | TypeScript Equivalent | Effort |
|---------------|----------------------|--------|
| `CoachingService` | `CoachingEngine` class | Low — pure logic, no platform deps |
| `SentimentAnalyzer` | Direct port (word lists + rules) | Low |
| `BiasDetector` | Direct port (pattern matching) | Low |
| `PIIDetector` | Direct port (regex patterns) | Low |
| `RedactionService` | Direct port (state management) | Low |
| `QuestionTypeAnalyzer` | Direct port (classification rules) | Low |
| `HighlightService` | Adapt to REST API + DB | Medium |
| `ParticipantManager` | Adapt to REST API + DB | Medium |
| `CulturalContextManager` | Direct port (configuration logic) | Low |
| `CoachingTimingSettings` | Direct port (timer logic) | Low |
| `TaggingService` | Adapt to REST API + DB | Medium |

### What Must Be Rewritten (~15,000 lines of UI)

- All SwiftUI views → React components
- SwiftData models → Drizzle schema + React Query
- `AudioCaptureEngine` → Meeting Bot SDK + Web Audio API
- `RealtimeAPIClient` → WebSocket client (simpler in JS)
- `KeychainService` → Server-side encrypted storage
- `CalendarService` → Google Calendar API / Microsoft Graph
- `ExportService` → Server-side PDF/Markdown generation
- Design system (`LiquidGlass`, `Typography`, `Spacing`) → Tailwind config + CSS

### What's Not Needed

- `BlackHole` setup wizard (eliminated by meeting bot approach)
- `AudioCaptureEngine` (replaced by meeting bot)
- macOS entitlements and sandboxing
- Sparkle auto-update framework

## 6. Phased Migration Plan

### Phase 1: Web Post-Session Analysis (Months 0-3)

**Goal:** Ship a web app for reviewing completed sessions — no live audio needed.

- Build web dashboard for session review, transcript browsing, highlight management
- Import existing sessions via JSON export (already supported)
- Team collaboration: shared sessions, comments, highlight collections
- **Effort:** 8-10 weeks, 2-3 developers
- **Value:** Immediate team collaboration; validates web stack

### Phase 2: Web Live Sessions via Meeting Bot (Months 3-6)

**Goal:** Full live interview support through the web.

- Integrate Recall.ai (or build custom meeting bot)
- Real-time transcription via WebSocket relay
- Port coaching engine to TypeScript
- Live coaching prompts in browser
- **Effort:** 10-14 weeks, 2-3 developers
- **Value:** Full product parity for remote interviews (80%+ of use cases)

### Phase 3: Tauri Shell + Native Deprecation (Months 6-12)

**Goal:** Cover edge cases that need native audio; sunset pure macOS app.

- Build Tauri wrapper for native audio capture scenarios
- Windows/Linux support "for free" via Tauri
- Migrate remaining macOS-only users to web + Tauri
- **Effort:** 7-11 weeks, 1-2 developers
- **Value:** Full platform coverage; single codebase

### Total Estimated Effort

- **25-35 developer-weeks** across all phases
- Phased delivery means **value ships incrementally** starting at week 8-10
- macOS app continues working during entire migration

## 7. Competitive Landscape

| Competitor | Platform | Audio Strategy |
|------------|----------|----------------|
| **Dovetail** | Web | File upload + integrations (Zoom, Teams) |
| **Condens** | Web | File upload + manual transcription |
| **Lookback** | Web + native | Browser extension + native recorder |
| **tl;dv** | Web | Meeting bot (Zoom, Meet, Teams) |
| **Grain** | Web | Meeting bot (Zoom, Meet) |
| **Otter.ai** | Web + mobile | Cloud recording + meeting bot |
| **HCD Coach** | macOS only | BlackHole virtual audio driver |

**Key insight:** Every competitor is web-first. Our native-only positioning is a market reach liability, not a differentiator. The BlackHole setup requirement is a significant adoption barrier.

## 8. Recommendation

**Pursue phased web migration.** Specifically:

1. **Don't do a full rewrite** — the macOS app works and serves current users
2. **Start with Phase 1** (post-session web) to validate the stack and ship value fast
3. **Phase 2** (meeting bot) covers 80%+ of interview scenarios without any native code
4. **Phase 3** (Tauri) is optional — only if native audio capture demand is significant
5. **Keep the macOS app maintained** during migration but freeze new feature development after Phase 2

The meeting bot approach is the critical architectural insight. It eliminates the hardest technical problem (browser audio capture) while actually **improving** the user experience (no BlackHole setup, automatic recording consent, works with any meeting platform).

---

*Generated by Technical Architect + Product Strategist evaluation agents, 2026-02-08*
