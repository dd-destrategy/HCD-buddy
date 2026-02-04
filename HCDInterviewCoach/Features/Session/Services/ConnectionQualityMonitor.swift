//
//  ConnectionQualityMonitor.swift
//  HCD Interview Coach
//
//  EPIC E4: Session Manager
//  Monitors and tracks connection quality for the realtime API
//

import Foundation
import Combine
import Network

// MARK: - Connection Quality

/// Represents the current quality level of the API connection
enum ConnectionQuality: Int, Comparable, Sendable {
    case excellent = 4
    case good = 3
    case fair = 2
    case poor = 1
    case disconnected = 0

    static func < (lhs: ConnectionQuality, rhs: ConnectionQuality) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Human-readable description
    var displayName: String {
        switch self {
        case .excellent:
            return "Excellent"
        case .good:
            return "Good"
        case .fair:
            return "Fair"
        case .poor:
            return "Poor"
        case .disconnected:
            return "Disconnected"
        }
    }

    /// Whether this quality level is acceptable for recording
    var isAcceptable: Bool {
        self >= .fair
    }

    /// Suggested action based on quality
    var suggestion: String? {
        switch self {
        case .excellent, .good:
            return nil
        case .fair:
            return "Connection quality is reduced. Some transcription delays may occur."
        case .poor:
            return "Connection quality is poor. Consider pausing until connection improves."
        case .disconnected:
            return "Connection lost. Attempting to reconnect..."
        }
    }
}

// MARK: - Connection Quality Monitor

/// Monitors network conditions and API connection quality
@MainActor
final class ConnectionQualityMonitor: ObservableObject {
    // MARK: - Published Properties

    /// Current connection quality level
    @Published private(set) var quality: ConnectionQuality = .disconnected

    /// Current network path status
    @Published var isNetworkAvailable: Bool = false

    /// Whether monitoring is active
    @Published private(set) var isMonitoring: Bool = false

    /// Current latency measurement in milliseconds
    @Published private(set) var latencyMs: Int = 0

    /// Recent quality history for trend analysis
    @Published private(set) var qualityHistory: [QualityMeasurement] = []

    // MARK: - Private Properties

    private let pathMonitor: NWPathMonitor
    private let monitorQueue: DispatchQueue
    private var latencyMeasurements: [LatencyMeasurement] = []
    private var errorCount: Int = 0
    private var successCount: Int = 0
    private var cancellables = Set<AnyCancellable>()

    // Configuration
    private let historyLimit = 60 // Keep last 60 measurements
    private let latencyWindowSize = 10 // Use last 10 latency samples

    // Quality thresholds (in milliseconds)
    private let excellentLatencyThreshold = 100
    private let goodLatencyThreshold = 250
    private let fairLatencyThreshold = 500
    private let poorLatencyThreshold = 1000

    // Error rate thresholds
    private let excellentErrorRate = 0.01
    private let goodErrorRate = 0.05
    private let fairErrorRate = 0.10
    private let poorErrorRate = 0.25

    // MARK: - Initialization

    init() {
        self.pathMonitor = NWPathMonitor()
        self.monitorQueue = DispatchQueue(label: "com.hcdinterviewcoach.connectionmonitor")
        setupPathMonitor()
    }

    deinit {
        pathMonitor.cancel()
    }

    // MARK: - Public Methods

    /// Starts monitoring connection quality
    func start() {
        guard !isMonitoring else { return }
        isMonitoring = true
        pathMonitor.start(queue: monitorQueue)
        AppLogger.shared.info("ConnectionQualityMonitor started")
    }

    /// Stops monitoring connection quality
    func stop() {
        guard isMonitoring else { return }
        isMonitoring = false
        pathMonitor.cancel()
        reset()
        AppLogger.shared.info("ConnectionQualityMonitor stopped")
    }

    /// Records a successful API response with latency
    /// - Parameter latencyMs: Round-trip latency in milliseconds
    func recordSuccess(latencyMs: Int) {
        successCount += 1

        let measurement = LatencyMeasurement(
            latencyMs: latencyMs,
            timestamp: Date(),
            wasSuccess: true
        )
        latencyMeasurements.append(measurement)

        // Keep only recent measurements
        if latencyMeasurements.count > latencyWindowSize {
            latencyMeasurements.removeFirst()
        }

        updateQuality()
    }

    /// Records a failed API request
    /// - Parameter error: The error that occurred
    func recordError(_ error: Error? = nil) {
        errorCount += 1

        let measurement = LatencyMeasurement(
            latencyMs: 0,
            timestamp: Date(),
            wasSuccess: false
        )
        latencyMeasurements.append(measurement)

        // Keep only recent measurements
        if latencyMeasurements.count > latencyWindowSize {
            latencyMeasurements.removeFirst()
        }

        updateQuality()

        if let error = error {
            AppLogger.shared.logAPI("Connection error recorded: \(error.localizedDescription)", level: .warning)
        }
    }

    /// Records that connection was lost
    func recordDisconnection() {
        quality = .disconnected
        addQualityToHistory(.disconnected)
        AppLogger.shared.logAPI("Connection disconnection recorded", level: .warning)
    }

    /// Records that connection was restored
    func recordReconnection() {
        // Reset error counts on reconnection
        errorCount = max(0, errorCount - 2)
        updateQuality()
        AppLogger.shared.logAPI("Connection reconnection recorded", level: .info)
    }

    /// Resets all measurements
    func reset() {
        latencyMeasurements.removeAll()
        qualityHistory.removeAll()
        errorCount = 0
        successCount = 0
        latencyMs = 0
        quality = isNetworkAvailable ? .good : .disconnected
    }

    /// Gets quality statistics for the session
    func getStatistics() -> ConnectionStatistics {
        let totalRequests = successCount + errorCount
        let errorRate = totalRequests > 0 ? Double(errorCount) / Double(totalRequests) : 0

        return ConnectionStatistics(
            averageLatencyMs: calculateAverageLatency(),
            errorRate: errorRate,
            successCount: successCount,
            errorCount: errorCount,
            currentQuality: quality,
            qualityHistory: qualityHistory
        )
    }

    // MARK: - Private Methods

    private func setupPathMonitor() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.handlePathUpdate(path)
            }
        }
    }

    private func handlePathUpdate(_ path: NWPath) {
        let wasAvailable = isNetworkAvailable
        isNetworkAvailable = path.status == .satisfied

        if !wasAvailable && isNetworkAvailable {
            // Network became available
            AppLogger.shared.logAPI("Network became available", level: .info)
            if quality == .disconnected {
                quality = .fair // Start with fair until we get measurements
            }
        } else if wasAvailable && !isNetworkAvailable {
            // Network became unavailable
            AppLogger.shared.logAPI("Network became unavailable", level: .warning)
            recordDisconnection()
        }

        // Check connection type for quality hints
        if path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet) {
            // Wired or WiFi is typically better
            if quality < .fair && isNetworkAvailable {
                quality = .fair
            }
        } else if path.usesInterfaceType(.cellular) {
            // Cellular might be less reliable
            if quality > .good {
                quality = .good
            }
        }
    }

    private func updateQuality() {
        guard isNetworkAvailable else {
            quality = .disconnected
            return
        }

        // Calculate metrics
        let avgLatency = calculateAverageLatency()
        let errorRate = calculateRecentErrorRate()

        // Determine quality based on latency and error rate
        let latencyQuality = qualityFromLatency(avgLatency)
        let errorQuality = qualityFromErrorRate(errorRate)

        // Use the worse of the two
        let newQuality = min(latencyQuality, errorQuality)

        if quality != newQuality {
            quality = newQuality
            addQualityToHistory(newQuality)
        }

        latencyMs = avgLatency
    }

    private func calculateAverageLatency() -> Int {
        let successfulMeasurements = latencyMeasurements.filter { $0.wasSuccess }
        guard !successfulMeasurements.isEmpty else { return 0 }

        let totalLatency = successfulMeasurements.reduce(0) { $0 + $1.latencyMs }
        return totalLatency / successfulMeasurements.count
    }

    private func calculateRecentErrorRate() -> Double {
        guard !latencyMeasurements.isEmpty else { return 0 }
        let failures = latencyMeasurements.filter { !$0.wasSuccess }.count
        return Double(failures) / Double(latencyMeasurements.count)
    }

    private func qualityFromLatency(_ latencyMs: Int) -> ConnectionQuality {
        if latencyMs <= excellentLatencyThreshold {
            return .excellent
        } else if latencyMs <= goodLatencyThreshold {
            return .good
        } else if latencyMs <= fairLatencyThreshold {
            return .fair
        } else if latencyMs <= poorLatencyThreshold {
            return .poor
        } else {
            return .disconnected
        }
    }

    private func qualityFromErrorRate(_ rate: Double) -> ConnectionQuality {
        if rate <= excellentErrorRate {
            return .excellent
        } else if rate <= goodErrorRate {
            return .good
        } else if rate <= fairErrorRate {
            return .fair
        } else if rate <= poorErrorRate {
            return .poor
        } else {
            return .disconnected
        }
    }

    private func addQualityToHistory(_ quality: ConnectionQuality) {
        let measurement = QualityMeasurement(
            quality: quality,
            timestamp: Date()
        )
        qualityHistory.append(measurement)

        // Trim history
        if qualityHistory.count > historyLimit {
            qualityHistory.removeFirst()
        }
    }
}

// MARK: - Supporting Types

/// A single latency measurement
private struct LatencyMeasurement {
    let latencyMs: Int
    let timestamp: Date
    let wasSuccess: Bool
}

/// A quality measurement for history
struct QualityMeasurement: Identifiable, Sendable {
    let id = UUID()
    let quality: ConnectionQuality
    let timestamp: Date
}

/// Statistics about connection quality during a session
struct ConnectionStatistics: Sendable {
    let averageLatencyMs: Int
    let errorRate: Double
    let successCount: Int
    let errorCount: Int
    let currentQuality: ConnectionQuality
    let qualityHistory: [QualityMeasurement]

    /// Percentage of time with acceptable quality
    var acceptableQualityPercentage: Double {
        guard !qualityHistory.isEmpty else { return 100 }
        let acceptable = qualityHistory.filter { $0.quality.isAcceptable }.count
        return Double(acceptable) / Double(qualityHistory.count) * 100
    }

    /// Formatted average latency string
    var formattedLatency: String {
        "\(averageLatencyMs)ms"
    }

    /// Formatted error rate string
    var formattedErrorRate: String {
        String(format: "%.1f%%", errorRate * 100)
    }
}
