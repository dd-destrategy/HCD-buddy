# HCD Interview Coach — Development Plan

**Status:** Ready to Execute
**Duration:** 13 weeks
**Start Date:** TBD (upon approval)

---

## Plan Overview

```
Week 1      ████████████████  Phase 0: Foundation
Week 2-4    ████████████████████████████████████████████████  Phase 1: Core Infrastructure
Week 5-7    ████████████████████████████████████████████████  Phase 2: Features
Week 8-9    ████████████████████████████████  Phase 3: Polish
Week 10-11  ████████████████████████████████  Phase 4: Beta
Week 12-13  ████████████████████████████████  Phase 5: Launch
```

---

## Phase 0: Foundation (Week 1)

**Objective:** Establish all foundations before writing product code.

### Track A: Design System (5-7 days)

| Task | Deliverable | Priority |
|------|-------------|----------|
| Define color palette (light + dark) | Color tokens file | P0 |
| Define typography scale | Type system spec | P0 |
| Define spacing system (4px base) | Spacing tokens | P0 |
| Create button components | Figma components | P0 |
| Create input components | Figma components | P0 |
| Create panel/card components | Figma components | P0 |
| Design Audio Setup Wizard (6 screens) | Screen mockups | P0 |
| Design Main Session View | Screen mockup | P0 |
| Design Post-Session Summary | Screen mockup | P0 |
| Design Settings screen | Screen mockup | P1 |

### Track B: Project Setup (2-3 days)

| Task | Deliverable | Priority |
|------|-------------|----------|
| Create Xcode project | Working project | P0 |
| Configure folder structure | Organized codebase | P0 |
| Add SwiftLint configuration | .swiftlint.yml | P0 |
| Set up GitHub Actions CI | Build + lint pipeline | P0 |
| Add SwiftOpenAI package | Package.swift | P0 |
| Create KeychainService wrapper | Security foundation | P0 |
| Set up SwiftData container | Persistence foundation | P0 |

### Track C: Documentation (2-3 days)

| Task | Deliverable | Priority |
|------|-------------|----------|
| Write session state machine spec | State diagram | P0 |
| Write error handling architecture | ADR document | P0 |
| Write accessibility requirements | A11y spec | P0 |
| Update PRD with approved decisions | Updated PRD | P0 |
| Create README for developers | README.md | P1 |

### Track D: Validation (5 days, parallel)

| Task | Deliverable | Priority |
|------|-------------|----------|
| Write interview script | 1-page script | P0 |
| Recruit 5 researchers | Scheduled interviews | P0 |
| Conduct interviews | Interview notes | P0 |
| Synthesize findings | Validation report | P0 |
| Go/no-go decision | Documented decision | P0 |

### Week 1 Exit Criteria

- [ ] Design system approved
- [ ] Xcode project building
- [ ] CI pipeline passing
- [ ] 5 validation interviews complete
- [ ] No major validation concerns (or pivots documented)

---

## Phase 1: Core Infrastructure (Weeks 2-4)

**Objective:** Build the technical foundation that all features depend on.

### Week 2: Audio Foundation

| Task | Deliverable | Est. Hours |
|------|-------------|------------|
| Implement AudioCaptureService protocol | Protocol definition | 2h |
| Implement BlackHole audio detection | Detection logic | 4h |
| Implement Multi-Output Device detection | Detection logic | 4h |
| Build audio capture from AVAudioEngine | Working capture | 8h |
| Implement PCM conversion (24kHz, 16-bit, mono) | Conversion pipeline | 4h |
| Build audio level metering | Real-time meters | 4h |
| Create audio capture unit tests | 80%+ coverage | 6h |

**Week 2 Milestone:** Can capture system audio + microphone with level meters.

### Week 3: API & Persistence

| Task | Deliverable | Est. Hours |
|------|-------------|------------|
| Integrate SwiftOpenAI package | Working import | 2h |
| Implement RealtimeAPIClient wrapper | Client class | 8h |
| Implement WebSocket connection handling | Connect/reconnect | 6h |
| Implement audio streaming to API | Streaming pipeline | 6h |
| Implement transcription event handling | Event parsing | 4h |
| Create SwiftData models (Session, Utterance, etc.) | Model classes | 4h |
| Implement SessionRepository | CRUD operations | 4h |
| Create API client unit tests | 80%+ coverage | 6h |

**Week 3 Milestone:** Can connect to OpenAI and receive transcription.

### Week 4: Session Management

| Task | Deliverable | Est. Hours |
|------|-------------|------------|
| Implement SessionManager state machine | State handling | 8h |
| Implement session lifecycle (create, start, pause, end) | Full lifecycle | 6h |
| Build connection quality monitor | Quality metrics | 4h |
| Implement graceful degradation | Fallback handling | 4h |
| Build Audio Setup Wizard UI | 6-screen wizard | 12h |
| Implement wizard logic (detection, verification) | Working wizard | 8h |
| Create session management tests | 70%+ coverage | 6h |

**Week 4 Milestone:** Complete audio setup wizard, can start and manage sessions.

### Phase 1 Exit Criteria

- [ ] Audio Setup Wizard fully functional
- [ ] Can capture audio from video calls (Zoom, Meet, Teams)
- [ ] Can connect to OpenAI Realtime API
- [ ] Transcription appears in real-time
- [ ] Sessions persist to SwiftData
- [ ] 70%+ test coverage on services

---

## Phase 2: Features (Weeks 5-7)

**Objective:** Implement all P0 features.

### Week 5: Transcript & Coaching

| Task | Deliverable | Est. Hours |
|------|-------------|------------|
| Build TranscriptView (SwiftUI) | Scrolling transcript | 8h |
| Implement speaker labels with manual toggle | Speaker switching | 4h |
| Implement timestamp display | Inline timestamps | 2h |
| Build CoachingService (silence-first logic) | Coaching engine | 8h |
| Implement coaching prompt UI (floating overlay) | Prompt display | 6h |
| Implement prompt timing rules | Timing logic | 4h |
| Implement prompt dismissal (auto + manual) | Dismiss handling | 2h |
| Create coaching service tests | 80%+ coverage | 6h |

**Week 5 Milestone:** Transcript displays with speaker labels; coaching prompts appear (when enabled).

### Week 6: Topics & Insights

| Task | Deliverable | Est. Hours |
|------|-------------|------------|
| Build TopicAwarenessView | Topic panel | 6h |
| Implement topic status tracking (AI-driven) | Status updates | 6h |
| Implement manual topic adjustment | Click to change | 2h |
| Build InsightsPanel | Insight list | 6h |
| Implement auto-insight flagging | AI detection | 6h |
| Implement manual insight flagging (⌘+I) | Keyboard shortcut | 2h |
| Implement insight-to-transcript navigation | Click to jump | 4h |
| Create topic/insight tests | 70%+ coverage | 4h |

**Week 6 Milestone:** Topic awareness tracks coverage; insights captured manually and automatically.

### Week 7: Session Flow & Export

| Task | Deliverable | Est. Hours |
|------|-------------|------------|
| Build SessionSetupView | Setup screen | 6h |
| Build ActiveSessionView (main interface) | Main view | 8h |
| Build PostSessionSummaryView | Summary screen | 8h |
| Implement AI-generated reflection | Summary generation | 4h |
| Implement export to Markdown | Markdown export | 4h |
| Implement export to JSON | JSON export | 2h |
| Build consent template selector | Template UI | 4h |
| Implement session mode switching | Mode logic | 2h |
| Create session flow tests | 70%+ coverage | 4h |

**Week 7 Milestone:** Complete session flow from setup to export.

### Phase 2 Exit Criteria

- [ ] All 8 P0 features functional
- [ ] Transcript, coaching, topics, insights working
- [ ] Export produces valid Markdown and JSON
- [ ] Consent templates selectable
- [ ] First-session coaching OFF behavior implemented
- [ ] 70%+ overall test coverage

---

## Phase 3: Polish (Weeks 8-9)

**Objective:** Prepare for external users.

### Week 8: Accessibility & UX

| Task | Deliverable | Est. Hours |
|------|-------------|------------|
| Accessibility audit | Audit report | 4h |
| Implement keyboard navigation | Full keyboard support | 8h |
| Add VoiceOver labels | Accessibility labels | 6h |
| Fix color contrast issues | WCAG compliance | 4h |
| Add non-color indicators to topics | Icons alongside colors | 2h |
| Implement focus indicators | Visible focus | 2h |
| Add Reduce Motion support | Motion preferences | 2h |
| Polish animations and transitions | Smooth animations | 6h |
| Fix UI edge cases | Bug fixes | 8h |

**Week 8 Milestone:** WCAG 2.1 AA compliance achieved.

### Week 9: Performance & Stability

| Task | Deliverable | Est. Hours |
|------|-------------|------------|
| Profile memory usage (60-min session) | Performance report | 4h |
| Implement utterance virtualization | Memory optimization | 8h |
| Optimize transcript scrolling | Smooth scrolling | 4h |
| Add crash reporting (optional telemetry) | Crash reports | 4h |
| Implement opt-in telemetry prompt | First-launch prompt | 2h |
| Fix connection edge cases | Reliability fixes | 8h |
| Write user documentation | Help content | 8h |
| Create troubleshooting guide | FAQ/troubleshooting | 4h |

**Week 9 Milestone:** Stable, performant, documented.

### Phase 3 Exit Criteria

- [ ] Accessibility audit passed
- [ ] Full keyboard navigation working
- [ ] Memory usage <500MB for 60-min session
- [ ] No crashes in 10 consecutive test sessions
- [ ] User documentation complete
- [ ] Ready for beta testers

---

## Phase 4: Beta (Weeks 10-11)

**Objective:** Validate with real users.

### Week 10: Internal Dogfooding

| Task | Deliverable | Est. Hours |
|------|-------------|------------|
| Code signing and notarization | Signed app | 4h |
| Set up Sparkle for auto-updates | Update mechanism | 4h |
| Create beta distribution package | Downloadable app | 2h |
| Conduct 20 internal sessions | Session logs | 20h |
| Collect feedback after each session | Feedback notes | 10h |
| Triage and fix critical bugs | Bug fixes | 20h |

**Week 10 Milestone:** 20 internal sessions complete; critical bugs fixed.

### Week 11: External Beta

| Task | Deliverable | Est. Hours |
|------|-------------|------------|
| Recruit 10-20 beta researchers | Beta user list | 4h |
| Onboard beta users | Onboarding emails | 4h |
| Monitor beta usage | Usage dashboard | 8h |
| Collect structured feedback | Feedback synthesis | 8h |
| Fix beta-reported issues | Bug fixes | 20h |
| Incorporate feedback into UX | UX improvements | 8h |

**Week 11 Milestone:** Beta feedback incorporated; ready for launch.

### Phase 4 Exit Criteria

- [ ] 20+ internal sessions completed
- [ ] 10-20 external beta users onboarded
- [ ] No critical bugs remaining
- [ ] Feedback incorporated
- [ ] Session completion rate >95%
- [ ] User satisfaction >4/5

---

## Phase 5: Launch (Weeks 12-13)

**Objective:** Public release.

### Week 12: Pre-Launch

| Task | Deliverable | Est. Hours |
|------|-------------|------------|
| Final bug fixes from beta | Polished app | 16h |
| Create product website | Landing page | 12h |
| Write launch blog post | Blog content | 4h |
| Create demo video (3 min) | Video | 8h |
| Prepare Product Hunt listing | PH draft | 4h |
| Set up payment processing | Stripe integration | 4h |
| Final accessibility review | Compliance check | 4h |

**Week 12 Milestone:** Launch-ready.

### Week 13: Launch

| Task | Deliverable | Est. Hours |
|------|-------------|------------|
| Final QA pass | Bug-free release | 8h |
| Publish to website | Live download | 2h |
| Submit to Product Hunt | PH listing | 2h |
| Social media announcement | Launch tweets/posts | 4h |
| Community outreach | Slack/Discord posts | 4h |
| Monitor launch metrics | Dashboard | 8h |
| Respond to user issues | Support | 16h |
| Plan v1.1 based on feedback | v1.1 roadmap | 4h |

**Week 13 Milestone:** LAUNCHED! 🚀

### Phase 5 Exit Criteria

- [ ] App available for public download
- [ ] Product Hunt launched
- [ ] Payment processing working
- [ ] First paying customers
- [ ] v1.1 roadmap drafted

---

## Milestone Summary

| Week | Milestone | Key Deliverable |
|------|-----------|-----------------|
| 1 | Foundation Complete | Design system, project setup, validation |
| 4 | Core Infrastructure | Audio capture, API connection, transcription |
| 7 | Features Complete | All 8 P0 features working |
| 9 | Polish Complete | Accessible, performant, documented |
| 11 | Beta Complete | User-validated, bugs fixed |
| 13 | **LAUNCH** | Public release |

---

## Risk Mitigation

| Risk | Mitigation | Contingency |
|------|------------|-------------|
| Audio setup too complex | Invest heavily in wizard UX | Add video tutorials |
| OpenAI API changes | Abstract behind our client | Fork SwiftOpenAI if needed |
| Coaching prompts poorly received | Default OFF, get feedback | Reduce/remove in v1.1 |
| Low beta recruitment | Leverage UX research communities | Extend beta period |
| Performance issues | Profile early, optimize late | Defer features if needed |

---

## Success Metrics

### Launch Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| Downloads (Week 1) | 500+ | Download count |
| Paid conversions (Month 1) | 50+ | Pro tier signups |
| Session completion rate | >95% | Sessions ended normally / started |
| Audio setup success | >85% | Users completing wizard |
| User satisfaction | >4.0/5 | Post-session survey |

### Anti-Metrics (Warning Signs)

| Anti-Metric | Warning Threshold |
|-------------|-------------------|
| Coaching disabled by users | >50% disable after trying |
| Audio setup abandonment | >30% fail to complete |
| Support requests | >10% of users need help |

---

## Immediate Next Steps

When ready to begin, execute in this order:

### Day 1
1. Create Xcode project with folder structure
2. Configure SwiftLint
3. Set up GitHub Actions
4. Add SwiftOpenAI package dependency
5. Begin Figma design system

### Day 2-3
6. Write interview script for validation
7. Begin recruiting researchers
8. Create KeychainService wrapper
9. Set up SwiftData models

### Day 4-5
10. Complete design system foundations
11. Conduct first validation interviews
12. Write state machine spec
13. Write error handling ADR

### End of Week 1
14. Review validation findings
15. Approve design system
16. Verify project builds and CI passes
17. **Go/no-go for Phase 1**

---

## Appendix: Folder Structure

```
HCDInterviewCoach/
├── App/
│   ├── HCDInterviewCoachApp.swift
│   └── AppDelegate.swift
├── Features/
│   ├── AudioSetup/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Services/
│   ├── Session/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Services/
│   ├── Transcript/
│   ├── Coaching/
│   ├── Topics/
│   ├── Insights/
│   └── Export/
├── Core/
│   ├── Services/
│   │   ├── AudioCaptureService.swift
│   │   ├── RealtimeAPIClient.swift
│   │   ├── SessionManager.swift
│   │   └── KeychainService.swift
│   ├── Models/
│   │   ├── Session.swift
│   │   ├── Utterance.swift
│   │   ├── Insight.swift
│   │   └── TopicStatus.swift
│   └── Utilities/
├── DesignSystem/
│   ├── Colors.swift
│   ├── Typography.swift
│   ├── Spacing.swift
│   └── Components/
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.strings
└── Tests/
    ├── UnitTests/
    ├── IntegrationTests/
    └── UITests/
```

---

**READY TO EXECUTE.**
