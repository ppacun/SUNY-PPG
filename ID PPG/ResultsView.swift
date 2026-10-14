//
//  ResultsView.swift
//  ID PPG
//
//  Created by Dylan Gonzalez on 10/10/2026.
//

import SwiftUI

struct ResultsView: View {
    let averageBPM: Double?

    @StateObject private var camera = CameraManager()

    var body: some View {
        VStack(spacing: 20) {
            Text("Reading Completed")
                .font(.largeTitle)
                .bold()

            CameraView(session: camera.session)
                .frame(width: 260, height: 260)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.gray, lineWidth: 4)
                )
                .overlay {
                    Text(averageBPM.map { String(Int($0.rounded())) } ?? "--")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundStyle(.black)
                }
                .onAppear {
                    camera.turnFlashlightOn()
                }
                .onDisappear {
                    camera.turnFlashlightOff()
                }

            Text("Average Heart Rate")
                .font(.title2)
                .foregroundStyle(.secondary)

            // Solid wave drawn at the average BPM
            StaticHeartbeatWave(bpm: averageBPM)
        }
        .padding()
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
        ResultsView(averageBPM: 72)  // 72 is a placeholder data for xcode's canvas (to test if a value appears)
    }
}


    
