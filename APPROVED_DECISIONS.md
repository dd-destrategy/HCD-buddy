# HCD Interview Coach — Final Decisions

**Status:** APPROVED
**Date:** February 1, 2026
**Decision Authority:** Team Recommendation (Best Options Selected)

---

## Approved Decisions Summary

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| D1 | MVP Feature Scope | **B: Full features, coaching optional** | Delivers complete vision; coaching OFF by default protects trust |
| D2 | Business Model | **B: Tiered SaaS** | Sustainable revenue; Free tier drives adoption, Pro funds development |
| D3 | Distribution | **A: Direct download first** | Faster iteration; no App Store review delays during rapid development |
| D4 | First Session Coaching | **B: OFF by default** | Builds trust through transcription value first; users opt-in |
| D5 | OpenAI Integration | **A: Use SwiftOpenAI package** | Saves 2-3 weeks; battle-tested; actively maintained |
| D6 | Audio Driver | **A: BlackHole only** | Proven reliable; invest in excellent setup wizard instead of alternatives |
| D7 | Design Approach | **A: Figma-first** | Prevents costly rework; enables design review; consistent UI |
| D8 | Testing Level | **B: Moderate (70% coverage)** | Balances quality with speed; covers critical paths |
| D9 | Telemetry | **B: Opt-in anonymous** | Respects privacy while enabling improvement; builds user trust |
| D10 | User Validation | **B: Light validation (5 interviews)** | Validates key assumptions without major delay; runs parallel to design |

---

## Detailed Decision Records

### D1: MVP Feature Scope — FULL FEATURES

**Decision:** Ship all 8 P0 features with coaching OFF by default.

**Features Included:**
1. ✅ F0: Audio Setup Wizard
2. ✅ F1: Real-Time Transcription
3. ✅ F2: Coaching Prompts (silence-first, OFF by default)
4. ✅ F3: Topic Awareness Tracking
5. ✅ F4: Insight Flagging
6. ✅ F5: Session Management
7. ✅ F6: Export (Markdown, JSON)
8. ✅ F7: Consent/Disclosure Templates

**Why:** The full feature set delivers our differentiated value proposition. Coaching being optional (OFF by default) means we get the benefit of complete vision without the risk of poor first impressions. Transcription alone validates core value; coaching is the power feature users unlock.

**Timeline Impact:** 10-13 weeks (vs 6-8 for minimal)

---

### D2: Business Model — TIERED SAAS

**Decision:** Tiered subscription with BYOK (Bring Your Own Key).

**Pricing:**

| Tier | Price | Features | API |
|------|-------|----------|-----|
| **Free** | $0 | 3 sessions/month, transcription only | BYOK |
| **Pro** | $12/month or $99/year | Unlimited sessions, coaching, insights, export | BYOK |
| **Team** | $29/seat/month (v1.5) | Pro + shared templates, analytics | Managed option |

**Why:**
- Free tier drives adoption and word-of-mouth
- $12/month is affordable for freelancers ($144/year vs ~$300-500 in API costs for heavy users)
- Annual discount ($99 = 31% off) encourages commitment
- BYOK keeps infrastructure simple; users already paying OpenAI
- Team tier with managed billing comes later for enterprise

**Launch Plan:**
- v1.0: Free + Pro tiers only
- v1.5: Add Team tier

---

### D3: Distribution — DIRECT DOWNLOAD FIRST

**Decision:** Distribute via direct download with Sparkle auto-updates. Consider Mac App Store for v1.5+.

**Implementation:**
- Host on product website
- Use Sparkle framework for auto-updates
- Code signing with Developer ID (notarization required)
- GitHub Releases as backup distribution

**Why:**
- No 1-2 week App Store review delays during rapid iteration
- No 30% Apple tax on subscriptions
- Full feature control (no sandboxing restrictions)
- Can always add App Store later when stable

**Trade-off Accepted:** Less discoverability, but target users (experienced researchers) find tools through community, not App Store browsing.

---

### D4: First Session Coaching — OFF BY DEFAULT

**Decision:** Coaching disabled for first session. Prompt to enable after first successful session.

**User Flow:**
```
First Session:
- Coaching toggle shows "OFF"
- Subtle indicator: "Coaching available after your first session"
- User experiences pure transcription value

After First Session Ends:
- Summary screen includes: "Ready to try AI coaching?"
- "Coaching watches silently and only speaks up when you've
   missed something significant. It's a safety net, not a copilot."
- [Enable for Next Session] [Not Now]

Subsequent Sessions:
- Coaching ON by default (user opted in)
- Can always toggle OFF per session
```

**Why:** Builds trust through demonstrated value. Users experience "wow, I don't need to take notes" before we ask them to trust AI coaching. Prevents bad first impressions from poorly-timed prompts.

---

### D5: OpenAI Integration — USE SWIFTOPENAI PACKAGE

**Decision:** Integrate [SwiftOpenAI](https://github.com/jamesrochabrun/SwiftOpenAI) package for Realtime API.

**Why:**
- Actively maintained (recent commits)
- Supports Realtime API with WebSocket and WebRTC options
- Handles authentication, reconnection, error handling
- MIT licensed, no vendor lock-in
- Saves 2-3 weeks of development time
- Battle-tested by community

**Implementation:**
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/jamesrochabrun/SwiftOpenAI", from: "3.0.0")
]
```

**Trade-off Accepted:** External dependency, but the package is well-maintained and we can fork if needed.

---

### D6: Audio Driver — BLACKHOLE ONLY

**Decision:** Require BlackHole virtual audio driver. Invest heavily in setup wizard quality.

**Why:**
- BlackHole is proven, free, and reliable
- ScreenCaptureKit (alternative) has different audio characteristics and is less tested for this use case
- Better to do one thing excellently than two things adequately
- Setup wizard investment pays off more than alternative driver support

**Setup Wizard Requirements:**
- Detect if BlackHole already installed
- Provide one-click Homebrew install option
- Step-by-step Multi-Output Device creation with screenshots
- Audio verification test before first session
- Store successful configuration
- Video tutorial link for complex cases

**Future Consideration:** Revisit ScreenCaptureKit for v1.5 if user feedback indicates setup friction is a major churn driver.

---

### D7: Design Approach — FIGMA-FIRST

**Decision:** Create complete design system in Figma before coding UI.

**Deliverables (5-7 days):**
1. **Color Tokens**
   - Light mode palette
   - Dark mode palette
   - Semantic naming (background, surface, text-primary, etc.)

2. **Typography Scale**
   - SF Pro font family
   - Size scale (12, 13, 14, 16, 20, 24)
   - Weight usage (regular, medium, semibold)

3. **Spacing System**
   - 4px base unit
   - Scale: 4, 8, 12, 16, 24, 32, 48

4. **Component Library**
   - Buttons (primary, secondary, ghost)
   - Input fields
   - Cards and panels
   - Status indicators
   - Navigation elements

5. **Screen Mockups**
   - Audio Setup Wizard (6 screens)
   - Main Session View
   - Post-Session Summary
   - Settings

**Why:** Prevents costly UI rework. Enables stakeholder review before coding. Ensures visual consistency. SwiftUI implementation becomes straightforward translation.

**Approach:** Use AI-assisted design (Figma + design plugins) or minimal viable design system if no dedicated designer.

---

### D8: Testing Level — MODERATE (70% COVERAGE)

**Decision:** Moderate testing investment targeting ~70% code coverage.

**Testing Strategy:**

| Layer | Approach | Coverage |
|-------|----------|----------|
| Unit Tests | XCTest for all services and business logic | 80%+ |
| Integration Tests | API client with mocked responses | Key paths |
| UI Tests | XCUITest for critical flows | Happy paths |
| Manual Testing | Exploratory testing before releases | Edge cases |

**Included:**
- ✅ Unit tests for AudioCaptureService, SessionManager, etc.
- ✅ Integration tests with mocked OpenAI responses
- ✅ Basic UI tests for session flow
- ✅ Accessibility audit (manual)

**Deferred to v1.1:**
- ⏳ Golden interviews test suite (recorded sessions for regression)
- ⏳ Performance benchmarking suite
- ⏳ Automated accessibility testing

**Why:** Balances quality with velocity. 70% coverage catches most bugs without excessive test maintenance burden. Add comprehensive testing after core is stable.

---

### D9: Telemetry — OPT-IN ANONYMOUS

**Decision:** Optional, anonymized telemetry with explicit user consent.

**First Launch Prompt:**
```
"Help us improve HCD Interview Coach?

We collect anonymous usage data (feature usage, crash reports)
to make the app better. We never collect transcript content or
personal information.

[Yes, I'll help] [No thanks]"
```

**Data Collected (if opted in):**
- Crash reports (stack traces, no user data)
- Session completion rates
- Feature usage counts (coaching enabled/disabled, exports)
- Audio setup success/failure

**Data NOT Collected:**
- ❌ Transcript content
- ❌ Participant names
- ❌ API keys
- ❌ Any PII

**Implementation:** Use privacy-respecting service (TelemetryDeck or Aptabase) or simple CloudKit-based analytics.

**Why:** Respects our privacy-first positioning while enabling data-driven improvement. Opt-in builds trust.

---

### D10: User Validation — LIGHT VALIDATION (5 INTERVIEWS)

**Decision:** Conduct 5 concept validation interviews during design week.

**Timeline:** Runs parallel to Figma design work (Week 1)

**Interview Focus:**
1. **Audio setup tolerance:** "Would you spend 10 minutes on one-time setup for this value?"
2. **Coaching appeal:** "How do you feel about AI that mostly stays silent but catches what you miss?"
3. **BYOK acceptance:** "Are you comfortable providing your own OpenAI API key?"
4. **Pricing reaction:** "Would you pay $12/month for unlimited use?"
5. **Current pain points:** Validate PRD problem statement

**Recruitment:**
- Target: Experienced UX researchers (5+ years)
- Channels: LinkedIn, UX research Slack communities, personal network
- Incentive: Free Pro tier for 6 months post-launch

**Deliverable:** 1-page validation summary with go/no-go recommendation and any pivots needed.

**Why:** Low-cost risk mitigation. 5 interviews surface major issues without delaying development significantly. If we hear "I would never install a virtual audio driver," we know to prioritize ScreenCaptureKit.

---

## Resource Assumptions

Based on these decisions, we assume:

| Resource | Assumption | Fallback if Not Available |
|----------|------------|---------------------------|
| Development | Claude-assisted (primary) + human review | Slower but viable |
| Design | AI-assisted Figma or templates | Slightly less polished |
| Validation | Product owner or team member conducts interviews | Skip and accept risk |
| Dogfooding | Internal team available for 20 sessions | Recruit from beta waitlist |
| Budget | ~$200-300 for tools and testing | Use free tiers only |

---

## Approved Configuration Summary

```yaml
product:
  name: HCD Interview Coach
  version: 1.0.0
  features: full (8 P0 features)
  coaching_default: off (opt-in after first session)

business:
  model: tiered_saas
  tiers:
    free: { price: 0, sessions: 3, features: [transcription] }
    pro: { price_monthly: 12, price_annual: 99, features: [all] }
    team: { price_seat: 29, version: "1.5" }
  api_billing: byok

technical:
  platform: macOS 13+
  language: Swift 5.9+
  ui: SwiftUI
  openai_client: SwiftOpenAI (package)
  audio_driver: BlackHole (only)
  storage: SwiftData
  api_keys: Keychain

quality:
  test_coverage: 70%
  design: figma_first
  telemetry: opt_in_anonymous

distribution:
  method: direct_download
  updates: sparkle
  app_store: v1.5+

validation:
  pre_development: 5 interviews
  dogfooding: 20 internal sessions
  beta: 10-20 external researchers
```

---

## Next Steps

With all decisions approved, we proceed to:

1. **Week 1:** Design system + validation interviews (parallel)
2. **Week 2-4:** Core infrastructure (audio, API, data)
3. **Week 5-7:** Feature implementation
4. **Week 8-9:** Polish and accessibility
5. **Week 10-11:** Beta testing
6. **Week 12-13:** Launch

**Immediate Actions:**
- [ ] Set up Xcode project structure
- [ ] Configure CI/CD pipeline
- [ ] Begin Figma design system
- [ ] Draft validation interview script
- [ ] Recruit 5 researchers for interviews

---

**DECISIONS LOCKED. READY FOR DEVELOPMENT.**
