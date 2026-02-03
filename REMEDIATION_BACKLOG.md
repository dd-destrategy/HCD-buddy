# Remediation Backlog
## Based on 20-Agent Evaluation (2026-02-03)

---

## EPIC R1: Critical Security & Reliability Fixes
**Priority:** P0 (BLOCKER)
**Estimated Effort:** 1 day
**Agents:** Security Engineer, SRE

### Stories
- [ ] R1-S1: Fix certificate pinning with real OpenAI SHA-256 hashes
- [ ] R1-S2: Implement proper reconnection logic in RealtimeAPIClient
- [ ] R1-S3: Replace fatalError() with graceful degradation in AudioCaptureEngine
- [ ] R1-S4: Replace fatalError() with graceful degradation in DataManager
- [ ] R1-S5: Implement actual recovery condition checks (not always true)

---

## EPIC R2: Design System Token Adoption
**Priority:** P1 (High)
**Estimated Effort:** 3 days
**Agents:** Design System Engineer, SwiftUI Specialist

### Stories
- [ ] R2-S1: Create Typography.swift with 6-8 named text styles
- [ ] R2-S2: Create Spacing.swift with consistent scale (4/8/12/16/24/40)
- [ ] R2-S3: Create CornerRadius.swift with small/medium/large/pill
- [ ] R2-S4: Create Shadow.swift with elevation scale
- [ ] R2-S5: Refactor views to use semantic colors (replace 374 raw colors)
- [ ] R2-S6: Create HCDButton component with consistent styling
- [ ] R2-S7: Create HCDCard component for containers

---

## EPIC R3: Accessibility Completion
**Priority:** P1 (High)
**Estimated Effort:** 2 days
**Agents:** Accessibility Engineer, QA

### Stories
- [ ] R3-S1: Add reduce-motion checks to 12 identified views
- [ ] R3-S2: Fix 4 missing accessibility labels
- [ ] R3-S3: Add WCAG contrast ratio tests
- [ ] R3-S4: Create WCAG_COMPLIANCE_REPORT.md
- [ ] R3-S5: Add VoiceOver testing documentation

---

## EPIC R4: Data Model Optimization
**Priority:** P1 (High)
**Estimated Effort:** 4 hours
**Agents:** Database Engineer

### Stories
- [ ] R4-S1: Add index on Utterance.timestampSeconds
- [ ] R4-S2: Add index on Utterance.sessionId
- [ ] R4-S3: Add index on Insight.timestampSeconds
- [ ] R4-S4: Add index on TopicStatus.sessionId
- [ ] R4-S5: Add compound index on Session dates

---

## EPIC R5: API Integration Hardening
**Priority:** P1 (High)
**Estimated Effort:** 1 day
**Agents:** API Engineer, Error Handling Specialist

### Stories
- [ ] R5-S1: Implement exponential backoff in ConnectionManager
- [ ] R5-S2: Add proper state transitions for reconnection
- [ ] R5-S3: Add connection health monitoring
- [ ] R5-S4: Implement circuit breaker pattern
- [ ] R5-S5: Add comprehensive error recovery tests

---

## EPIC R6: Animation & Motion Fixes
**Priority:** P2 (Medium)
**Estimated Effort:** 1 day
**Agents:** Motion Designer, SwiftUI Specialist

### Stories
- [ ] R6-S1: Add MotionSafeAnimation to CoachingPromptView
- [ ] R6-S2: Add MotionSafeAnimation to InsightFlagAnimation
- [ ] R6-S3: Add MotionSafeAnimation to TopicStatusIndicator
- [ ] R6-S4: Add MotionSafeAnimation to TranscriptView auto-scroll
- [ ] R6-S5: Add MotionSafeAnimation to 8 remaining views
- [ ] R6-S6: Create animation timing constants

---

## EPIC R7: User Journey Optimization
**Priority:** P2 (Medium)
**Estimated Effort:** 2 days
**Agents:** UX Engineer, Content Writer

### Stories
- [ ] R7-S1: Add troubleshooting tips to audio setup wizard
- [ ] R7-S2: Create video tutorial placeholders/links
- [ ] R7-S3: Improve error messages in setup flow
- [ ] R7-S4: Add "skip for now" option for advanced setup
- [ ] R7-S5: Create FAQ document for common issues

---

## EPIC R8: Documentation & Templates
**Priority:** P2 (Medium)
**Estimated Effort:** 1 day
**Agents:** Technical Writer, Content Strategist

### Stories
- [ ] R8-S1: Create 3-4 built-in interview templates
- [ ] R8-S2: Create TESTING_STRATEGY.md
- [ ] R8-S3: Create USER_FAQ.md
- [ ] R8-S4: Update SETUP.md with troubleshooting section
- [ ] R8-S5: Create SPARKLE_RELEASE_GUIDE.md

---

## EPIC R9: i18n Infrastructure
**Priority:** P3 (Future)
**Estimated Effort:** 2 weeks
**Agents:** i18n Engineer

### Stories
- [ ] R9-S1: Create Localizable.strings infrastructure
- [ ] R9-S2: Extract 400+ hardcoded strings to localization files
- [ ] R9-S3: Add LocalizedStringKey usage throughout views
- [ ] R9-S4: Implement locale-aware date/number formatting
- [ ] R9-S5: Add RTL layout considerations
- [ ] R9-S6: Create localization testing framework

---

## EPIC R10: SwiftUI Best Practices
**Priority:** P2 (Medium)
**Estimated Effort:** 4 hours
**Agents:** SwiftUI Specialist

### Stories
- [ ] R10-S1: Fix Timer memory leak in ContentView
- [ ] R10-S2: Add proper @StateObject vs @ObservedObject usage
- [ ] R10-S3: Implement proper view lifecycle management
- [ ] R10-S4: Add task cancellation on view disappear

---

## Summary

| Epic | Priority | Effort | Stories | Status |
|------|----------|--------|---------|--------|
| R1: Security & Reliability | P0 | 1 day | 5 | 🔴 Blocked |
| R2: Design System | P1 | 3 days | 7 | ⏳ Pending |
| R3: Accessibility | P1 | 2 days | 5 | ⏳ Pending |
| R4: Data Model | P1 | 4 hours | 5 | ⏳ Pending |
| R5: API Hardening | P1 | 1 day | 5 | ⏳ Pending |
| R6: Animation | P2 | 1 day | 6 | ⏳ Pending |
| R7: User Journey | P2 | 2 days | 5 | ⏳ Pending |
| R8: Documentation | P2 | 1 day | 5 | ⏳ Pending |
| R9: i18n | P3 | 2 weeks | 6 | ⏳ Pending |
| R10: SwiftUI | P2 | 4 hours | 4 | ⏳ Pending |

**Total Stories:** 53
**Critical Path:** R1 → R5 → R3 (must complete for launch)
