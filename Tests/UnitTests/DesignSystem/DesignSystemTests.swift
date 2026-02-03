//
//  DesignSystemTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for Design System components: Typography, Spacing,
//  CornerRadius, Shadows, and LiquidGlass.
//

import XCTest
import SwiftUI
@testable import HCDInterviewCoach

final class DesignSystemTests: XCTestCase {

    // MARK: - Typography Tests

    func testTypography_allStylesExist() {
        // Verify all 8 text styles are defined
        XCTAssertNotNil(Typography.display)
        XCTAssertNotNil(Typography.heading1)
        XCTAssertNotNil(Typography.heading2)
        XCTAssertNotNil(Typography.heading3)
        XCTAssertNotNil(Typography.body)
        XCTAssertNotNil(Typography.bodyMedium)
        XCTAssertNotNil(Typography.caption)
        XCTAssertNotNil(Typography.small)
    }

    func testTypography_displayIsLargestStyle() {
        // Display (32pt) should be the largest text style
        // Using string descriptions to verify font sizes
        let displayDescription = String(describing: Typography.display)
        let heading1Description = String(describing: Typography.heading1)

        // Display should contain "32" for 32pt
        XCTAssertTrue(displayDescription.contains("32"),
                     "Display font should be 32pt")
        // Heading1 should contain "24" for 24pt
        XCTAssertTrue(heading1Description.contains("24"),
                     "Heading1 font should be 24pt")
    }

    func testTypography_fontSizeProgression() {
        // Font sizes should follow hierarchy: display > heading1 > heading2 > heading3 > body > caption > small
        // Expected sizes: 32, 24, 18, 16, 14, 12, 10
        let expectedSizes: [(String, Int)] = [
            (String(describing: Typography.display), 32),
            (String(describing: Typography.heading1), 24),
            (String(describing: Typography.heading2), 18),
            (String(describing: Typography.heading3), 16),
            (String(describing: Typography.body), 14),
            (String(describing: Typography.caption), 12),
            (String(describing: Typography.small), 10)
        ]

        for (fontDescription, expectedSize) in expectedSizes {
            XCTAssertTrue(fontDescription.contains("\(expectedSize)"),
                         "Font should contain size \(expectedSize)")
        }
    }

    func testTypography_bodyMediumMatchesBodySize() {
        // bodyMedium should have same size (14pt) as body but different weight
        let bodyDescription = String(describing: Typography.body)
        let bodyMediumDescription = String(describing: Typography.bodyMedium)

        XCTAssertTrue(bodyDescription.contains("14"),
                     "Body should be 14pt")
        XCTAssertTrue(bodyMediumDescription.contains("14"),
                     "BodyMedium should also be 14pt")
    }

    func testTypography_displayIsBold() {
        let displayDescription = String(describing: Typography.display)
        XCTAssertTrue(displayDescription.lowercased().contains("bold"),
                     "Display font should be bold")
    }

    func testTypography_headingsAreSemibold() {
        let heading1Description = String(describing: Typography.heading1)
        let heading2Description = String(describing: Typography.heading2)
        let heading3Description = String(describing: Typography.heading3)

        XCTAssertTrue(heading1Description.lowercased().contains("semibold"),
                     "Heading1 should be semibold")
        XCTAssertTrue(heading2Description.lowercased().contains("semibold"),
                     "Heading2 should be semibold")
        XCTAssertTrue(heading3Description.lowercased().contains("semibold"),
                     "Heading3 should be semibold")
    }

    func testTypography_bodyIsRegular() {
        let bodyDescription = String(describing: Typography.body)
        XCTAssertTrue(bodyDescription.lowercased().contains("regular"),
                     "Body font should be regular weight")
    }

    func testTypography_bodyMediumIsMediumWeight() {
        let bodyMediumDescription = String(describing: Typography.bodyMedium)
        XCTAssertTrue(bodyMediumDescription.lowercased().contains("medium"),
                     "BodyMedium font should be medium weight")
    }

    // MARK: - Spacing Tests

    func testSpacing_allValuesExist() {
        // Verify all 6 spacing values are defined
        XCTAssertNotNil(Spacing.xs)
        XCTAssertNotNil(Spacing.sm)
        XCTAssertNotNil(Spacing.md)
        XCTAssertNotNil(Spacing.lg)
        XCTAssertNotNil(Spacing.xl)
        XCTAssertNotNil(Spacing.xxl)
    }

    func testSpacing_expectedValues() {
        // Verify exact spacing values: 4, 8, 12, 16, 24, 40
        XCTAssertEqual(Spacing.xs, 4, "xs should be 4")
        XCTAssertEqual(Spacing.sm, 8, "sm should be 8")
        XCTAssertEqual(Spacing.md, 12, "md should be 12")
        XCTAssertEqual(Spacing.lg, 16, "lg should be 16")
        XCTAssertEqual(Spacing.xl, 24, "xl should be 24")
        XCTAssertEqual(Spacing.xxl, 40, "xxl should be 40")
    }

    func testSpacing_scaleProgression() {
        // Verify scale progression: xs < sm < md < lg < xl < xxl
        XCTAssertLessThan(Spacing.xs, Spacing.sm,
                         "xs should be less than sm")
        XCTAssertLessThan(Spacing.sm, Spacing.md,
                         "sm should be less than md")
        XCTAssertLessThan(Spacing.md, Spacing.lg,
                         "md should be less than lg")
        XCTAssertLessThan(Spacing.lg, Spacing.xl,
                         "lg should be less than xl")
        XCTAssertLessThan(Spacing.xl, Spacing.xxl,
                         "xl should be less than xxl")
    }

    func testSpacing_valuesArePositive() {
        // All spacing values should be positive
        XCTAssertGreaterThan(Spacing.xs, 0, "xs should be positive")
        XCTAssertGreaterThan(Spacing.sm, 0, "sm should be positive")
        XCTAssertGreaterThan(Spacing.md, 0, "md should be positive")
        XCTAssertGreaterThan(Spacing.lg, 0, "lg should be positive")
        XCTAssertGreaterThan(Spacing.xl, 0, "xl should be positive")
        XCTAssertGreaterThan(Spacing.xxl, 0, "xxl should be positive")
    }

    func testSpacing_typesAreCGFloat() {
        // Verify all values are CGFloat for SwiftUI compatibility
        let xs: CGFloat = Spacing.xs
        let sm: CGFloat = Spacing.sm
        let md: CGFloat = Spacing.md
        let lg: CGFloat = Spacing.lg
        let xl: CGFloat = Spacing.xl
        let xxl: CGFloat = Spacing.xxl

        XCTAssertEqual(xs, 4)
        XCTAssertEqual(sm, 8)
        XCTAssertEqual(md, 12)
        XCTAssertEqual(lg, 16)
        XCTAssertEqual(xl, 24)
        XCTAssertEqual(xxl, 40)
    }

    func testSpacing_scaleRatios() {
        // Verify the spacing scale has reasonable ratios
        // Common spacing scales use multiples of 4 or 8
        XCTAssertEqual(Spacing.xs.truncatingRemainder(dividingBy: 4), 0,
                      "xs should be divisible by 4")
        XCTAssertEqual(Spacing.sm.truncatingRemainder(dividingBy: 4), 0,
                      "sm should be divisible by 4")
        XCTAssertEqual(Spacing.md.truncatingRemainder(dividingBy: 4), 0,
                      "md should be divisible by 4")
        XCTAssertEqual(Spacing.lg.truncatingRemainder(dividingBy: 4), 0,
                      "lg should be divisible by 4")
        XCTAssertEqual(Spacing.xl.truncatingRemainder(dividingBy: 4), 0,
                      "xl should be divisible by 4")
        XCTAssertEqual(Spacing.xxl.truncatingRemainder(dividingBy: 4), 0,
                      "xxl should be divisible by 4")
    }

    // MARK: - CornerRadius Tests

    func testCornerRadius_allOptionsExist() {
        // Verify all 5 radius options are defined
        XCTAssertNotNil(CornerRadius.small)
        XCTAssertNotNil(CornerRadius.medium)
        XCTAssertNotNil(CornerRadius.large)
        XCTAssertNotNil(CornerRadius.xl)
        XCTAssertNotNil(CornerRadius.pill)
    }

    func testCornerRadius_expectedValues() {
        // Verify expected corner radius values
        XCTAssertEqual(CornerRadius.small, 4, "small should be 4")
        XCTAssertEqual(CornerRadius.medium, 8, "medium should be 8")
        XCTAssertEqual(CornerRadius.large, 12, "large should be 12")
        XCTAssertEqual(CornerRadius.xl, 16, "xl should be 16")
        XCTAssertEqual(CornerRadius.pill, 9999, "pill should be 9999")
    }

    func testCornerRadius_scaleProgression() {
        // Verify progression: small < medium < large < xl < pill
        XCTAssertLessThan(CornerRadius.small, CornerRadius.medium,
                         "small should be less than medium")
        XCTAssertLessThan(CornerRadius.medium, CornerRadius.large,
                         "medium should be less than large")
        XCTAssertLessThan(CornerRadius.large, CornerRadius.xl,
                         "large should be less than xl")
        XCTAssertLessThan(CornerRadius.xl, CornerRadius.pill,
                         "xl should be less than pill")
    }

    func testCornerRadius_pillIsSignificantlyLarger() {
        // Pill should be significantly larger than xl for full rounding
        let pillToXlRatio = CornerRadius.pill / CornerRadius.xl
        XCTAssertGreaterThan(pillToXlRatio, 100,
                            "Pill should be at least 100x larger than xl for full rounding")
    }

    func testCornerRadius_valuesArePositive() {
        // All corner radius values should be positive
        XCTAssertGreaterThan(CornerRadius.small, 0, "small should be positive")
        XCTAssertGreaterThan(CornerRadius.medium, 0, "medium should be positive")
        XCTAssertGreaterThan(CornerRadius.large, 0, "large should be positive")
        XCTAssertGreaterThan(CornerRadius.xl, 0, "xl should be positive")
        XCTAssertGreaterThan(CornerRadius.pill, 0, "pill should be positive")
    }

    func testCornerRadius_typesAreCGFloat() {
        // Verify all values are CGFloat for SwiftUI compatibility
        let small: CGFloat = CornerRadius.small
        let medium: CGFloat = CornerRadius.medium
        let large: CGFloat = CornerRadius.large
        let xl: CGFloat = CornerRadius.xl
        let pill: CGFloat = CornerRadius.pill

        XCTAssertEqual(small, 4)
        XCTAssertEqual(medium, 8)
        XCTAssertEqual(large, 12)
        XCTAssertEqual(xl, 16)
        XCTAssertEqual(pill, 9999)
    }

    // MARK: - Shadows Tests

    func testShadows_allLevelsExist() {
        // Verify all shadow elevation levels are defined
        XCTAssertNotNil(Shadows.small)
        XCTAssertNotNil(Shadows.medium)
        XCTAssertNotNil(Shadows.large)
    }

    func testShadowStyle_hasRequiredProperties() {
        // Verify ShadowStyle has all required properties
        let shadow = Shadows.small
        XCTAssertNotNil(shadow.color)
        XCTAssertNotNil(shadow.radius)
        XCTAssertNotNil(shadow.x)
        XCTAssertNotNil(shadow.y)
    }

    func testShadows_smallProperties() {
        let shadow = Shadows.small
        XCTAssertEqual(shadow.radius, 4, "small shadow radius should be 4")
        XCTAssertEqual(shadow.x, 0, "small shadow x offset should be 0")
        XCTAssertEqual(shadow.y, 2, "small shadow y offset should be 2")
    }

    func testShadows_mediumProperties() {
        let shadow = Shadows.medium
        XCTAssertEqual(shadow.radius, 8, "medium shadow radius should be 8")
        XCTAssertEqual(shadow.x, 0, "medium shadow x offset should be 0")
        XCTAssertEqual(shadow.y, 4, "medium shadow y offset should be 4")
    }

    func testShadows_largeProperties() {
        let shadow = Shadows.large
        XCTAssertEqual(shadow.radius, 16, "large shadow radius should be 16")
        XCTAssertEqual(shadow.x, 0, "large shadow x offset should be 0")
        XCTAssertEqual(shadow.y, 8, "large shadow y offset should be 8")
    }

    func testShadows_radiusProgression() {
        // Verify radius progression: small < medium < large
        XCTAssertLessThan(Shadows.small.radius, Shadows.medium.radius,
                         "small radius should be less than medium")
        XCTAssertLessThan(Shadows.medium.radius, Shadows.large.radius,
                         "medium radius should be less than large")
    }

    func testShadows_yOffsetProgression() {
        // Verify y offset progression matches elevation
        XCTAssertLessThan(Shadows.small.y, Shadows.medium.y,
                         "small y offset should be less than medium")
        XCTAssertLessThan(Shadows.medium.y, Shadows.large.y,
                         "medium y offset should be less than large")
    }

    func testShadows_xOffsetIsZero() {
        // Shadows should have zero x offset (light from above)
        XCTAssertEqual(Shadows.small.x, 0, "small x offset should be 0")
        XCTAssertEqual(Shadows.medium.x, 0, "medium x offset should be 0")
        XCTAssertEqual(Shadows.large.x, 0, "large x offset should be 0")
    }

    func testShadows_radiusValuesArePositive() {
        XCTAssertGreaterThan(Shadows.small.radius, 0, "small radius should be positive")
        XCTAssertGreaterThan(Shadows.medium.radius, 0, "medium radius should be positive")
        XCTAssertGreaterThan(Shadows.large.radius, 0, "large radius should be positive")
    }

    func testShadows_yOffsetsArePositive() {
        // Positive y offset means shadow below element
        XCTAssertGreaterThan(Shadows.small.y, 0, "small y offset should be positive")
        XCTAssertGreaterThan(Shadows.medium.y, 0, "medium y offset should be positive")
        XCTAssertGreaterThan(Shadows.large.y, 0, "large y offset should be positive")
    }

    // MARK: - LiquidGlass Tests - GlassMaterial

    func testGlassMaterial_allCasesExist() {
        // Verify all 5 GlassMaterial cases exist
        let materials: [GlassMaterial] = [
            .ultraThin,
            .thin,
            .regular,
            .thick,
            .chrome
        ]
        XCTAssertEqual(materials.count, 5, "Should have 5 glass material options")
    }

    func testGlassMaterial_materialPropertyExists() {
        // Verify each material returns a valid Material
        XCTAssertNotNil(GlassMaterial.ultraThin.material)
        XCTAssertNotNil(GlassMaterial.thin.material)
        XCTAssertNotNil(GlassMaterial.regular.material)
        XCTAssertNotNil(GlassMaterial.thick.material)
        XCTAssertNotNil(GlassMaterial.chrome.material)
    }

    func testGlassMaterial_tintOpacityExists() {
        // Verify each material has tint opacity
        XCTAssertGreaterThanOrEqual(GlassMaterial.ultraThin.tintOpacity, 0)
        XCTAssertGreaterThanOrEqual(GlassMaterial.thin.tintOpacity, 0)
        XCTAssertGreaterThanOrEqual(GlassMaterial.regular.tintOpacity, 0)
        XCTAssertGreaterThanOrEqual(GlassMaterial.thick.tintOpacity, 0)
        XCTAssertGreaterThanOrEqual(GlassMaterial.chrome.tintOpacity, 0)
    }

    func testGlassMaterial_tintOpacityProgression() {
        // Tint opacity should generally increase with material density
        XCTAssertLessThan(GlassMaterial.ultraThin.tintOpacity, GlassMaterial.thin.tintOpacity,
                         "ultraThin tint should be less than thin")
        XCTAssertLessThan(GlassMaterial.thin.tintOpacity, GlassMaterial.regular.tintOpacity,
                         "thin tint should be less than regular")
        XCTAssertLessThan(GlassMaterial.regular.tintOpacity, GlassMaterial.thick.tintOpacity,
                         "regular tint should be less than thick")
        XCTAssertLessThan(GlassMaterial.thick.tintOpacity, GlassMaterial.chrome.tintOpacity,
                         "thick tint should be less than chrome")
    }

    func testGlassMaterial_shadowOpacityExists() {
        // Verify each material has shadow opacity
        XCTAssertGreaterThanOrEqual(GlassMaterial.ultraThin.shadowOpacity, 0)
        XCTAssertGreaterThanOrEqual(GlassMaterial.thin.shadowOpacity, 0)
        XCTAssertGreaterThanOrEqual(GlassMaterial.regular.shadowOpacity, 0)
        XCTAssertGreaterThanOrEqual(GlassMaterial.thick.shadowOpacity, 0)
        XCTAssertGreaterThanOrEqual(GlassMaterial.chrome.shadowOpacity, 0)
    }

    func testGlassMaterial_shadowOpacityProgression() {
        // Shadow opacity should generally increase with material density
        XCTAssertLessThan(GlassMaterial.ultraThin.shadowOpacity, GlassMaterial.thin.shadowOpacity,
                         "ultraThin shadow should be less than thin")
        XCTAssertLessThan(GlassMaterial.thin.shadowOpacity, GlassMaterial.regular.shadowOpacity,
                         "thin shadow should be less than regular")
        XCTAssertLessThan(GlassMaterial.regular.shadowOpacity, GlassMaterial.thick.shadowOpacity,
                         "regular shadow should be less than thick")
        XCTAssertLessThan(GlassMaterial.thick.shadowOpacity, GlassMaterial.chrome.shadowOpacity,
                         "thick shadow should be less than chrome")
    }

    func testGlassMaterial_opacityValuesInValidRange() {
        // All opacity values should be between 0 and 1
        let materials: [GlassMaterial] = [.ultraThin, .thin, .regular, .thick, .chrome]

        for material in materials {
            XCTAssertGreaterThanOrEqual(material.tintOpacity, 0,
                                       "\(material) tint opacity should be >= 0")
            XCTAssertLessThanOrEqual(material.tintOpacity, 1,
                                    "\(material) tint opacity should be <= 1")
            XCTAssertGreaterThanOrEqual(material.shadowOpacity, 0,
                                       "\(material) shadow opacity should be >= 0")
            XCTAssertLessThanOrEqual(material.shadowOpacity, 1,
                                    "\(material) shadow opacity should be <= 1")
        }
    }

    // MARK: - LiquidGlass Tests - GlassBorderStyle

    func testGlassBorderStyle_allCasesExist() {
        // Verify GlassBorderStyle cases exist
        let borderStyles: [GlassBorderStyle] = [
            .none,
            .subtle,
            .standard,
            .rainbow,
            .accent(.blue),
            .custom(Gradient(colors: [.red, .blue]))
        ]
        XCTAssertEqual(borderStyles.count, 6, "Should have 6 border style options")
    }

    func testGlassBorderStyle_noneCaseExists() {
        if case .none = GlassBorderStyle.none {
            // Success - none case exists
        } else {
            XCTFail("none case should exist")
        }
    }

    func testGlassBorderStyle_subtleCaseExists() {
        if case .subtle = GlassBorderStyle.subtle {
            // Success - subtle case exists
        } else {
            XCTFail("subtle case should exist")
        }
    }

    func testGlassBorderStyle_standardCaseExists() {
        if case .standard = GlassBorderStyle.standard {
            // Success - standard case exists
        } else {
            XCTFail("standard case should exist")
        }
    }

    func testGlassBorderStyle_rainbowCaseExists() {
        if case .rainbow = GlassBorderStyle.rainbow {
            // Success - rainbow case exists
        } else {
            XCTFail("rainbow case should exist")
        }
    }

    func testGlassBorderStyle_accentCaseWithColor() {
        let style = GlassBorderStyle.accent(.blue)
        if case .accent(let color) = style {
            XCTAssertEqual(color, .blue, "accent should store the provided color")
        } else {
            XCTFail("accent case should accept a Color")
        }
    }

    func testGlassBorderStyle_customCaseWithGradient() {
        let gradient = Gradient(colors: [.red, .green, .blue])
        let style = GlassBorderStyle.custom(gradient)
        if case .custom(_) = style {
            // Success - custom case accepts gradient
        } else {
            XCTFail("custom case should accept a Gradient")
        }
    }

    func testGlassBorderStyle_gradientReturnsValue() {
        // Verify gradient function returns valid gradients
        let styles: [GlassBorderStyle] = [.none, .subtle, .standard, .rainbow]

        for style in styles {
            let lightGradient = style.gradient(colorScheme: .light)
            let darkGradient = style.gradient(colorScheme: .dark)

            XCTAssertNotNil(lightGradient, "\(style) should return a gradient for light mode")
            XCTAssertNotNil(darkGradient, "\(style) should return a gradient for dark mode")
        }
    }

    func testGlassBorderStyle_noneReturnsEmptyGradient() {
        let gradient = GlassBorderStyle.none.gradient(colorScheme: .dark)
        // none should return a gradient with clear colors
        XCTAssertNotNil(gradient)
    }

    // MARK: - LiquidGlass Tests - View Modifier Creation

    func testLiquidGlassModifier_creation() {
        // Verify modifier can be created with default parameters
        let modifier = LiquidGlassModifier()
        XCTAssertNotNil(modifier)
    }

    func testLiquidGlassModifier_customParameters() {
        // Verify modifier accepts custom parameters
        let modifier = LiquidGlassModifier(
            material: .thick,
            cornerRadius: 20,
            borderStyle: .rainbow,
            borderWidth: 2,
            shadowRadius: 12,
            enableHover: false,
            enablePress: true
        )
        XCTAssertNotNil(modifier)
    }

    func testGlassCardModifier_creation() {
        // Verify card modifier can be created
        let modifier = GlassCardModifier(isSelected: false, accentColor: nil)
        XCTAssertNotNil(modifier)
    }

    func testGlassCardModifier_withSelection() {
        let modifier = GlassCardModifier(isSelected: true, accentColor: .orange)
        XCTAssertNotNil(modifier)
    }

    func testGlassPanelModifier_creation() {
        // Verify panel modifier can be created for all edges
        let edges: [Edge] = [.leading, .trailing, .top, .bottom]

        for edge in edges {
            let modifier = GlassPanelModifier(edge: edge)
            XCTAssertNotNil(modifier, "Panel modifier should be created for \(edge)")
        }
    }

    func testGlassButtonModifier_creation() {
        let modifier = GlassButtonModifier(isActive: false, style: .secondary)
        XCTAssertNotNil(modifier)
    }

    func testGlassButtonModifier_allStyles() {
        // Verify all button styles work
        let styles: [GlassButtonModifier.GlassButtonStyle] = [
            .primary, .secondary, .destructive, .ghost
        ]

        for style in styles {
            let modifier = GlassButtonModifier(isActive: true, style: style)
            XCTAssertNotNil(modifier, "Button modifier should be created for \(style)")
        }
    }

    func testGlassToolbarModifier_creation() {
        let modifier = GlassToolbarModifier()
        XCTAssertNotNil(modifier)
    }

    func testGlassSheetModifier_creation() {
        let modifier = GlassSheetModifier()
        XCTAssertNotNil(modifier)
    }

    func testGlassFloatingModifier_creation() {
        let modifier = GlassFloatingModifier()
        XCTAssertNotNil(modifier)
    }

    func testGlassFloatingModifier_withParameters() {
        let modifier = GlassFloatingModifier(isActive: true, pulseAnimation: true)
        XCTAssertNotNil(modifier)
    }

    func testLightRefractionModifier_creation() {
        let modifier = LightRefractionModifier()
        XCTAssertNotNil(modifier)
    }

    func testShimmerEffectModifier_creation() {
        let modifier = ShimmerEffectModifier()
        XCTAssertNotNil(modifier)
    }

    func testShimmerEffectModifier_withParameters() {
        let modifier = ShimmerEffectModifier(isAnimating: true, color: .blue)
        XCTAssertNotNil(modifier)
    }

    func testGlowEffectModifier_creation() {
        let modifier = GlowEffectModifier()
        XCTAssertNotNil(modifier)
    }

    func testGlowEffectModifier_withParameters() {
        let modifier = GlowEffectModifier(color: .purple, radius: 15, isActive: false)
        XCTAssertNotNil(modifier)
    }

    // MARK: - LiquidGlass Tests - View Extensions

    func testViewExtension_liquidGlass() {
        // Verify the liquidGlass view extension can be applied
        let view = Text("Test").liquidGlass()
        XCTAssertNotNil(view)
    }

    func testViewExtension_liquidGlassWithParameters() {
        let view = Text("Test").liquidGlass(
            material: .thick,
            cornerRadius: 20,
            borderStyle: .rainbow,
            enableHover: false,
            enablePress: true
        )
        XCTAssertNotNil(view)
    }

    func testViewExtension_glassCard() {
        let view = Text("Test").glassCard()
        XCTAssertNotNil(view)
    }

    func testViewExtension_glassCardWithParameters() {
        let view = Text("Test").glassCard(isSelected: true, accentColor: .red)
        XCTAssertNotNil(view)
    }

    func testViewExtension_glassPanel() {
        let view = Text("Test").glassPanel(edge: .trailing)
        XCTAssertNotNil(view)
    }

    func testViewExtension_glassButton() {
        let view = Text("Test").glassButton()
        XCTAssertNotNil(view)
    }

    func testViewExtension_glassButtonWithParameters() {
        let view = Text("Test").glassButton(isActive: true, style: .primary)
        XCTAssertNotNil(view)
    }

    func testViewExtension_glassToolbar() {
        let view = Text("Test").glassToolbar()
        XCTAssertNotNil(view)
    }

    func testViewExtension_glassSheet() {
        let view = Text("Test").glassSheet()
        XCTAssertNotNil(view)
    }

    func testViewExtension_glassFloating() {
        let view = Text("Test").glassFloating()
        XCTAssertNotNil(view)
    }

    func testViewExtension_glassFloatingWithParameters() {
        let view = Text("Test").glassFloating(isActive: true, pulseAnimation: true)
        XCTAssertNotNil(view)
    }

    func testViewExtension_lightRefraction() {
        let view = Text("Test").lightRefraction()
        XCTAssertNotNil(view)
    }

    func testViewExtension_shimmerEffect() {
        let view = Text("Test").shimmerEffect()
        XCTAssertNotNil(view)
    }

    func testViewExtension_shimmerEffectWithParameters() {
        let view = Text("Test").shimmerEffect(isAnimating: false, color: .yellow)
        XCTAssertNotNil(view)
    }

    func testViewExtension_glowEffect() {
        let view = Text("Test").glowEffect()
        XCTAssertNotNil(view)
    }

    func testViewExtension_glowEffectWithParameters() {
        let view = Text("Test").glowEffect(color: .green, radius: 20, isActive: false)
        XCTAssertNotNil(view)
    }

    // MARK: - Integration Tests

    func testDesignSystem_spacingUsedInCornerRadius() {
        // Spacing and CornerRadius should use compatible values
        // small spacing (4) matches small radius (4)
        XCTAssertEqual(Spacing.xs, CornerRadius.small,
                      "xs spacing should match small corner radius")
        // sm spacing (8) matches medium radius (8)
        XCTAssertEqual(Spacing.sm, CornerRadius.medium,
                      "sm spacing should match medium corner radius")
    }

    func testDesignSystem_shadowRadiusUsesEvenValues() {
        // Shadow radii should be even numbers for crisp rendering
        XCTAssertEqual(Shadows.small.radius.truncatingRemainder(dividingBy: 2), 0,
                      "small shadow radius should be even")
        XCTAssertEqual(Shadows.medium.radius.truncatingRemainder(dividingBy: 2), 0,
                      "medium shadow radius should be even")
        XCTAssertEqual(Shadows.large.radius.truncatingRemainder(dividingBy: 2), 0,
                      "large shadow radius should be even")
    }

    func testDesignSystem_cornerRadiusUsesMultiplesOf4() {
        // Corner radii (except pill) should be multiples of 4
        XCTAssertEqual(CornerRadius.small.truncatingRemainder(dividingBy: 4), 0,
                      "small radius should be multiple of 4")
        XCTAssertEqual(CornerRadius.medium.truncatingRemainder(dividingBy: 4), 0,
                      "medium radius should be multiple of 4")
        XCTAssertEqual(CornerRadius.large.truncatingRemainder(dividingBy: 4), 0,
                      "large radius should be multiple of 4")
        XCTAssertEqual(CornerRadius.xl.truncatingRemainder(dividingBy: 4), 0,
                      "xl radius should be multiple of 4")
    }

    // MARK: - Shadow View Extension Test

    func testShadowViewExtension() {
        // Verify the shadow view extension can be applied
        let view = Text("Test").shadow(Shadows.medium)
        XCTAssertNotNil(view)
    }

    func testShadowViewExtension_allLevels() {
        let smallShadow = Text("Test").shadow(Shadows.small)
        let mediumShadow = Text("Test").shadow(Shadows.medium)
        let largeShadow = Text("Test").shadow(Shadows.large)

        XCTAssertNotNil(smallShadow)
        XCTAssertNotNil(mediumShadow)
        XCTAssertNotNil(largeShadow)
    }

    // MARK: - Accessibility Considerations

    func testGlassMaterial_hasSufficientContrast() {
        // Chrome material should have highest opacity for best contrast
        let maxOpacity = [
            GlassMaterial.ultraThin.tintOpacity,
            GlassMaterial.thin.tintOpacity,
            GlassMaterial.regular.tintOpacity,
            GlassMaterial.thick.tintOpacity,
            GlassMaterial.chrome.tintOpacity
        ].max()!

        XCTAssertEqual(maxOpacity, GlassMaterial.chrome.tintOpacity,
                      "chrome should have highest tint opacity for best contrast")
    }

    func testGlassMaterial_ultraThinIsSubtle() {
        // ultraThin should be very subtle for background use
        XCTAssertLessThan(GlassMaterial.ultraThin.tintOpacity, 0.1,
                         "ultraThin tint should be very subtle")
        XCTAssertLessThan(GlassMaterial.ultraThin.shadowOpacity, 0.1,
                         "ultraThin shadow should be very subtle")
    }
}
