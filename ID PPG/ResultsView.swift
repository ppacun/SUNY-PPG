//
//  ResultsView.swift
//  ID PPG
//
//  Created by Dylan Gonzalez on 10/10/2026.
//

import SwiftUI

struct ResultsView: View {
    let averageBPM: Double?
    let confidancePCT: Double

    @StateObject private var camera = CameraManager()
    @AppStorage("patientAge") private var patientAge = 18.0
    var body: some View {
        NavigationStack() {
            VStack(spacing: 20) {
                Text(rangeMessage(patientAge, averageBPM))
                    .font(.largeTitle)
                    .foregroundStyle(rangeColor(patientAge, averageBPM))
                    .multilineTextAlignment(.center)
                Text("Based on a popluation average")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                StaticHeartbeatWave(bpm: averageBPM)
                HStack(){
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(averageBPM.map { String(Int($0.rounded())) } ?? "--")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundStyle(rangeColor(patientAge, averageBPM))
                        
                        Text("BPM")
                            .font(.title2)
                            .foregroundStyle(rangeColor(patientAge, averageBPM))
                    }
                }
                Text("@" + "99.9" + "% confidence" )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
                NavigationLink {
                    PastReadingsView()
                } label: {

                    Text("Save My Reading")
                        .font(.title)
                        .foregroundStyle(.white)
                        .padding()
                        .frame(width: 350, height: 80)
                        .background(.gray)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 25)
                        )
                }
                .padding(.horizontal, 40)
                NavigationLink {
                    HomeView()
                        .navigationBarBackButtonHidden()
                } label: {

                    Text("Not my reading")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding()
                        .frame(width: 250, height: 80)
                        .background(.gray)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 25)
                        )
                }
                .padding(.horizontal, 40)
          
                
                
                
                
                
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    HomeView().navigationBarBackButtonHidden()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        
                    }
                }
            }
        }
    }
}
private func rangeMessage(
    _ patientAge: Double,
    _ averageBPM: Double?
) -> String {

    guard let averageBPM, averageBPM.isFinite else {
        return "No heart rate reading available"
    }

    let range = heartRange(age: Int(patientAge))
    let bpm = Int(averageBPM.rounded())

    if range.contains(bpm) {
        return "Within the resting range for your age."
    } else if bpm < range.lowerBound {
        return "Below the resting range for your age."
    } else {
        return "Above the resting range for your age."
    }
}
private func rangeColor(_ patientAge: Double, _ averageBPM: Double?)-> Color{
    guard let averageBPM, averageBPM.isFinite else {
        return .white
    }

    let range = heartRange(age: Int(patientAge))
    let bpm = Int(averageBPM.rounded())

    if range.contains(bpm) {
        return .green
    } else if bpm < range.lowerBound {
        return .blue
    } else {
        return .red
    }
}

// Same wave shape the live wave uses, so both look alike.
func heartbeatHeight(angle: Double) -> Double {
    sin(angle) + 0.35 * sin(2.0 * angle + 0.5)
}

// A fixed (non-scrolling) wave for a given BPM.
// If bpm is nil, it draws a flat line.
struct StaticHeartbeatWave: View {
    let bpm: Double?
    var seconds: Double = 5
    private let pointsPerSecond = 60.0

    private var points: [Double] {
        let count = Int(seconds * pointsPerSecond)
        guard let bpm = bpm else {
            return Array(repeating: 0, count: count)
        }
        let beatsPerSecond = bpm / 60.0
        return (0..<count).map { i in
            let t = Double(i) / pointsPerSecond
            return heartbeatHeight(angle: t * beatsPerSecond * 2.0 * Double.pi)
        }
    }

    var body: some View {
        WaveformShape(points: points)
            .stroke(Color.red, style: StrokeStyle(lineWidth: 3, lineJoin: .round))
            .frame(height: 100)
    }
}
struct ResultsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ResultsView(
                averageBPM: 72,
                confidancePCT: 99.9,
               // path: .constant(NavigationPath())
            )
        }
    }
}
func heartRange(age: Int) -> ClosedRange<Int> {

    switch age {

    case 0:
        // This is tricky because newborn vs infant is based on months.
        // If you're only storing age in years, use this as a broad infant range.
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

    
