# HCD Interview Coach -- Mobile UI Optimization Plan

**Date**: 2026-02-07
**Scope**: Analysis of current macOS-only codebase for iOS/iPadOS portability
**Status**: Analysis complete -- no code changes made

---

## Table of Contents

1. [macOS-Specific API Dependencies](#1-macos-specific-api-dependencies)
2. [Layout Issues for Mobile](#2-layout-issues-for-mobile)
3. [Touch Input Adaptations Needed](#3-touch-input-adaptations-needed)
4. [Design Token Adjustments for Mobile](#4-design-token-adjustments-for-mobile)
5. [Recommended Architecture Changes](#5-recommended-architecture-changes)
6. [Priority-Ordered Implementation Plan](#6-priority-ordered-implementation-plan)

---

## 1. macOS-Specific API Dependencies

### 1.1 AppKit Imports

Three source files explicitly `import AppKit`:

| File | Usage | iOS Equivalent |
|------|-------|----------------|
| `HCDInterviewCoach/Features/Export/ExportService.swift` | `NSSavePanel`, `NSPasteboard` | `UIActivityViewController`, `UIPasteboard` |
| `HCDInterviewCoach/Features/Coaching/CoachingPromptView.swift` | Imported (used via CoachingViewModel for `NSEvent`) | Remove import; use SwiftUI gesture/focus APIs |
| `HCDInterviewCoach/Features/Session/Views/ConsentFlowView.swift` | `NSSpeechSynthesizer` | `AVSpeechSynthesizer` (AVFoundation, cross-platform) |

### 1.2 NSPasteboard Usage (Clipboard)

`NSPasteboard` is used in **8 files** for copy-to-clipboard functionality. Each must be replaced with `UIPasteboard.general` on iOS.

| File | Line(s) | Context |
|------|---------|---------|
| `Features/Transcript/UtteranceRowView.swift` | 392-393, 398-399 | Copy utterance text / text with timestamp |
| `Features/PostSession/EnhancedSummaryView.swift` | 536-537 | Export summary as Markdown to clipboard |
| `Features/PostSession/QuoteLibraryView.swift` | 604-605 | Export highlights to clipboard |
| `Features/PostSession/AIReflectionView.swift` | 217-218 | Copy AI reflection to clipboard |
| `Features/Session/Views/ConsentTemplateView.swift` | 90-91 | Copy consent text |
| `Features/Session/Views/ParticipantDetailView.swift` | 594 | Copy participant info |
| `Features/Export/ExportService.swift` | 306-308 | `copyToClipboard()` service method |
| `Features/Transcript/TaggingView.swift` | 696 | `Color.toHexString()` uses `NSColor(self)` |

**Recommended abstraction**:
```swift
// ClipboardService.swift
enum ClipboardService {
    static func copy(_ string: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #elseif os(iOS)
        UIPasteboard.general.string = string
        #endif
    }
}
```

### 1.3 NSSavePanel Usage (File Save Dialogs)

`NSSavePanel` is used in **3 locations**:

| File | Line(s) | Context |
|------|---------|---------|
| `Features/Transcript/TranscriptView.swift` | 457-469 | Export transcript as text file |
| `Features/Export/ExportService.swift` | 250-270 | Save string content to file |
| `Features/Export/ExportService.swift` | 281-300 | Save data content to file |

**iOS equivalent**: Use `UIActivityViewController` for sharing/saving, or `fileExporter()` SwiftUI modifier (available iOS 14+). The `fileExporter` approach is preferable as it stays within SwiftUI:
```swift
.fileExporter(isPresented: $showExporter, document: myDoc, contentType: .plainText) { result in ... }
```

### 1.4 NSSpeechSynthesizer (Text-to-Speech)

| File | Line(s) | Context |
|------|---------|---------|
| `Features/Session/Views/ConsentFlowView.swift` | 58, 688, 693, 738, 740 | TTS for consent text |

**iOS equivalent**: `AVSpeechSynthesizer` from AVFoundation (available on both platforms). This is a straightforward 1:1 replacement with minor API differences.

### 1.5 NSEvent (Keyboard Event Monitoring)

| File | Line(s) | Context |
|------|---------|---------|
| `Features/Coaching/CoachingViewModel.swift` | 374, 385, 392 | Global keyboard event monitor for Escape/Return |

**Note**: This code is already wrapped in `#if os(macOS)` guards. On iOS, the equivalent would be SwiftUI's `.onKeyPress()` (for external keyboards) or on-screen button alternatives.

### 1.6 NSApplication

| File | Line(s) | Context |
|------|---------|---------|
| `App/HCDInterviewCoachApp.swift` | 50-61 | `NSApplication.shared.orderFrontStandardAboutPanel()` |

**iOS equivalent**: Build a custom About screen as a SwiftUI view presented via `.sheet()`.

### 1.7 NSColor / NSFont References

| File | Line(s) | Context |
|------|---------|---------|
| `DesignSystem/Colors.swift` | 96-102, 147-172 | Fallback colors use `Color(nsColor:)`, `NSColor` extension with `init(hex:)` |
| `App/HCDInterviewCoachApp.swift` | 57-58 | `NSFont.systemFont()`, `NSColor.secondaryLabelColor` |
| `Features/PostSession/QuoteLibraryView.swift` | 283, 407 | `Color(nsColor: NSColor(hex:))` |
| `Features/Transcript/HighlightCreatorView.swift` | 205 | `Color(nsColor: NSColor(hex:))` |
| `Features/Transcript/TranscriptSearchView.swift` | 183, 230 | `Color(nsColor: .separatorColor)`, `Color(nsColor: .windowBackgroundColor)` |
| `Features/Transcript/TaggingView.swift` | 696 | `NSColor(self)` for color component extraction |

**iOS equivalents**:
- `Color(nsColor:)` --> `Color(uiColor:)` with `UIColor`
- `NSColor(hex:)` --> `UIColor(hex:)` with identical implementation
- `.windowBackgroundColor` --> `.systemBackground`
- `.controlBackgroundColor` --> `.secondarySystemBackground`
- `.underPageBackgroundColor` --> `.systemGroupedBackground`
- `.separatorColor` --> `.separator` (same name on UIKit)
- `.controlColor` --> `.tertiarySystemBackground`

### 1.8 macOS-Only Color References (controlBackgroundColor)

| File | Line(s) |
|------|---------|
| `App/ContentView.swift` | 463 |
| `DesignSystem/Colors.swift` | 97, 101 |
| `Features/AudioSetup/VerificationStepView.swift` | 319 |
| `Features/Export/ExportProgressView.swift` | 157 |
| `Features/Export/ExportView.swift` | 107, 158, 235, 243, 324, 340 |
| `Features/Session/Views/ConsentTemplateView.swift` | 30 |
| `Features/AudioSetup/MultiOutputSetupStepView.swift` | 390 |

### 1.9 HSplitView (macOS-Only View)

| File | Line(s) | Context |
|------|---------|---------|
| `Features/Demo/DemoModeView.swift` | 217 | `HSplitView` for transcript + side panel |

**iOS equivalent**: `HSplitView` does not exist on iOS. Replace with `NavigationSplitView` (iPad) or stacked `VStack`/tab-based layout (iPhone).

### 1.10 Audio Capture (BlackHole Virtual Driver)

The entire audio capture pipeline is macOS-specific:
- `Core/Services/Audio/AudioCaptureEngine.swift` -- uses `AVAudioEngine` with BlackHole virtual audio driver
- `Core/Services/Audio/BlackHoleDetector.swift` -- detects BlackHole installation
- `Core/Services/Audio/MultiOutputDetector.swift` -- detects multi-output audio devices
- `Features/AudioSetup/*` -- 6-screen setup wizard for BlackHole configuration

**iOS approach**: iOS does not support system audio capture from other apps due to sandboxing. The mobile version would need to:
- Use the device microphone to capture both sides of a conversation
- Or integrate with VoIP/conferencing APIs for audio streams
- The entire AudioSetup wizard flow (6 screens) is irrelevant on iOS and should be excluded

---

## 2. Layout Issues for Mobile

### 2.1 Fixed Minimum Widths That Exceed Phone Screens

iPhone screen widths range from 320pt (SE) to 430pt (Pro Max). The following constraints are incompatible:

| File | Constraint | Issue |
|------|-----------|-------|
| `ContentView.swift:98` | `.frame(minWidth: 800, minHeight: 600)` | **Critical** -- entire app requires 800pt minimum |
| `ContentView.swift:119` | `.frame(minWidth: 500, minHeight: 400)` | Participant picker sheet |
| `ContentView.swift:133` | `.frame(minWidth: 600, minHeight: 500)` | Consent flow sheet |
| `ContentView.swift:367` | `.frame(minWidth: 400, minHeight: 350)` | Coaching history sheet |
| `ContentView.swift:371` | `.frame(minWidth: 500, minHeight: 450)` | Cultural settings sheet |
| `ContentView.swift:379` | `.frame(minWidth: 550, minHeight: 450)` | Redaction review sheet |
| `ContentView.swift:569` | `.frame(width: 260)` | Right sidebar fixed width |
| `DemoModeView.swift:220` | `.frame(minWidth: 350)` | Transcript panel minimum |
| `DemoModeView.swift:224` | `.frame(minWidth: 250, maxWidth: 300)` | Side panel |
| `SessionSetupView.swift:196` | `.frame(minWidth: 600, minHeight: 800)` | Setup view |
| `AudioSetupWizardView.swift:48` | `.frame(minWidth: 620, idealWidth: 700)` | Audio wizard |
| `QuoteLibraryView.swift:69` | `.frame(minWidth: 600, minHeight: 500)` | Quote library |
| `ExportView.swift:61` | `.frame(minWidth: 500, minHeight: 600)` | Export view |
| `ConsentFlowView.swift:89` | `.frame(minWidth: 600, minHeight: 500)` | Consent flow |
| `ParticipantDetailView.swift:54` | `.frame(minWidth: 400, idealWidth: 480)` | Participant detail |
| `ParticipantPickerView.swift:56` | `.frame(minWidth: 420, idealWidth: 480)` | Participant picker |
| `CulturalSettingsView.swift:37` | `.frame(minWidth: 480)` | Cultural settings |

**Total**: 17+ locations with minimum widths exceeding 430pt (iPhone Pro Max width).

### 2.2 Side-by-Side Layouts Assuming Wide Screens

| File | Pattern | Issue |
|------|---------|-------|
| `ContentView.swift:348` | `HStack(spacing: 0)` for transcript + sidebar | Transcript and right sidebar side-by-side requires 800pt+ |
| `ContentView.swift:569` | Right sidebar `.frame(width: 260)` | Fixed 260pt sidebar leaves only 540pt for transcript |
| `DemoModeView.swift:217` | `HSplitView { transcriptPanel ... sidePanel }` | macOS-only split view for transcript + session info |
| `ContentView.swift:386-460` | Session toolbar `HStack` with many items | Too many items for phone-width toolbar |
| `TaggingView.swift:150-181` | Create tag form `HStack` with TextField + ColorPicker + 2 buttons | Too wide for phone |
| `EnhancedSummaryView.swift:168` | Quality score header `HStack` | Score badge + text needs wrapping on narrow screens |

### 2.3 Fixed-Width Preview Frames (Lower Priority)

Numerous `#Preview` blocks use fixed widths (300-900pt). These are preview-only and do not affect runtime, but should be updated with platform-appropriate sizes for development.

### 2.4 Navigation Pattern Issues

The current app uses a flat `VStack`-based navigation with conditional `Group` switching in `ContentView.swift`:
```swift
Group {
    if showDemoMode { DemoModeView(...) }
    else if showAnalyticsDashboard { CrossSessionAnalyticsView(...) }
    else if showQuoteLibrary { QuoteLibraryView(...) }
    else if let sessionConfig = activeSessionConfig { ActiveSessionPlaceholderView(...) }
    else { SessionSetupArea(...) }
}
```

This pattern works on macOS with large windows but is problematic on mobile because:
- No back navigation affordance (no navigation bar with back button)
- No standard iOS navigation transitions
- Users cannot swipe back to previous views
- No navigation stack for deep linking

---

## 3. Touch Input Adaptations Needed

### 3.1 Touch Target Size Violations (< 44pt)

Apple's Human Interface Guidelines require minimum 44x44pt touch targets. The following elements are undersized:

| File | Element | Current Size | Issue |
|------|---------|-------------|-------|
| `FocusModePickerView.swift:146` | Compact mode buttons | `28x24pt` | Below 44pt minimum in both dimensions |
| `ContentView.swift:232` | "Remove participant" (xmark) button | `12pt` icon, no frame padding | Far below 44pt |
| `ContentView.swift:397-420` | Coaching/cultural/redaction toolbar buttons | `12pt` icons with `.controlSize(.small)` | Below 44pt |
| `QuestionTypeView.swift:329` | Question type pills | `padding(.vertical, 3)` | Vertical touch target likely < 30pt |
| `QuestionTypeView.swift:346` | Anti-pattern pills | `padding(.vertical, 2)` | ~20pt vertical target |
| `QuestionTypeView.swift:388` | Compact toggle circle button | `24x24pt` | Below 44pt |
| `TaggingView.swift:128-134` | "New Tag" add button | Small capsule with `Spacing.xs` (4pt) vertical padding | ~24pt height |
| `TaggingView.swift:454-455` | Tag indicator dots | `6x6pt` | Decorative, but containing view may be tappable |
| `TalkTimeIndicatorView.swift:42` | Compact ratio bar | `height: 6` | Too thin to interact with on touch |
| `DemoModeView.swift:290` | Timestamp text | `width: 40` | Narrow column |
| Various | `.controlSize(.small)` buttons | System small control size | May be < 44pt on iOS |

### 3.2 Hover-Dependent Interactions

**18 files** use `.onHover` for hover-state feedback. On touch devices, hover is unavailable (except with Apple Pencil hover on iPad Pro). These interactions need touch alternatives:

| Pattern | Files Count | Replacement Strategy |
|---------|-------------|---------------------|
| Hover to show action buttons | `UtteranceRowView`, `InsightRowView`, `TopicRowView` | Always show actions, or use swipe actions / long-press menu |
| Hover highlight for rows | `TaggingView`, `TranscriptSearchView`, `UpcomingInterviewsView` | Use tap highlight or selection state |
| Hover shimmer effects | `LiquidGlass.swift` | Disable shimmer on iOS; use press state instead |
| Hover tooltips via `.help()` | `FocusModePickerView`, `WizardStepView` | Use long-press popover or informational (i) buttons |

### 3.3 Context Menus

Context menus (right-click on macOS) translate well to long-press on iOS. These are already compatible:
- `TaggingView.swift:427` -- Tag pill delete via `.contextMenu`

### 3.4 Keyboard Shortcuts Needing Touch Alternatives

**34 keyboard shortcuts** are defined across the app. On mobile without external keyboard, these need on-screen button equivalents:

| Shortcut | File | Action | Touch Alternative |
|----------|------|--------|-------------------|
| `Cmd+R` | `KeyboardNavigationModifiers.swift` | Start/Stop session | Prominent on-screen button |
| `Cmd+P` | `KeyboardNavigationModifiers.swift` | Pause/Resume | Toolbar button |
| `Cmd+I` | `InsightsPanel.swift` | Flag insight | Floating action button or swipe action |
| `Cmd+T` | `KeyboardNavigationModifiers.swift` | Toggle speaker | Inline tap on speaker label |
| `Cmd+F` | `TranscriptView.swift` | Search transcript | Search bar always visible or magnifying glass icon |
| `Cmd+S` | `PostSessionSummaryView.swift` | Export session | Share button in toolbar |
| `Cmd+M` | `KeyboardNavigationModifiers.swift` | Toggle coaching | Toggle in toolbar or settings sheet |
| `Cmd+Shift+A` | `HCDInterviewCoachApp.swift` | Audio Setup Wizard | Settings menu item |
| `Escape` | Various (8 files) | Dismiss/cancel | Swipe down to dismiss sheet, or explicit close button |
| `Return` | Various (6 files) | Confirm/accept | On-screen confirm button |
| Arrow keys | `TranscriptSearchView.swift` | Navigate search results | Tap directly on results |

### 3.5 Text Selection and Editing

- `TaggingView.swift:151` -- `TextField` for tag name: works on iOS but needs consideration for keyboard avoidance
- `TranscriptSearchView` -- Search text field: needs iOS search bar pattern
- All `TextEditor` instances need keyboard avoidance (`.scrollDismissesKeyboard()`)

---

## 4. Design Token Adjustments for Mobile

### 4.1 Typography Scale

Current values are tuned for macOS desktop viewing distance (~60cm). Mobile devices are held closer (~30cm), so text can be slightly smaller but needs to respect Dynamic Type.

| Token | Current (macOS) | Recommended (iPhone) | Recommended (iPad) | Notes |
|-------|-----------------|---------------------|--------------------|----|
| `display` | 32pt bold | 28pt bold | 32pt bold | Use `.largeTitle` dynamic style |
| `heading1` | 24pt semibold | 22pt semibold | 24pt semibold | Use `.title` dynamic style |
| `heading2` | 18pt semibold | 17pt semibold | 18pt semibold | Use `.title3` dynamic style |
| `heading3` | 16pt semibold | 15pt semibold | 16pt semibold | Use `.headline` dynamic style |
| `body` | 14pt regular | 15pt regular | 15pt regular | iOS body is 17pt by default -- consider matching |
| `bodyMedium` | 14pt medium | 15pt medium | 15pt medium | Match body size |
| `caption` | 12pt regular | 12pt regular | 12pt regular | Use `.caption` dynamic style |
| `small` | 10pt regular | 11pt regular | 11pt regular | 10pt is hard to read on mobile; minimum 11pt |

**Critical recommendation**: Switch from fixed `Font.system(size:)` to `Font.TextStyle`-based dynamic type:

```swift
enum Typography {
    #if os(iOS)
    static let display = Font.largeTitle.weight(.bold)
    static let heading1 = Font.title.weight(.semibold)
    static let heading2 = Font.title3.weight(.semibold)
    static let heading3 = Font.headline
    static let body = Font.body
    static let bodyMedium = Font.body.weight(.medium)
    static let caption = Font.caption
    static let small = Font.caption2
    #else
    // Keep existing macOS values
    static let display = Font.system(size: 32, weight: .bold)
    // ...
    #endif
}
```

This ensures compatibility with Dynamic Type accessibility settings on iOS, which is an App Store requirement for accessibility.

### 4.2 Spacing Scale

Current spacing values are appropriate for both platforms, but some adjustments would improve mobile density:

| Token | Current | iPhone Adjustment | Rationale |
|-------|---------|-------------------|-----------|
| `xs` | 4pt | 4pt (keep) | Minimum useful spacing |
| `sm` | 8pt | 8pt (keep) | Standard small spacing |
| `md` | 12pt | 12pt (keep) | Works well on both |
| `lg` | 16pt | 16pt (keep) | Standard padding |
| `xl` | 24pt | 20pt | Reduce slightly for screen economy on phone |
| `xxl` | 40pt | 32pt | 40pt uses too much vertical space on 667pt screen |

**Recommended approach**: Make spacing responsive:
```swift
enum Spacing {
    static var xl: CGFloat {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .phone ? 20 : 24
        #else
        24
        #endif
    }
}
```

### 4.3 Corner Radius

Current values are fine for mobile. No changes needed.

| Token | Current | Mobile | Notes |
|-------|---------|--------|-------|
| `small` | 4pt | 4pt | Fine |
| `medium` | 8pt | 8pt | Fine |
| `large` | 12pt | 12pt | Fine |
| `xl` | 16pt | 16pt | Fine |
| `pill` | 9999pt | 9999pt | Fine |

### 4.4 Shadows

Current shadow values work on both platforms. The `Shadows` enum is cross-platform SwiftUI. No changes required.

### 4.5 LiquidGlass Design System

The `LiquidGlass.swift` design system is **mostly cross-platform**. Key adjustments needed:

| Component | Issue | Fix |
|-----------|-------|-----|
| `LiquidGlassModifier.onHover` | `.onHover` unavailable on iPhone | Gate with `#if os(macOS)` or check for pointer device |
| `GlassButtonModifier.onHover` | Same hover issue | Same fix |
| Shimmer overlay | Triggered by hover | Disable on iOS or trigger on press |
| Performance | Multiple material layers + shadows | Test on older iPhones (A13/A14); may need `.ultraThin` default on phone |

### 4.6 Colors

The `Colors.swift` file has **6 references** to `NSColor`-based fallback colors. These need `#if os(macOS)` / `#if os(iOS)` guards:

```swift
// Current (macOS-only):
case "Background": return Color(nsColor: .windowBackgroundColor)

// Cross-platform:
#if os(macOS)
case "Background": return Color(nsColor: .windowBackgroundColor)
#elseif os(iOS)
case "Background": return Color(uiColor: .systemBackground)
#endif
```

The `NSColor` extension with `init(hex:)` needs a mirrored `UIColor` extension for iOS.

---

## 5. Recommended Architecture Changes

### 5.1 Conditional Compilation Strategy

Use `#if os(iOS)` / `#if os(macOS)` at the **view layer** only. Keep all business logic, services, and models shared.

**Files requiring conditional compilation**:

| Layer | Files | Strategy |
|-------|-------|----------|
| App Entry | `HCDInterviewCoachApp.swift` | `#if os(macOS)` for `CommandGroup`, `NSApplication` |
| Design System | `Colors.swift`, `Typography.swift` | `#if os` for platform-specific values |
| Clipboard | New `ClipboardService.swift` | Wrapper with `#if os` |
| File Export | `ExportService.swift` | `#if os` for `NSSavePanel` vs `UIActivityViewController` |
| TTS | `ConsentFlowView.swift` | `#if os` for `NSSpeechSynthesizer` vs `AVSpeechSynthesizer` |
| Audio Setup | Entire `AudioSetup/` folder | `#if os(macOS)` -- exclude from iOS build |
| Keyboard | `CoachingViewModel.swift` | Already has `#if os(macOS)` guards |

### 5.2 Views Requiring Platform-Specific Variants

Some views are different enough to warrant separate implementations:

| View | macOS Version | iOS Version | Reason |
|------|--------------|-------------|--------|
| `ContentView.swift` | Current flat navigation | `TabView` + `NavigationStack` | Fundamentally different navigation paradigm |
| `ActiveSessionPlaceholderView` | `HStack` with sidebar | Stacked `VStack` with bottom sheet or tab | No room for side-by-side on phone |
| `DemoModeView` | `HSplitView` | `TabView` or stacked | `HSplitView` is macOS-only |
| `SessionToolbar` | Wide `HStack` with many items | Compact toolbar with overflow menu | Too many items for phone width |
| `AudioSetup/*` | 6-screen wizard | Excluded (or microphone-only setup) | BlackHole is macOS-only |

### 5.3 Views That Can Be Shared (With Minor Adjustments)

| View | Adjustments Needed |
|------|-------------------|
| `FocusModePickerView` | Increase compact button sizes to 44pt; remove hover |
| `TalkTimeIndicatorView` | Works as-is; compact bar height may need increase |
| `QuestionTypeView` | Remove `.glassPanel(edge:)`; use standalone card; increase pill sizes |
| `TaggingView` | Wrap create-tag form for narrow screens; increase touch targets |
| `EnhancedSummaryView` | Remove `NSPasteboard`; replace with `ClipboardService` |
| `CoachingPromptView` | Already a floating overlay; works well on both platforms |
| `SessionSetupView` | Remove `minWidth` constraint; template selector works in vertical scroll |
| `TranscriptView` | Remove `NSSavePanel`; use `fileExporter()` modifier |

### 5.4 Navigation Pattern Changes

**iPhone**: Tab-based navigation with 4-5 tabs:

```
TabView {
    SessionTab       // Setup + Active session
    TranscriptTab    // Transcript view
    InsightsTab      // Insights + coaching
    HistoryTab       // Past sessions + analytics
    SettingsTab      // App settings
}
```

During an active session, switch to a focused layout:
```
VStack {
    SessionHeaderBar (elapsed time, end button)
    TranscriptView (primary content, full width)
    BottomToolbar (insight flag, coaching toggle, speaker toggle)
}
// Coaching sidebar --> bottom sheet (.sheet or .overlay)
// Topics sidebar --> swipe-up panel or separate tab
```

**iPad**: `NavigationSplitView` with sidebar:
```
NavigationSplitView {
    Sidebar (session list, analytics, quote library)
} detail: {
    ActiveSession or SessionSetup
}
```

During an active session on iPad:
```
NavigationSplitView {
    Topics/Insights sidebar
} detail: {
    VStack {
        SessionToolbar
        TranscriptView
    }
}
```

### 5.5 Sheet Presentation Differences

On macOS, sheets are presented as attached panels with fixed minimum sizes. On iOS:
- Sheets are presented as cards from the bottom
- They support detents (`.presentationDetents([.medium, .large])`)
- No `minWidth` constraints -- sheets fill screen width on iPhone
- Remove all `.frame(minWidth:)` from sheet content on iOS

### 5.6 Recommended File Organization

```
HCDInterviewCoach/
├── Shared/                    # Cross-platform code
│   ├── Models/                # All SwiftData models (unchanged)
│   ├── Services/              # Business logic (unchanged)
│   │   ├── ClipboardService.swift  # NEW: platform abstraction
│   │   └── FileExportService.swift # NEW: platform abstraction
│   ├── DesignSystem/          # Tokens with #if os guards
│   └── ViewModels/            # Shared view models
├── macOS/                     # macOS-only views
│   ├── ContentView_macOS.swift
│   ├── AudioSetup/            # BlackHole wizard
│   └── MacPlatformExtensions.swift
├── iOS/                       # iOS-only views
│   ├── ContentView_iOS.swift
│   ├── TabNavigation.swift
│   ├── MobileSessionView.swift
│   └── iOSPlatformExtensions.swift
└── Features/                  # Shared feature views (with minor #if os)
    ├── Coaching/
    ├── Transcript/
    ├── Insights/
    └── ...
```

---

## 6. Priority-Ordered Implementation Plan

### CRITICAL -- App Will Not Work on Mobile Without These

These changes are **blocking**. The app will not compile or function on iOS without addressing them.

| # | Change | Files Affected | Effort |
|---|--------|---------------|--------|
| C1 | Remove/guard `import AppKit` and all `NSColor`, `NSFont`, `NSApplication` references | `ExportService.swift`, `CoachingPromptView.swift`, `ConsentFlowView.swift`, `HCDInterviewCoachApp.swift`, `Colors.swift`, `TaggingView.swift` | Medium |
| C2 | Replace `NSPasteboard` with cross-platform `ClipboardService` | 8 files (see Section 1.2) | Low |
| C3 | Replace `NSSavePanel` with `fileExporter()` modifier or `UIActivityViewController` | `TranscriptView.swift`, `ExportService.swift` (2 methods) | Medium |
| C4 | Replace `NSSpeechSynthesizer` with `AVSpeechSynthesizer` | `ConsentFlowView.swift` | Low |
| C5 | Replace `HSplitView` with cross-platform layout | `DemoModeView.swift` | Low |
| C6 | Remove `.frame(minWidth: 800, minHeight: 600)` from root `ContentView` | `ContentView.swift:98` | Low |
| C7 | Guard/exclude `AudioSetup/` from iOS build target | 8 files in `Features/AudioSetup/` | Low |
| C8 | Replace `Color(.controlBackgroundColor)` with cross-platform color tokens | 10+ files (see Section 1.8) | Low |
| C9 | Replace `Color(nsColor:)` calls with platform-conditional equivalents | `Colors.swift`, `QuoteLibraryView.swift`, `HighlightCreatorView.swift`, `TranscriptSearchView.swift` | Low |
| C10 | Add `UIColor(hex:)` extension mirroring existing `NSColor(hex:)` | `Colors.swift` | Low |
| C11 | Guard `NSEvent` keyboard monitoring (already partially done) | `CoachingViewModel.swift` | Done |
| C12 | Replace `CommandGroup` / menu bar commands with iOS equivalents | `HCDInterviewCoachApp.swift` | Medium |

### IMPORTANT -- Poor UX Without These

The app would technically run but would be nearly unusable without these changes.

| # | Change | Files Affected | Effort |
|---|--------|---------------|--------|
| I1 | Create iPhone navigation structure (`TabView` + `NavigationStack`) | New `ContentView_iOS.swift` | High |
| I2 | Create iPad navigation structure (`NavigationSplitView`) | New `ContentView_iPad.swift` or shared with size class checks | High |
| I3 | Replace session sidebar layout with mobile-friendly stacked/sheet layout | `ContentView.swift` (ActiveSessionPlaceholderView) | High |
| I4 | Remove all `minWidth` > 430pt from sheet presentations | `ContentView.swift`, `QuoteLibraryView`, `ExportView`, `ConsentFlowView`, `ParticipantDetailView`, `ParticipantPickerView`, `AudioSetupWizardView`, `CulturalSettingsView`, `SessionSetupView` | Medium |
| I5 | Increase all touch targets to minimum 44x44pt | `FocusModePickerView`, `QuestionTypeView`, `ContentView` toolbar buttons, `TaggingView` | Medium |
| I6 | Replace `.onHover` interactions with touch alternatives | 18 files (see Section 3.2) | Medium |
| I7 | Add on-screen buttons for all keyboard shortcuts | Various -- create floating action buttons, toolbar items | Medium |
| I8 | Switch Typography to Dynamic Type (`Font.TextStyle`) on iOS | `Typography.swift` | Low |
| I9 | Create mobile-friendly Demo Mode layout (no `HSplitView`) | `DemoModeView.swift` | Medium |
| I10 | Add `.presentationDetents()` to all sheets on iOS | All `.sheet()` presentations | Low |
| I11 | Wrap wide `HStack` toolbars for narrow screens | `ContentView.swift` session toolbar, `DemoModeView.swift` playback controls | Medium |
| I12 | Handle keyboard avoidance for text fields and editors | `TaggingView`, `TranscriptSearchView`, `InsightDetailSheet`, `ResearcherNotesEditor` | Low |
| I13 | Replace `.help()` tooltips with iOS-compatible alternatives | `FocusModePickerView`, `WizardStepView` | Low |

### NICE-TO-HAVE -- Polish

These improve the experience but are not essential for a functional mobile version.

| # | Change | Files Affected | Effort |
|---|--------|---------------|--------|
| N1 | Add swipe actions on transcript utterance rows (flag insight, copy, tag) | `UtteranceRowView.swift` | Medium |
| N2 | Add haptic feedback for key actions (insight flagged, coaching prompt) | Various | Low |
| N3 | Optimize `LiquidGlass` performance for older iPhones (reduce layers) | `LiquidGlass.swift` | Medium |
| N4 | Add pull-to-refresh on session list/analytics | `CrossSessionAnalyticsView.swift` | Low |
| N5 | Support iPad multitasking (Split View, Slide Over) | Info.plist + layout testing | Medium |
| N6 | Add iOS-native share sheet for exports (replacing clipboard-only) | `EnhancedSummaryView`, `QuoteLibraryView`, `AIReflectionView` | Low |
| N7 | Implement Spotlight search integration for sessions | New service | Medium |
| N8 | Add iOS widget for upcoming interviews (from CalendarService) | New widget extension | High |
| N9 | Support Apple Pencil hover on iPad Pro (use existing hover code) | `LiquidGlass.swift`, hover-dependent views | Low |
| N10 | Create compact coaching prompt for iPhone (smaller floating card) | `CoachingPromptView.swift` | Low |
| N11 | Add landscape support and responsive layouts for all orientations | All feature views | High |
| N12 | Adapt `FlowLayout` (used in `TaggingView`, `QuestionTypeView`) for smaller widths | Already works, but test with real data on 320pt width | Low |
| N13 | Use `.searchable()` modifier for iOS-native search experience | `TranscriptView` | Medium |

---

## Summary Statistics

| Category | Count |
|----------|-------|
| Files with macOS-only APIs | 15+ source files |
| Fixed widths > 430pt (phone max) | 17 locations |
| Hover-dependent interactions | 18 files |
| Keyboard shortcuts needing touch alternatives | 34 shortcuts |
| Touch targets below 44pt | 10+ elements |
| Critical changes (blocking) | 12 items |
| Important changes (UX) | 13 items |
| Nice-to-have (polish) | 13 items |

### Estimated Effort Distribution

| Phase | Items | Estimated Effort |
|-------|-------|-----------------|
| Phase 1: Compilation (Critical) | C1-C12 | 2-3 days |
| Phase 2: Core Mobile UX (Important) | I1-I13 | 5-8 days |
| Phase 3: Polish (Nice-to-have) | N1-N13 | 3-5 days |
| **Total** | **38 items** | **10-16 days** |

### Key Risk: Audio Capture

The most significant architectural challenge is audio capture. The entire app concept relies on capturing system audio via BlackHole, which is fundamentally impossible on iOS due to sandboxing. The mobile version must either:

1. **Microphone-only mode**: Capture ambient audio from the device mic (lower quality, privacy considerations)
2. **Integration approach**: Partner with video conferencing APIs (Zoom SDK, Teams SDK) for audio streams
3. **Manual mode**: Allow researchers to manually control the transcript (type/paste) without live audio

This architectural decision should be made before beginning mobile development, as it affects the session flow, audio setup, and real-time transcription features.
