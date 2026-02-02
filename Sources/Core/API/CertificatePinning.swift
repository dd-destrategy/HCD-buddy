//
//  CertificatePinning.swift
//  HCD Interview Coach
//
//  Certificate pinning for OpenAI API connections to protect against MITM attacks.
//
//  IMPORTANT: Certificate Pin Rotation
//  -----------------------------------
//  OpenAI may rotate their TLS certificates periodically. When this happens:
//  1. The app will log warnings about pinning failures
//  2. In DEBUG builds, connections will still proceed with a warning
//  3. In RELEASE builds, connections will fail
//
//  To update the pins:
//  1. Run: openssl s_client -connect api.openai.com:443 -servername api.openai.com < /dev/null 2>/dev/null | openssl x509 -pubkey -noout | openssl pkey -pubin -outform DER | openssl dgst -sha256 -binary | base64
//  2. Update the `openAIPins` set below with the new hash
//  3. Keep the old hash as a backup during transition periods
//

import Foundation
import CommonCrypto

/// Certificate pinning configuration and validation for API connections
enum CertificatePinning {

    // MARK: - Configuration

    /// Pinned hosts and their expected certificate hashes
    /// Key: hostname, Value: Set of valid SHA-256 public key hashes
    private static let pinnedHosts: [String: Set<String>] = [
        "api.openai.com": openAIPins
    ]

    /// SHA-256 public key hashes for api.openai.com
    /// These are the SPKI (Subject Public Key Info) hashes
    ///
    /// To generate these hashes, run:
    /// ```
    /// openssl s_client -connect api.openai.com:443 -servername api.openai.com < /dev/null 2>/dev/null | \
    ///   openssl x509 -pubkey -noout | openssl pkey -pubin -outform DER | \
    ///   openssl dgst -sha256 -binary | base64
    /// ```
    ///
    /// Include multiple pins for certificate rotation resilience:
    /// - Current production certificate
    /// - Backup/intermediate certificates
    /// - Root CA certificates (more stable, less secure)
    static let openAIPins: Set<String> = [
        // OpenAI's current certificate public key hash (example - replace with actual)
        // These should be obtained by running the openssl command above against api.openai.com
        "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=",
        // Backup pin - DigiCert Global Root G2 (OpenAI's typical CA chain)
        "i7WTqTvh0OioIruIfFR4kMPnBqrS2rdiVPl/s2uC/CY=",
        // Additional backup - DigiCert Global Root CA
        "r/mIkG3eEpVdm+u/ko/cwxzOMo1bk4TyHIlByibiA5E="
    ]

    /// Whether certificate pinning is enabled
    /// In DEBUG mode, can be disabled via environment variable for testing
    static var isEnabled: Bool {
        #if DEBUG
        // Allow disabling in debug builds for testing with proxies like Charles
        if ProcessInfo.processInfo.environment["HCD_DISABLE_CERT_PINNING"] == "true" {
            return false
        }
        #endif
        return true
    }

    /// Whether to allow connections when pinning fails (DEBUG only)
    static var allowConnectionOnPinningFailure: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    // MARK: - Validation

    /// Result of certificate validation
    enum ValidationResult {
        case valid
        case pinningDisabled
        case invalidHost
        case noCertificateFound
        case hashMismatch(actual: String)
        case evaluationFailed(OSStatus)
    }

    /// Validates server trust against pinned certificates
    /// - Parameters:
    ///   - serverTrust: The server's trust object from the authentication challenge
    ///   - host: The hostname being connected to
    /// - Returns: ValidationResult indicating success or the type of failure
    static func validate(_ serverTrust: SecTrust, for host: String) -> ValidationResult {
        // Check if pinning is enabled
        guard isEnabled else {
            return .pinningDisabled
        }

        // Check if we have pins for this host
        guard let expectedPins = pinnedHosts[host] else {
            // No pins configured for this host, allow connection
            return .valid
        }

        // Evaluate the server trust
        var error: CFError?
        let evaluationSucceeded = SecTrustEvaluateWithError(serverTrust, &error)

        guard evaluationSucceeded else {
            let status = error.map { CFErrorGetCode($0) } ?? -1
            return .evaluationFailed(OSStatus(status))
        }

        // Get the certificate chain
        guard let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
              !certificateChain.isEmpty else {
            return .noCertificateFound
        }

        // Check each certificate in the chain against our pins
        for certificate in certificateChain {
            if let publicKeyHash = extractPublicKeyHash(from: certificate) {
                if expectedPins.contains(publicKeyHash) {
                    return .valid
                }
            }
        }

        // No matching pin found - get the leaf certificate hash for logging
        let leafHash = certificateChain.first.flatMap { extractPublicKeyHash(from: $0) } ?? "unknown"
        return .hashMismatch(actual: leafHash)
    }

    /// Extracts the SHA-256 hash of the public key from a certificate
    /// - Parameter certificate: The certificate to extract the public key from
    /// - Returns: Base64-encoded SHA-256 hash of the public key, or nil if extraction fails
    private static func extractPublicKeyHash(from certificate: SecCertificate) -> String? {
        // Get the public key from the certificate
        guard let publicKey = SecCertificateCopyKey(certificate) else {
            return nil
        }

        // Get the external representation of the public key
        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            return nil
        }

        // Calculate SHA-256 hash
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        publicKeyData.withUnsafeBytes { bytes in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(publicKeyData.count), &hash)
        }

        // Return base64-encoded hash
        return Data(hash).base64EncodedString()
    }

    // MARK: - Logging Helpers

    /// Returns a human-readable description of the validation result
    static func describeValidationResult(_ result: ValidationResult) -> String {
        switch result {
        case .valid:
            return "Certificate validation successful"
        case .pinningDisabled:
            return "Certificate pinning is disabled"
        case .invalidHost:
            return "Host is not in the pinned hosts list"
        case .noCertificateFound:
            return "No certificate found in server trust"
        case .hashMismatch(let actual):
            return "Certificate hash mismatch. Actual hash: \(actual)"
        case .evaluationFailed(let status):
            return "Trust evaluation failed with status: \(status)"
        }
    }
}

// MARK: - URLSessionDelegate for Certificate Pinning

/// URLSession delegate that implements certificate pinning
final class CertificatePinningDelegate: NSObject, URLSessionDelegate {

    /// Logger for certificate pinning events
    private let logger = AppLogger.shared

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Only handle server trust challenges
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host
        let result = CertificatePinning.validate(serverTrust, for: host)

        switch result {
        case .valid:
            logger.logAPI("Certificate pinning validation successful for \(host)", level: .debug)
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)

        case .pinningDisabled:
            logger.logAPI("Certificate pinning disabled, allowing connection to \(host)", level: .warning)
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)

        case .hashMismatch(let actualHash):
            logger.logAPI(
                "Certificate pinning FAILED for \(host): hash mismatch. " +
                "Actual: \(actualHash). This may indicate a MITM attack or certificate rotation.",
                level: .error
            )

            if CertificatePinning.allowConnectionOnPinningFailure {
                logger.logAPI(
                    "DEBUG BUILD: Allowing connection despite pinning failure. " +
                    "Update certificate pins if this persists.",
                    level: .warning
                )
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                logger.logAPI("RELEASE BUILD: Rejecting connection due to pinning failure", level: .critical)
                completionHandler(.cancelAuthenticationChallenge, nil)
            }

        case .noCertificateFound:
            logger.logAPI("Certificate pinning FAILED for \(host): no certificate in chain", level: .error)
            if CertificatePinning.allowConnectionOnPinningFailure {
                completionHandler(.performDefaultHandling, nil)
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }

        case .evaluationFailed(let status):
            logger.logAPI(
                "Certificate trust evaluation failed for \(host) with status: \(status)",
                level: .error
            )
            completionHandler(.cancelAuthenticationChallenge, nil)

        case .invalidHost:
            // Host not in pinned list, use default handling
            logger.logAPI("Host \(host) not in pinned hosts, using default validation", level: .debug)
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - URLSessionWebSocketDelegate for Certificate Pinning

/// URLSession delegate for WebSocket connections with certificate pinning
final class WebSocketCertificatePinningDelegate: NSObject, URLSessionWebSocketDelegate {

    /// Logger for certificate pinning events
    private let logger = AppLogger.shared

    /// Callback for when WebSocket connection opens
    var onOpen: (() -> Void)?

    /// Callback for when WebSocket connection closes
    var onClose: ((URLSessionWebSocketTask.CloseCode, Data?) -> Void)?

    // MARK: - URLSessionDelegate

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Only handle server trust challenges
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host
        let result = CertificatePinning.validate(serverTrust, for: host)

        switch result {
        case .valid:
            logger.logAPI("WebSocket certificate pinning validation successful for \(host)", level: .debug)
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)

        case .pinningDisabled:
            logger.logAPI("Certificate pinning disabled for WebSocket to \(host)", level: .warning)
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)

        case .hashMismatch(let actualHash):
            logger.logAPI(
                "WebSocket certificate pinning FAILED for \(host): hash mismatch. " +
                "Actual: \(actualHash). Possible MITM attack or certificate rotation.",
                level: .error
            )

            if CertificatePinning.allowConnectionOnPinningFailure {
                logger.logAPI(
                    "DEBUG BUILD: Allowing WebSocket connection despite pinning failure",
                    level: .warning
                )
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                logger.logAPI("RELEASE BUILD: Rejecting WebSocket connection", level: .critical)
                completionHandler(.cancelAuthenticationChallenge, nil)
            }

        case .noCertificateFound, .evaluationFailed:
            logger.logAPI(
                "WebSocket certificate validation failed for \(host): \(CertificatePinning.describeValidationResult(result))",
                level: .error
            )
            if CertificatePinning.allowConnectionOnPinningFailure {
                completionHandler(.performDefaultHandling, nil)
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }

        case .invalidHost:
            logger.logAPI("WebSocket host \(host) not in pinned hosts", level: .debug)
            completionHandler(.performDefaultHandling, nil)
        }
    }

    // MARK: - URLSessionWebSocketDelegate

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        logger.logAPI("WebSocket connection opened", level: .info)
        onOpen?()
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        logger.logAPI("WebSocket connection closed with code: \(closeCode.rawValue)", level: .info)
        onClose?(closeCode, reason)
    }
}
