//
//  SignalQuality.swift
//  ID PPG
//
//  Created by Elif Yaren Celebi on 16/11/26.
//
import Foundation

//evaluate signal quality during the measurement
final class SignalQualityAnalyzer {

    struct Confidence {
        let fftScore: Double
        let bpm: Double
        let fingerCovered: Bool
        let timestamp: TimeInterval
    }

    private var measurements: [Confidence] = []
    
    //tracking possible missed pulse detections
    private var beatChecks = 0
    private var missedBeatChecks = 0

    func addBeatInterval(_ interval: Double, bpm: Double) {
        guard interval > 0, bpm > 0 else {
            return
        }

        //expected time between beats based on BPM
        let expectedInterval = 60.0 / bpm

        beatChecks += 1

        //flag a gap much longer than expected
        if interval > expectedInterval * 1.8 {
            missedBeatChecks += 1
        }
    }
    //see finger coverage separately from BPM measurements
    //will help me record if the finger is positioned regardless if the bpm is not recorded
    private var coverageChecks = 0
    private var coveredChecks = 0

    func addFingerCoverage(_ covered: Bool) {
        coverageChecks += 1

        if covered {
            coveredChecks += 1
        }
    }

    //starting new measurement
    func reset() {
        measurements.removeAll()
        coverageChecks = 0
        coveredChecks = 0
        //reset beat consistency calcs
        beatChecks = 0
        missedBeatChecks = 0
    }

    //storing one measurement
    func add(fftScore: Double, bpm: Double, fingerCovered: Bool, timestamp: TimeInterval) {        guard fftScore.isFinite,
              (0...1).contains(fftScore),
              bpm.isFinite,
              (42...240).contains(bpm) else {
            return
        }
        measurements.append(
            Confidence(
                fftScore: fftScore,
                bpm: bpm,
                fingerCovered: fingerCovered,
                timestamp: timestamp
            )
        )
        print("BPM sample for quality: \(bpm)")
    }

    //see the complete recording
    func finalQuality() -> (percent: Double, label: String) {
        
        guard measurements.count >= 5 else {
            return (percent: 0, label: "Poor Signal")
        }
        
        let count = Double(measurements.count)
        
        //average fft signal score
        let averageFFT = measurements.reduce(0.0) {
            $0 + $1.fftScore
        } / count
        
        //measure bpm stability using standard deviation
        //using the last 20 seconds for BPM stability bc the starting seconds are unstable for both the oximeter and the app
        let lastTimestamp = measurements.last!.timestamp

        let recentMeasurements = measurements.filter {
            $0.timestamp >= lastTimestamp - 20.0
        }

        // Fall back to all measurements if too few are available
        let stabilityMeasurements = recentMeasurements.count >= 5
            ? recentMeasurements
            : measurements

        let stabilityCount = Double(stabilityMeasurements.count)

        // Average BPM during the selected period
        let averageBPM = stabilityMeasurements.reduce(0.0) {
            $0 + $1.bpm
        } / stabilityCount

        // Calculate BPM variation
        let variance = stabilityMeasurements.reduce(0.0) {
            $0 + pow($1.bpm - averageBPM, 2)
        } / stabilityCount

        let bpmSD = sqrt(variance)
        
        //testing
        print("Average BPM (last 20 seconds): \(averageBPM)")
        print("BPM Standard Deviation: \(bpmSD)")
        
        //percentage of finger checks with good coverage
        let coverageRatio = coverageChecks > 0
        ? Double(coveredChecks) / Double(coverageChecks)
        : 0.0
        
        //converting the three measurement into score between 0 and 1
        let fftQuality = min(max(averageFFT, 0), 1)
        //less bpm difference means good stable
        let bpmQuality = max(0, 1 - bpmSD / 20)
        //overall signal quality
        let qualityPCT = (fftQuality + bpmQuality + coverageRatio) / 3 * 100
    
        //calculate beat consistency
        let beatQuality = beatChecks > 0
            ? Double(beatChecks - missedBeatChecks) / Double(beatChecks)
            : 0
            
        
        print("Beat Consistency: \(beatQuality * 100)%")
        print("Possible missed detections: \(missedBeatChecks) / \(beatChecks)")
        
        //testing
        //use beat consistency only when enough intervals were checked
        let qualityPCTWithBeats: Double

        if beatChecks >= 5 {
            qualityPCTWithBeats = (fftQuality + bpmQuality + coverageRatio + beatQuality) / 4 * 100
        } else {
            qualityPCTWithBeats = qualityPCT
        }

        print("Quality with beats: \(qualityPCTWithBeats)%")
        
        //testing the signal quality:
        print("----- SIGNAL QUALITY DEBUG -----")
        print("FFT Quality: \(fftQuality * 100)%")
        print("BPM Stability: \(bpmQuality * 100)%")
        print("Finger Coverage: \(coverageRatio * 100)%")
        print("Final Signal Quality: \(qualityPCT)%")
        print("--------------------------------")
        
        if qualityPCTWithBeats >= 80 {
            return (percent: qualityPCTWithBeats, label: "Good Signal")
        }

        if qualityPCTWithBeats >= 50 {
            return (percent: qualityPCTWithBeats, label: "Moderate Signal")
        }

        return (percent: qualityPCTWithBeats, label: "Poor Signal")
    }
}

