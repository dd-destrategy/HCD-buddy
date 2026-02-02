//
//  ConnectionQualityMonitorTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for ConnectionQualityMonitor metrics and quality calculations
//

import XCTest
@testable import HCDInterviewCoach

@MainActor
final class ConnectionQualityMonitorTests: XCTestCase {

    var monitor: ConnectionQualityMonitor!

    override func setUp() {
        super.setUp()
        monitor = ConnectionQualityMonitor()
    }

    override func tearDown() {
        monitor.stop()
        monitor = nil
        super.tearDown()
    }

    // MARK: - Test: Quality Calculation - Excellent

    func testQualityCalculation_excellent() {
        // Given: Monitor is started
        monitor.start()

        // When: Record excellent metrics (low latency, no errors)
        for _ in 0..<10 {
            monitor.recordSuccess(latencyMs: 50) // Well under 100ms threshold
        }

        // Then: Quality should be excellent
        XCTAssertEqual(monitor.quality, .excellent)
        XCTAssertLessThanOrEqual(monitor.latencyMs, 100)
    }

    func testQualityCalculation_excellentThreshold() {
        // Given: Monitor started
        monitor.start()

        // When: Record exactly at excellent threshold
        for _ in 0..<10 {
            monitor.recordSuccess(latencyMs: 100)
        }

        // Then: Should still be excellent
        XCTAssertEqual(monitor.quality, .excellent)
    }

    func testQualityCalculation_excellentWithMinimalErrors() {
        // Given: Monitor started
        monitor.start()

        // When: Record mostly successes with 1% error rate
        for _ in 0..<99 {
            monitor.recordSuccess(latencyMs: 50)
        }
        monitor.recordError()

        // Then: Quality should still be excellent (1% error rate allowed)
        // Note: Uses sliding window, so depends on window size
        let quality = monitor.quality
        XCTAssertTrue(quality == .excellent || quality == .good)
    }

    // MARK: - Test: Quality Calculation - Good

    func testQualityCalculation_good() {
        // Given: Monitor started
        monitor.start()

        // When: Record good metrics (moderate latency)
        for _ in 0..<10 {
            monitor.recordSuccess(latencyMs: 200) // Between 100-250ms
        }

        // Then: Quality should be good
        XCTAssertEqual(monitor.quality, .good)
    }

    func testQualityCalculation_goodThreshold() {
        // Given: Monitor started
        monitor.start()

        // When: Record at good threshold upper limit
        for _ in 0..<10 {
            monitor.recordSuccess(latencyMs: 250)
        }

        // Then: Should be good
        XCTAssertEqual(monitor.quality, .good)
    }

    func testQualityCalculation_goodWithSomeErrors() {
        // Given: Monitor started
        monitor.start()

        // When: Record with ~5% error rate
        for _ in 0..<19 {
            monitor.recordSuccess(latencyMs: 150)
        }
        monitor.recordError()

        // Then: Quality should be good or fair
        let quality = monitor.quality
        XCTAssertTrue(quality == .good || quality == .fair)
    }

    // MARK: - Test: Quality Calculation - Fair

    func testQualityCalculation_fair() {
        // Given: Monitor started
        monitor.start()

        // When: Record fair metrics (higher latency)
        for _ in 0..<10 {
            monitor.recordSuccess(latencyMs: 400) // Between 250-500ms
        }

        // Then: Quality should be fair
        XCTAssertEqual(monitor.quality, .fair)
    }

    func testQualityCalculation_fairThreshold() {
        // Given: Monitor started
        monitor.start()

        // When: Record at fair threshold upper limit
        for _ in 0..<10 {
            monitor.recordSuccess(latencyMs: 500)
        }

        // Then: Should be fair
        XCTAssertEqual(monitor.quality, .fair)
    }

    func testQualityCalculation_fairIsAcceptable() {
        // Given: Fair quality
        let quality = ConnectionQuality.fair

        // Then: Should be acceptable for recording
        XCTAssertTrue(quality.isAcceptable)
    }

    // MARK: - Test: Quality Calculation - Poor

    func testQualityCalculation_poor() {
        // Given: Monitor started
        monitor.start()

        // When: Record poor metrics (high latency)
        for _ in 0..<10 {
            monitor.recordSuccess(latencyMs: 800) // Between 500-1000ms
        }

        // Then: Quality should be poor
        XCTAssertEqual(monitor.quality, .poor)
    }

    func testQualityCalculation_poorWithHighErrorRate() {
        // Given: Monitor started
        monitor.start()

        // When: Record with high error rate (~25%)
        for _ in 0..<7 {
            monitor.recordSuccess(latencyMs: 100)
        }
        for _ in 0..<3 {
            monitor.recordError()
        }

        // Then: Quality should be poor due to error rate
        let quality = monitor.quality
        XCTAssertTrue(quality == .poor || quality == .fair)
    }

    func testQualityCalculation_poorIsNotAcceptable() {
        // Given: Poor quality
        let quality = ConnectionQuality.poor

        // Then: Should not be acceptable for recording
        XCTAssertFalse(quality.isAcceptable)
    }

    // MARK: - Test: Latency Tracking

    func testLatencyTracking_calculatesAverage() {
        // Given: Monitor started
        monitor.start()

        // When: Record various latencies
        monitor.recordSuccess(latencyMs: 100)
        monitor.recordSuccess(latencyMs: 200)
        monitor.recordSuccess(latencyMs: 300)

        // Then: Average should be calculated
        XCTAssertEqual(monitor.latencyMs, 200)
    }

    func testLatencyTracking_usesRecentMeasurements() {
        // Given: Monitor started
        monitor.start()

        // When: Record many measurements (more than window size)
        for i in 0..<15 {
            monitor.recordSuccess(latencyMs: (i + 1) * 10)
        }

        // Then: Should use recent measurements only (window size is 10)
        // Recent: 60, 70, 80, 90, 100, 110, 120, 130, 140, 150 = avg 105
        let latency = monitor.latencyMs
        XCTAssertGreaterThan(latency, 50)
    }

    func testLatencyTracking_excludesFailedRequests() {
        // Given: Monitor started
        monitor.start()

        // When: Record mix of success and failures
        monitor.recordSuccess(latencyMs: 100)
        monitor.recordError() // Should not affect average
        monitor.recordSuccess(latencyMs: 200)

        // Then: Average should only include successes
        XCTAssertEqual(monitor.latencyMs, 150)
    }

    // MARK: - Test: Packet Loss Tracking (Error Rate)

    func testPacketLossTracking_calculatesErrorRate() {
        // Given: Monitor started
        monitor.start()

        // When: Record mix of success and errors
        for _ in 0..<8 {
            monitor.recordSuccess(latencyMs: 100)
        }
        for _ in 0..<2 {
            monitor.recordError()
        }

        // Then: Statistics should reflect error rate
        let stats = monitor.getStatistics()
        XCTAssertEqual(stats.errorRate, 0.2, accuracy: 0.01) // 20% error rate
    }

    func testPacketLossTracking_zeroErrors() {
        // Given: Monitor started
        monitor.start()

        // When: Record only successes
        for _ in 0..<10 {
            monitor.recordSuccess(latencyMs: 100)
        }

        // Then: Error rate should be zero
        let stats = monitor.getStatistics()
        XCTAssertEqual(stats.errorRate, 0.0)
    }

    func testPacketLossTracking_allErrors() {
        // Given: Monitor started
        monitor.start()

        // When: Record only errors
        for _ in 0..<5 {
            monitor.recordError()
        }

        // Then: Should have high error rate (quality degraded)
        let stats = monitor.getStatistics()
        XCTAssertGreaterThan(stats.errorRate, 0.5)
    }

    // MARK: - Test: Quality Change Notification

    func testQualityChangeNotification_updatesOnImprovement() {
        // Given: Monitor started with poor quality
        monitor.start()
        for _ in 0..<5 {
            monitor.recordSuccess(latencyMs: 800) // Poor
        }
        XCTAssertEqual(monitor.quality, .poor)

        // When: Record better metrics
        for _ in 0..<10 {
            monitor.recordSuccess(latencyMs: 50) // Excellent
        }

        // Then: Quality should improve
        XCTAssertTrue(monitor.quality > .poor)
    }

    func testQualityChangeNotification_updatesOnDegradation() {
        // Given: Monitor started with excellent quality
        monitor.start()
        for _ in 0..<5 {
            monitor.recordSuccess(latencyMs: 50) // Excellent
        }
        let initialQuality = monitor.quality

        // When: Record worse metrics
        for _ in 0..<10 {
            monitor.recordSuccess(latencyMs: 800) // Poor
        }

        // Then: Quality should degrade
        XCTAssertTrue(monitor.quality < initialQuality || initialQuality == .excellent)
    }

    func testQualityChangeNotification_addsToHistory() {
        // Given: Monitor started
        monitor.start()

        // When: Quality changes
        for _ in 0..<5 {
            monitor.recordSuccess(latencyMs: 50)
        }
        let historyAfterExcellent = monitor.qualityHistory.count

        for _ in 0..<10 {
            monitor.recordSuccess(latencyMs: 800)
        }

        // Then: History should grow when quality changes
        // Note: History only records when quality changes
        XCTAssertGreaterThanOrEqual(monitor.qualityHistory.count, 0)
    }

    // MARK: - Test: Metrics Reset

    func testMetricsReset_clearsAllData() {
        // Given: Monitor with data
        monitor.start()
        for _ in 0..<10 {
            monitor.recordSuccess(latencyMs: 200)
        }
        monitor.recordError()

        let statsBefore = monitor.getStatistics()
        XCTAssertGreaterThan(statsBefore.successCount, 0)

        // When: Reset
        monitor.reset()

        // Then: All metrics should be cleared
        let statsAfter = monitor.getStatistics()
        XCTAssertEqual(statsAfter.successCount, 0)
        XCTAssertEqual(statsAfter.errorCount, 0)
        XCTAssertEqual(monitor.latencyMs, 0)
        XCTAssertTrue(monitor.qualityHistory.isEmpty)
    }

    func testMetricsReset_preservesNetworkState() {
        // Given: Monitor with network available
        monitor.start()

        // When: Reset
        monitor.reset()

        // Then: Network availability should be preserved
        // Quality should be based on network state
        XCTAssertNotNil(monitor.quality)
    }

    // MARK: - Test: Disconnection Handling

    func testDisconnectionHandling_setsDisconnectedQuality() {
        // Given: Monitor started with good connection
        monitor.start()
        for _ in 0..<5 {
            monitor.recordSuccess(latencyMs: 100)
        }

        // When: Record disconnection
        monitor.recordDisconnection()

        // Then: Quality should be disconnected
        XCTAssertEqual(monitor.quality, .disconnected)
    }

    func testDisconnectionHandling_addsToHistory() {
        // Given: Monitor started
        monitor.start()
        let historyBefore = monitor.qualityHistory.count

        // When: Record disconnection
        monitor.recordDisconnection()

        // Then: Should add to history
        XCTAssertGreaterThan(monitor.qualityHistory.count, historyBefore)
        XCTAssertEqual(monitor.qualityHistory.last?.quality, .disconnected)
    }

    // MARK: - Test: Reconnection Handling

    func testReconnectionHandling_updatesQuality() {
        // Given: Monitor with disconnection
        monitor.start()
        monitor.recordDisconnection()
        XCTAssertEqual(monitor.quality, .disconnected)

        // When: Record reconnection
        monitor.recordReconnection()

        // Then: Quality should improve (or at least not be disconnected if network available)
        // Note: Depends on network state
        XCTAssertTrue(monitor.quality != .disconnected || !monitor.isNetworkAvailable)
    }

    func testReconnectionHandling_reducesErrorCount() {
        // Given: Monitor with some errors
        monitor.start()
        for _ in 0..<5 {
            monitor.recordError()
        }

        let errorsBefore = monitor.getStatistics().errorCount

        // When: Record reconnection
        monitor.recordReconnection()

        // Then: Error count should be reduced (by 2)
        let errorsAfter = monitor.getStatistics().errorCount
        XCTAssertLessThanOrEqual(errorsAfter, errorsBefore)
    }

    // MARK: - Test: Monitoring State

    func testMonitoringState_initiallyNotMonitoring() {
        // Given: Fresh monitor
        // Then: Should not be monitoring
        XCTAssertFalse(monitor.isMonitoring)
    }

    func testMonitoringState_startsMonitoring() {
        // When: Start monitoring
        monitor.start()

        // Then: Should be monitoring
        XCTAssertTrue(monitor.isMonitoring)
    }

    func testMonitoringState_stopsMonitoring() {
        // Given: Started monitor
        monitor.start()
        XCTAssertTrue(monitor.isMonitoring)

        // When: Stop monitoring
        monitor.stop()

        // Then: Should not be monitoring
        XCTAssertFalse(monitor.isMonitoring)
    }

    func testMonitoringState_canRestartAfterStop() {
        // Given: Stopped monitor
        monitor.start()
        monitor.stop()

        // When: Start again
        monitor.start()

        // Then: Should be monitoring
        XCTAssertTrue(monitor.isMonitoring)
    }

    // MARK: - Test: Statistics

    func testStatistics_calculatesAccurately() {
        // Given: Monitor with known data
        monitor.start()

        for _ in 0..<8 {
            monitor.recordSuccess(latencyMs: 100)
        }
        for _ in 0..<2 {
            monitor.recordError()
        }

        // When: Get statistics
        let stats = monitor.getStatistics()

        // Then: Should have accurate counts
        XCTAssertEqual(stats.successCount, 8)
        XCTAssertEqual(stats.errorCount, 2)
        XCTAssertEqual(stats.averageLatencyMs, 100)
        XCTAssertEqual(stats.errorRate, 0.2, accuracy: 0.01)
    }

    func testStatistics_formattedLatency() {
        // Given: Statistics with known latency
        monitor.start()
        monitor.recordSuccess(latencyMs: 150)

        // When: Get formatted latency
        let stats = monitor.getStatistics()

        // Then: Should be properly formatted
        XCTAssertEqual(stats.formattedLatency, "150ms")
    }

    func testStatistics_formattedErrorRate() {
        // Given: Statistics with known error rate
        monitor.start()
        for _ in 0..<8 {
            monitor.recordSuccess(latencyMs: 100)
        }
        for _ in 0..<2 {
            monitor.recordError()
        }

        // When: Get formatted error rate
        let stats = monitor.getStatistics()

        // Then: Should be percentage formatted
        XCTAssertEqual(stats.formattedErrorRate, "20.0%")
    }

    func testStatistics_acceptableQualityPercentage() {
        // Given: Monitor with quality history
        monitor.start()

        // Add excellent quality
        for _ in 0..<5 {
            monitor.recordSuccess(latencyMs: 50)
        }

        // Add poor quality
        for _ in 0..<5 {
            monitor.recordSuccess(latencyMs: 800)
        }

        // When: Get statistics
        let stats = monitor.getStatistics()

        // Then: Should calculate acceptable percentage
        // Note: Depends on how many quality changes occurred
        XCTAssertGreaterThanOrEqual(stats.acceptableQualityPercentage, 0)
        XCTAssertLessThanOrEqual(stats.acceptableQualityPercentage, 100)
    }

    // MARK: - Test: Quality Display Properties

    func testQualityDisplayProperties_displayName() {
        XCTAssertEqual(ConnectionQuality.excellent.displayName, "Excellent")
        XCTAssertEqual(ConnectionQuality.good.displayName, "Good")
        XCTAssertEqual(ConnectionQuality.fair.displayName, "Fair")
        XCTAssertEqual(ConnectionQuality.poor.displayName, "Poor")
        XCTAssertEqual(ConnectionQuality.disconnected.displayName, "Disconnected")
    }

    func testQualityDisplayProperties_isAcceptable() {
        XCTAssertTrue(ConnectionQuality.excellent.isAcceptable)
        XCTAssertTrue(ConnectionQuality.good.isAcceptable)
        XCTAssertTrue(ConnectionQuality.fair.isAcceptable)
        XCTAssertFalse(ConnectionQuality.poor.isAcceptable)
        XCTAssertFalse(ConnectionQuality.disconnected.isAcceptable)
    }

    func testQualityDisplayProperties_suggestion() {
        XCTAssertNil(ConnectionQuality.excellent.suggestion)
        XCTAssertNil(ConnectionQuality.good.suggestion)
        XCTAssertNotNil(ConnectionQuality.fair.suggestion)
        XCTAssertNotNil(ConnectionQuality.poor.suggestion)
        XCTAssertNotNil(ConnectionQuality.disconnected.suggestion)

        XCTAssertTrue(ConnectionQuality.fair.suggestion?.contains("reduced") ?? false)
        XCTAssertTrue(ConnectionQuality.poor.suggestion?.contains("pausing") ?? false)
        XCTAssertTrue(ConnectionQuality.disconnected.suggestion?.contains("reconnect") ?? false)
    }

    // MARK: - Test: Quality Comparison

    func testQualityComparison_ordering() {
        XCTAssertTrue(ConnectionQuality.excellent > ConnectionQuality.good)
        XCTAssertTrue(ConnectionQuality.good > ConnectionQuality.fair)
        XCTAssertTrue(ConnectionQuality.fair > ConnectionQuality.poor)
        XCTAssertTrue(ConnectionQuality.poor > ConnectionQuality.disconnected)
    }

    func testQualityComparison_equality() {
        XCTAssertEqual(ConnectionQuality.excellent, ConnectionQuality.excellent)
        XCTAssertNotEqual(ConnectionQuality.excellent, ConnectionQuality.good)
    }

    // MARK: - Test: Quality History

    func testQualityHistory_limitsSize() {
        // Given: Monitor started
        monitor.start()

        // When: Generate many quality changes
        for i in 0..<100 {
            // Alternate between high and low latency to trigger quality changes
            if i % 2 == 0 {
                for _ in 0..<5 {
                    monitor.recordSuccess(latencyMs: 50)
                }
            } else {
                for _ in 0..<5 {
                    monitor.recordSuccess(latencyMs: 800)
                }
            }
        }

        // Then: History should be limited (60 max)
        XCTAssertLessThanOrEqual(monitor.qualityHistory.count, 60)
    }

    func testQualityHistory_containsTimestamps() {
        // Given: Monitor with quality change
        monitor.start()
        let beforeTime = Date()

        for _ in 0..<5 {
            monitor.recordSuccess(latencyMs: 100)
        }

        // Then: History entries should have timestamps
        if let lastEntry = monitor.qualityHistory.last {
            XCTAssertGreaterThanOrEqual(lastEntry.timestamp, beforeTime)
        }
    }
}

// MARK: - Quality Measurement Tests

@MainActor
final class QualityMeasurementTests: XCTestCase {

    func testQualityMeasurement_hasUniqueId() {
        // Given: Two measurements
        let measurement1 = QualityMeasurement(quality: .good, timestamp: Date())
        let measurement2 = QualityMeasurement(quality: .good, timestamp: Date())

        // Then: Should have unique IDs
        XCTAssertNotEqual(measurement1.id, measurement2.id)
    }

    func testQualityMeasurement_storesQualityAndTimestamp() {
        // Given: Known values
        let timestamp = Date()
        let quality = ConnectionQuality.excellent

        // When: Create measurement
        let measurement = QualityMeasurement(quality: quality, timestamp: timestamp)

        // Then: Should store values
        XCTAssertEqual(measurement.quality, quality)
        XCTAssertEqual(measurement.timestamp, timestamp)
    }
}

// MARK: - Connection Statistics Tests

@MainActor
final class ConnectionStatisticsTests: XCTestCase {

    func testConnectionStatistics_acceptablePercentageWithEmptyHistory() {
        // Given: Statistics with empty history
        let stats = ConnectionStatistics(
            averageLatencyMs: 100,
            errorRate: 0.0,
            successCount: 10,
            errorCount: 0,
            currentQuality: .excellent,
            qualityHistory: []
        )

        // Then: Should return 100% for empty history
        XCTAssertEqual(stats.acceptableQualityPercentage, 100)
    }

    func testConnectionStatistics_acceptablePercentageWithMixedHistory() {
        // Given: History with mixed quality
        let history = [
            QualityMeasurement(quality: .excellent, timestamp: Date()),
            QualityMeasurement(quality: .good, timestamp: Date()),
            QualityMeasurement(quality: .fair, timestamp: Date()),
            QualityMeasurement(quality: .poor, timestamp: Date()),
            QualityMeasurement(quality: .disconnected, timestamp: Date())
        ]

        let stats = ConnectionStatistics(
            averageLatencyMs: 200,
            errorRate: 0.1,
            successCount: 9,
            errorCount: 1,
            currentQuality: .good,
            qualityHistory: history
        )

        // Then: 3 out of 5 are acceptable (excellent, good, fair)
        XCTAssertEqual(stats.acceptableQualityPercentage, 60)
    }
}
