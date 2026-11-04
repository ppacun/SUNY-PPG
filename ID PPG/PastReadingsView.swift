//
//  PastReadingsView.swift
//  ID PPG
//
//  Created by Mamadou Wague on 10/29/2026
//
import SwiftUI

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

    var body: some View {
        VStack(spacing: 0) {
            summaryHeader
                .padding()

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

struct PastReadingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PastReadingsView()
        }
    }
}
