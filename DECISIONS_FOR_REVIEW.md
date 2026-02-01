# HCD Interview Coach — Decisions for Review

**Status:** Awaiting Approval
**Date:** February 1, 2026
**Purpose:** Surface all key decisions requiring stakeholder approval before development begins

---

## How to Use This Document

Each decision includes:
- **Context:** Why this decision matters
- **Options:** Available choices with trade-offs
- **Recommendation:** Team's suggested choice
- **Your Decision:** Space to mark your choice

Please review each section and indicate your decision. Development will proceed based on your approvals.

---

## Quick Decision Summary

| # | Decision | Recommendation | Your Choice |
|---|----------|----------------|-------------|
| D1 | MVP Feature Scope | Option B: Full features, coaching optional | ⬜ A ⬜ B ⬜ C |
| D2 | Business Model | Option B: Tiered SaaS | ⬜ A ⬜ B ⬜ C |
| D3 | Distribution Strategy | Option A: Direct download first | ⬜ A ⬜ B ⬜ C |
| D4 | First Session Coaching | Option B: OFF by default | ⬜ A ⬜ B ⬜ C |
| D5 | OpenAI Package Choice | Option A: Use SwiftOpenAI | ⬜ A ⬜ B |
| D6 | Audio Driver Strategy | Option A: BlackHole only | ⬜ A ⬜ B |
| D7 | Design Approach | Option A: Figma-first | ⬜ A ⬜ B |
| D8 | Testing Investment | Option B: Moderate (70% coverage) | ⬜ A ⬜ B ⬜ C |
| D9 | Telemetry/Analytics | Option B: Opt-in anonymous | ⬜ A ⬜ B ⬜ C |
| D10 | Pre-Development Validation | Option B: Light validation | ⬜ A ⬜ B ⬜ C |

---

## Product Decisions

### D1: MVP Feature Scope

**Context:** The PRD defines 8 P0 features. This is ambitious for a first release. We need to decide how much to ship initially.

**Options:**

| Option | Features | Pros | Cons |
|--------|----------|------|------|
| **A: Minimal** | Audio Setup, Transcription, Session Management, Export | Faster to ship (6-8 weeks), lower risk, validates core value | No coaching = weaker differentiation |
| **B: Full** | All 8 P0 features, but coaching OFF by default | Complete vision, stronger positioning | Longer timeline (10-13 weeks), more risk |
| **C: Staged** | Ship Option A first, add coaching 4 weeks later | Validates in stages, fast initial launch | Two major releases to manage, messaging complexity |

**Recommendation:** **Option B** — Ship full features but with coaching disabled by default. Users opt-in after experiencing transcription value. This delivers the full vision while managing trust.

**Trade-off to accept:** Longer development timeline but stronger market entry.

```
Your Decision: ⬜ A (Minimal)  ⬜ B (Full)  ⬜ C (Staged)

Notes: _______________________________________________
```

---

### D2: Business Model

**Context:** The PRD proposes $29-49 one-time purchase with BYOK. The Growth team raised concerns about sustainability.

**Options:**

| Option | Model | Pricing | Pros | Cons |
|--------|-------|---------|------|------|
| **A: One-time** | Pay once, BYOK | $49 one-time | Simple, low friction, validates quickly | No recurring revenue, can't fund ongoing development |
| **B: Tiered SaaS** | Free/Pro/Team | Free: 3 sessions/mo, Pro: $12/mo, Team: $29/seat/mo | Sustainable, upsell path, scales | More complex, may reduce initial adoption |
| **C: Hybrid** | One-time + optional subscription | $49 one-time OR $8/mo | Maximum flexibility | Confusing, harder to communicate |

**Recommendation:** **Option B** — Tiered SaaS model. Start with Free and Pro tiers. Add Team tier in v1.5.

**Trade-off to accept:** Slightly higher friction than one-time, but sustainable business.

**Pricing Details (if Option B):**

| Tier | Price | Includes |
|------|-------|----------|
| Free | $0 | 3 sessions/month, transcription only, no coaching |
| Pro | $12/month or $99/year | Unlimited sessions, coaching, insights, export |
| Team | $29/seat/month (v1.5) | Pro + shared templates, team analytics, managed billing |

```
Your Decision: ⬜ A (One-time)  ⬜ B (Tiered SaaS)  ⬜ C (Hybrid)

If B, approve pricing? ⬜ Yes  ⬜ Adjust: ________________

Notes: _______________________________________________
```

---

### D3: Distribution Strategy

**Context:** macOS apps can be distributed via Mac App Store or direct download. Each has trade-offs.

**Options:**

| Option | Approach | Pros | Cons |
|--------|----------|------|------|
| **A: Direct first** | Direct download with Sparkle auto-updates, consider App Store later | Faster iteration, no review delays, full feature control | Less discoverable, users must trust direct download |
| **B: App Store first** | Submit to Mac App Store from day 1 | Trust, discovery, familiar install | Review delays (1-2 weeks), 30% fee, sandboxing limits |
| **C: Both simultaneously** | Launch on both channels | Maximum reach | Double the work, version sync issues |

**Recommendation:** **Option A** — Direct download first. Faster iteration during early product development. Consider App Store for v1.5+ when stable.

**Trade-off to accept:** Less visibility but faster feedback loop.

```
Your Decision: ⬜ A (Direct first)  ⬜ B (App Store first)  ⬜ C (Both)

Notes: _______________________________________________
```

---

### D4: First Session Coaching Behavior

**Context:** The PRD philosophy is "silence-first." The team debated whether coaching should be ON or OFF for new users.

**Options:**

| Option | Behavior | Pros | Cons |
|--------|----------|------|------|
| **A: ON by default** | Coaching enabled from first session | Users see full value immediately | Risk of bad first impression if prompts are poorly timed |
| **B: OFF by default** | Coaching disabled for first session, prompt to enable after | Builds trust through transcription first, safer | Users may never discover coaching |
| **C: OFF for first 3 sessions** | Extended evaluation period before coaching | Maximum trust building | May feel like feature is hidden |

**Recommendation:** **Option B** — Coaching OFF for first session only. After first session completes, show: "You've completed your first session! Want to try AI coaching in your next interview? [Enable] [Not now]"

**Trade-off to accept:** Users must opt-in, but trust is protected.

```
Your Decision: ⬜ A (ON)  ⬜ B (OFF first session)  ⬜ C (OFF first 3)

Notes: _______________________________________________
```

---

## Technical Decisions

### D5: OpenAI Integration Approach

**Context:** We need to connect to OpenAI's Realtime API. We can build custom or use an existing package.

**Options:**

| Option | Approach | Pros | Cons |
|--------|----------|------|------|
| **A: Use SwiftOpenAI package** | Integrate [SwiftOpenAI](https://github.com/jamesrochabrun/SwiftOpenAI) | Faster, battle-tested, maintained, handles edge cases | Dependency on third party, less control |
| **B: Build custom** | Build WebSocket client from scratch | Full control, no dependencies | More time, more bugs, reinventing solved problems |

**Recommendation:** **Option A** — Use SwiftOpenAI package. It's actively maintained, supports Realtime API, and reduces development time by 2-3 weeks.

**Trade-off to accept:** External dependency, but well-maintained and MIT licensed.

```
Your Decision: ⬜ A (Use SwiftOpenAI)  ⬜ B (Build custom)

Notes: _______________________________________________
```

---

### D6: Audio Driver Strategy

**Context:** Capturing system audio on macOS requires a virtual audio driver. BlackHole is the standard but requires manual setup.

**Options:**

| Option | Approach | Pros | Cons |
|--------|----------|------|------|
| **A: BlackHole only** | Require BlackHole, provide excellent setup wizard | Well-documented, free, reliable | Setup friction, ~10 min first-time setup |
| **B: Add ScreenCaptureKit** | Use macOS 13+ ScreenCaptureKit as alternative | No driver install, easier setup | macOS 13+ only, different audio quality, less tested |

**Recommendation:** **Option A** — BlackHole only for v1. Invest heavily in setup wizard quality. Consider ScreenCaptureKit for v1.5 after validating user demand.

**Trade-off to accept:** Setup friction, but reliability is more important.

```
Your Decision: ⬜ A (BlackHole only)  ⬜ B (Add ScreenCaptureKit)

Notes: _______________________________________________
```

---

### D7: Design Approach

**Context:** We need visual design before building UI. The question is how much to invest upfront.

**Options:**

| Option | Approach | Effort | Pros | Cons |
|--------|----------|--------|------|------|
| **A: Figma-first** | Complete design system in Figma before coding UI | 5-7 days | Consistent UI, fewer iterations, design review possible | Delays coding start |
| **B: Code-first** | Design in SwiftUI directly, iterate in code | 0 days design | Faster start | Inconsistent UI, more rework, harder to get feedback |

**Recommendation:** **Option A** — Create Figma design system first. This includes color tokens, typography, spacing, and key screen mockups. Blocks UI coding but prevents costly rework.

**Trade-off to accept:** 5-7 days before UI coding, but higher quality output.

**Do you have a designer available, or should we use a template/AI-generated starting point?**

```
Your Decision: ⬜ A (Figma-first)  ⬜ B (Code-first)

Designer available? ⬜ Yes  ⬜ No (will use templates)

Notes: _______________________________________________
```

---

### D8: Testing Investment Level

**Context:** Testing real-time audio + AI is complex. We need to decide how much to invest in test infrastructure.

**Options:**

| Option | Coverage | Effort | Includes |
|--------|----------|--------|----------|
| **A: Minimal** | ~40% | Low | Unit tests for core logic only |
| **B: Moderate** | ~70% | Medium | Unit + integration tests, API mocking, basic UI tests |
| **C: Comprehensive** | ~85%+ | High | All of B + golden interviews test suite, performance tests, accessibility tests |

**Recommendation:** **Option B** — Moderate testing. Covers critical paths without excessive investment. Add golden interviews in v1.1 after core is stable.

**Trade-off to accept:** Some edge cases may slip through, but faster to ship.

```
Your Decision: ⬜ A (Minimal)  ⬜ B (Moderate)  ⬜ C (Comprehensive)

Notes: _______________________________________________
```

---

### D9: Telemetry & Analytics

**Context:** To improve the product, we need data on how it's used. But this is a privacy-focused tool for researchers.

**Options:**

| Option | Approach | Data Collected | Pros | Cons |
|--------|----------|----------------|------|------|
| **A: None** | No telemetry at all | Nothing | Maximum privacy, simplest | Flying blind, can't improve |
| **B: Opt-in anonymous** | Optional, anonymized usage stats | Crash reports, feature usage counts, session completion rates (no content) | Balance of privacy and insight | Some users won't opt in |
| **C: Default on** | Telemetry on by default, opt-out | Same as B | More data | May feel intrusive for privacy-focused users |

**Recommendation:** **Option B** — Opt-in anonymous telemetry. First launch asks: "Help us improve? [Yes] [No]". Collect only aggregate stats, never transcript content.

**Trade-off to accept:** Less data, but user trust preserved.

```
Your Decision: ⬜ A (None)  ⬜ B (Opt-in)  ⬜ C (Default on)

Notes: _______________________________________________
```

---

## Validation Decisions

### D10: Pre-Development User Validation

**Context:** The Researcher agent flagged that personas appear invented, not validated. Should we validate before coding?

**Options:**

| Option | Approach | Timeline Impact | Pros | Cons |
|--------|----------|-----------------|------|------|
| **A: Skip** | Trust the PRD, proceed to development | No delay | Fastest to market | Risk building wrong thing |
| **B: Light validation** | 5 concept interviews with target users (1 week) | +1 week | Validates key assumptions, low effort | Still limited data |
| **C: Full validation** | 10 interviews + survey of 50+ researchers (3-4 weeks) | +3-4 weeks | High confidence | Significant delay |

**Recommendation:** **Option B** — Light validation. Conduct 5 interviews during the design system week (parallel work). Focus on validating:
1. Is audio setup friction acceptable?
2. Is "silence-first" coaching appealing?
3. Is BYOK acceptable or a blocker?

**Trade-off to accept:** Not statistically rigorous, but directionally useful.

```
Your Decision: ⬜ A (Skip)  ⬜ B (Light)  ⬜ C (Full)

If B or C, do you have access to 5-10 UX researchers for interviews?
⬜ Yes  ⬜ No (need to recruit)

Notes: _______________________________________________
```

---

## Resource & Capacity Decisions

### D11: Team Composition

**Context:** We need to understand available resources to create a realistic plan.

**Questions:**

```
1. Who will be developing?
   ⬜ Just Claude (AI-assisted solo development)
   ⬜ Human developer(s) + Claude
   ⬜ Other: ________________

2. Is there a designer available?
   ⬜ Yes, dedicated designer
   ⬜ No, will use templates/AI-generated designs
   ⬜ Can hire freelance designer

3. Who will conduct user validation interviews?
   ⬜ You (product owner)
   ⬜ Someone on the team
   ⬜ Skip validation
   ⬜ Need to identify someone

4. Who is the "BCM team" mentioned in PRD for dogfooding?
   Answer: ________________________________________________
   Available for testing? ⬜ Yes  ⬜ No  ⬜ Unknown

5. Target launch date (if any):
   ⬜ ASAP (as fast as possible)
   ⬜ Specific date: ________________
   ⬜ No hard deadline
```

---

## Budget Decisions

### D12: External Costs

**Context:** Some options involve external costs. Please confirm budget availability.

| Item | Cost | Required? |
|------|------|-----------|
| Apple Developer Program | $99/year | Yes (for distribution) |
| Figma (if no designer) | $0-15/mo | Optional |
| Crash reporting (Sentry) | $0-26/mo | Recommended |
| Domain + hosting (docs site) | ~$20/year | Optional |
| OpenAI API (testing) | ~$50-100 total | Yes |

```
Approved budget: ⬜ <$200  ⬜ $200-500  ⬜ $500+  ⬜ Minimal (free tier only)

Notes: _______________________________________________
```

---

## Decisions Requiring Later Resolution

These don't need answers now but will need decisions during development:

| Decision | When Needed | Default If No Decision |
|----------|-------------|------------------------|
| Exact coaching confidence thresholds | During AI integration | Use values from PRD (HIGH = 0.85) |
| Export file format details | During export feature | Markdown primary, JSON secondary |
| Keyboard shortcut conflicts | During UI implementation | Follow recommendations in collaboration doc |
| Post-session survey wording | Before beta launch | Draft in review before shipping |

---

## Development Plan (Contingent on Approvals)

Assuming recommended options are approved, here's the proposed plan:

### Phase 0: Foundation (Week 1)
- Create Figma design system
- Set up Xcode project + CI/CD
- Write architecture specs (state machine, error handling)
- Conduct 5 validation interviews (if approved)
- **Milestone:** Design approved, project structure ready

### Phase 1: Core Infrastructure (Weeks 2-4)
- Implement audio capture with BlackHole
- Build audio setup wizard
- Integrate SwiftOpenAI for Realtime API
- Create SwiftData models
- Build session management
- **Milestone:** Can capture and transcribe a live video call

### Phase 2: Features (Weeks 5-7)
- Implement transcript view
- Build coaching prompts (silence-first)
- Add topic awareness tracking
- Implement insight flagging
- Create export functionality
- **Milestone:** All P0 features working

### Phase 3: Polish (Weeks 8-9)
- Accessibility audit and fixes
- Performance optimization
- Error handling refinement
- User documentation
- **Milestone:** Beta-ready

### Phase 4: Beta (Weeks 10-11)
- Internal dogfooding (20 sessions)
- External beta (10-20 researchers)
- Feedback incorporation
- **Milestone:** Production-ready

### Phase 5: Launch (Weeks 12-13)
- Code signing and notarization
- Launch content preparation
- Public release
- **Milestone:** Shipped!

---

## How to Respond

Please review this document and provide your decisions. You can:

1. **Reply with decisions** — e.g., "D1: B, D2: B with $10/mo Pro tier, D3: A..."
2. **Ask clarifying questions** — I'll provide more detail on any decision
3. **Request changes** — If none of the options work, describe what you need
4. **Approve all recommendations** — "Approve all recommended options"

Once I have your decisions, I'll create:
1. Updated PRD with your decisions incorporated
2. Detailed development plan with milestones
3. Specification documents for approved approaches

---

**Awaiting your review.**
