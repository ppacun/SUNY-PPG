//
//  PastReadingsView.swift
//  ID PPG
//
//  Created by Mamadou Wague on 10/29/2026
//

import SwiftUI
import Charts

enum ReadingActivity: String, CaseIterable, Codable {
    case none = "None"
    case light = "Light"
    case heavy = "Heavy"
}

struct SavedReading: Identifiable, Codable, Equatable {
    var id = UUID()
    let date: Date
    let bpm: Double
    let confidence: Double
    let activity: ReadingActivity
}

// Saved readings live in UserDefaults as JSON, newest reading is always first in `readings`.
final class ReadingStore: ObservableObject {
    static let shared = ReadingStore()

    @Published private(set) var readings: [SavedReading] = []
    private let key = "savedReadings"

    init() { load() }

    func add(bpm: Double, confidence: Double, activity: ReadingActivity, date: Date = Date()) {
        let reading = SavedReading(date: date, bpm: bpm, confidence: confidence, activity: activity)
        readings.insert(reading, at: 0)
        persist()
    }

    func delete(at offsets: IndexSet) {
        readings.remove(atOffsets: offsets)
        persist()
    }

    func deleteAll() {
        readings.removeAll()
        persist()
    }

    // Average BPM across all saved readings (nil if none).
    var averageBPM: Double? {
        guard !readings.isEmpty else { return nil }
        return readings.map(\.bpm).reduce(0, +) / Double(readings.count)
    }

    // Standard deviation of saved BPMs (nil with fewer than 2 readings).
    var standardDeviation: Double? {
        guard readings.count >= 2, let mean = averageBPM else { return nil }
        let sumSquares = readings.map { pow($0.bpm - mean, 2) }.reduce(0, +)
        return (sumSquares / Double(readings.count - 1)).squareRoot()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SavedReading].self, from: data)
        else { return }
        readings = decoded
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(readings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// Low / Strong / High compared with the resting range for the user's age.
enum RangeStatus {
    case low, strong, high

    init(bpm: Double, age: Double) {
        let range = heartRange(age: Int(age))
        let rounded = Int(bpm.rounded())
        if range.contains(rounded) {
            self = .strong
        } else if rounded < range.lowerBound {
            self = .low
        } else {
            self = .high
        }
    }

    var label: String {
        switch self {
        case .low: return "Low"
        case .strong: return "Strong"
        case .high: return "High"
        }
    }

    var color: Color {
        switch self {
        case .low: return .blue
        case .strong: return .green
        case .high: return .red
        }
    }
}

enum VarianceLevel {
    case low, moderate, high

    init(standardDeviation: Double) {
        if standardDeviation < 6 {
            self = .low
        } else if standardDeviation < 12 {
            self = .moderate
        } else {
            self = .high
        }
    }

    var label: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        }
    }

    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .orange
        case .high: return .red
        }
    }
}

//Past Readings screen
struct PastReadingsView: View {
    @ObservedObject private var store = ReadingStore.shared
    @AppStorage("patientAge") private var patientAge = 18.0
    @State private var confirmDeleteAll = false
    @State private var selectedReadingID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            summaryHeader
                .padding()

            // Graph of the most recent readings (hidden until something is saved)
            if !store.readings.isEmpty {
                ReadingsGraph(
                    readings: store.readings,
                    age: patientAge,
                    selectedID: $selectedReadingID
                )
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            Divider()

            if store.readings.isEmpty {
                Spacer()
                Text("No saved readings yet.\nTake a heart rate and tap Save.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                // allows the list to scroll
                List {
                    ForEach(store.readings) { reading in
                        ReadingRow(
                            reading: reading,
                            status: RangeStatus(bpm: reading.bpm, age: patientAge)
                        )
                    }
                    .onDelete { store.delete(at: $0) }
                }
                .listStyle(.plain)
            }
        }
        // Clear the graph selection if a reading is added or deleted, or when leaving the screen
        .onChange(of: store.readings.count) { _ in
            selectedReadingID = nil
        }
        .onDisappear {
            selectedReadingID = nil
        }
        .navigationTitle("Past Readings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Delete all readings", role: .destructive) {
                        confirmDeleteAll = true
                    }
                    .disabled(store.readings.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "Delete all saved readings?",
            isPresented: $confirmDeleteAll,
            titleVisibility: .visible
        ) {
            Button("Delete all", role: .destructive) { store.deleteAll() }
        }
    }

    // Average circle, variance, and the Recommendations button.
    private var summaryHeader: some View {
        HStack(spacing: 16) {
            let avgColor = store.averageBPM
                .map { RangeStatus(bpm: $0, age: patientAge).color } ?? .gray

            Text(store.averageBPM.map { String(Int($0.rounded())) } ?? "--")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(avgColor)
                .frame(width: 84, height: 84)
                .background(avgColor.opacity(0.12))
                .clipShape(Circle())
                .overlay(Circle().stroke(avgColor, lineWidth: 4))

            VStack(alignment: .leading, spacing: 6) {
                Text("Your Average")
                    .font(.headline)

                HStack(spacing: 6) {
                    Text("Variance")
                    if let sd = store.standardDeviation {
                        let level = VarianceLevel(standardDeviation: sd)
                        Text(level.label)
                            .bold()
                            .foregroundStyle(level.color)
                    } else {
                        Text("--").foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)

                NavigationLink {
                    HealthRecommendationsView()
                } label: {
                    Text("Recommendations")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.gray)
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
    }
}

// One saved reading: BPM circle, date / time / activity, and the Low / Strong / High label.
private struct ReadingRow: View {
    let reading: SavedReading
    let status: RangeStatus

    var body: some View {
        HStack(spacing: 16) {
            Text(String(Int(reading.bpm.rounded())))
                .font(.title2.bold())
                .foregroundStyle(status.color)
                .frame(width: 64, height: 64)
                .background(status.color.opacity(0.12))
                .clipShape(Circle())
                .overlay(Circle().stroke(status.color, lineWidth: 3))

            VStack(alignment: .leading, spacing: 2) {
                Text("Date: " + reading.date.formatted(date: .abbreviated, time: .omitted))
                Text("Time: " + reading.date.formatted(date: .omitted, time: .shortened))
                Text("Activity: " + reading.activity.rawValue)
            }
            .font(.subheadline)

            Spacer()

            Text(status.label)
                .font(.title3.bold())
                .foregroundStyle(status.color)
        }
        .padding(.vertical, 6)
    }
}

// save popup (shown from ResultsView)
struct SaveReadingSheet: View {
    let bpm: Double
    let onSave: (ReadingActivity, Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var activity: ReadingActivity = .none
    private let now = Date()

    var body: some View {
        VStack(spacing: 20) {
            Text("Save this reading")
                .font(.title2.bold())

            VStack(spacing: 4) {
                Text(now.formatted(date: .complete, time: .omitted))
                Text(now.formatted(date: .omitted, time: .shortened))
                Text("\(Int(bpm.rounded())) BPM")
                    .font(.headline)
            }
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                Text("Activity").font(.headline)
                ForEach(ReadingActivity.allCases, id: \.self) { option in
                    Button {
                        activity = option
                    } label: {
                        HStack {
                            Image(systemName: activity == option ? "largecircle.fill.circle" : "circle")
                            Text(option.rawValue)
                            Spacer()
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .frame(maxWidth: 260)

            Button {
                onSave(activity, now)
                dismiss()
            } label: {
                Text("Save").frame(maxWidth: 200)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("Cancel", role: .cancel) { dismiss() }
        }
        .padding()
        .presentationDetents([.medium])
    }
}

// One plotted reading. `index` is its slot on the x-axis (0 = oldest shown).
private struct GraphPoint: Identifiable {
    let index: Int
    let reading: SavedReading
    let status: RangeStatus

    var id: UUID { reading.id }
}

// Line graph of the newest readings, oldest on the left.
private struct ReadingsGraph: View {
    let readings: [SavedReading]      // newest first, same order as the store
    let age: Double
    @Binding var selectedID: UUID?
    
    @State private var isTouching = false
    @State private var movedFar = false
    @State private var selectionAtTouchStart: UUID?
    
    private let maxPoints = 30
    
    // Newest 30 readings, reversed so the oldest is on the left.
    private var points: [GraphPoint] {
        let recent = Array(readings.prefix(maxPoints).reversed())
        return recent.enumerated().map { offset, reading in
            GraphPoint(
                index: offset,
                reading: reading,
                status: RangeStatus(bpm: reading.bpm, age: age)
            )
        }
    }
 
    // Y-axis follows the data with padding, in steps of 10.
    private func yDomain(for points: [GraphPoint]) -> ClosedRange<Double> {
        let values = points.map { $0.reading.bpm }

        guard let low = values.min(),
              let high = values.max() else {
            return 50...90
        }

        if high - low < 10 {
            let start = (((low + high) / 2 - 10) / 10).rounded(.down) * 10
            return start...(start + 20)
        }

        let padding = max(5.0, (high - low) * 0.15)
        let lower = ((low - padding) / 10).rounded(.down) * 10
        let upper = ((high + padding) / 10).rounded(.up) * 10
        return lower...upper
    }

    var body: some View {
        let pts = points
        let domain = yDomain(for: pts)
        let middle = (domain.lowerBound + domain.upperBound) / 2
        let ticks = [domain.lowerBound, middle, domain.upperBound]
        let selected = pts.first { $0.id == selectedID }
        let dotSize: CGFloat = pts.count > 12 ? 22 : 40

        VStack(spacing: 4) {

            Chart {

                // Selection marker: dashed guide, halo, and the readout label.
                if let sel = selected {

                    RuleMark(x: .value("Reading", Double(sel.index)))
                        .foregroundStyle(Color.secondary.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    PointMark(
                        x: .value("Reading", Double(sel.index)),
                        y: .value("BPM", sel.reading.bpm)
                    )
                    .symbolSize(450)
                    .foregroundStyle(sel.status.color.opacity(0.22))
                    .annotation(
                        position: sel.reading.bpm > middle ? .bottom : .top,
                        alignment: .center,
                        spacing: 6
                    ) {
                        readoutLabel(for: sel)
                    }
                }

                ForEach(pts) { point in
                    LineMark(
                        x: .value("Reading", Double(point.index)),
                        y: .value("BPM", point.reading.bpm)
                    )
                    .foregroundStyle(Color.primary)
                    .lineStyle(
                        StrokeStyle(
                            lineWidth: 2.5,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                }

                ForEach(pts) { point in
                    PointMark(
                        x: .value("Reading", Double(point.index)),
                        y: .value("BPM", point.reading.bpm)
                    )
                    .symbolSize(point.id == selected?.id ? 110 : dotSize)
                    .foregroundStyle(point.status.color)
                }
            }
            .chartYScale(domain: domain)
            .chartXScale(domain: -0.5...(Double(pts.count) - 0.5))
            .chartXAxis(.hidden)
            .chartLegend(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: ticks) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    let plotFrame = geo[proxy.plotAreaFrame]

                    ZStack {
                        // The chart's two dark side borders
                        Path { path in
                            path.move(to: CGPoint(x: plotFrame.minX, y: plotFrame.minY - 6))
                            path.addLine(to: CGPoint(x: plotFrame.minX, y: plotFrame.maxY + 6))
                            path.move(to: CGPoint(x: plotFrame.maxX, y: plotFrame.minY - 6))
                            path.addLine(to: CGPoint(x: plotFrame.maxX, y: plotFrame.maxY + 6))
                        }
                        .stroke(
                            Color.primary,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .allowsHitTesting(false)

                        // Touch layer over the whole chart
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                touchGesture(plotFrame: plotFrame, points: pts)
                            )
                    }
                }
            }
            .frame(height: 150)
            .accessibilityLabel(
                "Graph of your \(pts.count) most recent heart rate readings"
            )

            Text(readings.count > maxPoints ? "Last \(maxPoints) readings" : "All time")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
    }

    // Label shown next to the selected dot.
    private func readoutLabel(for point: GraphPoint) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(Int(point.reading.bpm.rounded())) BPM · \(point.status.label)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(point.status.color)

            Text(
                point.reading.date.formatted(date: .abbreviated, time: .shortened)
                + " · " + point.reading.activity.rawValue
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(uiColor: .systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
        )
    }

    // Touch down or slide: select the nearest dot.
    private func touchGesture(plotFrame: CGRect, points: [GraphPoint]) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isTouching {
                    isTouching = true
                    movedFar = false
                    selectionAtTouchStart = selectedID
                }

                if abs(value.translation.width) > 10 ||
                    abs(value.translation.height) > 10 {
                    movedFar = true
                }

                if let point = nearestPoint(
                    to: value.location,
                    plotFrame: plotFrame,
                    points: points
                ) {
                    selectedID = point.id
                }
            }
            .onEnded { value in
                if !movedFar,
                   let startID = selectionAtTouchStart,
                   let point = nearestPoint(
                       to: value.location,
                       plotFrame: plotFrame,
                       points: points
                   ),
                   point.id == startID {
                    selectedID = nil
                }

                isTouching = false
                selectionAtTouchStart = nil
            }
    }

    // Each reading owns one equal-width slot across the plot area.
    private func nearestPoint(
        to location: CGPoint,
        plotFrame: CGRect,
        points: [GraphPoint]
    ) -> GraphPoint? {
        guard !points.isEmpty,
              plotFrame.width > 0 else {
            return nil
        }

        let fraction = min(
            max((location.x - plotFrame.minX) / plotFrame.width, 0),
            1
        )

        let index = min(
            Int(fraction * Double(points.count)),
            points.count - 1
        )

        return points[index]
    }
}

struct PastReadingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PastReadingsView()
        }
    }
}
// MARK: - Heart Rate Range

private func heartRange(
    age: Int
) -> ClosedRange<Int> {

    let minimum: Int

    switch age {

    case 0:
        minimum = 80

    case 1...2:
        minimum = 80

    case 3...5:
        minimum = 80

    case 6...12:
        minimum = 70

    default:
        minimum = 60
    }

    let maximum: Int

    if age >= 13 {
        maximum = Int(
            (208.0 - (0.7 * Double(age))).rounded()
        )
    } else {

        switch age {

        case 0:
            maximum = 160

        case 1...2:
            maximum = 130

        case 3...5:
            maximum = 110

        case 6...12:
            maximum = 100

        default:
            maximum = 100
        }
    }

    return minimum...maximum
}


