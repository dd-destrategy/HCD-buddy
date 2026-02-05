# Remediation Backlog
## Based on 20-Agent Evaluation (2026-02-03)

**Last Updated:** 2026-02-03
**Commit Reference:** `7289398` (Comprehensive remediation: 11 parallel agent swarm fixes)

---

## EPIC R1: Critical Security & Reliability Fixes ✅ DONE
**Priority:** P0 (BLOCKER)
**Estimated Effort:** 1 day
**Agents:** Security Engineer, SRE
**Status:** Completed in commit 7289398

### Stories
- [x] R1-S1: Fix certificate pinning with real OpenAI SHA-256 hashes
- [x] R1-S2: Implement proper reconnection logic in RealtimeAPIClient
- [x] R1-S3: Replace fatalError() with graceful degradation in AudioCaptureEngine
- [x] R1-S4: Replace fatalError() with graceful degradation in DataManager
- [x] R1-S5: Implement actual recovery condition checks (not always true)

---

## EPIC R2: Design System Token Adoption ✅ DONE
**Priority:** P1 (High)
**Estimated Effort:** 3 days
**Agents:** Design System Engineer, SwiftUI Specialist
**Status:** Completed in commit 7289398
**Note:** Includes LiquidGlass.swift beyond original scope

### Stories
- [x] R2-S1: Create Typography.swift with 6-8 named text styles
- [x] R2-S2: Create Spacing.swift with consistent scale (4/8/12/16/24/40)
- [x] R2-S3: Create CornerRadius.swift with small/medium/large/pill
- [x] R2-S4: Create Shadow.swift with elevation scale
- [x] R2-S5: Refactor views to use semantic colors (replace 374 raw colors)
- [x] R2-S6: Create HCDButton component with consistent styling
- [x] R2-S7: Create HCDCard component for containers

---

## EPIC R3: Accessibility Completion ✅ DONE
**Priority:** P1 (High)
**Estimated Effort:** 2 days
**Agents:** Accessibility Engineer, QA
**Status:** Completed in commit 7289398

### Stories
- [x] R3-S1: Add reduce-motion checks to 12 identified views
- [x] R3-S2: Fix 4 missing accessibility labels
- [x] R3-S3: Add WCAG contrast ratio tests
- [x] R3-S4: Create WCAG_COMPLIANCE_REPORT.md
- [x] R3-S5: Add VoiceOver testing documentation

---

## EPIC R4: Data Model Optimization ✅ DONE
**Priority:** P1 (High)
**Estimated Effort:** 4 hours
**Agents:** Database Engineer
**Status:** Completed in commit 7289398

### Stories
- [x] R4-S1: Add index on Utterance.timestampSeconds
- [x] R4-S2: Add index on Utterance.sessionId
- [x] R4-S3: Add index on Insight.timestampSeconds
- [x] R4-S4: Add index on TopicStatus.sessionId
- [x] R4-S5: Add compound index on Session dates

---

## EPIC R5: API Integration Hardening ✅ DONE
**Priority:** P1 (High)
**Estimated Effort:** 1 day
**Agents:** API Engineer, Error Handling Specialist
**Status:** Completed in commit 7289398

### Stories
- [x] R5-S1: Implement exponential backoff in ConnectionManager
- [x] R5-S2: Add proper state transitions for reconnection
- [x] R5-S3: Add connection health monitoring
- [x] R5-S4: Implement circuit breaker pattern
- [x] R5-S5: Add comprehensive error recovery tests

---

## EPIC R6: Animation & Motion Fixes ✅ DONE
**Priority:** P2 (Medium)
**Estimated Effort:** 1 day
**Agents:** Motion Designer, SwiftUI Specialist
**Status:** Completed in commit 7289398

### Stories
- [x] R6-S1: Add MotionSafeAnimation to CoachingPromptView
- [x] R6-S2: Add MotionSafeAnimation to InsightFlagAnimation
- [x] R6-S3: Add MotionSafeAnimation to TopicStatusIndicator
- [x] R6-S4: Add MotionSafeAnimation to TranscriptView auto-scroll
- [x] R6-S5: Add MotionSafeAnimation to 8 remaining views
- [x] R6-S6: Create animation timing constants

---

## EPIC R7: User Journey Optimization ✅ DONE
**Priority:** P2 (Medium)
**Estimated Effort:** 2 days
**Agents:** UX Engineer, Content Writer
**Status:** Completed in commit 167e56d

### Stories
- [x] R7-S1: Add troubleshooting tips to audio setup wizard
- [x] R7-S2: Create video tutorial placeholders/links
- [x] R7-S3: Improve error messages in setup flow
- [x] R7-S4: Add "skip for now" option for advanced setup
- [x] R7-S5: Create FAQ document for common issues

---

## EPIC R8: Documentation & Templates ✅ DONE
**Priority:** P2 (Medium)
**Estimated Effort:** 1 day
**Agents:** Technical Writer, Content Strategist
**Status:** Completed in commit 7289398

### Stories
- [x] R8-S1: Create 3-4 built-in interview templates
- [x] R8-S2: Create TESTING_STRATEGY.md
- [x] R8-S3: Create USER_FAQ.md
- [x] R8-S4: Update SETUP.md with troubleshooting section
- [x] R8-S5: Create SPARKLE_RELEASE_GUIDE.md

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

## EPIC R10: SwiftUI Best Practices ✅ DONE
**Priority:** P2 (Medium)
**Estimated Effort:** 4 hours
**Agents:** SwiftUI Specialist
**Status:** Completed in commit 7289398

### Stories
- [x] R10-S1: Fix Timer memory leak in ContentView
- [x] R10-S2: Add proper @StateObject vs @ObservedObject usage
- [x] R10-S3: Implement proper view lifecycle management
- [x] R10-S4: Add task cancellation on view disappear

---

## Summary

| Epic | Priority | Effort | Stories | Status |
|------|----------|--------|---------|--------|
| R1: Security & Reliability | P0 | 1 day | 5 | ✅ Done |
| R2: Design System | P1 | 3 days | 7 | ✅ Done |
| R3: Accessibility | P1 | 2 days | 5 | ✅ Done |
| R4: Data Model | P1 | 4 hours | 5 | ✅ Done |
| R5: API Hardening | P1 | 1 day | 5 | ✅ Done |
| R6: Animation | P2 | 1 day | 6 | ✅ Done |
| R7: User Journey | P2 | 2 days | 5 | ✅ Done |
| R8: Documentation | P2 | 1 day | 5 | ✅ Done |
| R9: i18n | P3 | 2 weeks | 6 | ⏳ Pending |
| R10: SwiftUI | P2 | 4 hours | 4 | ✅ Done |

**Total Stories:** 53
**Completed:** 48/53 (91%)
**Remaining:** R9 (i18n) = 6 stories
**Critical Path:** ✅ Complete (R1 → R5 → R3 all done)
**Reference Commit:** `7289398`
