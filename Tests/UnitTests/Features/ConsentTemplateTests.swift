//
//  ConsentTemplateTests.swift
//  HCD Interview Coach Tests
//
//  FEATURE H: Accessible Consent System
//  Unit tests for ConsentLanguage, ConsentPermission, and ConsentTemplate.
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class ConsentTemplateTests: XCTestCase {

    // MARK: - ConsentLanguage Tests

    func testConsentLanguage_allCases_hasExpectedCount() {
        XCTAssertEqual(ConsentLanguage.allCases.count, 6)
    }

    func testConsentLanguage_displayNames_areNonEmpty() {
        for language in ConsentLanguage.allCases {
            XCTAssertFalse(language.displayName.isEmpty, "\(language.rawValue) should have a displayName")
        }
    }

    func testConsentLanguage_nativeNames_areNonEmpty() {
        for language in ConsentLanguage.allCases {
            XCTAssertFalse(language.nativeName.isEmpty, "\(language.rawValue) should have a nativeName")
        }
    }

    func testConsentLanguage_icons_areNonEmpty() {
        for language in ConsentLanguage.allCases {
            XCTAssertFalse(language.icon.isEmpty, "\(language.rawValue) should have an icon")
        }
    }

    func testConsentLanguage_displayNames_areEnglishNames() {
        XCTAssertEqual(ConsentLanguage.english.displayName, "English")
        XCTAssertEqual(ConsentLanguage.spanish.displayName, "Spanish")
        XCTAssertEqual(ConsentLanguage.french.displayName, "French")
        XCTAssertEqual(ConsentLanguage.german.displayName, "German")
        XCTAssertEqual(ConsentLanguage.japanese.displayName, "Japanese")
        XCTAssertEqual(ConsentLanguage.chinese.displayName, "Chinese")
    }

    func testConsentLanguage_nativeNames_areCorrect() {
        XCTAssertEqual(ConsentLanguage.english.nativeName, "English")
        XCTAssertEqual(ConsentLanguage.spanish.nativeName, "Espa\u{00F1}ol")
        XCTAssertEqual(ConsentLanguage.french.nativeName, "Fran\u{00E7}ais")
        XCTAssertEqual(ConsentLanguage.german.nativeName, "Deutsch")
    }

    func testConsentLanguage_rawValues_areISO639() {
        XCTAssertEqual(ConsentLanguage.english.rawValue, "en")
        XCTAssertEqual(ConsentLanguage.spanish.rawValue, "es")
        XCTAssertEqual(ConsentLanguage.french.rawValue, "fr")
        XCTAssertEqual(ConsentLanguage.german.rawValue, "de")
        XCTAssertEqual(ConsentLanguage.japanese.rawValue, "ja")
        XCTAssertEqual(ConsentLanguage.chinese.rawValue, "zh")
    }

    // MARK: - ConsentPermission Tests

    func testConsentPermission_init_defaultIsAcceptedIsFalse() {
        let permission = ConsentPermission(
            title: "Test",
            description: "Test description",
            icon: "mic.fill",
            isRequired: true
        )
        XCTAssertFalse(permission.isAccepted)
    }

    func testConsentPermission_init_setsAllProperties() {
        let id = UUID()
        let permission = ConsentPermission(
            id: id,
            title: "Record",
            description: "We record the talk.",
            icon: "mic.fill",
            isRequired: true,
            isAccepted: true
        )
        XCTAssertEqual(permission.id, id)
        XCTAssertEqual(permission.title, "Record")
        XCTAssertEqual(permission.description, "We record the talk.")
        XCTAssertEqual(permission.icon, "mic.fill")
        XCTAssertTrue(permission.isRequired)
        XCTAssertTrue(permission.isAccepted)
    }

    func testConsentPermission_equatable_sameId() {
        let id = UUID()
        let perm1 = ConsentPermission(id: id, title: "A", description: "A", icon: "mic.fill", isRequired: true)
        let perm2 = ConsentPermission(id: id, title: "A", description: "A", icon: "mic.fill", isRequired: true)
        XCTAssertEqual(perm1, perm2)
    }

    func testConsentPermission_codable_roundTrip() throws {
        let original = ConsentPermission(
            title: "Record Our Talk",
            description: "We will record what we say.",
            icon: "mic.fill",
            isRequired: true,
            isAccepted: true
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ConsentPermission.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.icon, original.icon)
        XCTAssertEqual(decoded.isRequired, original.isRequired)
        XCTAssertEqual(decoded.isAccepted, original.isAccepted)
    }

    // MARK: - ConsentTemplate Default English Tests

    func testDefaultEnglish_hasFivePermissions() {
        let template = ConsentTemplate.defaultEnglish()
        XCTAssertEqual(template.permissionCount, 5)
    }

    func testDefaultEnglish_versionIs1_0_0() {
        let template = ConsentTemplate.defaultEnglish()
        XCTAssertEqual(template.version, "1.0.0")
    }

    func testDefaultEnglish_languageIsEnglish() {
        let template = ConsentTemplate.defaultEnglish()
        XCTAssertEqual(template.language, .english)
    }

    func testDefaultEnglish_isDefault() {
        let template = ConsentTemplate.defaultEnglish()
        XCTAssertTrue(template.isDefault)
    }

    func testDefaultEnglish_hasThreeRequiredPermissions() {
        let template = ConsentTemplate.defaultEnglish()
        let requiredCount = template.permissions.filter { $0.isRequired }.count
        XCTAssertEqual(requiredCount, 3)
    }

    func testDefaultEnglish_hasTwoOptionalPermissions() {
        let template = ConsentTemplate.defaultEnglish()
        let optionalCount = template.permissions.filter { !$0.isRequired }.count
        XCTAssertEqual(optionalCount, 2)
    }

    func testDefaultEnglish_introIsSimpleLanguage() {
        let template = ConsentTemplate.defaultEnglish()
        // 5th-grade reading level: short sentences, common words, no jargon
        let intro = template.introductionText
        XCTAssertFalse(intro.isEmpty)
        // Check for the absence of complex/jargon words
        let complexWords = ["hereafter", "pursuant", "notwithstanding", "aforementioned", "herein"]
        for word in complexWords {
            XCTAssertFalse(intro.lowercased().contains(word), "Introduction should not contain complex word: \(word)")
        }
        // Check sentences are short (average under 20 words per sentence)
        let sentences = intro.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let totalWords = sentences.reduce(0) { $0 + $1.components(separatedBy: .whitespaces).count }
        let avgWordsPerSentence = sentences.isEmpty ? 0 : Double(totalWords) / Double(sentences.count)
        XCTAssertLessThanOrEqual(avgWordsPerSentence, 20.0, "Average sentence length should be 20 words or fewer for 5th-grade reading level")
    }

    // MARK: - ConsentTemplate Default Spanish Tests

    func testDefaultSpanish_hasFivePermissions() {
        let template = ConsentTemplate.defaultSpanish()
        XCTAssertEqual(template.permissionCount, 5)
    }

    func testDefaultSpanish_languageIsSpanish() {
        let template = ConsentTemplate.defaultSpanish()
        XCTAssertEqual(template.language, .spanish)
    }

    // MARK: - ConsentTemplate Default French Tests

    func testDefaultFrench_hasFivePermissions() {
        let template = ConsentTemplate.defaultFrench()
        XCTAssertEqual(template.permissionCount, 5)
    }

    func testDefaultFrench_languageIsFrench() {
        let template = ConsentTemplate.defaultFrench()
        XCTAssertEqual(template.language, .french)
    }

    // MARK: - allRequiredAccepted Tests

    func testAllRequiredAccepted_allRequiredAccepted_returnsTrue() {
        var template = ConsentTemplate.defaultEnglish()
        // Accept all required permissions
        for index in template.permissions.indices where template.permissions[index].isRequired {
            template.permissions[index].isAccepted = true
        }
        XCTAssertTrue(template.allRequiredAccepted)
    }

    func testAllRequiredAccepted_someRequiredNotAccepted_returnsFalse() {
        var template = ConsentTemplate.defaultEnglish()
        // Accept only the first required permission
        let firstRequiredIndex = template.permissions.firstIndex(where: { $0.isRequired })
        if let index = firstRequiredIndex {
            template.permissions[index].isAccepted = true
        }
        // Leave other required ones unaccepted
        XCTAssertFalse(template.allRequiredAccepted)
    }

    func testAllRequiredAccepted_optionalNotAccepted_butRequiredAccepted_returnsTrue() {
        var template = ConsentTemplate.defaultEnglish()
        // Accept all required, leave optional unaccepted
        for index in template.permissions.indices {
            template.permissions[index].isAccepted = template.permissions[index].isRequired
        }
        XCTAssertTrue(template.allRequiredAccepted)
    }

    func testAllRequiredAccepted_noPermissionsAccepted_returnsFalse() {
        let template = ConsentTemplate.defaultEnglish()
        // None accepted by default
        XCTAssertFalse(template.allRequiredAccepted)
    }

    // MARK: - permissionCount and acceptedCount Tests

    func testPermissionCount_returnsCorrectCount() {
        let template = ConsentTemplate.defaultEnglish()
        XCTAssertEqual(template.permissionCount, 5)
    }

    func testAcceptedCount_noneAccepted_returnsZero() {
        let template = ConsentTemplate.defaultEnglish()
        XCTAssertEqual(template.acceptedCount, 0)
    }

    func testAcceptedCount_someAccepted_returnsCorrectCount() {
        var template = ConsentTemplate.defaultEnglish()
        template.permissions[0].isAccepted = true
        template.permissions[1].isAccepted = true
        XCTAssertEqual(template.acceptedCount, 2)
    }

    func testAcceptedCount_allAccepted_returnsTotal() {
        var template = ConsentTemplate.defaultEnglish()
        for index in template.permissions.indices {
            template.permissions[index].isAccepted = true
        }
        XCTAssertEqual(template.acceptedCount, template.permissionCount)
    }

    // MARK: - ConsentTemplate Codable Tests

    func testConsentTemplate_codable_roundTrip() throws {
        var original = ConsentTemplate.defaultEnglish()
        original.permissions[0].isAccepted = true
        original.permissions[2].isAccepted = true

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ConsentTemplate.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.version, original.version)
        XCTAssertEqual(decoded.language, original.language)
        XCTAssertEqual(decoded.introductionText, original.introductionText)
        XCTAssertEqual(decoded.permissions.count, original.permissions.count)
        XCTAssertEqual(decoded.closingText, original.closingText)
        XCTAssertEqual(decoded.isDefault, original.isDefault)
        XCTAssertTrue(decoded.permissions[0].isAccepted)
        XCTAssertFalse(decoded.permissions[1].isAccepted)
        XCTAssertTrue(decoded.permissions[2].isAccepted)
    }

    // MARK: - ConsentTemplate Equatable Tests

    func testConsentTemplate_equatable_sameId_equal() {
        let id = UUID()
        let template1 = ConsentTemplate(
            id: id,
            name: "Template A",
            introductionText: "Hello",
            permissions: [],
            closingText: "Bye"
        )
        let template2 = ConsentTemplate(
            id: id,
            name: "Template A",
            introductionText: "Hello",
            permissions: [],
            closingText: "Bye"
        )
        XCTAssertEqual(template1, template2)
    }

    func testConsentTemplate_equatable_differentId_notEqual() {
        let template1 = ConsentTemplate(
            name: "Template A",
            introductionText: "Hello",
            permissions: [],
            closingText: "Bye"
        )
        let template2 = ConsentTemplate(
            name: "Template A",
            introductionText: "Hello",
            permissions: [],
            closingText: "Bye"
        )
        XCTAssertNotEqual(template1, template2)
    }

    // MARK: - Cross-Language Consistency Tests

    func testAllDefaultTemplates_haveSamePermissionCount() {
        let english = ConsentTemplate.defaultEnglish()
        let spanish = ConsentTemplate.defaultSpanish()
        let french = ConsentTemplate.defaultFrench()

        XCTAssertEqual(english.permissionCount, spanish.permissionCount)
        XCTAssertEqual(english.permissionCount, french.permissionCount)
    }

    func testAllDefaultTemplates_haveSameRequiredFlags() {
        let english = ConsentTemplate.defaultEnglish()
        let spanish = ConsentTemplate.defaultSpanish()
        let french = ConsentTemplate.defaultFrench()

        for i in 0..<english.permissionCount {
            XCTAssertEqual(
                english.permissions[i].isRequired,
                spanish.permissions[i].isRequired,
                "Permission at index \(i) should have the same isRequired flag in English and Spanish"
            )
            XCTAssertEqual(
                english.permissions[i].isRequired,
                french.permissions[i].isRequired,
                "Permission at index \(i) should have the same isRequired flag in English and French"
            )
        }
    }

    func testAllDefaultTemplates_haveSameIcons() {
        let english = ConsentTemplate.defaultEnglish()
        let spanish = ConsentTemplate.defaultSpanish()
        let french = ConsentTemplate.defaultFrench()

        for i in 0..<english.permissionCount {
            XCTAssertEqual(
                english.permissions[i].icon,
                spanish.permissions[i].icon,
                "Permission at index \(i) should have the same icon in English and Spanish"
            )
            XCTAssertEqual(
                english.permissions[i].icon,
                french.permissions[i].icon,
                "Permission at index \(i) should have the same icon in English and French"
            )
        }
    }
}
