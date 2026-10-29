//
//  LiveReadingView.swift
//  ID PPG
//
//  Created by Mamadou Wague on 10/7/26.
//  The waveform and BPM are MOCK data until Track B's real output exists.


import SwiftUI
 
struct WaveformShape: Shape {
    let samples: [Double]
 
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard samples.count > 1 else { return path }
        let stepX = rect.width / CGFloat(samples.count - 1)
        let midY = rect.midY
        let scale = rect.height * 0.35
        for (i, value) in samples.enumerated() {
            let x = CGFloat(i) * stepX
            let y = midY - CGFloat(value) * scale
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}
 
struct LiveReadingView: View {
    @ObservedObject var camera: CameraManager
 
    private let mockBPM = 81 // hard coded for now, will change this
 
    @State private var secondsLeft = 5
    @State private var samples: [Double] = Array(repeating: 0, count: 150)
    @State private var time = 0.0
    @State private var phase = 0.0
    @State private var shownBPM: Int? = nil
 
    private let sampleTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()
    private let secondTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
 
    var body: some View {
        VStack(spacing: 24) {
            Text(secondsLeft > 0 ? "Please hold for \(secondsLeft)" : "Done")
                .font(.title2)
                .padding(.horizontal)
 
            WaveformShape(samples: samples)
                .stroke(Color.red, style: StrokeStyle(lineWidth: 4, lineJoin: .round))
                .frame(height: 160)
 
            ZStack {
                CameraView(session: camera.session)
                    .frame(width: 260, height: 260)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.gray, lineWidth: 4)
                    )
 
                VStack(spacing: 0) {
                    Text("Reading")
                        .font(.title2)
                    Text(shownBPM.map { String($0) } ?? "--")
                        .font(.system(size: 72, weight: .bold))
                }
                .foregroundStyle(.black)
            }
 
            Spacer()
 
            Text("Please wait and remain still and quiet")
                .foregroundStyle(.primary)
                .padding(.horizontal)
        }
        .padding(.vertical)
        .onReceive(sampleTimer) { _ in
            time += 1.0 / 30.0
            let currentBPM = Double(mockBPM) + 6.0 * sin(time * 0.5)
            phase += currentBPM / 60.0 * 2.0 * Double.pi / 30.0
            samples.append(sin(phase) + 0.35 * sin(2.0 * phase + 0.5))
            samples.removeFirst()
        }
        .onReceive(secondTimer) { _ in
            if secondsLeft > 0 {
                secondsLeft -= 1
                shownBPM = estimateBPM(from: samples)
            }
        }
    }
 
    // Track B's real pipeline replaces this
    private func estimateBPM(from samples: [Double]) -> Int? {
        var peaks: [Int] = []
        for i in 1..<(samples.count - 1) {
            if samples[i] > samples[i - 1] && samples[i] >= samples[i + 1] && samples[i] > 0.5 {
                peaks.append(i)
            }
        }
        guard peaks.count >= 3 else { return nil }
        let gaps = zip(peaks.dropFirst(), peaks).map { Double($0 - $1) }
        let meanGap = gaps.reduce(0, +) / Double(gaps.count)
        return Int((60.0 * 30.0 / meanGap).rounded())
    }
}
 
private struct LiveReadingPreviewHost: View {
    @StateObject private var camera = CameraManager()
 
    var body: some View {
        LiveReadingView(camera: camera)
    }
}
 
struct LiveReadingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LiveReadingPreviewHost()
        }
    }
}
 
