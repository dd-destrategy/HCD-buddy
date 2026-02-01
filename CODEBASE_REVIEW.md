# HCD Interview Coach — Codebase Review & Strategic Plan

**Version:** 1.0
**Date:** February 1, 2026
**Author:** Claude Code Team Analysis
**Status:** Complete

---

## Executive Summary

### Repository Status: Pre-Development Planning Phase

This repository contains **no code** — only comprehensive planning documentation for a native macOS application called "HCD Interview Coach." The product is designed to provide real-time AI support during human-centered design research interviews.

### Key Findings

| Area | Status | Risk Level |
|------|--------|------------|
| Product Vision | Excellent — clear, differentiated | Low |
| Documentation | Good but fragmented | Medium |
| Architecture | Sound design, gaps in details | Medium |
| Code | None exists | N/A |
| Testing Strategy | Missing | High |
| Accessibility | Missing | High |
| Security Considerations | Partial | Medium |

### Critical Actions Required Before Development

1. **Create design system** (Figma) — blocks all UI work
2. **Define testing strategy** — affects entire development approach
3. **Document accessibility requirements** — required for professional tool
4. **Specify error handling architecture** — affects all async code
5. **Archive outdated documentation** — reduce confusion

### Estimated Time to MVP

With the recommended foundation work: **10-13 weeks**

---

## Table of Contents

1. [Codebase Health Report](#1-codebase-health-report)
2. [Architecture Assessment](#2-architecture-assessment)
3. [Technical Debt Register](#3-technical-debt-register)
4. [Strategic Roadmap](#4-strategic-roadmap)
5. [Specification Backlog](#5-specification-backlog)
6. [Open Questions](#6-open-questions)
7. [Agent Analysis Summary](#7-agent-analysis-summary)

---

## 1. Codebase Health Report

### 1.1 Repository Inventory

```
/home/user/HCD-buddy/
├── .git/                                    # Git repository
├── hcd-interview-coach-prd-v1.1.md         # Product Requirements Document (990 lines)
├── hcd-interview-coach-outline.docx        # Functional & Technical Specification
└── hcd-interview-coach-spec.docx           # Technical Specification
```

**Total files:** 3 documentation files
**Code files:** 0
**Test files:** 0
**Configuration files:** 0

### 1.2 Documentation Quality

| Document | Lines | Quality | Freshness | Authority |
|----------|-------|---------|-----------|-----------|
| PRD v1.1 (md) | 990 | Excellent | Current (Jan 30, 2026) | Primary |
| Functional Spec (docx) | ~600 | Good | Older | Secondary |
| Technical Spec (docx) | ~400 | Good | Older | Secondary |

**Issues:**
- Docx files contain older thinking that conflicts with PRD v1.1
- No README.md (common entry point missing)
- No CONTRIBUTING.md or development guidelines

### 1.3 Planned Technology Assessment

| Technology | Choice | Assessment | Risk |
|------------|--------|------------|------|
| Platform | macOS 13+ | Appropriate for target users | Low |
| Language | Swift 5.9+ | Modern, well-supported | Low |
| UI | SwiftUI | Native, appropriate | Low |
| Audio | AVAudioEngine + BlackHole | Complex setup, fragile | **Medium** |
| AI | OpenAI Realtime API | Cutting-edge, may change | **Medium** |
| Storage | SwiftData | Modern, Apple-backed | Low |
| WebSocket | URLSessionWebSocketTask | Native, reliable | Low |

### 1.4 Risk Register

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| R-001 | Audio setup too complex for users | High | High | First-class setup wizard, video tutorials |
| R-002 | Coaching prompts disrupt interviews | Medium | Critical | Silence-first philosophy, aggressive thresholds |
| R-003 | API key stored insecurely | Medium | High | Use macOS Keychain |
| R-004 | OpenAI API changes break app | Medium | High | Abstract API layer, version pin |
| R-005 | No test coverage leads to bugs | High | High | Define testing strategy before coding |
| R-006 | Inaccessible app limits market | Medium | Medium | Accessibility requirements as P0 |
| R-007 | Memory issues in long sessions | Medium | Medium | Performance monitoring, virtualization |

### 1.5 Health Scores

| Dimension | Score | Notes |
|-----------|-------|-------|
| Vision Clarity | 9/10 | Excellent philosophy and positioning |
| Documentation | 7/10 | Good but fragmented |
| Architecture Design | 7/10 | Sound foundation, missing details |
| Code Quality | N/A | No code exists |
| Test Coverage | 0/10 | No tests or strategy |
| Security Posture | 5/10 | Privacy-first but implementation gaps |
| Accessibility | 2/10 | Not addressed |
| Operational Readiness | 3/10 | No CI/CD, monitoring, or crash reporting |

---

## 2. Architecture Assessment

### 2.1 Planned Architecture (Current)

```
┌──────────────────────────────────────────────────────────────────┐
│                         macOS Application                         │
├──────────────────────────────────────────────────────────────────┤
│  Presentation Layer (SwiftUI)                                     │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │ Main Window │ │ Transcript  │ │  Coaching   │ │  Settings   │ │
│  │             │ │   Panel     │ │   Panel     │ │             │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
├──────────────────────────────────────────────────────────────────┤
│  Business Logic Layer                                             │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────┐           │
│  │ AudioCapture  │ │  Realtime     │ │   Session     │           │
│  │   Service     │ │  APIClient    │ │   Manager     │           │
│  └───────────────┘ └───────────────┘ └───────────────┘           │
│  ┌───────────────┐ ┌───────────────┐                             │
│  │  Transcript   │ │   Coaching    │                             │
│  │  Processor    │ │   Engine      │                             │
│  └───────────────┘ └───────────────┘                             │
├──────────────────────────────────────────────────────────────────┤
│  Data Layer (SwiftData)                                           │
│  ┌─────────┐ ┌───────────┐ ┌─────────┐ ┌─────────────┐           │
│  │ Session │ │ Utterance │ │ Insight │ │ TopicStatus │           │
│  └─────────┘ └───────────┘ └─────────┘ └─────────────┘           │
└──────────────────────────────────────────────────────────────────┘
                                │
                                ▼
                ┌───────────────────────────────┐
                │   OpenAI Realtime API         │
                │   wss://api.openai.com/v1/    │
                │   realtime?model=gpt-realtime │
                └───────────────────────────────┘
```

### 2.2 Architecture Gaps

| Gap | Impact | Recommendation |
|-----|--------|----------------|
| No error handling architecture | Reliability issues | Define error types, recovery strategies |
| No state machine diagram | Implementation confusion | Document session states and transitions |
| No graceful degradation | Poor failure experience | Define offline/degraded modes |
| No logging architecture | Debugging difficulty | Implement structured logging |
| No dependency injection | Testing difficulty | Use protocols and DI |

### 2.3 Proposed Target Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                         macOS Application                         │
├──────────────────────────────────────────────────────────────────┤
│  Presentation Layer (SwiftUI + Accessibility)                     │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  Component Library (Design System)                           │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐        │ │
│  │  │ Views    │ │ Modifiers│ │ Themes   │ │ A11y     │        │ │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘        │ │
│  └─────────────────────────────────────────────────────────────┘ │
├──────────────────────────────────────────────────────────────────┤
│  Domain Layer (Business Logic)                                    │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────┐           │
│  │   Session     │ │   Coaching    │ │  Transcript   │           │
│  │   Coordinator │ │   Evaluator   │ │   Assembler   │           │
│  └───────────────┘ └───────────────┘ └───────────────┘           │
├──────────────────────────────────────────────────────────────────┤
│  Infrastructure Layer (Protocols + Implementations)               │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │ Protocols:     │ Implementations:                          │   │
│  │ - AudioSource  │ - BlackHoleAudioSource                    │   │
│  │ - AIClient     │ - OpenAIRealtimeClient (via SwiftOpenAI)  │   │
│  │ - Storage      │ - SwiftDataStorage                        │   │
│  │ - KeyStorage   │ - KeychainKeyStorage                      │   │
│  └───────────────────────────────────────────────────────────┘   │
├──────────────────────────────────────────────────────────────────┤
│  Cross-Cutting Concerns                                           │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │ Logging  │ │ Analytics│ │  Error   │ │ Feature  │            │
│  │          │ │          │ │ Handling │ │  Flags   │            │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘            │
└──────────────────────────────────────────────────────────────────┘
```

### 2.4 Key Architecture Decisions (Proposed)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| API Client | Use SwiftOpenAI package | Reduces risk, faster development |
| DI Approach | Protocol-based with manual injection | Testable, no framework dependency |
| State Management | Combine + @Observable | Native, modern Swift |
| Error Handling | Result type + typed errors | Explicit, composable |
| Logging | OSLog | Native, privacy-aware |

---

## 3. Technical Debt Register

Since no code exists, this section documents **documentation debt** and **anticipated debt** to avoid during implementation.

### 3.1 Documentation Debt

| ID | Description | Location | Severity | Effort | Action |
|----|-------------|----------|----------|--------|--------|
| DD-001 | Outdated docx specs conflict with PRD | Root dir | Medium | Low | Archive/remove |
| DD-002 | No README.md | Root dir | Medium | Low | Create |
| DD-003 | No CONTRIBUTING.md | Root dir | Low | Low | Create |
| DD-004 | Accessibility not documented | PRD | High | Medium | Add section |
| DD-005 | Test strategy missing | All docs | High | Medium | Create spec |
| DD-006 | Error handling undefined | Architecture | High | Medium | Create spec |

### 3.2 Anti-Patterns to Avoid

| ID | Anti-Pattern | Risk | Prevention |
|----|--------------|------|------------|
| AP-001 | API key in UserDefaults | Security breach | Use Keychain from day 1 |
| AP-002 | God object SessionManager | Unmaintainable | Split responsibilities |
| AP-003 | Untested real-time code | Bugs in production | Mock/record API sessions |
| AP-004 | Hardcoded strings | i18n blocked | Use NSLocalizedString |
| AP-005 | SwiftData default location | Data conflicts | Custom container location |

---

## 4. Strategic Roadmap

### 4.1 Phase Overview

```
Week 0-1   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  Foundation (Design, CI, Specs)
Week 2-4   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  Core Infrastructure
Week 5-7   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  Features (P0)
Week 8-10  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  Polish & Beta
Week 11-13 ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  Launch
```

### 4.2 Phase A: Foundation (Week 0-1)

**Objective:** Establish all foundations before writing product code.

| Task | Priority | Owner | Deliverable |
|------|----------|-------|-------------|
| Archive outdated docs | P0 | PM | Clean repo |
| Create design system | P0 | Designer | Figma file |
| Define project structure | P0 | Engineer | Folder structure doc |
| Set up Xcode project | P0 | Engineer | Working project |
| Configure CI/CD | P0 | DevOps | GitHub Actions |
| Write testing strategy | P0 | QA | Test strategy doc |
| Document a11y requirements | P0 | A11y | Requirements doc |
| Define error handling | P0 | Architect | ADR document |
| Create Keychain wrapper | P0 | Security | Code + tests |

**Exit Criteria:**
- [ ] Design system approved
- [ ] CI pipeline running
- [ ] All P0 specs written
- [ ] Project skeleton building

### 4.3 Phase B: Core Infrastructure (Week 2-4)

**Objective:** Build the technical foundation that all features depend on.

| Task | Priority | Owner | Deliverable |
|------|----------|-------|-------------|
| AudioCaptureService | P0 | Engineer | Working audio capture |
| Audio setup wizard | P0 | Engineer | UI + verification |
| RealtimeAPIClient | P0 | Engineer | WebSocket connection |
| SwiftData models | P0 | Engineer | Persistence layer |
| SessionManager | P0 | Engineer | State machine |
| Basic transcript view | P0 | Frontend | UI component |
| Connection monitoring | P0 | Engineer | Status UI |
| Unit tests | P0 | QA | 60%+ coverage |

**Exit Criteria:**
- [ ] Audio captured from Zoom/Teams/Meet
- [ ] Connected to OpenAI Realtime API
- [ ] Transcript displaying in real-time
- [ ] Test suite passing

### 4.4 Phase C: Features (Week 5-7)

**Objective:** Implement all P0 features.

| Task | Priority | Owner | Deliverable |
|------|----------|-------|-------------|
| Coaching prompts (silence-first) | P0 | Engineer | Prompt display |
| Topic awareness tracker | P0 | Engineer | Tracker UI |
| Insight flagging | P0 | Engineer | Manual + auto flagging |
| Post-interview summary | P1 | Engineer | Summary screen |
| Export (Markdown, JSON) | P0 | Engineer | Export functionality |
| Consent templates | P0 | Engineer | Templates UI |
| Session history | P1 | Engineer | History view |
| Accessibility audit | P0 | A11y | Audit report + fixes |

**Exit Criteria:**
- [ ] All P0 features working
- [ ] Accessibility audit passed
- [ ] Export functionality verified
- [ ] Internal testing started

### 4.5 Phase D: Polish & Beta (Week 8-10)

**Objective:** Prepare for external users.

| Task | Priority | Owner | Deliverable |
|------|----------|-------|-------------|
| Performance optimization | P1 | Engineer | Optimized app |
| Crash reporting | P1 | SRE | Reporting integration |
| User documentation | P1 | Writer | Docs site/README |
| Code signing | P0 | DevOps | Signed app |
| Beta distribution | P0 | DevOps | Sparkle/TestFlight |
| Internal dogfooding | P0 | Team | 20 sessions |
| Beta recruitment | P0 | PM | 10-20 researchers |

**Exit Criteria:**
- [ ] App notarized and distributable
- [ ] 20 internal sessions completed
- [ ] Beta users recruited
- [ ] Feedback mechanism active

### 4.6 Phase E: Launch (Week 11-13)

**Objective:** Public release.

| Task | Priority | Owner | Deliverable |
|------|----------|-------|-------------|
| Beta feedback incorporation | P0 | Team | Updated app |
| Product Hunt preparation | P1 | Marketing | PH listing |
| Launch content | P1 | Marketing | Blog, videos |
| Public release | P0 | Team | Available app |
| Post-launch monitoring | P0 | SRE | Dashboard |

---

## 5. Specification Backlog

### 5.1 Priority 0 (Before Any Code)

| # | Spec Title | Description | Est. Pages |
|---|------------|-------------|------------|
| S-001 | Error Handling Architecture | Error types, recovery strategies, user messaging | 3-5 |
| S-002 | Session State Machine | States, transitions, edge cases | 2-3 |
| S-003 | Testing Strategy | Unit, integration, E2E approach | 4-6 |
| S-004 | Accessibility Requirements | WCAG mapping, keyboard nav, VoiceOver | 3-4 |
| S-005 | Design System | Colors, typography, spacing, components | 5-8 |
| S-006 | Project Structure | Folders, naming conventions, patterns | 2-3 |

### 5.2 Priority 1 (Before Feature Implementation)

| # | Spec Title | Description | Est. Pages |
|---|------------|-------------|------------|
| S-007 | SwiftData Migration Plan | Schema versioning, migration strategy | 2-3 |
| S-008 | Performance Benchmarks | Memory limits, latency targets, monitoring | 2-3 |
| S-009 | Distribution Strategy | App Store vs. direct, updates, signing | 2-3 |
| S-010 | User Documentation Plan | Topics, format, hosting | 2-3 |

### 5.3 Spec Template

```markdown
# [Spec Title]

## Overview
Brief description of what this spec covers.

## Goals
- Goal 1
- Goal 2

## Non-Goals
- Explicitly out of scope

## Background
Context and prior decisions.

## Detailed Design
The actual specification.

## Alternatives Considered
Other options and why they were rejected.

## Open Questions
Unresolved decisions.

## References
Related documents and resources.
```

---

## 6. Open Questions

### 6.1 Product Questions

| # | Question | Impact | Owner | Status |
|---|----------|--------|-------|--------|
| Q-001 | Should coaching be OFF by default for first session? | User trust | PM | Open |
| Q-002 | Should we invest in ScreenCaptureKit as BlackHole alternative? | Setup friction | Engineer | Open |
| Q-003 | Is there budget for custom illustrations/branding? | Design quality | PM | Open |
| Q-004 | Who is the BCM team for dogfooding? | Testing | PM | Open |
| Q-005 | Mac App Store or direct distribution first? | Launch strategy | PM | Open |

### 6.2 Technical Questions

| # | Question | Impact | Owner | Status |
|---|----------|--------|-------|--------|
| Q-006 | Use SwiftOpenAI package or build custom WebSocket? | Dev time | Architect | **Recommend: Use package** |
| Q-007 | Local fallback for transcription (Apple Speech)? | Reliability | Architect | Open |
| Q-008 | How to handle macOS audio routing changes mid-session? | UX | Engineer | Open |
| Q-009 | What numerical confidence thresholds for coaching? | AI behavior | AI/ML | Open |
| Q-010 | Should system prompts be remotely updatable? | Iteration speed | Architect | Open |

### 6.3 Questions Requiring Investigation

| # | Question | Investigation Approach |
|---|----------|------------------------|
| I-001 | What's the actual latency of OpenAI Realtime API? | Build prototype, measure |
| I-002 | How does BlackHole behave with macOS 14+ audio changes? | Test on latest OS |
| I-003 | What's memory usage for 90-minute session? | Build prototype, profile |
| I-004 | Can SwiftUI handle 2000+ utterances without lag? | Build prototype, stress test |

---

## 7. Agent Analysis Summary

### 7.1 Issues by Severity

#### Critical (🔴)

| # | Issue | Agent(s) | Recommendation |
|---|-------|----------|----------------|
| 1 | No test strategy | Engineer, QA | Create test strategy spec |
| 2 | No accessibility requirements | Frontend, A11y | Add as P0 requirement |
| 3 | No error handling architecture | Architect, Engineer | Create ADR |
| 4 | API key storage not specified | Security | Use Keychain |
| 5 | No design files | Designer, Frontend | Create Figma design system |
| 6 | Floating overlay + VoiceOver conflict | A11y | Test and document workarounds |

#### Important (🟠)

| # | Issue | Agent(s) | Recommendation |
|---|-------|----------|----------------|
| 7 | Documentation conflicts (docx vs PRD) | PM | Archive docx files |
| 8 | No CI/CD pipeline | DevOps | Set up GitHub Actions |
| 9 | No crash reporting | SRE | Integrate crash reporting |
| 10 | SwiftData migration plan missing | DBA | Create migration spec |
| 11 | Performance monitoring missing | SRE, Perf | Add monitoring |
| 12 | Prompt engineering iteration | AI/ML | Version prompts, enable A/B |

#### Minor (🟡)

| # | Issue | Agent(s) | Recommendation |
|---|-------|----------|----------------|
| 13 | Animation timing undefined | Motion | Define timing curves |
| 14 | Typography scale missing | Designer | Add to design system |
| 15 | No rate limit handling | Cloud | Implement detection |
| 16 | No i18n preparation | i18n | Use NSLocalizedString |

### 7.2 Opportunities Identified

| # | Opportunity | Agent | Value | Effort |
|---|-------------|-------|-------|--------|
| 1 | Use SwiftOpenAI package | Engineer | High | Low |
| 2 | Create video tutorials for audio setup | Writer | High | Medium |
| 3 | Build session replay for testing | QA | High | Medium |
| 4 | Add shareable export attribution | Growth | Medium | Low |
| 5 | Content marketing around philosophy | Strategist | Medium | Medium |
| 6 | CloudKit sync for future | Cloud | Medium | High |

---

## Research Sources

This analysis incorporated research from:

- [SwiftOpenAI Package](https://github.com/jamesrochabrun/SwiftOpenAI) — Swift package for OpenAI APIs including Realtime
- [swift-realtime-openai](https://github.com/m1guelpf/swift-realtime-openai) — Modern Swift SDK for Realtime API
- [OpenAI Realtime API Documentation](https://platform.openai.com/docs/guides/realtime) — Official API documentation
- [OpenAI Developer Notes on Realtime API](https://developers.openai.com/blog/realtime-api) — Best practices and migration guidance
- [BlackHole Audio Driver](https://github.com/ExistentialAudio/BlackHole) — Virtual audio loopback driver
- [BlackHole Alternatives](https://alternativeto.net/software/blackhole-by-existentialaudio/?platform=mac) — Comparison of audio routing options
- [SwiftData Best Practices](https://www.hackingwithswift.com/quick-start/swiftdata) — Tutorial and reference
- [SwiftData Storage on Mac](https://gist.github.com/pdarcey/981b99bcc436a64df222cd8e3dd92871) — macOS-specific considerations
- [SwiftData Considerations](https://fatbobman.com/en/posts/key-considerations-before-using-swiftdata/) — Key decisions before using SwiftData

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-01 | Claude Code Team | Initial comprehensive review |

---

**[COMPLETE]** This analysis is complete. Next step: Review findings with stakeholders and begin Phase A: Foundation work.
