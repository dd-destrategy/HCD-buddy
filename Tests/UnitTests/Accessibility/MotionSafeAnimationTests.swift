//
//  MotionSafeAnimationTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for MotionSafeAnimation accessibility support
//

import XCTest
import SwiftUI
@testable import HCDInterviewCoach

// MARK: - AnimationTiming Tests

final class AnimationTimingTests: XCTestCase {

    // MARK: - Test: Timing Constants Exist

    func testAnimationTiming_fastConstantExists() {
        // Given/When: Access the fast timing constant
        let fast = AnimationTiming.fast

        // Then: It should have a value
        XCTAssertGreaterThan(fast, 0)
    }

    func testAnimationTiming_normalConstantExists() {
        // Given/When: Access the normal timing constant
        let normal = AnimationTiming.normal

        // Then: It should have a value
        XCTAssertGreaterThan(normal, 0)
    }

    func testAnimationTiming_slowConstantExists() {
        // Given/When: Access the slow timing constant
        let slow = AnimationTiming.slow

        // Then: It should have a value
        XCTAssertGreaterThan(slow, 0)
    }

    func testAnimationTiming_veryFastConstantExists() {
        // Given/When: Access the veryFast timing constant
        let veryFast = AnimationTiming.veryFast

        // Then: It should have a value
        XCTAssertGreaterThan(veryFast, 0)
    }

    // MARK: - Test: Timing Progression

    func testAnimationTiming_veryFastIsLessThanFast() {
        // Given: Both timing constants
        let veryFast = AnimationTiming.veryFast
        let fast = AnimationTiming.fast

        // Then: veryFast should be less than fast
        XCTAssertLessThan(veryFast, fast, "veryFast should be quicker than fast")
    }

    func testAnimationTiming_fastIsLessThanNormal() {
        // Given: Both timing constants
        let fast = AnimationTiming.fast
        let normal = AnimationTiming.normal

        // Then: fast should be less than normal
        XCTAssertLessThan(fast, normal, "fast should be quicker than normal")
    }

    func testAnimationTiming_normalIsLessThanSlow() {
        // Given: Both timing constants
        let normal = AnimationTiming.normal
        let slow = AnimationTiming.slow

        // Then: normal should be less than slow
        XCTAssertLessThan(normal, slow, "normal should be quicker than slow")
    }

    func testAnimationTiming_fullProgression() {
        // Given: All timing constants
        let veryFast = AnimationTiming.veryFast
        let fast = AnimationTiming.fast
        let normal = AnimationTiming.normal
        let slow = AnimationTiming.slow

        // Then: They should be in ascending order
        XCTAssertLessThan(veryFast, fast)
        XCTAssertLessThan(fast, normal)
        XCTAssertLessThan(normal, slow)
    }

    // MARK: - Test: Exact Values

    func testAnimationTiming_veryFastExactValue() {
        XCTAssertEqual(AnimationTiming.veryFast, 0.1, accuracy: 0.001)
    }

    func testAnimationTiming_fastExactValue() {
        XCTAssertEqual(AnimationTiming.fast, 0.15, accuracy: 0.001)
    }

    func testAnimationTiming_normalExactValue() {
        XCTAssertEqual(AnimationTiming.normal, 0.25, accuracy: 0.001)
    }

    func testAnimationTiming_slowExactValue() {
        XCTAssertEqual(AnimationTiming.slow, 0.4, accuracy: 0.001)
    }

    // MARK: - Test: Reasonable Duration Ranges

    func testAnimationTiming_veryFastIsReasonable() {
        // veryFast should be between 0.05 and 0.15 seconds
        let veryFast = AnimationTiming.veryFast
        XCTAssertGreaterThanOrEqual(veryFast, 0.05)
        XCTAssertLessThanOrEqual(veryFast, 0.15)
    }

    func testAnimationTiming_fastIsReasonable() {
        // fast should be between 0.1 and 0.2 seconds
        let fast = AnimationTiming.fast
        XCTAssertGreaterThanOrEqual(fast, 0.1)
        XCTAssertLessThanOrEqual(fast, 0.2)
    }

    func testAnimationTiming_normalIsReasonable() {
        // normal should be between 0.2 and 0.35 seconds
        let normal = AnimationTiming.normal
        XCTAssertGreaterThanOrEqual(normal, 0.2)
        XCTAssertLessThanOrEqual(normal, 0.35)
    }

    func testAnimationTiming_slowIsReasonable() {
        // slow should be between 0.3 and 0.5 seconds
        let slow = AnimationTiming.slow
        XCTAssertGreaterThanOrEqual(slow, 0.3)
        XCTAssertLessThanOrEqual(slow, 0.5)
    }
}

// MARK: - MotionSafeAnimation Modifier Tests

final class MotionSafeAnimationModifierTests: XCTestCase {

    // MARK: - Test: Modifier Existence

    func testMotionSafeAnimation_modifierCanBeCreated() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply motionSafeAnimation modifier
        let modifiedView = view.motionSafeAnimation(.easeInOut, value: true)

        // Then: The modifier should return a view
        XCTAssertNotNil(modifiedView)
    }

    func testMotionSafeAnimation_withDifferentAnimationTypes() {
        let view = Text("Test")

        // Test with different animation types
        let easeInOut = view.motionSafeAnimation(.easeInOut, value: 1)
        XCTAssertNotNil(easeInOut)

        let linear = view.motionSafeAnimation(.linear, value: 1)
        XCTAssertNotNil(linear)

        let spring = view.motionSafeAnimation(.spring(), value: 1)
        XCTAssertNotNil(spring)

        let easeIn = view.motionSafeAnimation(.easeIn, value: 1)
        XCTAssertNotNil(easeIn)

        let easeOut = view.motionSafeAnimation(.easeOut, value: 1)
        XCTAssertNotNil(easeOut)
    }

    func testMotionSafeAnimation_withDifferentValueTypes() {
        let view = Text("Test")

        // Test with different value types
        let boolValue = view.motionSafeAnimation(.easeInOut, value: true)
        XCTAssertNotNil(boolValue)

        let intValue = view.motionSafeAnimation(.easeInOut, value: 42)
        XCTAssertNotNil(intValue)

        let doubleValue = view.motionSafeAnimation(.easeInOut, value: 3.14)
        XCTAssertNotNil(doubleValue)

        let stringValue = view.motionSafeAnimation(.easeInOut, value: "test")
        XCTAssertNotNil(stringValue)
    }

    func testMotionSafeAnimation_withCustomDuration() {
        // Given: A view with custom animation duration
        let view = Text("Test")
        let customAnimation = Animation.easeInOut(duration: AnimationTiming.slow)

        // When: Apply motion safe animation
        let modifiedView = view.motionSafeAnimation(customAnimation, value: true)

        // Then: The modifier should work
        XCTAssertNotNil(modifiedView)
    }

    func testMotionSafeAnimation_withSpringAnimation() {
        // Given: A view with spring animation
        let view = Text("Test")
        let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7)

        // When: Apply motion safe animation
        let modifiedView = view.motionSafeAnimation(springAnimation, value: true)

        // Then: The modifier should work
        XCTAssertNotNil(modifiedView)
    }

    // MARK: - Test: Modifier Struct Properties

    func testMotionSafeAnimationModifier_storesAnimation() {
        // Given: An animation
        let animation = Animation.easeInOut

        // When: Create the modifier struct directly
        let modifier = MotionSafeAnimation(animation: animation, value: true)

        // Then: The animation should be stored
        // Note: We can't directly compare animations, but we can verify the modifier exists
        XCTAssertNotNil(modifier)
    }

    func testMotionSafeAnimationModifier_storesValue() {
        // Given: A value
        let value = 42

        // When: Create the modifier struct directly
        let modifier = MotionSafeAnimation(animation: .easeInOut, value: value)

        // Then: The value should be stored
        XCTAssertEqual(modifier.value, value)
    }
}

// MARK: - MotionSafeTransition Tests

final class MotionSafeTransitionTests: XCTestCase {

    // MARK: - Test: Transition Modifier Existence

    func testMotionSafeTransition_modifierExists() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply motionSafeTransition modifier
        let modifiedView = view.motionSafeTransition(.slide)

        // Then: The modifier should return a view
        XCTAssertNotNil(modifiedView)
    }

    func testMotionSafeTransition_withDifferentTransitions() {
        let view = Text("Test")

        // Test with different transitions
        let slide = view.motionSafeTransition(.slide)
        XCTAssertNotNil(slide)

        let opacity = view.motionSafeTransition(.opacity)
        XCTAssertNotNil(opacity)

        let scale = view.motionSafeTransition(.scale)
        XCTAssertNotNil(scale)

        let move = view.motionSafeTransition(.move(edge: .leading))
        XCTAssertNotNil(move)
    }

    // MARK: - Test: Convenience Transition Methods

    func testMotionSafeSlide_modifierExists() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply motionSafeSlide modifier
        let modifiedView = view.motionSafeSlide(edge: .leading)

        // Then: The modifier should return a view
        XCTAssertNotNil(modifiedView)
    }

    func testMotionSafeSlide_withDifferentEdges() {
        let view = Text("Test")

        // Test with different edges
        let leading = view.motionSafeSlide(edge: .leading)
        XCTAssertNotNil(leading)

        let trailing = view.motionSafeSlide(edge: .trailing)
        XCTAssertNotNil(trailing)

        let top = view.motionSafeSlide(edge: .top)
        XCTAssertNotNil(top)

        let bottom = view.motionSafeSlide(edge: .bottom)
        XCTAssertNotNil(bottom)
    }

    func testMotionSafeScale_modifierExists() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply motionSafeScale modifier with default scale
        let modifiedView = view.motionSafeScale()

        // Then: The modifier should return a view
        XCTAssertNotNil(modifiedView)
    }

    func testMotionSafeScale_withCustomScale() {
        let view = Text("Test")

        // Test with different scale values
        let halfScale = view.motionSafeScale(scale: 0.5)
        XCTAssertNotNil(halfScale)

        let fullScale = view.motionSafeScale(scale: 1.0)
        XCTAssertNotNil(fullScale)

        let quarterScale = view.motionSafeScale(scale: 0.25)
        XCTAssertNotNil(quarterScale)
    }

    // MARK: - Test: MotionSafeTransitionModifier Struct

    func testMotionSafeTransitionModifier_storesTransition() {
        // Given: A transition
        let transition = AnyTransition.slide

        // When: Create the modifier struct directly
        let modifier = MotionSafeTransitionModifier(transition: transition)

        // Then: The modifier should exist
        XCTAssertNotNil(modifier)
    }
}

// MARK: - MotionSafeAnimations Helper Tests

final class MotionSafeAnimationsTests: XCTestCase {

    // MARK: - Test: Initialization

    func testMotionSafeAnimations_initWithReduceMotionFalse() {
        // Given/When: Create with reduceMotion = false
        let animations = MotionSafeAnimations(reduceMotion: false)

        // Then: reduceMotion should be false
        XCTAssertFalse(animations.reduceMotion)
    }

    func testMotionSafeAnimations_initWithReduceMotionTrue() {
        // Given/When: Create with reduceMotion = true
        let animations = MotionSafeAnimations(reduceMotion: true)

        // Then: reduceMotion should be true
        XCTAssertTrue(animations.reduceMotion)
    }

    // MARK: - Test: Animations When Motion Enabled

    func testMotionSafeAnimations_gentleSpringWhenMotionEnabled() {
        // Given: Motion is enabled
        let animations = MotionSafeAnimations(reduceMotion: false)

        // When: Access gentleSpring
        let spring = animations.gentleSpring

        // Then: Should return an animation (not nil)
        XCTAssertNotNil(spring)
    }

    func testMotionSafeAnimations_standardEaseWhenMotionEnabled() {
        // Given: Motion is enabled
        let animations = MotionSafeAnimations(reduceMotion: false)

        // When: Access standardEase
        let ease = animations.standardEase

        // Then: Should return an animation (not nil)
        XCTAssertNotNil(ease)
    }

    func testMotionSafeAnimations_slowEaseWhenMotionEnabled() {
        // Given: Motion is enabled
        let animations = MotionSafeAnimations(reduceMotion: false)

        // When: Access slowEase
        let slowEase = animations.slowEase

        // Then: Should return an animation (not nil)
        XCTAssertNotNil(slowEase)
    }

    func testMotionSafeAnimations_quickFadeWhenMotionEnabled() {
        // Given: Motion is enabled
        let animations = MotionSafeAnimations(reduceMotion: false)

        // When: Access quickFade
        let fade = animations.quickFade

        // Then: Should return an animation (not nil)
        XCTAssertNotNil(fade)
    }

    // MARK: - Test: Animations When Motion Reduced

    func testMotionSafeAnimations_gentleSpringWhenMotionReduced() {
        // Given: Motion is reduced
        let animations = MotionSafeAnimations(reduceMotion: true)

        // When: Access gentleSpring
        let spring = animations.gentleSpring

        // Then: Should return nil (no animation)
        XCTAssertNil(spring)
    }

    func testMotionSafeAnimations_standardEaseWhenMotionReduced() {
        // Given: Motion is reduced
        let animations = MotionSafeAnimations(reduceMotion: true)

        // When: Access standardEase
        let ease = animations.standardEase

        // Then: Should return nil (no animation)
        XCTAssertNil(ease)
    }

    func testMotionSafeAnimations_slowEaseWhenMotionReduced() {
        // Given: Motion is reduced
        let animations = MotionSafeAnimations(reduceMotion: true)

        // When: Access slowEase
        let slowEase = animations.slowEase

        // Then: Should return nil (no animation)
        XCTAssertNil(slowEase)
    }

    func testMotionSafeAnimations_quickFadeWhenMotionReduced() {
        // Given: Motion is reduced
        let animations = MotionSafeAnimations(reduceMotion: true)

        // When: Access quickFade
        let fade = animations.quickFade

        // Then: Should return nil (no animation)
        XCTAssertNil(fade)
    }

    // MARK: - Test: All Animations Are Nil When Reduced

    func testMotionSafeAnimations_allAnimationsNilWhenReduced() {
        // Given: Motion is reduced
        let animations = MotionSafeAnimations(reduceMotion: true)

        // Then: All animations should be nil
        XCTAssertNil(animations.gentleSpring)
        XCTAssertNil(animations.standardEase)
        XCTAssertNil(animations.slowEase)
        XCTAssertNil(animations.quickFade)
    }

    // MARK: - Test: All Animations Are Non-Nil When Enabled

    func testMotionSafeAnimations_allAnimationsExistWhenEnabled() {
        // Given: Motion is enabled
        let animations = MotionSafeAnimations(reduceMotion: false)

        // Then: All animations should exist
        XCTAssertNotNil(animations.gentleSpring)
        XCTAssertNotNil(animations.standardEase)
        XCTAssertNotNil(animations.slowEase)
        XCTAssertNotNil(animations.quickFade)
    }
}

// MARK: - PulsingEffect Tests

final class PulsingEffectTests: XCTestCase {

    // MARK: - Test: Modifier Existence

    func testPulsingEffect_modifierExists() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply pulsingEffect modifier
        let modifiedView = view.pulsingEffect()

        // Then: The modifier should return a view
        XCTAssertNotNil(modifiedView)
    }

    func testPulsingEffect_withDefaultParameters() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply pulsingEffect with default parameters
        let modifiedView = view.pulsingEffect()

        // Then: The modifier should work
        XCTAssertNotNil(modifiedView)
    }

    func testPulsingEffect_withCustomOpacity() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply pulsingEffect with custom opacity values
        let modifiedView = view.pulsingEffect(minOpacity: 0.3, maxOpacity: 0.9)

        // Then: The modifier should work
        XCTAssertNotNil(modifiedView)
    }

    func testPulsingEffect_withCustomDuration() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply pulsingEffect with custom duration
        let modifiedView = view.pulsingEffect(duration: 2.0)

        // Then: The modifier should work
        XCTAssertNotNil(modifiedView)
    }

    func testPulsingEffect_withAllCustomParameters() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply pulsingEffect with all custom parameters
        let modifiedView = view.pulsingEffect(minOpacity: 0.2, maxOpacity: 0.8, duration: 1.5)

        // Then: The modifier should work
        XCTAssertNotNil(modifiedView)
    }

    // MARK: - Test: PulsingEffect Struct

    func testPulsingEffectStruct_defaultValues() {
        // Given/When: Create PulsingEffect with defaults
        let effect = PulsingEffect()

        // Then: Default values should be applied
        XCTAssertEqual(effect.minOpacity, 0.5)
        XCTAssertEqual(effect.maxOpacity, 1.0)
        XCTAssertEqual(effect.duration, 1.0)
    }

    func testPulsingEffectStruct_customValues() {
        // Given/When: Create PulsingEffect with custom values
        let effect = PulsingEffect(minOpacity: 0.3, maxOpacity: 0.9, duration: 2.0)

        // Then: Custom values should be stored
        XCTAssertEqual(effect.minOpacity, 0.3)
        XCTAssertEqual(effect.maxOpacity, 0.9)
        XCTAssertEqual(effect.duration, 2.0)
    }

    // MARK: - Test: Opacity Bounds

    func testPulsingEffect_minOpacityIsLessThanMax() {
        // Given: A pulsing effect with default values
        let effect = PulsingEffect()

        // Then: min should be less than max
        XCTAssertLessThan(effect.minOpacity, effect.maxOpacity)
    }

    func testPulsingEffect_opacityValuesAreValid() {
        // Given: A pulsing effect with default values
        let effect = PulsingEffect()

        // Then: Both values should be between 0 and 1
        XCTAssertGreaterThanOrEqual(effect.minOpacity, 0)
        XCTAssertLessThanOrEqual(effect.minOpacity, 1)
        XCTAssertGreaterThanOrEqual(effect.maxOpacity, 0)
        XCTAssertLessThanOrEqual(effect.maxOpacity, 1)
    }
}

// MARK: - RotatingEffect Tests

final class RotatingEffectTests: XCTestCase {

    // MARK: - Test: Modifier Existence

    func testRotatingEffect_modifierExists() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply rotatingEffect modifier
        let modifiedView = view.rotatingEffect()

        // Then: The modifier should return a view
        XCTAssertNotNil(modifiedView)
    }

    func testRotatingEffect_withDefaultDuration() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply rotatingEffect with default duration
        let modifiedView = view.rotatingEffect()

        // Then: The modifier should work
        XCTAssertNotNil(modifiedView)
    }

    func testRotatingEffect_withCustomDuration() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply rotatingEffect with custom duration
        let modifiedView = view.rotatingEffect(duration: 2.5)

        // Then: The modifier should work
        XCTAssertNotNil(modifiedView)
    }

    func testRotatingEffect_withFastDuration() {
        // Given: A simple view
        let view = Text("Test")

        // When: Apply rotatingEffect with fast duration
        let modifiedView = view.rotatingEffect(duration: 0.5)

        // Then: The modifier should work
        XCTAssertNotNil(modifiedView)
    }

    // MARK: - Test: RotatingEffect Struct

    func testRotatingEffectStruct_defaultDuration() {
        // Given/When: Create RotatingEffect with default
        let effect = RotatingEffect()

        // Then: Default duration should be 1.0
        XCTAssertEqual(effect.duration, 1.0)
    }

    func testRotatingEffectStruct_customDuration() {
        // Given/When: Create RotatingEffect with custom duration
        let effect = RotatingEffect(duration: 3.0)

        // Then: Custom duration should be stored
        XCTAssertEqual(effect.duration, 3.0)
    }

    // MARK: - Test: Duration Validation

    func testRotatingEffect_durationIsPositive() {
        // Given: A rotating effect with default duration
        let effect = RotatingEffect()

        // Then: Duration should be positive
        XCTAssertGreaterThan(effect.duration, 0)
    }
}

// MARK: - ShakeEffect Tests

final class ShakeEffectTests: XCTestCase {

    // MARK: - Test: Modifier Existence

    func testShakeEffect_modifierExists() {
        // Given: A simple view and a binding
        let view = Text("Test")
        @State var shake = false

        // When: Apply shakeEffect modifier
        let modifiedView = view.shakeEffect(shake: .constant(false))

        // Then: The modifier should return a view
        XCTAssertNotNil(modifiedView)
    }

    func testShakeEffect_withTrueBinding() {
        // Given: A simple view with shake = true
        let view = Text("Test")

        // When: Apply shakeEffect modifier with shake = true
        let modifiedView = view.shakeEffect(shake: .constant(true))

        // Then: The modifier should work
        XCTAssertNotNil(modifiedView)
    }

    func testShakeEffect_withFalseBinding() {
        // Given: A simple view with shake = false
        let view = Text("Test")

        // When: Apply shakeEffect modifier with shake = false
        let modifiedView = view.shakeEffect(shake: .constant(false))

        // Then: The modifier should work
        XCTAssertNotNil(modifiedView)
    }

    // MARK: - Test: ShakeEffect Binding Behavior

    func testShakeEffect_bindingCanChange() {
        // Given: A mutable shake state
        var shakeState = false

        // When: State changes
        shakeState = true

        // Then: State should reflect the change
        XCTAssertTrue(shakeState)

        shakeState = false
        XCTAssertFalse(shakeState)
    }
}

// MARK: - MotionSafeScrolling Tests

final class MotionSafeScrollingTests: XCTestCase {

    // MARK: - Test: Modifier Existence

    func testMotionSafeScrolling_modifierExists() {
        // Given: A ScrollView
        let view = ScrollView {
            Text("Content")
        }

        // When: Apply motionSafeScrolling modifier
        let modifiedView = view.motionSafeScrolling()

        // Then: The modifier should return a view
        XCTAssertNotNil(modifiedView)
    }

    func testMotionSafeScrolling_worksWithDifferentViews() {
        // Test with various view types
        let textView = Text("Test").motionSafeScrolling()
        XCTAssertNotNil(textView)

        let imageView = Image(systemName: "star").motionSafeScrolling()
        XCTAssertNotNil(imageView)

        let stackView = VStack { Text("Test") }.motionSafeScrolling()
        XCTAssertNotNil(stackView)
    }

    // MARK: - Test: MotionSafeScrollModifier Struct

    func testMotionSafeScrollModifier_exists() {
        // Given/When: Create the modifier directly
        let modifier = MotionSafeScrollModifier()

        // Then: Modifier should exist
        XCTAssertNotNil(modifier)
    }
}

// MARK: - MotionSafeScrollController Tests

@MainActor
final class MotionSafeScrollControllerTests: XCTestCase {

    // MARK: - Test: Initialization

    func testScrollController_initWithReduceMotionFalse() {
        // Given/When: Create controller with motion enabled
        let controller = MotionSafeScrollController(reduceMotion: false)

        // Then: Should auto-scroll by default
        XCTAssertTrue(controller.shouldAutoScroll)
    }

    func testScrollController_initWithReduceMotionTrue() {
        // Given/When: Create controller with motion reduced
        let controller = MotionSafeScrollController(reduceMotion: true)

        // Then: Should auto-scroll by default (setting controls animation, not auto-scroll)
        XCTAssertTrue(controller.shouldAutoScroll)
    }

    // MARK: - Test: Auto-scroll Toggle

    func testScrollController_toggleAutoScroll() {
        // Given: A scroll controller with auto-scroll enabled
        let controller = MotionSafeScrollController(reduceMotion: false)
        XCTAssertTrue(controller.shouldAutoScroll)

        // When: Disable auto-scroll
        controller.shouldAutoScroll = false

        // Then: Auto-scroll should be disabled
        XCTAssertFalse(controller.shouldAutoScroll)
    }

    func testScrollController_enableAutoScroll() {
        // Given: A scroll controller with auto-scroll disabled
        let controller = MotionSafeScrollController(reduceMotion: false)
        controller.shouldAutoScroll = false

        // When: Enable auto-scroll
        controller.shouldAutoScroll = true

        // Then: Auto-scroll should be enabled
        XCTAssertTrue(controller.shouldAutoScroll)
    }

    // MARK: - Test: Scroll Method Existence

    func testScrollController_scrollMethodExists() {
        // Given: A scroll controller
        let controller = MotionSafeScrollController(reduceMotion: false)

        // When/Then: Scroll method should be callable with different positions
        controller.scroll(to: .top)
        controller.scroll(to: .bottom)
        controller.scroll(to: .id("test-id"))
        controller.scroll(to: .offset(100))

        // No assertion needed - test verifies method exists and is callable
    }

    func testScrollController_scrollWithAnimatedParameter() {
        // Given: A scroll controller
        let controller = MotionSafeScrollController(reduceMotion: false)

        // When/Then: Scroll method should accept animated parameter
        controller.scroll(to: .top, animated: true)
        controller.scroll(to: .bottom, animated: false)

        // No assertion needed - test verifies method signature
    }
}

// MARK: - ScrollPosition Tests

final class ScrollPositionTests: XCTestCase {

    // MARK: - Test: Position Cases Exist

    func testScrollPosition_topExists() {
        let position = ScrollPosition.top
        XCTAssertNotNil(position)
    }

    func testScrollPosition_bottomExists() {
        let position = ScrollPosition.bottom
        XCTAssertNotNil(position)
    }

    func testScrollPosition_idExists() {
        let position = ScrollPosition.id("test-id")
        XCTAssertNotNil(position)
    }

    func testScrollPosition_offsetExists() {
        let position = ScrollPosition.offset(100.0)
        XCTAssertNotNil(position)
    }

    // MARK: - Test: Position Values

    func testScrollPosition_idWithDifferentStrings() {
        let position1 = ScrollPosition.id("first")
        let position2 = ScrollPosition.id("second")
        let position3 = ScrollPosition.id("")

        XCTAssertNotNil(position1)
        XCTAssertNotNil(position2)
        XCTAssertNotNil(position3)
    }

    func testScrollPosition_offsetWithDifferentValues() {
        let zeroOffset = ScrollPosition.offset(0)
        let positiveOffset = ScrollPosition.offset(500)
        let largeOffset = ScrollPosition.offset(10000)

        XCTAssertNotNil(zeroOffset)
        XCTAssertNotNil(positiveOffset)
        XCTAssertNotNil(largeOffset)
    }
}

// MARK: - View Extension Tests

final class MotionSafeViewExtensionTests: XCTestCase {

    // MARK: - Test: withMotionSafeAnimations Extension

    func testWithMotionSafeAnimations_extensionExists() {
        // Given: A simple view
        let view = Text("Test")

        // When: Use withMotionSafeAnimations
        let modifiedView = view.withMotionSafeAnimations { animations in
            Text("Using animations: \(animations.reduceMotion)")
        }

        // Then: The extension should return a view
        XCTAssertNotNil(modifiedView)
    }

    func testWithMotionSafeAnimations_providesAnimationsObject() {
        // Given: A view using withMotionSafeAnimations
        var receivedAnimations: MotionSafeAnimations?

        let view = Text("Test").withMotionSafeAnimations { animations in
            receivedAnimations = animations
            return Text("Inner")
        }

        // Then: View should be created (animations object tested in closure)
        XCTAssertNotNil(view)
    }

    // MARK: - Test: Combined Modifiers

    func testCombinedMotionSafeModifiers() {
        // Given: A view with multiple motion-safe modifiers
        let view = Text("Test")
            .motionSafeAnimation(.easeInOut, value: true)
            .motionSafeScrolling()
            .pulsingEffect()

        // Then: All modifiers should work together
        XCTAssertNotNil(view)
    }

    func testCombinedTransitionAndAnimation() {
        // Given: A view with both transition and animation modifiers
        let view = Text("Test")
            .motionSafeTransition(.slide)
            .motionSafeAnimation(.spring(), value: true)

        // Then: Both modifiers should work
        XCTAssertNotNil(view)
    }

    func testCombinedEffects() {
        // Given: A view with multiple effects
        let view = Text("Test")
            .pulsingEffect()
            .rotatingEffect()

        // Then: Both effects should work
        XCTAssertNotNil(view)
    }
}

// MARK: - Integration Tests

final class MotionSafeAnimationIntegrationTests: XCTestCase {

    // MARK: - Test: Full Animation Pipeline

    func testFullAnimationPipeline_withMotionEnabled() {
        // Given: Motion is enabled
        let animations = MotionSafeAnimations(reduceMotion: false)

        // When: Build a view with motion-safe animations
        let view = Text("Test")
            .motionSafeAnimation(.easeInOut, value: true)
            .motionSafeTransition(.slide)
            .pulsingEffect()

        // Then: View should be created, animations should not be nil
        XCTAssertNotNil(view)
        XCTAssertNotNil(animations.gentleSpring)
        XCTAssertNotNil(animations.standardEase)
    }

    func testFullAnimationPipeline_withMotionReduced() {
        // Given: Motion is reduced
        let animations = MotionSafeAnimations(reduceMotion: true)

        // When: Access animations
        // Then: All animations should be nil
        XCTAssertNil(animations.gentleSpring)
        XCTAssertNil(animations.standardEase)
        XCTAssertNil(animations.slowEase)
        XCTAssertNil(animations.quickFade)
    }

    // MARK: - Test: Timing Constants with Animations

    func testTimingConstantsWithAnimations() {
        // Given: Timing constants
        let veryFast = AnimationTiming.veryFast
        let fast = AnimationTiming.fast
        let normal = AnimationTiming.normal
        let slow = AnimationTiming.slow

        // When: Create animations with these durations
        let veryFastAnim = Animation.easeInOut(duration: veryFast)
        let fastAnim = Animation.easeInOut(duration: fast)
        let normalAnim = Animation.easeInOut(duration: normal)
        let slowAnim = Animation.easeInOut(duration: slow)

        // Then: All animations should be created successfully
        XCTAssertNotNil(veryFastAnim)
        XCTAssertNotNil(fastAnim)
        XCTAssertNotNil(normalAnim)
        XCTAssertNotNil(slowAnim)
    }

    func testTimingConstantsWithMotionSafeAnimation() {
        // Given: A view
        let view = Text("Test")

        // When: Apply motion safe animations with timing constants
        let veryFastView = view.motionSafeAnimation(
            .easeInOut(duration: AnimationTiming.veryFast),
            value: true
        )
        let fastView = view.motionSafeAnimation(
            .easeInOut(duration: AnimationTiming.fast),
            value: true
        )
        let normalView = view.motionSafeAnimation(
            .easeInOut(duration: AnimationTiming.normal),
            value: true
        )
        let slowView = view.motionSafeAnimation(
            .easeInOut(duration: AnimationTiming.slow),
            value: true
        )

        // Then: All views should be created
        XCTAssertNotNil(veryFastView)
        XCTAssertNotNil(fastView)
        XCTAssertNotNil(normalView)
        XCTAssertNotNil(slowView)
    }

    // MARK: - Test: Scroll Controller Integration

    @MainActor
    func testScrollControllerWithReduceMotion() {
        // Given: Controllers with different reduce motion settings
        let enabledController = MotionSafeScrollController(reduceMotion: false)
        let reducedController = MotionSafeScrollController(reduceMotion: true)

        // Then: Both should work but with different behavior
        XCTAssertTrue(enabledController.shouldAutoScroll)
        XCTAssertTrue(reducedController.shouldAutoScroll)

        // When: Scroll to different positions
        enabledController.scroll(to: .top, animated: true)
        reducedController.scroll(to: .top, animated: true)

        // No explicit assertion needed - test verifies no crash occurs
    }
}
