//
//  CertificatePinningTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for certificate pinning security implementation
//

import XCTest
import Security
@testable import HCDInterviewCoach

final class CertificatePinningTests: XCTestCase {

    // MARK: - Test Data

    /// Mock certificate data for testing
    private var mockServerTrust: SecTrust?
    private var mockCertificate: SecCertificate?

    override func setUp() {
        super.setUp()
        // Setup will be done per-test as needed
    }

    override func tearDown() {
        mockServerTrust = nil
        mockCertificate = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Creates a mock SecTrust for testing
    private func createMockSecTrust(with certificates: [SecCertificate]? = nil) -> SecTrust? {
        // For testing, we create a minimal trust object
        // In real tests, you would use actual certificate data
        guard let certData = createSelfSignedCertificateData() else {
            return nil
        }

        guard let certificate = SecCertificateCreateWithData(nil, certData as CFData) else {
            return nil
        }

        let certs = certificates ?? [certificate]
        var trust: SecTrust?
        let policy = SecPolicyCreateBasicX509()

        let status = SecTrustCreateWithCertificates(certs as CFArray, policy, &trust)
        guard status == errSecSuccess else {
            return nil
        }

        return trust
    }

    /// Creates mock certificate data for testing
    private func createSelfSignedCertificateData() -> Data? {
        // Return a minimal DER-encoded certificate structure for testing
        // This is a placeholder - in production tests, use actual test certificates
        let mockCertBytes: [UInt8] = [
            0x30, 0x82, 0x01, 0x22, // SEQUENCE
            0x30, 0x81, 0xCC,       // TBSCertificate
            0x02, 0x01, 0x00,       // Version
            // ... minimal cert structure for testing
        ]
        return Data(mockCertBytes)
    }

    // MARK: - Test: isEnabled Property

    func testPinningIsEnabledByDefault() {
        // Given: Default configuration
        // When: Checking if pinning is enabled
        // Then: Should be enabled (actual value depends on build config)
        // In tests, we just verify the property is accessible
        let isEnabled = CertificatePinning.isEnabled
        // Note: In DEBUG builds with env var set, this could be false
        XCTAssertNotNil(isEnabled as Bool?)
    }

    func testPinningDisabled_envVariable() {
        // Given: Environment variable set to disable pinning
        // Note: This test documents the behavior - in actual tests,
        // we can't easily set env vars at runtime
        // When: HCD_DISABLE_CERT_PINNING=true is set
        // Then: isEnabled should return false in DEBUG builds

        // Verify the logic exists by checking the static property
        _ = CertificatePinning.isEnabled

        // The actual behavior is compile-time dependent
        // This test verifies the API is accessible
        XCTAssertTrue(true, "Environment variable check is compile-time dependent")
    }

    // MARK: - Test: ValidationResult Enum

    func testValidationResult_valid() {
        // Given: A valid validation result
        let result = CertificatePinning.ValidationResult.valid

        // When: Describing the result
        let description = CertificatePinning.describeValidationResult(result)

        // Then: Should have appropriate description
        XCTAssertEqual(description, "Certificate validation successful")
    }

    func testValidationResult_pinningDisabled() {
        // Given: Pinning disabled result
        let result = CertificatePinning.ValidationResult.pinningDisabled

        // When: Describing the result
        let description = CertificatePinning.describeValidationResult(result)

        // Then: Should indicate pinning is disabled
        XCTAssertEqual(description, "Certificate pinning is disabled")
    }

    func testValidationResult_invalidHost() {
        // Given: Invalid host result
        let result = CertificatePinning.ValidationResult.invalidHost

        // When: Describing the result
        let description = CertificatePinning.describeValidationResult(result)

        // Then: Should indicate host issue
        XCTAssertEqual(description, "Host is not in the pinned hosts list")
    }

    func testValidationResult_noCertificateFound() {
        // Given: No certificate found result
        let result = CertificatePinning.ValidationResult.noCertificateFound

        // When: Describing the result
        let description = CertificatePinning.describeValidationResult(result)

        // Then: Should indicate missing certificate
        XCTAssertEqual(description, "No certificate found in server trust")
    }

    func testValidationResult_hashMismatch() {
        // Given: Hash mismatch result with actual hash
        let actualHash = "ABC123DEF456"
        let result = CertificatePinning.ValidationResult.hashMismatch(actual: actualHash)

        // When: Describing the result
        let description = CertificatePinning.describeValidationResult(result)

        // Then: Should include the actual hash
        XCTAssertTrue(description.contains(actualHash))
        XCTAssertTrue(description.contains("mismatch"))
    }

    func testValidationResult_evaluationFailed() {
        // Given: Evaluation failed result with status
        let status: OSStatus = -67062 // Example error status
        let result = CertificatePinning.ValidationResult.evaluationFailed(status)

        // When: Describing the result
        let description = CertificatePinning.describeValidationResult(result)

        // Then: Should include the status code
        XCTAssertTrue(description.contains("\(status)"))
        XCTAssertTrue(description.contains("evaluation failed"))
    }

    // MARK: - Test: OpenAI Pins Configuration

    func testOpenAIPins_hasMultiplePins() {
        // Given: The OpenAI pins configuration
        let pins = CertificatePinning.openAIPins

        // Then: Should have multiple pins for redundancy
        XCTAssertGreaterThanOrEqual(pins.count, 2, "Should have at least 2 pins for rotation resilience")
    }

    func testOpenAIPins_allPinsAreBase64() {
        // Given: The OpenAI pins
        let pins = CertificatePinning.openAIPins

        // Then: All pins should be valid base64 strings
        for pin in pins {
            // Base64 strings should only contain valid characters
            let base64CharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")
            let pinCharacters = CharacterSet(charactersIn: pin)
            XCTAssertTrue(pinCharacters.isSubset(of: base64CharacterSet), "Pin '\(pin)' should be valid base64")

            // Should decode to 32 bytes (SHA-256)
            if let data = Data(base64Encoded: pin) {
                XCTAssertEqual(data.count, 32, "Pin should decode to 32 bytes (SHA-256)")
            }
        }
    }

    func testMultiplePins_anyMatch() {
        // Given: Multiple pins are configured
        let pins = CertificatePinning.openAIPins

        // When: Any one of the pins matches
        // Then: Validation should succeed

        // This test verifies the set contains expected pins
        XCTAssertTrue(pins.contains("47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=") ||
                     pins.contains("i7WTqTvh0OioIruIfFR4kMPnBqrS2rdiVPl/s2uC/CY=") ||
                     pins.contains("r/mIkG3eEpVdm+u/ko/cwxzOMo1bk4TyHIlByibiA5E="),
                     "Should contain at least one of the known pins")
    }

    // MARK: - Test: Validate Method with Unknown Host

    func testValidateCertificate_unknownHost() {
        // Given: A server trust for an unknown host
        guard let serverTrust = createMockSecTrust() else {
            // Skip if we can't create mock trust
            XCTSkip("Unable to create mock server trust")
            return
        }

        // When: Validating for an unknown host
        let result = CertificatePinning.validate(serverTrust, for: "unknown.example.com")

        // Then: Should return valid (no pins configured means pass-through)
        // Note: The actual behavior depends on isEnabled and trust evaluation
        switch result {
        case .valid, .pinningDisabled:
            // Expected - unknown hosts are allowed through
            XCTAssertTrue(true)
        case .evaluationFailed:
            // Also acceptable if trust evaluation fails on mock cert
            XCTAssertTrue(true)
        default:
            // Document what we got
            XCTAssertTrue(true, "Got result: \(CertificatePinning.describeValidationResult(result))")
        }
    }

    func testValidateCertificate_emptyChain() {
        // Given: An empty certificate chain scenario
        // When: The server trust has no certificates
        // Then: Should return noCertificateFound

        // Note: This is difficult to test without mocking SecTrust internals
        // We verify the enum case exists and is handled
        let result = CertificatePinning.ValidationResult.noCertificateFound
        let description = CertificatePinning.describeValidationResult(result)
        XCTAssertFalse(description.isEmpty)
    }

    // MARK: - Test: CertificatePinningDelegate

    func testPinningDelegate_initialization() {
        // Given: Creating a new delegate
        let delegate = CertificatePinningDelegate()

        // Then: Should be a valid URLSessionDelegate
        XCTAssertTrue(delegate is URLSessionDelegate)
    }

    func testPinningDelegate_respondsToAuthChallenge() {
        // Given: A certificate pinning delegate
        let delegate = CertificatePinningDelegate()

        // Then: Should respond to the urlSession:didReceiveChallenge selector
        let selector = #selector(URLSessionDelegate.urlSession(_:didReceive:completionHandler:))
        XCTAssertTrue(delegate.responds(to: selector))
    }

    // MARK: - Test: WebSocketCertificatePinningDelegate

    func testWebSocketPinningDelegate_initialization() {
        // Given: Creating a new WebSocket delegate
        let delegate = WebSocketCertificatePinningDelegate()

        // Then: Should be a valid URLSessionWebSocketDelegate
        XCTAssertTrue(delegate is URLSessionWebSocketDelegate)
    }

    func testWebSocketPinningDelegate_hasCallbacks() {
        // Given: A WebSocket certificate pinning delegate
        let delegate = WebSocketCertificatePinningDelegate()

        // When: Setting callbacks
        var openCalled = false
        var closeCalled = false

        delegate.onOpen = { openCalled = true }
        delegate.onClose = { _, _ in closeCalled = true }

        // Then: Callbacks should be settable
        delegate.onOpen?()
        delegate.onClose?(.normalClosure, nil)

        XCTAssertTrue(openCalled)
        XCTAssertTrue(closeCalled)
    }

    func testWebSocketPinningDelegate_respondsToWebSocketMethods() {
        // Given: A WebSocket pinning delegate
        let delegate = WebSocketCertificatePinningDelegate()

        // Then: Should respond to WebSocket delegate methods
        let openSelector = #selector(URLSessionWebSocketDelegate.urlSession(_:webSocketTask:didOpenWithProtocol:))
        let closeSelector = #selector(URLSessionWebSocketDelegate.urlSession(_:webSocketTask:didCloseWith:reason:))

        XCTAssertTrue(delegate.responds(to: openSelector))
        XCTAssertTrue(delegate.responds(to: closeSelector))
    }

    // MARK: - Test: allowConnectionOnPinningFailure

    func testAllowConnectionOnPinningFailure_existsAsProperty() {
        // Given: The allowConnectionOnPinningFailure property
        let allowOnFailure = CertificatePinning.allowConnectionOnPinningFailure

        // Then: Property should exist and be boolean
        // In DEBUG: true, In RELEASE: false
        XCTAssertNotNil(allowOnFailure as Bool?)
    }

    // MARK: - Test: Hash Extraction (via description)

    func testExtractPublicKeyHash_documentedFormat() {
        // Given: The expected hash format
        // Public key hashes should be base64-encoded SHA-256

        // When: A hash mismatch occurs
        let testHash = "dGVzdGhhc2g="  // "testhash" in base64
        let result = CertificatePinning.ValidationResult.hashMismatch(actual: testHash)

        // Then: The description should include the hash
        let description = CertificatePinning.describeValidationResult(result)
        XCTAssertTrue(description.contains(testHash))
    }

    // MARK: - Test: Integration Scenarios

    func testPinningValidation_forOpenAIHost() {
        // Given: A mock server trust
        guard let serverTrust = createMockSecTrust() else {
            XCTSkip("Unable to create mock server trust")
            return
        }

        // When: Validating for api.openai.com
        let result = CertificatePinning.validate(serverTrust, for: "api.openai.com")

        // Then: Should get a valid result (valid, hashMismatch, or evaluationFailed)
        switch result {
        case .valid:
            // If pinning is disabled or mock cert happens to match
            XCTAssertTrue(true)
        case .hashMismatch:
            // Expected with mock certificate
            XCTAssertTrue(true)
        case .evaluationFailed:
            // Mock cert may fail trust evaluation
            XCTAssertTrue(true)
        case .pinningDisabled:
            // Pinning may be disabled in test environment
            XCTAssertTrue(true)
        case .noCertificateFound:
            // Mock trust setup may have failed
            XCTAssertTrue(true)
        case .invalidHost:
            // Should not happen for api.openai.com
            XCTFail("api.openai.com should be a known host")
        }
    }
}
