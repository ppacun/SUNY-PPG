import SwiftUI

struct ResultsView: View {

    let averageBPM: Double?
    let confidencePCT: Double
    let finalPPGWaveform: [Double]

    @AppStorage("patientAge")
    private var patientAge = 18.0

    @State private var showSaveSheet = false
    @State private var showPastReadings = false

    var body: some View {

        VStack(spacing: 24) {

            // MARK: - Result Header

            VStack(spacing: 8) {

                Text("Heart Rate Result")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(rangeMessage(patientAge, averageBPM))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        rangeColor(
                            patientAge,
                            averageBPM
                        )
                    )
                    .multilineTextAlignment(.center)

                Text("Based on population averages")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)


            // MARK: - BPM

            VStack(spacing: 6) {

                Text("AVERAGE HEART RATE")
                    .font(
                        .system(
                            size: 12,
                            weight: .semibold
                        )
                    )
                    .tracking(2)
                    .foregroundStyle(.secondary)

                HStack(
                    alignment: .lastTextBaseline,
                    spacing: 8
                ) {

                    Text(
                        averageBPM.map {
                            String(
                                Int(
                                    $0.rounded()
                                )
                            )
                        } ?? "--"
                    )
                    .font(
                        .system(
                            size: 86,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .monospacedDigit()
                    .foregroundStyle(
                        rangeColor(
                            patientAge,
                            averageBPM
                        )
                    )

                    Text("BPM")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)


            // MARK: - Waveform

            VStack(spacing: 10) {

                Text("YOUR PULSE WAVEFORM")
                    .font(
                        .system(
                            size: 12,
                            weight: .semibold
                        )
                    )
                    .tracking(2)
                    .foregroundStyle(.secondary)

                if finalPPGWaveform.count > 1 {

                    WaveformShape(
                        points: finalPPGWaveform
                    )
                    .stroke(
                        Color.red,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(height: 100)

                } else {

                    Text("Waveform unavailable")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(height: 100)
                }
            }
            .padding(18)
            .background(
                Color(
                    uiColor:
                        .secondarySystemBackground
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )


            // MARK: - Confidence / Signal Quality

            VStack(spacing: 4) {

                Text("SIGNAL QUALITY")
                    .font(
                        .system(
                            size: 11,
                            weight: .semibold
                        )
                    )
                    .tracking(1.5)
                    .foregroundStyle(.secondary)

                Text(
                    "\(confidencePCT, specifier: "%.1f")%"
                )
                .font(.headline)
                .foregroundStyle(.primary)
            }


            Spacer()


            // MARK: - Save

            Button {

                showSaveSheet = true

            } label: {

                HStack(spacing: 10) {

                    Image(
                        systemName:
                            "square.and.arrow.down"
                    )
                    .font(
                        .system(
                            size: 18,
                            weight: .semibold
                        )
                    )

                    Text("Save My Reading")
                        .font(
                            .system(
                                size: 18,
                                weight: .semibold
                            )
                        )
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                    .fill(Color.red)
                )
            }
            .buttonStyle(.plain)
            .disabled(averageBPM == nil)
            .opacity(
                averageBPM == nil
                ? 0.5
                : 1
            )


            // MARK: - Not My Reading

            NavigationLink {

                HomeView()
                    .navigationBarBackButtonHidden()

            } label: {

                HStack(spacing: 10) {

                    Image(
                        systemName:
                            "arrow.counterclockwise"
                    )
                    .font(
                        .system(
                            size: 16,
                            weight: .medium
                        )
                    )

                    Text("Not My Reading")
                        .font(
                            .system(
                                size: 17,
                                weight: .medium
                            )
                        )
                }
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                    .stroke(
                        Color.secondary.opacity(0.4),
                        lineWidth: 1.5
                    )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 30)

        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)

        .toolbar {

            ToolbarItem(
                placement:
                    .navigationBarLeading
            ) {

                NavigationLink {

                    HomeView()
                        .navigationBarBackButtonHidden()

                } label: {

                    Image(
                        systemName:
                            "chevron.left"
                    )
                }
            }
        }

        .sheet(
            isPresented: $showSaveSheet
        ) {

            if let bpm = averageBPM {

                SaveReadingSheet(
                    bpm: bpm
                ) { activity, date in

                    ReadingStore.shared.add(
                        bpm: bpm,
                        confidence:
                            confidencePCT,
                        activity:
                            activity,
                        date:
                            date
                    )

                    showSaveSheet = false
                    showPastReadings = true
                }
            }
        }

        .navigationDestination(
            isPresented:
                $showPastReadings
        ) {

            PastReadingsView()
        }
    }


    // MARK: - Range Message

    private func rangeMessage(
        _ patientAge: Double,
        _ averageBPM: Double?
    ) -> String {

        guard
            let averageBPM,
            averageBPM.isFinite
        else {

            return
                "No heart rate reading available"
        }

        let range =
            heartRange(
                age: Int(patientAge)
            )

        let bpm =
            Int(
                averageBPM.rounded()
            )

        if range.contains(bpm) {

            return
                "Within the resting range for your age."

        } else if bpm <
                    range.lowerBound {

            return
                "Below the resting range for your age."

        } else {

            return
                "Above the resting range for your age."
        }
    }


    // MARK: - Range Color

    private func rangeColor(
        _ patientAge: Double,
        _ averageBPM: Double?
    ) -> Color {

        guard
            let averageBPM,
            averageBPM.isFinite
        else {

            return .primary
        }

        let range =
            heartRange(
                age: Int(patientAge)
            )

        let bpm =
            Int(
                averageBPM.rounded()
            )

        if range.contains(bpm) {

            return .green

        } else if bpm <
                    range.lowerBound {

            return .blue

        } else {

            return .red
        }
    }


    // MARK: - Heart Rate Range

    private func heartRange(
        age: Int
    ) -> ClosedRange<Int> {

        switch age {

        case 0:
            return 80...160

        case 1...2:
            return 80...130

        case 3...5:
            return 80...110

        case 6...12:
            return 70...100

        default:
            return 60...100
        }
    }
}


// MARK: - Preview

struct ResultsView_Previews:
    PreviewProvider {

    static var previews: some View {

        NavigationStack {

            ResultsView(
                averageBPM: 72,
                confidencePCT: 99.9,
                finalPPGWaveform: []
            )
        }
    }
}
