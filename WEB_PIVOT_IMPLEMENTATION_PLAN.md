# HCD Interview Coach — Web Pivot Implementation Plan

> **Date:** 2026-02-08
> **Scope:** Full pivot from native macOS to web-based platform
> **Phases:** Phase 1 (Post-Session Web) + Phase 2 (Live Sessions) + macOS Archive
> **Supersedes:** Native macOS development roadmap

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Technology Stack](#2-technology-stack)
3. [Monorepo Structure](#3-monorepo-structure)
4. [Database Schema](#4-database-schema)
5. [Phase 1: Post-Session Web Platform](#5-phase-1-post-session-web-platform)
6. [Phase 2: Live Sessions via Meeting Bot](#6-phase-2-live-sessions-via-meeting-bot)
7. [Code Portability Map](#7-code-portability-map)
8. [Authentication & Authorization](#8-authentication--authorization)
9. [Deployment Architecture](#9-deployment-architecture)
10. [macOS App Archive Plan](#10-macos-app-archive-plan)
11. [Cost Model](#11-cost-model)
12. [Risk Register](#12-risk-register)
13. [Sprint Breakdown](#13-sprint-breakdown)

---

## 1. Executive Summary

The HCD Interview Coach is pivoting from a native macOS app (Swift/SwiftUI/SwiftData) to a web-based platform (Next.js/React/PostgreSQL). This plan covers full implementation of Phase 1 (post-session analysis & collaboration) and Phase 2 (live interview sessions via meeting bot), followed by archiving the macOS codebase.

**What exists today:**
- 210 Swift files, 88,598 lines of code
- 151 source files (51,527 lines) + 59 test files (37,071 lines)
- 16 implemented features across 2 batches
- Mobile UI optimizations for iOS/iPadOS

**What we're building:**
- Web platform with real-time collaboration
- Meeting bot integration for live audio capture (Recall.ai)
- Server-side persistence (PostgreSQL) replacing local SwiftData
- Team features (shared sessions, comments, multi-user)

**Key architectural insight:** ~40-50% of business logic (coaching engine, sentiment analysis, bias detection, PII detection, question classification) ports directly to TypeScript with minimal changes. The UI layer (~15,000 lines) must be completely rewritten in React.

---

## 2. Technology Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **Framework** | Next.js 15+ (App Router) | Server Components for performance; Client Components for real-time UI |
| **Language** | TypeScript 5.5+ | Type safety matching Swift's strong typing |
| **State** | Zustand | Lightweight; maps to `@StateObject` / `ObservableObject` pattern |
| **UI Components** | Radix UI + Tailwind CSS | Accessible primitives (WCAG 2.1 AA) + utility-first styling |
| **WebSocket** | Custom Node.js server + `ws` library | Full control over audio relay; noServer mode shares port with Next.js |
| **Meeting Bot** | Recall.ai | Real-time WebSocket audio streaming; $0.50/hour; Zoom/Meet/Teams/Webex |
| **AI** | OpenAI Realtime API (server-side WebSocket) | Direct server-to-server; transcription + coaching in one connection |
| **ORM** | Drizzle ORM | SQL-first, 7.4kb, zero deps, type-safe; maps well from SwiftData |
| **Database** | PostgreSQL 16 (managed) | Co-located with app; proven for real-time workloads |
| **Cache** | Redis | WebSocket pub/sub for multi-instance scaling; session state cache |
| **Auth** | Better Auth | Free at scale; Drizzle adapter; RBAC + organizations built-in |
| **Deployment** | Railway | Full WebSocket support; managed Postgres + Redis; $8-15/mo base |
| **Monorepo** | Turborepo + pnpm workspaces | Incremental builds; remote caching; parallel tasks |
| **CI/CD** | GitHub Actions | Existing pipeline; add web build/test/deploy stages |
| **Browser Audio** | getUserMedia (mic only) | Reliable cross-browser; Recall.ai handles meeting audio |

### Why NOT Vercel

Vercel's serverless functions do not support WebSocket upgrade. Our app requires persistent WebSocket connections for:
- Live transcription relay from Recall.ai
- Real-time coaching prompts to browser
- OpenAI Realtime API server-side connection

Railway provides container-based deployment with full WebSocket support and managed databases in one platform.

---

## 3. Monorepo Structure

```
hcd-web/
├── apps/
│   └── web/                        # Next.js 15 App Router
│       ├── app/                    # Pages and layouts
│       │   ├── (auth)/             # Auth pages (sign-in, sign-up)
│       │   ├── (dashboard)/        # Authenticated dashboard
│       │   │   ├── sessions/       # Session list, detail, review
│       │   │   ├── library/        # Quote library, highlights
│       │   │   ├── analytics/      # Cross-session analytics
│       │   │   ├── participants/   # Participant management
│       │   │   ├── live/           # Live session interface (Phase 2)
│       │   │   └── settings/       # User preferences
│       │   ├── api/                # REST API route handlers
│       │   │   ├── sessions/
│       │   │   ├── export/
│       │   │   ├── participants/
│       │   │   └── webhooks/       # Recall.ai webhooks (Phase 2)
│       │   └── layout.tsx          # Root layout
│       ├── components/             # App-specific React components
│       │   ├── transcript/         # TranscriptPanel, UtteranceRow
│       │   ├── coaching/           # CoachingPanel, PromptCard
│       │   ├── session/            # SessionControls, SetupWizard
│       │   ├── analytics/          # Charts, EmotionalArc
│       │   └── export/             # ExportDialog, FormatPicker
│       ├── hooks/                  # Custom React hooks
│       │   ├── useWebSocket.ts     # WebSocket connection manager
│       │   ├── useSession.ts       # Session state hook
│       │   └── useCoaching.ts      # Coaching engine hook
│       ├── server.ts               # Custom Node.js server (ws + Next.js)
│       ├── next.config.js
│       ├── Dockerfile
│       ├── tailwind.config.ts
│       └── package.json
│
├── packages/
│   ├── db/                         # Drizzle ORM schema + migrations
│   │   ├── src/
│   │   │   ├── schema/
│   │   │   │   ├── sessions.ts
│   │   │   │   ├── utterances.ts
│   │   │   │   ├── insights.ts
│   │   │   │   ├── highlights.ts
│   │   │   │   ├── participants.ts
│   │   │   │   ├── tags.ts
│   │   │   │   ├── redactions.ts
│   │   │   │   ├── consent.ts
│   │   │   │   └── users.ts
│   │   │   ├── migrations/
│   │   │   └── client.ts           # Drizzle client singleton
│   │   ├── drizzle.config.ts
│   │   └── package.json
│   │
│   ├── engine/                     # Ported business logic (TypeScript)
│   │   ├── src/
│   │   │   ├── coaching/
│   │   │   │   ├── coaching-service.ts
│   │   │   │   ├── coaching-thresholds.ts
│   │   │   │   ├── coaching-timing.ts
│   │   │   │   ├── follow-up-suggester.ts
│   │   │   │   └── question-type-analyzer.ts
│   │   │   ├── analysis/
│   │   │   │   ├── sentiment-analyzer.ts
│   │   │   │   ├── bias-detector.ts
│   │   │   │   ├── talk-time-analyzer.ts
│   │   │   │   └── pii-detector.ts
│   │   │   ├── redaction/
│   │   │   │   └── redaction-service.ts
│   │   │   ├── export/
│   │   │   │   ├── markdown-exporter.ts
│   │   │   │   └── json-exporter.ts
│   │   │   └── models/
│   │   │       ├── speaker.ts
│   │   │       ├── cultural-context.ts
│   │   │       ├── consent-template.ts
│   │   │       └── interview-template.ts
│   │   └── package.json
│   │
│   ├── ws-protocol/                # WebSocket message types
│   │   ├── src/
│   │   │   ├── messages.ts         # Typed message definitions
│   │   │   └── codec.ts           # Encode/decode helpers
│   │   └── package.json
│   │
│   ├── ui/                         # Shared design system
│   │   ├── src/
│   │   │   ├── tokens/
│   │   │   │   ├── colors.ts      # Color tokens (maps from Colors.swift)
│   │   │   │   ├── typography.ts  # Typography tokens
│   │   │   │   ├── spacing.ts     # Spacing scale
│   │   │   │   └── glass.ts       # Glassmorphism effects (CSS)
│   │   │   └── components/
│   │   │       ├── button.tsx
│   │   │       ├── card.tsx
│   │   │       ├── panel.tsx
│   │   │       └── badge.tsx
│   │   └── package.json
│   │
│   ├── auth/                       # Better Auth configuration
│   │   └── package.json
│   │
│   ├── eslint-config/
│   │   └── package.json
│   │
│   └── tsconfig/
│       └── package.json
│
├── turbo.json
├── pnpm-workspace.yaml
├── package.json
├── Dockerfile
└── .github/
    └── workflows/
        ├── ci.yml
        └── deploy.yml
```

---

## 4. Database Schema

### Core Tables (maps from SwiftData models)

```sql
-- Users & Auth (managed by Better Auth)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Organizations (team support)
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE organization_members (
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member', -- 'owner', 'admin', 'member', 'viewer'
    PRIMARY KEY (organization_id, user_id)
);

-- Studies (cross-session grouping)
CREATE TABLE studies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    owner_id UUID REFERENCES users(id),
    title TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Sessions (maps from Session @Model)
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    study_id UUID REFERENCES studies(id) ON DELETE SET NULL,
    owner_id UUID REFERENCES users(id),
    title TEXT NOT NULL,
    session_mode TEXT NOT NULL DEFAULT 'interview', -- 'interview', 'usability', 'discovery'
    status TEXT NOT NULL DEFAULT 'draft', -- 'draft', 'ready', 'running', 'paused', 'ended'
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    duration_seconds INTEGER,
    template_id UUID,
    participant_id UUID REFERENCES participants(id) ON DELETE SET NULL,
    consent_status TEXT DEFAULT 'not_obtained',
    coaching_enabled BOOLEAN DEFAULT false,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Utterances (maps from Utterance @Model)
CREATE TABLE utterances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    speaker TEXT NOT NULL, -- 'interviewer', 'participant'
    text TEXT NOT NULL,
    start_time REAL NOT NULL,
    end_time REAL,
    confidence REAL,
    sentiment_score REAL,
    sentiment_polarity TEXT, -- 'positive', 'negative', 'neutral', 'mixed'
    is_redacted BOOLEAN DEFAULT false,
    redacted_text TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Full-text search on utterances
ALTER TABLE utterances ADD COLUMN search_vector tsvector
    GENERATED ALWAYS AS (to_tsvector('english', text)) STORED;
CREATE INDEX idx_utterances_search ON utterances USING gin(search_vector);

-- Insights (maps from Insight @Model)
CREATE TABLE insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    utterance_id UUID REFERENCES utterances(id) ON DELETE SET NULL,
    source TEXT NOT NULL, -- 'manual', 'auto_emotional_shift', 'auto_bias', 'auto_pii'
    note TEXT,
    timestamp REAL NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Topics (maps from TopicStatus @Model)
CREATE TABLE topic_statuses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    topic_name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'not_covered', -- 'not_covered', 'partial', 'covered'
    covered_at TIMESTAMPTZ,
    UNIQUE(session_id, topic_name)
);

-- Coaching Events (maps from CoachingEvent @Model)
CREATE TABLE coaching_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    prompt_type TEXT NOT NULL,
    prompt_text TEXT NOT NULL,
    confidence REAL,
    response TEXT, -- 'accepted', 'dismissed', 'snoozed', 'expired'
    displayed_at TIMESTAMPTZ NOT NULL,
    responded_at TIMESTAMPTZ,
    cultural_context TEXT
);

-- Highlights (maps from Highlight Codable struct)
CREATE TABLE highlights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    utterance_id UUID REFERENCES utterances(id) ON DELETE SET NULL,
    owner_id UUID REFERENCES users(id),
    title TEXT NOT NULL,
    category TEXT NOT NULL, -- 'pain_point', 'user_need', 'delight', 'workaround', 'feature_request', 'key_quote'
    text_selection TEXT NOT NULL,
    notes TEXT,
    is_starred BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Tags (maps from Tag Codable struct)
CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    color TEXT,
    parent_id UUID REFERENCES tags(id) ON DELETE SET NULL,
    UNIQUE(organization_id, name)
);

CREATE TABLE utterance_tags (
    utterance_id UUID REFERENCES utterances(id) ON DELETE CASCADE,
    tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (utterance_id, tag_id)
);

-- Participants (maps from Participant Codable struct)
CREATE TABLE participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    role TEXT,
    department TEXT,
    experience_level TEXT, -- 'novice', 'intermediate', 'expert'
    metadata JSONB DEFAULT '{}', -- custom screener fields
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- PII Redactions
CREATE TABLE redactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    utterance_id UUID NOT NULL REFERENCES utterances(id) ON DELETE CASCADE,
    pii_type TEXT NOT NULL, -- 'email', 'phone', 'ssn', 'name', 'company', 'address'
    original_text TEXT NOT NULL,
    replacement TEXT DEFAULT '[REDACTED]',
    decision TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'redact', 'keep', 'replace'
    decided_by UUID REFERENCES users(id),
    decided_at TIMESTAMPTZ
);

-- Consent Records
CREATE TABLE consent_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    participant_id UUID REFERENCES participants(id) ON DELETE SET NULL,
    template_version TEXT NOT NULL,
    status TEXT NOT NULL, -- 'not_obtained', 'verbal', 'written', 'declined'
    permissions JSONB NOT NULL, -- array of {name, accepted, required}
    signature_name TEXT,
    obtained_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Session Comments (NEW — team collaboration)
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    utterance_id UUID REFERENCES utterances(id) ON DELETE SET NULL,
    author_id UUID NOT NULL REFERENCES users(id),
    text TEXT NOT NULL,
    timestamp REAL, -- optional: anchor to session timeline
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Interview Templates
CREATE TABLE templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    owner_id UUID REFERENCES users(id),
    name TEXT NOT NULL,
    description TEXT,
    topics TEXT[] NOT NULL DEFAULT '{}',
    coaching_prompts JSONB DEFAULT '[]',
    is_shared BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- User Preferences (maps from CoachingPreferences + UserDefaults)
CREATE TABLE user_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    coaching_enabled BOOLEAN DEFAULT false,
    auto_dismiss_preset TEXT DEFAULT 'standard', -- 'quick', 'standard', 'relaxed', 'extended', 'manual'
    coaching_delivery_mode TEXT DEFAULT 'realtime', -- 'realtime', 'pull', 'scheduled'
    cultural_preset TEXT DEFAULT 'western',
    cultural_context JSONB DEFAULT '{}',
    focus_mode TEXT DEFAULT 'coached', -- 'interview', 'coached', 'analysis'
    theme TEXT DEFAULT 'system',
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX idx_utterances_session ON utterances(session_id, start_time);
CREATE INDEX idx_insights_session ON insights(session_id);
CREATE INDEX idx_highlights_session ON highlights(session_id);
CREATE INDEX idx_highlights_category ON highlights(category);
CREATE INDEX idx_sessions_study ON sessions(study_id);
CREATE INDEX idx_sessions_owner ON sessions(owner_id);
CREATE INDEX idx_participants_org ON participants(organization_id);
CREATE INDEX idx_comments_session ON comments(session_id);
```

---

## 5. Phase 1: Post-Session Web Platform

**Goal:** Ship a web app for reviewing, analyzing, and collaborating on completed interview sessions. No live audio capture needed.

**Duration:** Weeks 1-8

### Phase 1A: Foundation (Weeks 1-3)

#### Sprint 1 (Week 1-2): Project Setup + Auth + Data Layer

| Task | Description | Files |
|------|-------------|-------|
| **Monorepo init** | Turborepo + pnpm + TypeScript config | Root config files |
| **Database setup** | Drizzle schema for all tables; initial migration | `packages/db/` |
| **Auth setup** | Better Auth with email/password + Google OAuth | `packages/auth/` |
| **Design system** | Port color tokens, typography, spacing to Tailwind config | `packages/ui/` |
| **App shell** | Next.js app with authenticated layout, navigation sidebar | `apps/web/app/` |
| **CI pipeline** | GitHub Actions: lint, type-check, test, build | `.github/workflows/ci.yml` |

**Deliverable:** Authenticated app shell with database. User can sign up, sign in, see empty dashboard.

#### Sprint 2 (Week 2-3): Session Import + Transcript Review

| Task | Description | Files |
|------|-------------|-------|
| **JSON import API** | Upload existing session exports → parse → insert into PostgreSQL | `api/sessions/import/` |
| **Session list page** | Paginated list with search, filter by date/study/status | `sessions/page.tsx` |
| **Session detail page** | Metadata header + transcript panel | `sessions/[id]/page.tsx` |
| **Transcript panel** | Virtualized utterance list with speaker labels, timestamps | `components/transcript/` |
| **Port Markdown exporter** | TypeScript port of MarkdownExporter.swift | `packages/engine/export/` |
| **Port JSON exporter** | TypeScript port of JSONExporter.swift | `packages/engine/export/` |
| **Export API** | Download session as Markdown or JSON | `api/export/` |

**Deliverable:** Import existing sessions and browse transcripts. Export to Markdown/JSON.

### Phase 1B: Analysis Features (Weeks 3-5)

#### Sprint 3 (Week 3-4): Business Logic Ports + Insights

| Task | Description | Source Swift File |
|------|-------------|-------------------|
| **Port SentimentAnalyzer** | Rules-based sentiment (word lists + heuristics) | `SentimentAnalyzer.swift` → `sentiment-analyzer.ts` |
| **Port QuestionTypeAnalyzer** | Question classification (open/closed/leading) | `QuestionTypeAnalyzer.swift` → `question-type-analyzer.ts` |
| **Port BiasDetector** | Pattern-based bias detection | `BiasDetector.swift` → `bias-detector.ts` |
| **Port PIIDetector** | Regex PII detection | `PIIDetector.swift` → `pii-detector.ts` |
| **Port TalkTimeAnalyzer** | Speaking ratio computation | `TalkTimeAnalyzer.swift` → `talk-time-analyzer.ts` |
| **Insight flagging UI** | View/create/edit insights on transcript | `components/insights/` |
| **Emotional arc chart** | Sentiment timeline visualization (Chart.js or Recharts) | `components/analytics/` |
| **Question analysis panel** | Question type distribution chart | `components/analytics/` |

**Deliverable:** Full post-session analysis — sentiment, question types, bias detection, talk-time ratio, PII detection.

#### Sprint 4 (Week 4-5): Tagging, Highlights, Redaction

| Task | Description | Source Swift File |
|------|-------------|-------------------|
| **Tagging system** | Hierarchical tags, inline tag application on utterances | `TaggingService.swift` → DB + API |
| **Highlight creation** | Select text → create highlight with category | `HighlightService.swift` → DB + API |
| **Quote library** | Cross-session highlight browsing with search | `QuoteLibraryView.swift` → React page |
| **PII redaction UI** | Review detected PII, approve/reject/replace | `RedactionService.swift` → DB + API |
| **Batch redaction** | Scan entire session, bulk review | `RedactionReviewView.swift` → React page |
| **Redaction-aware export** | Exports apply redactions | `packages/engine/export/` |

**Deliverable:** Full post-session workflow — tag, highlight, redact, export.

### Phase 1C: Collaboration + Polish (Weeks 5-8)

#### Sprint 5 (Week 5-6): Team Features

| Task | Description |
|------|-------------|
| **Organizations** | Create org, invite members, role management |
| **Session sharing** | Share sessions within organization |
| **Comments** | Timestamped comments on transcript segments |
| **Shared tag library** | Organization-wide tag hierarchies |
| **Shared templates** | Organization-level interview templates |
| **Activity feed** | Recent activity across team sessions |

**Deliverable:** Multi-user collaboration on session analysis.

#### Sprint 6 (Week 6-7): Cross-Session Analytics

| Task | Description | Source Swift File |
|------|-------------|-------------------|
| **Study management** | Group sessions into studies | `Study.swift` → DB + API |
| **Cross-session dashboard** | Theme trends, coverage patterns, coaching history | `CrossSessionAnalyticsView.swift` → React |
| **Participant management** | Participant CRUD, link to sessions, history | `ParticipantManager.swift` → DB + API |
| **Search** | Full-text search across all transcripts (PostgreSQL tsquery) | New |
| **Consent tracking** | Consent status per session + per participant | `ConsentTracker.swift` → DB + API |

**Deliverable:** Research intelligence platform — studies, participants, cross-session analytics.

#### Sprint 7 (Week 7-8): Polish + Deploy

| Task | Description |
|------|-------------|
| **Accessibility audit** | WCAG 2.1 AA compliance; keyboard navigation; screen reader testing |
| **Responsive design** | Tablet + mobile layouts |
| **Performance optimization** | Virtualized lists for large transcripts; optimistic updates |
| **Error handling** | Toast notifications, error boundaries, retry logic |
| **Onboarding flow** | First-run tutorial, sample session import |
| **Production deployment** | Railway: PostgreSQL + Redis + Next.js container |
| **Domain + SSL** | Custom domain, HTTPS |
| **Monitoring** | Error tracking (Sentry), analytics (Posthog or Plausible) |

**Deliverable:** Production-ready web platform for post-session analysis.

### Phase 1 Definition of Done

- [ ] User can sign up, sign in, manage account
- [ ] User can create organization, invite team members
- [ ] User can import existing sessions (JSON)
- [ ] User can browse session list with search/filter
- [ ] User can review full transcript with speaker labels
- [ ] User can flag insights on transcript
- [ ] User can view sentiment analysis + emotional arc
- [ ] User can view question type analysis
- [ ] User can view talk-time ratio
- [ ] User can detect and review PII in transcripts
- [ ] User can apply redactions (single + batch)
- [ ] User can create highlights with categories
- [ ] User can browse quote library across sessions
- [ ] User can tag utterances with hierarchical tags
- [ ] User can export sessions (Markdown, JSON) with redactions applied
- [ ] User can add timestamped comments on transcripts
- [ ] User can group sessions into studies
- [ ] User can manage participants and link to sessions
- [ ] User can view cross-session analytics dashboard
- [ ] User can manage consent status per session
- [ ] App is accessible (WCAG 2.1 AA)
- [ ] App is responsive (desktop + tablet + mobile)
- [ ] Deployed to production on Railway

---

## 6. Phase 2: Live Sessions via Meeting Bot

**Goal:** Full live interview support — real-time transcription, coaching, and analysis through the web browser.

**Duration:** Weeks 9-16

### Phase 2A: Real-Time Infrastructure (Weeks 9-11)

#### Sprint 8 (Week 9-10): WebSocket Server + Recall.ai Integration

| Task | Description |
|------|-------------|
| **Custom server** | Node.js server wrapping Next.js with `ws` WebSocket handling |
| **WebSocket protocol** | Typed message definitions in `packages/ws-protocol/` |
| **Recall.ai integration** | API client for bot management (create, join, leave, status) |
| **Recall.ai webhook handler** | Receive real-time events (bot joined, audio available, bot left) |
| **Audio relay** | Receive Recall.ai WebSocket audio → forward to OpenAI Realtime API |
| **Transcription relay** | Receive OpenAI transcription → broadcast to browser clients via WebSocket |
| **Session state machine** | Port SessionManager state machine (idle → ready → running → ended) |
| **`useWebSocket` hook** | React hook: typed messages, reconnection, cleanup |

**Architecture:**

```
Meeting Platform (Zoom/Meet/Teams)
    ↓ Recall.ai bot joins
Recall.ai Infrastructure
    ↓ Real-time WebSocket audio stream
┌─────────────────────────────────────┐
│ Railway: Custom Node.js Server       │
│                                      │
│ Recall.ai WS ──→ Audio Relay ──→ OpenAI Realtime API WS │
│                                  ↓                        │
│                    Transcription + Coaching                │
│                                  ↓                        │
│                    Browser WS ←── Broadcast                │
└─────────────────────────────────────┘
    ↓ WebSocket
Browser (Next.js Client Components)
    ├── TranscriptPanel (live updating)
    ├── CoachingPanel (real-time prompts)
    ├── TalkTimeIndicator (live ratio)
    └── TopicTracker (live coverage)
```

**Deliverable:** Real-time audio capture from any meeting platform. Transcription appears live in browser.

#### Sprint 9 (Week 10-11): Coaching Engine + Live UI

| Task | Description | Source Swift File |
|------|-------------|-------------------|
| **Port CoachingService** | Silence-first coaching logic (server-side) | `CoachingService.swift` → `coaching-service.ts` |
| **Port CoachingThresholds** | Threshold configuration | `CoachingThresholds.swift` → `coaching-thresholds.ts` |
| **Port CoachingTimingSettings** | Auto-dismiss, pull mode, delivery mode | `CoachingTimingSettings.swift` → `coaching-timing.ts` |
| **Port FollowUpSuggester** | Context-aware follow-up suggestions | `FollowUpSuggester.swift` → `follow-up-suggester.ts` |
| **Port CulturalContextManager** | Cultural sensitivity adjustments | `CulturalContext.swift` → `cultural-context.ts` |
| **Live coaching UI** | Coaching prompt cards with dismiss/accept/snooze | `components/coaching/` |
| **Coaching history** | Scrollback of all prompts shown during session | `components/coaching/` |
| **Settings panel** | Coaching preferences (timing, delivery mode, cultural context) | `settings/coaching/` |

**Deliverable:** Full coaching engine running server-side with real-time prompts delivered to browser.

### Phase 2B: Live Session Features (Weeks 11-14)

#### Sprint 10 (Week 11-12): Live Analysis

| Task | Description |
|------|-------------|
| **Live talk-time indicator** | Real-time interviewer/participant ratio (color-coded badge) |
| **Live topic tracking** | Topics check off as they're covered in conversation |
| **Live sentiment** | Sparkline showing emotional flow during session |
| **Live PII alerts** | Flag PII in real-time as utterances arrive |
| **Live insight flagging** | Keyboard shortcut (Cmd+I / Ctrl+I) to flag moments |
| **Focus modes** | Interview mode (transcript only) / Coached mode / Analysis mode |
| **Keyboard shortcuts** | Port all shortcuts: start/stop, pause, flag, toggle speaker, search |

**Deliverable:** Full live session experience with all analysis running in real-time.

#### Sprint 11 (Week 12-13): Session Setup + getUserMedia

| Task | Description |
|------|-------------|
| **Session setup wizard** | Template selection → participant selection → consent flow → start |
| **getUserMedia integration** | Microphone capture for in-person interviews (no meeting bot needed) |
| **Audio level meter** | Visual audio level indicator (Web Audio API AnalyserNode) |
| **Meeting link input** | Paste Zoom/Meet/Teams link → Recall.ai bot joins automatically |
| **Consent flow** | Port accessible consent wizard for pre-session consent capture |
| **Demo mode** | Sample session playback without any audio setup or API key |
| **Connection quality** | WebSocket connection status indicator with auto-reconnect |

**Deliverable:** Complete session setup flow supporting both meeting bot (remote) and microphone (in-person).

#### Sprint 12 (Week 13-14): Session Wrap-Up + Summary

| Task | Description | Source Swift File |
|------|-------------|-------------------|
| **Port SessionSummaryGenerator** | AI-generated session summary | `SessionSummaryGenerator.swift` → `session-summary-generator.ts` |
| **Post-session summary view** | Key themes, pain points, follow-up questions | `components/session/` |
| **Auto-save** | Utterances, insights, coaching events persisted in real-time | Server-side |
| **Session recording** | Store audio via Recall.ai recording URL (not self-hosted) | Metadata only |
| **Transition to review** | Session ends → redirect to post-session review (Phase 1 features) | Navigation |

**Deliverable:** Complete session lifecycle — setup → live → summary → review.

### Phase 2C: Collaboration + Polish (Weeks 14-16)

#### Sprint 13 (Week 14-15): Live Collaboration

| Task | Description |
|------|-------------|
| **Observer mode** | Share live session link → observers see transcript + add notes in real-time |
| **Observer question queue** | Observers suggest follow-up questions → interviewer sees in sidebar |
| **Live comments** | Observers add timestamped comments during live session |
| **Multi-device** | Same user can view session on laptop + phone simultaneously |
| **Notification** | Browser notifications for upcoming interviews (from participant schedule) |

**Deliverable:** Team can observe and contribute during live interviews.

#### Sprint 14 (Week 15-16): Production Hardening

| Task | Description |
|------|-------------|
| **Load testing** | Simulate 50 concurrent live sessions |
| **WebSocket scaling** | Redis pub/sub for multi-instance broadcast |
| **Silence detection** | Server-side VAD to avoid streaming silence to OpenAI (cost optimization) |
| **Error recovery** | WebSocket reconnection, session state recovery after disconnect |
| **Rate limiting** | API rate limits, WebSocket message throttling |
| **Audit logging** | Track session access, redaction decisions, data exports |
| **Data retention** | Configurable retention policies per organization |
| **GDPR compliance** | Data export, right to erasure, consent records |
| **End-to-end testing** | Playwright E2E tests for critical flows |
| **Performance profiling** | Lighthouse, Core Web Vitals |
| **Documentation** | API docs, deployment guide, user guide |

**Deliverable:** Production-ready live session platform.

### Phase 2 Definition of Done

- [ ] User can start a live session by pasting a meeting link (Zoom/Meet/Teams)
- [ ] Recall.ai bot joins the meeting and captures audio
- [ ] Real-time transcription appears in browser with speaker labels
- [ ] Coaching prompts appear in real-time (silence-first logic)
- [ ] User can configure coaching timing, delivery mode, cultural context
- [ ] Live talk-time ratio indicator works
- [ ] Live topic tracking works
- [ ] Live sentiment sparkline works
- [ ] User can flag insights during live session
- [ ] Focus modes switch between transcript-only / coached / analysis
- [ ] All keyboard shortcuts work
- [ ] User can start in-person session with microphone (getUserMedia)
- [ ] Session setup wizard covers template, participant, consent
- [ ] AI-generated session summary produced at end
- [ ] Session transitions to post-session review seamlessly
- [ ] Observers can view live session and add comments/questions
- [ ] Demo mode works without API key or meeting bot
- [ ] System handles 50+ concurrent live sessions
- [ ] WebSocket reconnection works after network interruption
- [ ] All Phase 1 features work with live-captured sessions

---

## 7. Code Portability Map

### Direct Port: Pure Business Logic (16 files → TypeScript)

These Swift files contain no platform dependencies and port directly:

| Swift File | TypeScript Target | Lines | Effort |
|-----------|-------------------|-------|--------|
| `CoachingService.swift` | `coaching-service.ts` | ~400 | 4h |
| `CoachingThresholds.swift` | `coaching-thresholds.ts` | ~120 | 1h |
| `CoachingTimingSettings.swift` | `coaching-timing.ts` | ~280 | 1h |
| `CoachingEventTracker.swift` | `coaching-event-tracker.ts` | ~200 | 2h |
| `FollowUpSuggester.swift` | `follow-up-suggester.ts` | ~300 | 3h |
| `QuestionTypeAnalyzer.swift` | `question-type-analyzer.ts` | ~350 | 3h |
| `SentimentAnalyzer.swift` | `sentiment-analyzer.ts` | ~600 | 3h |
| `BiasDetector.swift` | `bias-detector.ts` | ~440 | 2h |
| `PIIDetector.swift` | `pii-detector.ts` | ~480 | 3h |
| `MarkdownExporter.swift` | `markdown-exporter.ts` | ~250 | 2h |
| `JSONExporter.swift` | `json-exporter.ts` | ~150 | 1h |
| `Speaker.swift` | `speaker.ts` | ~30 | 0.5h |
| `InterviewTemplate.swift` | `interview-template.ts` | ~80 | 0.5h |
| `CulturalContext.swift` | `cultural-context.ts` | ~320 | 1h |
| `ConsentTemplate.swift` | `consent-template.ts` | ~280 | 1h |
| `Highlight.swift` (model) | `highlight.ts` | ~165 | 0.5h |

**Subtotal: ~4,445 lines → ~28 hours**

### Adapt: Platform Dependencies with Web Equivalents (18 files)

| Swift File | Platform Dep | Web Equivalent | Effort |
|-----------|--------------|----------------|--------|
| `Session.swift` | SwiftData `@Model` | Drizzle `pgTable` | 3h |
| `Utterance.swift` | SwiftData `@Model` | Drizzle `pgTable` | 2h |
| `Insight.swift` | SwiftData `@Model` | Drizzle `pgTable` | 2h |
| `TopicStatus.swift` | SwiftData `@Model` | Drizzle `pgTable` | 1h |
| `CoachingEvent.swift` | SwiftData `@Model` | Drizzle `pgTable` | 1h |
| `DataManager.swift` | SwiftData container | Drizzle client + connection pool | 8h |
| `KeychainService.swift` | macOS Keychain | Server env vars + JWT | 4h |
| `TemplateManager.swift` | SwiftData queries | Drizzle queries + Redis cache | 4h |
| `SessionManager.swift` | Orchestrates audio + API + SwiftData | WebSocket + Recall.ai + Drizzle | 12h |
| `RedactionService.swift` | JSON file persistence | PostgreSQL + API | 4h |
| `HighlightService.swift` | JSON file persistence | PostgreSQL + API | 5h |
| `TaggingService.swift` | JSON file persistence | PostgreSQL + API | 4h |
| `ParticipantManager.swift` | JSON file persistence | PostgreSQL + API | 4h |
| `ConsentTracker.swift` | JSON file persistence | PostgreSQL + API | 2h |
| `ExportService.swift` | AppKit file dialogs | Browser download API | 4h |
| `CoachingPreferences.swift` | UserDefaults | PostgreSQL user_preferences | 2h |
| `RealtimeAPIClient.swift` | URLSession WebSocket | `ws` library (server-side) | 6h |
| `FocusModeManager.swift` | SwiftUI state | Zustand store | 2h |

**Subtotal: ~63 hours**

### Rewrite: Deeply Platform-Tied (All SwiftUI views → React)

All ~90 SwiftUI view files must be rewritten as React components. Key rewrites:

| Swift View | React Component | Complexity |
|-----------|-----------------|------------|
| `ContentView.swift` | App shell + navigation | High |
| `TranscriptView.swift` | TranscriptPanel | High (virtualization) |
| `CoachingPromptView.swift` | CoachingPanel | Medium |
| `EmotionalArcView.swift` | EmotionalArcChart | Medium (charting library) |
| `QuoteLibraryView.swift` | QuoteLibraryPage | Medium |
| `RedactionReviewView.swift` | RedactionReviewPage | Medium |
| `ConsentFlowView.swift` | ConsentFlowWizard | Medium |
| `ParticipantPickerView.swift` | ParticipantPicker | Medium |
| `ExportView.swift` | ExportDialog | Low |
| All other views | Corresponding components | Varies |

**Subtotal: ~120 hours** (estimated from ~15,000 lines of SwiftUI)

### Drop: Not Needed in Web (4+ files)

| Swift File | Reason |
|-----------|--------|
| `BlackHoleDetector.swift` | No virtual audio driver needed |
| `MultiOutputDetector.swift` | No multi-output device needed |
| `AudioCaptureEngine.swift` | Replaced by Recall.ai + getUserMedia |
| `AudioSetup/` (entire wizard) | 6-screen wizard eliminated |
| `ClipboardService.swift` | Browser Clipboard API is native |
| `PlatformColor.swift` | Tailwind handles theming |
| `MobileContentView.swift` | Web is inherently responsive |
| Sparkle update framework | Web deploys instantly |

---

## 8. Authentication & Authorization

### Better Auth Configuration

```typescript
// packages/auth/src/config.ts
import { betterAuth } from 'better-auth';
import { drizzleAdapter } from 'better-auth/adapters/drizzle';
import { organization, rbac } from 'better-auth/plugins';
import { db } from '@hcd/db';

export const auth = betterAuth({
  database: drizzleAdapter(db),
  emailAndPassword: { enabled: true },
  socialProviders: {
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    },
  },
  plugins: [
    organization({
      roles: {
        owner: { permissions: ['*'] },
        admin: { permissions: ['session:*', 'member:invite', 'member:remove', 'settings:*'] },
        member: { permissions: ['session:create', 'session:read', 'session:update', 'comment:*', 'highlight:*', 'tag:*'] },
        viewer: { permissions: ['session:read', 'comment:read', 'highlight:read'] },
      },
    }),
    rbac(),
  ],
});
```

### Authorization Model

| Role | Capabilities |
|------|-------------|
| **Owner** | Full access; manage billing, delete org, transfer ownership |
| **Admin** | Manage members, templates, settings; all session operations |
| **Member** | Create/edit sessions, add comments/highlights/tags |
| **Viewer** | Read-only access to shared sessions |

---

## 9. Deployment Architecture

### Railway Configuration

```
Railway Project: hcd-web-production
├── Service: web (Docker container)
│   ├── Custom Node.js server (Next.js + ws)
│   ├── PORT: 3000
│   ├── Memory: 512MB-2GB (auto-scale)
│   ├── Region: US East (closest to OpenAI servers)
│   └── Health check: /api/health
│
├── Service: postgresql (managed)
│   ├── Version: 16
│   ├── Storage: 10GB (auto-expand)
│   └── Backups: Daily, 7-day retention
│
├── Service: redis (managed)
│   ├── Memory: 256MB
│   └── Purpose: WebSocket pub/sub, session cache
│
└── Private networking between all services
```

### Dockerfile

```dockerfile
FROM node:20-alpine AS base

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Build stage
FROM base AS builder
WORKDIR /app
COPY . .
RUN pnpm install --frozen-lockfile
RUN pnpm turbo build --filter=web

# Production stage
FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production

COPY --from=builder /app/apps/web/.next/standalone ./
COPY --from=builder /app/apps/web/.next/static ./apps/web/.next/static
COPY --from=builder /app/apps/web/public ./apps/web/public

EXPOSE 3000
CMD ["node", "apps/web/server.js"]
```

### Environment Variables

```env
# Database
DATABASE_URL=postgresql://user:pass@host:5432/hcd_web
REDIS_URL=redis://host:6379

# Auth
BETTER_AUTH_SECRET=...
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...

# OpenAI
OPENAI_API_KEY=sk-...

# Recall.ai
RECALL_API_KEY=...
RECALL_WEBHOOK_SECRET=...

# App
NEXT_PUBLIC_APP_URL=https://app.hcdcoach.com
NEXT_PUBLIC_WS_URL=wss://app.hcdcoach.com/ws
```

### CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm turbo lint type-check test build
      - uses: bervProject/railway-deploy@main
        with:
          railway_token: ${{ secrets.RAILWAY_TOKEN }}
          service: web
```

---

## 10. macOS App Archive Plan

### Timeline

| When | Action |
|------|--------|
| **Phase 1 launch** | Announce web platform; macOS app enters "maintenance mode" |
| **Phase 2 launch** | macOS app receives final update with migration notice |
| **Phase 2 + 4 weeks** | macOS app shows "sunset" banner with migration link |
| **Phase 2 + 12 weeks** | macOS app removed from distribution; repo archived |

### Migration Path for Existing Users

1. **Export all sessions** from macOS app as JSON (already supported)
2. **Sign up** on web platform
3. **Import sessions** via web upload (Phase 1 feature)
4. **All data preserved** — transcripts, insights, highlights, tags, redactions

### Repository Actions

```
Step 1: Create final macOS release tag
  git tag v1.0-final-macos -m "Final macOS release before web pivot"
  git push origin v1.0-final-macos

Step 2: Archive the macOS codebase
  Option A: Rename and archive in place
    - Move all Swift code to archive/macos/ directory
    - Keep README pointing to web platform

  Option B: Separate repository (recommended)
    - Create hcd-buddy-macos-archive repository
    - Push current codebase there
    - Mark as archived (read-only)
    - Update this repo for web development

Step 3: Initialize web codebase in this repo
  - Remove Swift source files
  - Initialize Turborepo monorepo structure
  - Keep docs/ and planning files
```

### Recommended: Option B — Separate Archive

```bash
# 1. Create archive repo and push macOS code
gh repo create dd-destrategy/hcd-buddy-macos-archive --private
git remote add archive https://github.com/dd-destrategy/hcd-buddy-macos-archive.git
git push archive main
gh repo archive dd-destrategy/hcd-buddy-macos-archive --yes

# 2. Create final release tag
git tag v1.0-final-macos -m "Final macOS release - migrating to web platform"
git push origin v1.0-final-macos

# 3. Clean this repo for web development
# (Remove Swift files, keep planning docs, initialize monorepo)
```

### Files to Preserve in Web Repo

| File | Reason |
|------|--------|
| `CLAUDE.md` | Project documentation (will be updated for web) |
| `FEATURE_EVALUATION_REPORT.md` | Product decisions |
| `WEB_ARCHITECTURE_EVALUATION.md` | Architecture decisions |
| `WEB_PIVOT_IMPLEMENTATION_PLAN.md` | This plan |
| `APPROVED_DECISIONS.md` | Product decisions |
| `PRODUCT_BACKLOG.md` | Feature backlog |
| `docs/` | Setup and architecture docs |
| `.github/workflows/` | CI/CD (will be rewritten) |

### Final macOS App Update

The last macOS release should include:
1. In-app banner: "HCD Interview Coach is moving to the web! Visit app.hcdcoach.com"
2. One-click "Export All Sessions" button for easy migration
3. Link to web sign-up with migration guide
4. No new features — bug fixes only

---

## 11. Cost Model

### Infrastructure Costs (Monthly)

| Service | Plan | Monthly Cost |
|---------|------|-------------|
| Railway (web server) | Pro | $10-20 |
| Railway (PostgreSQL) | Managed | $5-10 |
| Railway (Redis) | Managed | $3-5 |
| Domain + DNS | Cloudflare | $0-12/year |
| Error tracking | Sentry (free tier) | $0 |
| Analytics | Plausible | $9 |
| **Infrastructure total** | | **$27-44/month** |

### Per-Session Costs

| Component | Cost | Per 1-hour session |
|-----------|------|-------------------|
| Recall.ai (meeting bot) | $0.50/hour | $0.50 |
| OpenAI audio input | $0.06/min | $3.60 |
| OpenAI coaching output (text) | ~$0.01/session | $0.01 |
| Railway compute overhead | ~$0.01/hour | $0.01 |
| **Per-session total** | | **~$4.12/hour** |

### Cost Optimization Strategies

1. **Server-side VAD** — Don't stream silence to OpenAI (saves ~30-50% of audio input cost)
2. **Text-only coaching** — Use text output ($20/1M tokens) instead of audio ($200/1M tokens)
3. **Cached instructions** — Cache repeated system prompts ($20/1M vs $100/1M for audio input)
4. **Batch analysis** — Run sentiment/bias/PII analysis client-side (zero API cost)
5. **Optimized with VAD + text coaching** → estimated **~$2.50/hour**

### Break-Even Analysis

| Users | Sessions/month | Monthly Cost | Revenue needed |
|-------|---------------|-------------|----------------|
| 10 | 40 | $44 + $165 = $209 | $21/user/month |
| 50 | 200 | $44 + $825 = $869 | $17/user/month |
| 200 | 800 | $44 + $3,300 = $3,344 | $17/user/month |
| 500 | 2,000 | $44 + $8,250 = $8,294 | $17/user/month |

---

## 12. Risk Register

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|-----------|--------|------------|
| 1 | **Recall.ai API changes** | Low | High | Abstract behind interface; evaluate MeetingBaaS as backup |
| 2 | **OpenAI Realtime API price increase** | Medium | High | Server-side VAD reduces cost 50%; local Whisper fallback for transcription |
| 3 | **WebSocket scaling under load** | Medium | Medium | Redis pub/sub; horizontal scaling on Railway; load test at 50 concurrent sessions |
| 4 | **Meeting platform blocks bots** | Low | High | Recall.ai manages platform relationships; fallback to getUserMedia + screen share |
| 5 | **Browser audio quality issues** | Medium | Medium | getUserMedia is reliable for mic; Recall.ai handles meeting audio server-side |
| 6 | **Data migration loss** | Low | High | Validate JSON import with checksums; dry-run import before production |
| 7 | **Auth security breach** | Low | Critical | Better Auth with RBAC; audit logging; rate limiting; 2FA for admins |
| 8 | **Team adoption friction** | Medium | Medium | Onboarding wizard; sample session; video tutorials |
| 9 | **Drizzle ORM migration issues** | Low | Medium | Test migrations in CI; staging environment mirrors production |
| 10 | **Railway outage** | Low | High | Multi-region deployment option; database backups; status page monitoring |

---

## 13. Sprint Breakdown

### Phase 1: Post-Session Platform (Weeks 1-8)

| Sprint | Week | Focus | Key Deliverables |
|--------|------|-------|-----------------|
| **S1** | 1-2 | Foundation | Monorepo, DB schema, auth, app shell, CI |
| **S2** | 2-3 | Session Review | JSON import, session list, transcript viewer, export |
| **S3** | 3-4 | Analysis Engine | Port 6 analyzers (sentiment, question, bias, PII, talk-time, redaction) |
| **S4** | 4-5 | Post-Session Tools | Tagging, highlights, quote library, redaction UI |
| **S5** | 5-6 | Team Features | Organizations, sharing, comments, shared tags/templates |
| **S6** | 6-7 | Cross-Session | Studies, analytics dashboard, participants, search |
| **S7** | 7-8 | Production | Accessibility, responsive, performance, monitoring, deploy |

### Phase 2: Live Sessions (Weeks 9-16)

| Sprint | Week | Focus | Key Deliverables |
|--------|------|-------|-----------------|
| **S8** | 9-10 | Real-Time Infra | WebSocket server, Recall.ai integration, audio relay, transcription |
| **S9** | 10-11 | Coaching Engine | Port coaching service, live coaching UI, settings |
| **S10** | 11-12 | Live Analysis | Talk-time, topics, sentiment, PII alerts, focus modes, shortcuts |
| **S11** | 12-13 | Session Setup | Setup wizard, getUserMedia, meeting link, consent, demo mode |
| **S12** | 13-14 | Session Lifecycle | AI summary, auto-save, session transition to review |
| **S13** | 14-15 | Live Collaboration | Observer mode, question queue, live comments |
| **S14** | 15-16 | Production Hardening | Load testing, scaling, error recovery, GDPR, E2E tests, docs |

### Post-Phase 2: macOS Sunset (Weeks 16-20)

| Week | Action |
|------|--------|
| 16 | Final macOS update with migration banner + export helper |
| 17 | Archive macOS codebase to separate repository |
| 18 | Initialize web codebase in main repository |
| 19 | Update all documentation for web platform |
| 20 | macOS app sunset complete |

---

## Appendix A: WebSocket Message Protocol

```typescript
// packages/ws-protocol/src/messages.ts

// Client → Server
type ClientMessage =
  | { type: 'session.start'; sessionId: string; meetingUrl?: string }
  | { type: 'session.pause' }
  | { type: 'session.resume' }
  | { type: 'session.stop' }
  | { type: 'audio.chunk'; data: string } // base64 audio (getUserMedia)
  | { type: 'insight.flag'; timestamp: number; note?: string }
  | { type: 'coaching.respond'; eventId: string; response: 'accepted' | 'dismissed' | 'snoozed' }
  | { type: 'observer.join'; sessionId: string }
  | { type: 'observer.comment'; text: string; timestamp: number }
  | { type: 'observer.question'; text: string }

// Server → Client
type ServerMessage =
  | { type: 'session.status'; status: string }
  | { type: 'transcript.utterance'; utterance: Utterance }
  | { type: 'transcript.update'; utteranceId: string; text: string } // partial update
  | { type: 'coaching.prompt'; event: CoachingEvent }
  | { type: 'coaching.dismiss'; eventId: string } // auto-dismiss
  | { type: 'analysis.talktime'; ratio: { interviewer: number; participant: number } }
  | { type: 'analysis.sentiment'; score: number; polarity: string }
  | { type: 'analysis.topic'; topicName: string; status: string }
  | { type: 'analysis.pii'; utteranceId: string; detections: PIIDetection[] }
  | { type: 'analysis.bias'; alert: BiasAlert }
  | { type: 'observer.comment'; comment: Comment }
  | { type: 'observer.question'; question: string; from: string }
  | { type: 'session.summary'; summary: SessionSummary }
  | { type: 'error'; code: string; message: string }
  | { type: 'connection.quality'; latency: number; status: 'good' | 'degraded' | 'poor' }
```

## Appendix B: Design System Token Mapping

| Swift Token | Tailwind Equivalent |
|-------------|-------------------|
| `Typography.display` | `text-4xl font-bold` |
| `Typography.heading1` | `text-2xl font-semibold` |
| `Typography.heading2` | `text-xl font-semibold` |
| `Typography.heading3` | `text-lg font-semibold` |
| `Typography.body` | `text-base` |
| `Typography.bodyMedium` | `text-base font-medium` |
| `Typography.caption` | `text-sm text-muted-foreground` |
| `Typography.small` | `text-xs` |
| `Spacing.xxs` (2) | `space-0.5` or `gap-0.5` |
| `Spacing.xs` (4) | `space-1` or `p-1` |
| `Spacing.sm` (8) | `space-2` or `p-2` |
| `Spacing.md` (12) | `space-3` or `p-3` |
| `Spacing.lg` (16) | `space-4` or `p-4` |
| `Spacing.xl` (24) | `space-6` or `p-6` |
| `Spacing.xxl` (40) | `space-10` or `p-10` |
| `CornerRadius.small` (4) | `rounded` |
| `CornerRadius.medium` (8) | `rounded-lg` |
| `CornerRadius.large` (12) | `rounded-xl` |
| `CornerRadius.xl` (16) | `rounded-2xl` |
| `CornerRadius.pill` (9999) | `rounded-full` |
| `.liquidGlass()` | `backdrop-blur-md bg-white/10 border border-white/20` |
| `.glassPanel()` | `backdrop-blur-lg bg-white/5 border border-white/10` |
| `.glassCard()` | `backdrop-blur-sm bg-white/15 border border-white/20 rounded-xl` |
| `.glassButton()` | `backdrop-blur-md bg-white/20 hover:bg-white/30 rounded-lg` |

---

*This plan supersedes the native macOS development roadmap. All future feature development will target the web platform.*
