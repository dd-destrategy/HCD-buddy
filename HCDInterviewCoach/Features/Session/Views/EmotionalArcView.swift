//
//  EmotionalArcView.swift
//  HCD Interview Coach
//
//  Feature G: Emotional Arc Tracking
//  SwiftUI view displaying the emotional timeline of a session as a
//  sentiment chart with shift markers, summary cards, and intensity peaks.
//

import SwiftUI

// MARK: - Emotional Arc View

/// Displays the emotional arc of an interview session.
///
/// **Compact mode** (toolbar/sidebar): sparkline, current sentiment dot, shift count badge.
/// **Expanded mode** (analysis): full timeline chart, shift list, summary card, intensity peaks.
struct EmotionalArcView: View {

    @ObservedObject var analyzer: SentimentAnalyzer

    /// Whether to show the full expanded analysis view or a compact sparkline
    var isExpanded: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if isExpanded {
            expandedView
        } else {
            compactView
        }
    }

    // MARK: - Compact View

    /// Minimal sparkline with current sentiment indicator and shift count
    private var compactView: some View {
        HStack(spacing: Spacing.sm) {
            // Sparkline
            if analyzer.results.count >= 2 {
                sparklineCanvas
                    .frame(width: 60, height: 20)
            }

            // Current sentiment dot
            if let lastResult = analyzer.results.last {
                Circle()
                    .fill(colorForPolarity(lastResult.polarity))
                    .frame(width: 8, height: 8)

                Text(lastResult.polarity.displayName)
                    .font(Typography.small)
                    .foregroundColor(.hcdTextSecondary)
            }

            // Shift count badge
            if !analyzer.emotionalShifts.isEmpty {
                Text("\(analyzer.emotionalShifts.count)")
                    .font(Typography.small)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.hcdWarning)
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(compactAccessibilityLabel)
        .accessibilityHint("Emotional arc summary. Expand for full analysis.")
    }

    /// Accessibility label for compact mode
    private var compactAccessibilityLabel: String {
        guard let last = analyzer.results.last else {
            return "Emotional arc: no data yet"
        }
        var label = "Current sentiment: \(last.polarity.displayName)"
        if !analyzer.emotionalShifts.isEmpty {
            label += ", \(analyzer.emotionalShifts.count) emotional shift\(analyzer.emotionalShifts.count == 1 ? "" : "s") detected"
        }
        return label
    }

    // MARK: - Sparkline Canvas

    /// A small sparkline drawn with Canvas showing sentiment score over time
    private var sparklineCanvas: some View {
        Canvas { context, size in
            let dataPoints = analyzer.results
            guard dataPoints.count >= 2 else { return }

            let stepX = size.width / CGFloat(dataPoints.count - 1)
            let midY = size.height / 2.0

            var path = Path()
            for (index, result) in dataPoints.enumerated() {
                let x = CGFloat(index) * stepX
                // Map score from [-1, +1] to [height, 0]
                let normalizedY = midY - (CGFloat(result.score) * midY)
                let point = CGPoint(x: x, y: normalizedY)

                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }

            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [.green, .gray, .red]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: size.height)
                ),
                lineWidth: 1.5
            )
        }
    }

    // MARK: - Expanded View

    /// Full analysis view with chart, shifts, summary, and peaks
    private var expandedView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Header
                headerSection

                if analyzer.results.isEmpty {
                    emptyStateView
                } else {
                    // Sentiment Timeline Chart
                    sentimentChartSection

                    // Summary Card
                    if let summary = analyzer.arcSummary {
                        summaryCardSection(summary)
                    }

                    // Emotional Shifts
                    if !analyzer.emotionalShifts.isEmpty {
                        emotionalShiftsSection
                    }

                    // Intensity Peaks
                    if let summary = analyzer.arcSummary, !summary.intensityPeaks.isEmpty {
                        intensityPeaksSection(summary.intensityPeaks)
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Emotional arc analysis")
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "waveform.path.ecg")
                .font(Typography.heading2)
                .foregroundColor(.hcdPrimary)

            Text("Emotional Arc")
                .font(Typography.heading2)
                .foregroundColor(.hcdTextPrimary)

            Spacer()

            if !analyzer.results.isEmpty {
                Text("\(analyzer.results.count) data points")
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Emotional Arc, \(analyzer.results.count) data points")
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 40))
                .foregroundColor(.hcdTextSecondary)
                .opacity(0.5)

            Text("No sentiment data yet")
                .font(Typography.body)
                .foregroundColor(.hcdTextSecondary)

            Text("Sentiment analysis will appear as the conversation progresses.")
                .font(Typography.caption)
                .foregroundColor(.hcdTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xxl)
        .liquidGlass(
            material: .thin,
            cornerRadius: CornerRadius.large,
            borderStyle: .subtle,
            enableHover: false
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No sentiment data yet. Analysis will appear as the conversation progresses.")
    }

    // MARK: - Sentiment Chart Section

    private var sentimentChartSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Sentiment Timeline")
                .font(Typography.bodyMedium)
                .foregroundColor(.hcdTextPrimary)

            sentimentChart
                .frame(height: 200)
                .liquidGlass(
                    material: .thin,
                    cornerRadius: CornerRadius.large,
                    borderStyle: .subtle,
                    enableHover: false
                )

            // Legend
            chartLegend
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chartAccessibilityLabel)
    }

    /// Full sentiment timeline chart drawn with Canvas
    private var sentimentChart: some View {
        Canvas { context, size in
            let dataPoints = analyzer.results
            guard !dataPoints.isEmpty else { return }

            let chartInsets = EdgeInsets(top: 16, leading: 40, bottom: 24, trailing: 16)
            let chartWidth = size.width - chartInsets.leading - chartInsets.trailing
            let chartHeight = size.height - chartInsets.top - chartInsets.bottom
            let originX = chartInsets.leading
            let originY = chartInsets.top
            let midChartY = originY + chartHeight / 2.0

            // Draw Y-axis labels and grid lines
            drawYAxis(context: context, originX: originX, originY: originY,
                      chartWidth: chartWidth, chartHeight: chartHeight, midChartY: midChartY)

            // Draw X-axis labels
            drawXAxis(context: context, dataPoints: dataPoints, originX: originX,
                      originY: originY, chartWidth: chartWidth, chartHeight: chartHeight)

            // Draw zero line
            let zeroPath = Path { p in
                p.move(to: CGPoint(x: originX, y: midChartY))
                p.addLine(to: CGPoint(x: originX + chartWidth, y: midChartY))
            }
            context.stroke(zeroPath, with: .color(.gray.opacity(0.3)), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

            guard dataPoints.count >= 2 else {
                // Single point: draw a dot
                let point = dataPoints[0]
                let x = originX + chartWidth / 2
                let y = midChartY - (CGFloat(point.score) * chartHeight / 2.0)
                let dotRect = CGRect(x: x - 5, y: y - 5, width: 10, height: 10)
                context.fill(Path(ellipseIn: dotRect), with: .color(colorForPolarity(point.polarity)))
                return
            }

            // Calculate point positions
            let stepX = chartWidth / CGFloat(dataPoints.count - 1)
            var points: [CGPoint] = []
            for (index, result) in dataPoints.enumerated() {
                let x = originX + CGFloat(index) * stepX
                let y = midChartY - (CGFloat(result.score) * chartHeight / 2.0)
                points.append(CGPoint(x: x, y: y))
            }

            // Draw the sentiment line with gradient segments
            for i in 1..<points.count {
                let segmentPath = Path { p in
                    p.move(to: points[i - 1])
                    p.addLine(to: points[i])
                }
                let avgScore = (dataPoints[i - 1].score + dataPoints[i].score) / 2.0
                let lineColor = colorForScore(avgScore)
                context.stroke(segmentPath, with: .color(lineColor), lineWidth: 2.5)
            }

            // Draw data point dots (size proportional to intensity)
            for (index, result) in dataPoints.enumerated() {
                let baseRadius: CGFloat = 3.0
                let intensityBonus: CGFloat = CGFloat(result.intensity) * 4.0
                let radius = baseRadius + intensityBonus
                let center = points[index]
                let dotRect = CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                context.fill(Path(ellipseIn: dotRect), with: .color(colorForPolarity(result.polarity)))

                // White border for visibility
                let borderPath = Path(ellipseIn: dotRect)
                context.stroke(borderPath, with: .color(.white.opacity(0.8)), lineWidth: 1)
            }

            // Draw emotional shift markers
            drawShiftMarkers(context: context, points: points, originY: originY,
                             chartHeight: chartHeight, chartInsets: chartInsets)

        }
        .padding(Spacing.sm)
    }

    /// Draw Y-axis labels and horizontal grid lines
    private func drawYAxis(context: GraphicsContext, originX: CGFloat, originY: CGFloat,
                           chartWidth: CGFloat, chartHeight: CGFloat, midChartY: CGFloat) {
        let labels: [(String, Double)] = [("+1.0", 1.0), ("+0.5", 0.5), ("0", 0.0), ("-0.5", -0.5), ("-1.0", -1.0)]

        for (label, value) in labels {
            let y = midChartY - (CGFloat(value) * chartHeight / 2.0)

            // Grid line
            if value != 0.0 {
                let gridPath = Path { p in
                    p.move(to: CGPoint(x: originX, y: y))
                    p.addLine(to: CGPoint(x: originX + chartWidth, y: y))
                }
                context.stroke(gridPath, with: .color(.gray.opacity(0.15)), lineWidth: 0.5)
            }

            // Label
            let text = Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            context.draw(text, at: CGPoint(x: originX - 6, y: y), anchor: .trailing)
        }
    }

    /// Draw X-axis time labels
    private func drawXAxis(context: GraphicsContext, dataPoints: [SentimentResult],
                           originX: CGFloat, originY: CGFloat,
                           chartWidth: CGFloat, chartHeight: CGFloat) {
        guard dataPoints.count >= 2 else { return }

        let stepX = chartWidth / CGFloat(dataPoints.count - 1)
        let labelInterval = max(1, dataPoints.count / 5) // Show ~5 labels

        for index in stride(from: 0, to: dataPoints.count, by: labelInterval) {
            let x = originX + CGFloat(index) * stepX
            let y = originY + chartHeight + 4

            let timestamp = dataPoints[index].timestamp
            let minutes = Int(timestamp) / 60
            let seconds = Int(timestamp) % 60
            let label = String(format: "%d:%02d", minutes, seconds)

            let text = Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            context.draw(text, at: CGPoint(x: x, y: y), anchor: .top)
        }

        // Always draw the last label
        if dataPoints.count > 1 {
            let lastIndex = dataPoints.count - 1
            let x = originX + CGFloat(lastIndex) * stepX
            let y = originY + chartHeight + 4
            let timestamp = dataPoints[lastIndex].timestamp
            let minutes = Int(timestamp) / 60
            let seconds = Int(timestamp) % 60
            let label = String(format: "%d:%02d", minutes, seconds)
            let text = Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            context.draw(text, at: CGPoint(x: x, y: y), anchor: .top)
        }
    }

    /// Draw diamond markers at emotional shift points
    private func drawShiftMarkers(context: GraphicsContext, points: [CGPoint],
                                  originY: CGFloat, chartHeight: CGFloat,
                                  chartInsets: EdgeInsets) {
        for shift in analyzer.emotionalShifts {
            // Find the index of the toResult
            guard let toIndex = analyzer.results.firstIndex(where: { $0.id == shift.toResult.id }),
                  toIndex < points.count else { continue }

            let center = points[toIndex]
            let markerSize: CGFloat = 8.0

            // Draw a diamond marker
            let diamond = Path { p in
                p.move(to: CGPoint(x: center.x, y: center.y - markerSize))
                p.addLine(to: CGPoint(x: center.x + markerSize, y: center.y))
                p.addLine(to: CGPoint(x: center.x, y: center.y + markerSize))
                p.addLine(to: CGPoint(x: center.x - markerSize, y: center.y))
                p.closeSubpath()
            }
            context.fill(diamond, with: .color(Color.hcdWarning.opacity(0.8)))
            context.stroke(diamond, with: .color(.white), lineWidth: 1)
        }
    }

    /// Legend below the chart
    private var chartLegend: some View {
        HStack(spacing: Spacing.lg) {
            legendItem(color: .green, label: "Positive")
            legendItem(color: .gray, label: "Neutral")
            legendItem(color: .red, label: "Negative")

            Spacer()

            HStack(spacing: Spacing.xs) {
                diamondShape
                    .fill(Color.hcdWarning)
                    .frame(width: 8, height: 8)
                Text("Emotional Shift")
                    .font(Typography.small)
                    .foregroundColor(.hcdTextSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Chart legend: green for positive, gray for neutral, red for negative, diamond for emotional shifts")
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(Typography.small)
                .foregroundColor(.hcdTextSecondary)
        }
    }

    /// A diamond shape for the legend
    private var diamondShape: some Shape {
        DiamondShape()
    }

    /// Accessibility label for the chart
    private var chartAccessibilityLabel: String {
        guard !analyzer.results.isEmpty else {
            return "Sentiment timeline: no data"
        }
        let first = analyzer.results.first!
        let last = analyzer.results.last!
        var label = "Sentiment timeline with \(analyzer.results.count) data points."
        label += " Started \(first.polarity.displayName.lowercased()), ended \(last.polarity.displayName.lowercased())."
        if !analyzer.emotionalShifts.isEmpty {
            label += " \(analyzer.emotionalShifts.count) emotional shift\(analyzer.emotionalShifts.count == 1 ? "" : "s") detected."
        }
        return label
    }

    // MARK: - Summary Card

    private func summaryCardSection(_ summary: EmotionalArcSummary) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Summary")
                .font(Typography.bodyMedium)
                .foregroundColor(.hcdTextPrimary)

            VStack(alignment: .leading, spacing: Spacing.md) {
                // Arc description
                Text(summary.arcDescription)
                    .font(Typography.body)
                    .foregroundColor(.hcdTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                // Stats grid
                HStack(spacing: Spacing.lg) {
                    statItem(label: "Average", value: formatScore(summary.averageSentiment),
                             color: colorForScore(summary.averageSentiment))

                    statItem(label: "Dominant", value: summary.dominantPolarity.displayName,
                             color: colorForPolarity(summary.dominantPolarity))

                    statItem(label: "Range", value: "\(formatScore(summary.minSentiment)) to \(formatScore(summary.maxSentiment))",
                             color: .hcdTextSecondary)

                    statItem(label: "Shifts", value: "\(summary.emotionalShifts.count)",
                             color: summary.emotionalShifts.isEmpty ? .hcdTextSecondary : .hcdWarning)
                }
            }
            .padding(Spacing.md)
            .glassCard()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(summaryAccessibilityLabel(summary))
    }

    private func statItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(Typography.bodyMedium)
                .foregroundColor(color)
            Text(label)
                .font(Typography.small)
                .foregroundColor(.hcdTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func summaryAccessibilityLabel(_ summary: EmotionalArcSummary) -> String {
        "Summary: \(summary.arcDescription). Average sentiment \(formatScore(summary.averageSentiment)), dominant polarity \(summary.dominantPolarity.displayName), \(summary.emotionalShifts.count) shifts."
    }

    // MARK: - Emotional Shifts Section

    private var emotionalShiftsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Emotional Shifts")
                .font(Typography.bodyMedium)
                .foregroundColor(.hcdTextPrimary)

            ForEach(analyzer.emotionalShifts) { shift in
                shiftCard(shift)
            }
        }
    }

    private func shiftCard(_ shift: EmotionalShift) -> some View {
        HStack(spacing: Spacing.md) {
            // Shift direction indicator
            VStack(spacing: Spacing.xs) {
                Circle()
                    .fill(colorForPolarity(shift.fromResult.polarity))
                    .frame(width: 10, height: 10)

                Image(systemName: "arrow.down")
                    .font(.system(size: 10))
                    .foregroundColor(.hcdTextSecondary)

                Circle()
                    .fill(colorForPolarity(shift.toResult.polarity))
                    .frame(width: 10, height: 10)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(shift.description)
                    .font(Typography.bodyMedium)
                    .foregroundColor(.hcdTextPrimary)

                HStack(spacing: Spacing.sm) {
                    Text(formatTimestamp(shift.toResult.timestamp))
                        .font(Typography.caption)
                        .foregroundColor(.hcdTextSecondary)

                    Text("Magnitude: \(formatScore(shift.shiftMagnitude))")
                        .font(Typography.caption)
                        .foregroundColor(.hcdWarning)
                }
            }

            Spacer()
        }
        .padding(Spacing.md)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Shift at \(formatTimestamp(shift.toResult.timestamp)): \(shift.description), magnitude \(formatScore(shift.shiftMagnitude))")
        .accessibilityHint("Emotional shift between consecutive utterances")
    }

    // MARK: - Intensity Peaks Section

    private func intensityPeaksSection(_ peaks: [SentimentResult]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Intensity Peaks")
                .font(Typography.bodyMedium)
                .foregroundColor(.hcdTextPrimary)

            ForEach(peaks) { peak in
                peakCard(peak)
            }
        }
    }

    private func peakCard(_ peak: SentimentResult) -> some View {
        HStack(spacing: Spacing.md) {
            // Intensity indicator
            ZStack {
                Circle()
                    .fill(colorForPolarity(peak.polarity).opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: peak.polarity.icon)
                    .font(Typography.body)
                    .foregroundColor(colorForPolarity(peak.polarity))
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.sm) {
                    Text(peak.polarity.displayName)
                        .font(Typography.bodyMedium)
                        .foregroundColor(colorForPolarity(peak.polarity))

                    if let emotion = peak.dominantEmotion {
                        Text(emotion.capitalized)
                            .font(Typography.caption)
                            .foregroundColor(.hcdTextSecondary)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.hcdTextSecondary.opacity(0.12))
                            )
                    }
                }

                HStack(spacing: Spacing.sm) {
                    Text(formatTimestamp(peak.timestamp))
                        .font(Typography.caption)
                        .foregroundColor(.hcdTextSecondary)

                    Text("Score: \(formatScore(peak.score))")
                        .font(Typography.caption)
                        .foregroundColor(.hcdTextSecondary)

                    Text("Intensity: \(formatScore(peak.intensity))")
                        .font(Typography.caption)
                        .foregroundColor(.hcdWarning)
                }
            }

            Spacer()
        }
        .padding(Spacing.md)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Intensity peak at \(formatTimestamp(peak.timestamp)): \(peak.polarity.displayName), score \(formatScore(peak.score)), intensity \(formatScore(peak.intensity))")
        .accessibilityHint(peak.dominantEmotion.map { "Dominant emotion: \($0)" } ?? "")
    }

    // MARK: - Helpers

    /// Return a color for a given sentiment polarity
    private func colorForPolarity(_ polarity: SentimentPolarity) -> Color {
        switch polarity {
        case .positive: return .green
        case .neutral: return .gray
        case .negative: return .red
        case .mixed: return .orange
        }
    }

    /// Return a color interpolated between red, gray, and green based on score
    private func colorForScore(_ score: Double) -> Color {
        if score > 0.15 {
            return .green
        } else if score < -0.15 {
            return .red
        } else {
            return .gray
        }
    }

    /// Format a sentiment score for display (e.g., "+0.45" or "-0.32")
    private func formatScore(_ score: Double) -> String {
        if score >= 0 {
            return String(format: "+%.2f", score)
        } else {
            return String(format: "%.2f", score)
        }
    }

    /// Format a timestamp in seconds to MM:SS
    private func formatTimestamp(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Diamond Shape

/// A simple diamond shape used for shift markers in the legend
struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let halfWidth = rect.width / 2.0
        let halfHeight = rect.height / 2.0
        path.move(to: CGPoint(x: center.x, y: center.y - halfHeight))
        path.addLine(to: CGPoint(x: center.x + halfWidth, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + halfHeight))
        path.addLine(to: CGPoint(x: center.x - halfWidth, y: center.y))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#if DEBUG
struct EmotionalArcView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                // Compact view
                EmotionalArcView(
                    analyzer: previewAnalyzer(),
                    isExpanded: false
                )
                .padding(Spacing.md)
                .glassCard()

                // Expanded view
                EmotionalArcView(
                    analyzer: previewAnalyzer(),
                    isExpanded: true
                )
            }
            .padding()
        }
    }

    @MainActor
    static func previewAnalyzer() -> SentimentAnalyzer {
        let analyzer = SentimentAnalyzer()

        let utterances = [
            Utterance(speaker: .participant, text: "I really love this feature, it's amazing", timestampSeconds: 30.0),
            Utterance(speaker: .participant, text: "This part is okay, nothing special", timestampSeconds: 120.0),
            Utterance(speaker: .participant, text: "I'm so frustrated, this is really confusing", timestampSeconds: 240.0),
            Utterance(speaker: .participant, text: "That was a nightmare to figure out", timestampSeconds: 360.0),
            Utterance(speaker: .participant, text: "Oh wait, I see now, that's actually pretty helpful", timestampSeconds: 480.0),
            Utterance(speaker: .participant, text: "Yes this is great, I really appreciate it", timestampSeconds: 600.0),
        ]

        analyzer.analyzeSession(utterances)
        return analyzer
    }
}
#endif
