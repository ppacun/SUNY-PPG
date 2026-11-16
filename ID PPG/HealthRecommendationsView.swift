//
//  CameraView.swift
//  ID PPG
//
//  Created by Dylan Gonzalez on 29/9/2026.
//
import SwiftUI

struct HealthRecommendationsView: View {

    @ObservedObject private var store = ReadingStore.shared

    @AppStorage("patientAge")
    private var patientAge = 18.0

    @State private var showStatusInfo = false


    // MARK: - Health Flags

    private struct HealthFlags {
        var rising = false
        var declining = false
        var unusuallyHigh = false
        var unusuallyLow = false
        var highEnd = false
        var lowEnd = false
    }


    // MARK: - Sorted Readings

    private var sortedReadings: [SavedReading] {
        store.readings.sorted {
            $0.date < $1.date
        }
    }

    private var latestReading: SavedReading? {
        sortedReadings.last
    }

    private var latestActivity: ReadingActivity {
        latestReading?.activity ?? .none
    }


    // MARK: - Separate By Activity

    private var restingReadings: [SavedReading] {
        sortedReadings.filter {
            $0.activity == .none
        }
    }

    private var lightReadings: [SavedReading] {
        sortedReadings.filter {
            $0.activity == .light
        }
    }

    private var heavyReadings: [SavedReading] {
        sortedReadings.filter {
            $0.activity == .heavy
        }
    }

    private var relevantReadings: [SavedReading] {

        switch latestActivity {

        case .none:
            return restingReadings

        case .light:
            return lightReadings

        case .heavy:
            return heavyReadings
        }
    }


    // MARK: - Current Analysis

    private var currentFlags: HealthFlags {

        analyzeReadings(
            relevantReadings,
            age: Int(patientAge),
            activity: latestActivity
        )
    }


    // MARK: - Latest Values

    private var latestBPM: Double? {
        latestReading?.bpm
    }

    private var latestConfidence: Double? {
        latestReading?.confidence
    }

    private var activityDisplayName: String {

        switch latestActivity {

        case .none:
            return "Resting"

        case .light:
            return "Light Activity"

        case .heavy:
            return "Heavy Activity"
        }
    }


    // MARK: - Overall Status

    private var hasConcern: Bool {

        currentFlags.rising ||
        currentFlags.declining ||
        currentFlags.unusuallyHigh ||
        currentFlags.unusuallyLow ||
        currentFlags.highEnd ||
        currentFlags.lowEnd
    }

    private var overallStatus: String {

        if store.readings.isEmpty {
            return "No Data"
        }

        return hasConcern
            ? "Review Recommended"
            : "Healthy"
    }

    private var overallMessage: String {

        guard !store.readings.isEmpty else {
            return "Save a reading to begin receiving insights."
        }

        if currentFlags.unusuallyHigh {
            return "Your latest reading was higher than most similar readings."
        }

        if currentFlags.unusuallyLow {
            return "Your latest reading was lower than most similar readings."
        }

        if currentFlags.rising {
            return "Your recent readings show an upward trend."
        }

        if currentFlags.declining {
            return "Your recent readings show a downward trend."
        }

        if currentFlags.highEnd {
            return "Your latest reading is near the high end of its expected range."
        }

        if currentFlags.lowEnd {
            return "Your latest reading is near the low end of its expected range."
        }

        return "No current trends require attention."
    }

    private var overallColor: Color {

        if store.readings.isEmpty {
            return .secondary
        }

        return hasConcern
            ? .orange
            : .green
    }


    // MARK: - Trend

    private var trendText: String {

        if relevantReadings.count < 4 {
            return "Not Enough Data"
        }

        if currentFlags.rising {
            return "Rising"
        }

        if currentFlags.declining {
            return "Declining"
        }

        return "Stable"
    }

    private var trendColor: Color {

        if relevantReadings.count < 4 {
            return .secondary
        }

        if currentFlags.rising ||
            currentFlags.declining {

            return .orange
        }

        return .green
    }


    // MARK: - Compared With History

    private var historyComparisonText: String {

        if relevantReadings.count < 5 {
            return "Not Enough Data"
        }

        if currentFlags.unusuallyHigh {
            return "Higher Than Usual"
        }

        if currentFlags.unusuallyLow {
            return "Lower Than Usual"
        }

        return "Typical"
    }

    private var historyComparisonColor: Color {

        if relevantReadings.count < 5 {
            return .secondary
        }

        if currentFlags.unusuallyHigh ||
            currentFlags.unusuallyLow {

            return .orange
        }

        return .green
    }


    // MARK: - Range Position

    private var rangePositionText: String {

        guard latestReading != nil else {
            return "--"
        }

        if currentFlags.highEnd {
            return "High End"
        }

        if currentFlags.lowEnd {
            return "Low End"
        }

        return "Middle"
    }

    private var rangePositionColor: Color {

        guard latestReading != nil else {
            return .secondary
        }

        if currentFlags.highEnd ||
            currentFlags.lowEnd {

            return .orange
        }

        return .green
    }


    // MARK: - Main Recommendation

    private var recommendationText: String {

        guard !store.readings.isEmpty else {

            return """
            Save heart rate readings to receive personalized trends and recommendations.
            """
        }

        if currentFlags.unusuallyHigh {

            return """
            Your latest \(activityDisplayName.lowercased()) heart rate was significantly higher than most of your previous readings taken at the same activity level. Consider taking another reading under similar conditions.
            """
        }

        if currentFlags.unusuallyLow {

            return """
            Your latest \(activityDisplayName.lowercased()) heart rate was significantly lower than most of your previous readings taken at the same activity level. Continue monitoring future readings for consistency.
            """
        }

        if currentFlags.rising {

            return """
            Your recent \(activityDisplayName.lowercased()) heart rate readings show an upward trend. Try to keep testing conditions consistent and monitor whether the trend continues.
            """
        }

        if currentFlags.declining {

            return """
            Your recent \(activityDisplayName.lowercased()) heart rate readings show a downward trend. Continue monitoring future readings under similar conditions.
            """
        }

        if currentFlags.highEnd {

            return """
            Your latest reading is within its expected range but is near the upper end of that range. Rest, hydration, recent activity, and stress may affect your heart rate.
            """
        }

        if currentFlags.lowEnd {

            return """
            Your latest reading is within its expected range but is near the lower end of that range. Continue monitoring future readings for consistency.
            """
        }

        return """
        Your recent \(activityDisplayName.lowercased()) readings are consistent with your previous results and are not currently raising any trend flags.
        """
    }


    // MARK: - Dynamic Recommendations

    private var activityRecommendation: String {

        if currentFlags.unusuallyHigh ||
            currentFlags.rising ||
            currentFlags.highEnd {

            return "Consider lighter activity and compare your next reading."
        }

        if currentFlags.unusuallyLow ||
            currentFlags.declining ||
            currentFlags.lowEnd {

            return "Maintain comfortable activity and continue monitoring your readings."
        }

        return "Maintain your current activity level."
    }

    private var sleepRecommendation: String {

        if currentFlags.unusuallyHigh ||
            currentFlags.rising ||
            currentFlags.highEnd {

            return "Prioritize adequate rest and consistent sleep before your next reading."
        }

        if currentFlags.unusuallyLow ||
            currentFlags.declining {

            return "Maintain a consistent sleep and recovery routine."
        }

        return "Continue getting adequate rest and consistent sleep."
    }

    private var hydrationRecommendation: String {

        if currentFlags.unusuallyHigh ||
            currentFlags.rising ||
            currentFlags.highEnd {

            return "Make sure you are adequately hydrated before your next reading."
        }

        return "Continue maintaining normal hydration."
    }

    private var stressRecommendation: String {

        if currentFlags.unusuallyHigh ||
            currentFlags.rising ||
            currentFlags.highEnd {

            return "Consider whether stress, caffeine, or recent activity may have influenced your reading."
        }

        if currentFlags.unusuallyLow ||
            currentFlags.declining {

            return "Continue tracking your readings alongside changes in stress and daily activity."
        }

        return "Continue monitoring your readings under relaxed and consistent conditions."
    }

    private var mentalWellnessRecommendation: String {

        if currentFlags.unusuallyHigh ||
            currentFlags.rising {

            return "If you feel tense or stressed, take some time to relax before your next reading."
        }

        if currentFlags.unusuallyLow ||
            currentFlags.declining {

            return "Pay attention to changes in energy, mood, and overall well-being."
        }

        return "Continue habits that support relaxation and overall well-being."
    }


    // MARK: - Body

    var body: some View {

        ZStack {

            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 18
                ) {

                    headerSection

                    overallStatusCard

                    readingInsightsCard

                    recommendationCard

                    nextStepsCard
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }

            if showStatusInfo {

                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeStatusInfo()
                    }

                statusInfoPopup
                    .padding(.horizontal, 28)
                    .transition(
                        .scale(scale: 0.95)
                            .combined(with: .opacity)
                    )
            }
        }
        .navigationTitle("Recommendations")
        .navigationBarTitleDisplayMode(.inline)
    }


    // MARK: - Header

    private var headerSection: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text("Health Recommendations")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(
                "Personalized insights based on your previous heart rate readings."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
    }


    // MARK: - Overall Status

    private var overallStatusCard: some View {

        HStack(
            alignment: .center,
            spacing: 14
        ) {

            Image(
                systemName: "waveform.path.ecg"
            )
            .font(.system(size: 30))
            .foregroundStyle(overallColor)
            .frame(width: 42)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Overall Status")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(overallStatus)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(overallColor)

                Text(overallMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }

            Spacer()

            Button {

                withAnimation(
                    .spring(
                        response: 0.3,
                        dampingFraction: 0.8
                    )
                ) {

                    showStatusInfo = true
                }

            } label: {

                Image(
                    systemName: "info.circle"
                )
                .font(.title2)
                .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            cardBackground
        )
    }


    // MARK: - Reading Insights

    private var readingInsightsCard: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack(spacing: 10) {

                Image(
                    systemName: "chart.bar.fill"
                )
                .foregroundStyle(.blue)

                Text("Reading Insights")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            VStack(spacing: 0) {

                insightRow(
                    title: "Activity",
                    value:
                        latestReading == nil
                        ? "--"
                        : activityDisplayName,
                    color: .blue
                )

                Divider()

                insightRow(
                    title: "Heart Rate",
                    value:
                        latestBPM.map {
                            "\(Int($0.rounded())) bpm"
                        } ?? "--",
                    color: .primary
                )

                Divider()

                insightRow(
                    title: "Signal Confidence",
                    value:
                        latestConfidence.map {
                            String(
                                format: "%.1f%%",
                                $0
                            )
                        } ?? "--",
                    color: .primary
                )

                Divider()

                insightRow(
                    title: "Recent Trend",
                    value: trendText,
                    color: trendColor
                )

                Divider()

                insightRow(
                    title: "Compared With Your History",
                    value: historyComparisonText,
                    color: historyComparisonColor
                )

                Divider()

                insightRow(
                    title: "Range Position",
                    value: rangePositionText,
                    color: rangePositionColor
                )
            }
            .background(
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .fill(
                    Color(
                        uiColor:
                            .tertiarySystemBackground
                    )
                )
            )
        }
        .padding(18)
        .background(
            cardBackground
        )
    }


    // MARK: - Recommendation

    private var recommendationCard: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack(spacing: 10) {

                Image(
                    systemName:
                        "heart.text.square.fill"
                )
                .font(.title3)
                .foregroundStyle(.red)

                Text("Recommendation")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            Text(recommendationText)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
        .padding(18)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            cardBackground
        )
    }


    // MARK: - Next Steps

    private var nextStepsCard: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            HStack(spacing: 10) {

                Image(systemName: "checklist")
                    .foregroundStyle(.blue)

                Text("Next Steps")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding()

            Divider()

            nextStepRow(
                icon: "figure.walk",
                title: "Activity",
                text: activityRecommendation
            )

            Divider()

            nextStepRow(
                icon: "bed.double.fill",
                title: "Rest & Sleep",
                text: sleepRecommendation
            )

            Divider()

            nextStepRow(
                icon: "drop.fill",
                title: "Hydration",
                text: hydrationRecommendation
            )

            Divider()

            nextStepRow(
                icon: "brain.head.profile",
                title: "Stress",
                text: stressRecommendation
            )

            Divider()

            nextStepRow(
                icon: "heart.circle.fill",
                title: "Mental Wellness",
                text: mentalWellnessRecommendation
            )
        }
        .background(
            cardBackground
        )
    }


    // MARK: - Popup

    private var statusInfoPopup: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack {

                HStack(spacing: 8) {

                    Image(
                        systemName:
                            "info.circle.fill"
                    )
                    .foregroundStyle(.blue)

                    Text("Overall Status")
                        .font(.headline)
                }

                Spacer()

                Button {
                    closeStatusInfo()
                } label: {

                    Image(systemName: "xmark")
                        .font(
                            .system(
                                size: 12,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.secondary)
                        .frame(
                            width: 28,
                            height: 28
                        )
                        .background(
                            Color.secondary
                                .opacity(0.12)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Divider()

            Text(
                "Your status is calculated from your saved readings."
            )
            .font(.subheadline)
            .foregroundStyle(.primary)

            Text(
                "Readings are compared only with previous readings taken at the same activity level."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(
                horizontal: false,
                vertical: true
            )

            Text(
                "The app checks recent trends, unusually high or low readings, and whether your latest reading is near the high or low end of its expected range."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(
                horizontal: false,
                vertical: true
            )

            Text(
                "These recommendations are intended for general wellness information and are not a medical diagnosis."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(
                horizontal: false,
                vertical: true
            )
        }
        .padding(18)
        .frame(maxWidth: 330)
        .background(
            cardBackground
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(
                Color.primary.opacity(0.08),
                lineWidth: 1
            )
        )
        .shadow(
            color: .black.opacity(0.25),
            radius: 20,
            x: 0,
            y: 10
        )
    }


    // MARK: - Card Background

    private var cardBackground: some View {

        RoundedRectangle(
            cornerRadius: 20,
            style: .continuous
        )
        .fill(
            Color(
                uiColor:
                    .secondarySystemBackground
            )
        )
    }


    // MARK: - Insight Row

    private func insightRow(
        title: String,
        value: String,
        color: Color
    ) -> some View {

        HStack {

            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .multilineTextAlignment(.trailing)
        }
        .padding()
    }


    // MARK: - Next Step Row

    private func nextStepRow(
        icon: String,
        title: String,
        text: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 26)
                .padding(.top, 2)

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }

            Spacer()
        }
        .padding()
    }


    // MARK: - Analyze Readings

    private func analyzeReadings(
        _ readings: [SavedReading],
        age: Int,
        activity: ReadingActivity
    ) -> HealthFlags {

        let sorted = readings.sorted {
            $0.date < $1.date
        }

        guard let latest = sorted.last else {
            return HealthFlags()
        }

        var flags = HealthFlags()

        let recent =
            Array(
                sorted.suffix(7)
            )

        flags.rising =
            isRising(
                readings: recent
            )

        flags.declining =
            isDeclining(
                readings: recent
            )

        flags.unusuallyHigh =
            isUnusuallyHigh(
                readings: sorted
            )

        flags.unusuallyLow =
            isUnusuallyLow(
                readings: sorted
            )

        flags.highEnd =
            isHighEndOfRange(
                bpm: latest.bpm,
                age: age,
                activity: activity
            )

        flags.lowEnd =
            isLowEndOfRange(
                bpm: latest.bpm,
                age: age,
                activity: activity
            )

        return flags
    }


    // MARK: - Rising Trend

    private func isRising(
        readings: [SavedReading]
    ) -> Bool {

        guard readings.count >= 4 else {
            return false
        }

        let values =
            readings.map {
                $0.bpm
            }

        let slope =
            trendSlope(
                values
            )

        return slope >= 1.0
    }


    // MARK: - Declining Trend

    private func isDeclining(
        readings: [SavedReading]
    ) -> Bool {

        guard readings.count >= 4 else {
            return false
        }

        let values =
            readings.map {
                $0.bpm
            }

        let slope =
            trendSlope(
                values
            )

        return slope <= -1.0
    }


    // MARK: - Trend Slope

    private func trendSlope(
        _ values: [Double]
    ) -> Double {

        guard values.count >= 2 else {
            return 0
        }

        let count =
            Double(
                values.count
            )

        let xMean =
            Double(
                values.count - 1
            ) / 2.0

        let yMean =
            values.reduce(0, +)
            / count

        var numerator = 0.0
        var denominator = 0.0

        for index in values.indices {

            let x =
                Double(index)

            let y =
                values[index]

            numerator +=
                (x - xMean)
                * (y - yMean)

            denominator +=
                pow(
                    x - xMean,
                    2
                )
        }

        guard denominator > 0 else {
            return 0
        }

        return
            numerator
            / denominator
    }


    // MARK: - Unusually High

    private func isUnusuallyHigh(
        readings: [SavedReading]
    ) -> Bool {

        guard readings.count >= 5 else {
            return false
        }

        let sorted =
            readings.sorted {
                $0.date < $1.date
            }

        guard let latest =
            sorted.last
        else {
            return false
        }

        let previous =
            sorted
                .dropLast()
                .map {
                    $0.bpm
                }

        guard !previous.isEmpty else {
            return false
        }

        let mean =
            previous.reduce(0, +)
            / Double(previous.count)

        let variance =
            previous
                .map {
                    pow(
                        $0 - mean,
                        2
                    )
                }
                .reduce(0, +)
            / Double(previous.count)

        let standardDeviation =
            sqrt(variance)

        guard standardDeviation > 0 else {
            return latest.bpm > mean
        }

        return latest.bpm >
            mean +
            (
                standardDeviation * 2
            )
    }


    // MARK: - Unusually Low

    private func isUnusuallyLow(
        readings: [SavedReading]
    ) -> Bool {

        guard readings.count >= 5 else {
            return false
        }

        let sorted =
            readings.sorted {
                $0.date < $1.date
            }

        guard let latest =
            sorted.last
        else {
            return false
        }

        let previous =
            sorted
                .dropLast()
                .map {
                    $0.bpm
                }

        guard !previous.isEmpty else {
            return false
        }

        let mean =
            previous.reduce(0, +)
            / Double(previous.count)

        let variance =
            previous
                .map {
                    pow(
                        $0 - mean,
                        2
                    )
                }
                .reduce(0, +)
            / Double(previous.count)

        let standardDeviation =
            sqrt(variance)

        guard standardDeviation > 0 else {
            return latest.bpm < mean
        }

        return latest.bpm <
            mean -
            (
                standardDeviation * 2
            )
    }


    // MARK: - High End of Range

    private func isHighEndOfRange(
        bpm: Double,
        age: Int,
        activity: ReadingActivity
    ) -> Bool {

        let range =
            heartRange(
                age: age,
                activity: activity
            )

        guard
            bpm >= range.lowerBound,
            bpm <= range.upperBound
        else {
            return false
        }

        let width =
            range.upperBound
            - range.lowerBound

        let threshold =
            range.upperBound
            - (width * 0.10)

        return bpm >= threshold
    }


    // MARK: - Low End of Range

    private func isLowEndOfRange(
        bpm: Double,
        age: Int,
        activity: ReadingActivity
    ) -> Bool {

        let range =
            heartRange(
                age: age,
                activity: activity
            )

        guard
            bpm >= range.lowerBound,
            bpm <= range.upperBound
        else {
            return false
        }

        let width =
            range.upperBound
            - range.lowerBound

        let threshold =
            range.lowerBound
            + (width * 0.10)

        return bpm <= threshold
    }


    // MARK: - Heart Rate Range

    private func heartRange(
        age: Int,
        activity: ReadingActivity
    ) -> ClosedRange<Double> {

        let restingRange:
            ClosedRange<Double>

        switch age {

        case 0:
            restingRange =
                80...160

        case 1...2:
            restingRange =
                80...130

        case 3...5:
            restingRange =
                80...110

        case 6...12:
            restingRange =
                70...100

        default:
            restingRange =
                60...100
        }

        let multiplier: Double

        switch activity {

        case .none:
            multiplier = 1.0

        case .light:
            multiplier = 1.50

        case .heavy:
            multiplier = 1.75
        }

        let lower =
            restingRange.lowerBound
            * multiplier

        let upper =
            restingRange.upperBound
            * multiplier

        return lower...upper
    }


    // MARK: - Close Popup

    private func closeStatusInfo() {

        withAnimation(
            .spring(
                response: 0.3,
                dampingFraction: 0.8
            )
        ) {

            showStatusInfo = false
        }
    }
}
