//
//  ID_PPGTests.swift
//  ID PPGTests
//
//  Created by Paul Pacun on 9/14/26.
//

import XCTest
@testable import ID_PPG

final class ID_PPGTests: XCTestCase {

    func testExample() throws {
        // Write your test here and use APIs like `XCTAssert(...)` to check expected conditions.
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest
    }
    // Track B: Test heart rate estimation at 72 BPM
    func test72BPM() {

        // The heart rate we want to simulate
        let expectedBPM = 72.0
        let frequency = expectedBPM / 60.0

        // Generate 15 seconds of data at 30 FPS
        let sampleRate = 30.0
        let duration = 15.0

        var samples: [PPGSample] = []

        for i in 0..<Int(duration * sampleRate) {

            // Timestamp of the current measurement
            let time = Double(i) / sampleRate

            // Simulated red intensity changing with heartbeat
            let red = 190.0 +
                5.0 * sin(2.0 * Double.pi * frequency * time)

            // Add the measurement to our array
            samples.append(
                PPGSample(
                    timestamp: time,
                    red: red,
                    green: 10.0,
                    blue: 2.0
                )
            )
        }

        // Create the signal processor
        let processor = PulseSignalProcessor()

        // Estimate BPM from our simulated data
        let result = processor.estimate(from: samples)

        // Make sure we received a result
        XCTAssertNotNil(result)

        if let result = result {

            print("Expected BPM:", expectedBPM)
            print("Calculated BPM:", result.bpm)
            print("Signal Score:", result.signalScore)

            // Check whether the BPM is within 2 of 72
            XCTAssertEqual(
                result.bpm,
                expectedBPM,
                accuracy: 2.0
            )
        }
    }
    
    
    // Track B: Test several different heart rates.
    func testMultipleHeartRates() {

        // Heart rates required by the project specification.
        let heartRates = [50.0, 72.0, 100.0, 150.0]

        let sampleRate = 30.0
        let duration = 15.0
        let processor = PulseSignalProcessor()

        for expectedBPM in heartRates {

            // Convert BPM to Hz.
            let frequency = expectedBPM / 60.0

            var samples: [PPGSample] = []

            // Generate a simulated signal for this BPM.
            for i in 0..<Int(duration * sampleRate) {

                let time = Double(i) / sampleRate

                let red = 190.0 +
                    5.0 * sin(
                        2.0 * Double.pi * frequency * time
                    )

                samples.append(
                    PPGSample(
                        timestamp: time,
                        red: red,
                        green: 10.0,
                        blue: 2.0
                    )
                )
            }

            // Calculate BPM using our processor.
            let result = processor.estimate(from: samples)

            XCTAssertNotNil(
                result,
                "No result for \(expectedBPM) BPM"
            )

            if let result = result {

                print("Expected: \(expectedBPM) BPM")
                print("Calculated: \(result.bpm) BPM")

                // The result must be within 2 BPM.
                XCTAssertEqual(
                    result.bpm,
                    expectedBPM,
                    accuracy: 2.0
                )
            }
        }
    }
    
    // Track B: Test heart rate estimation with brightness drift
    func testWithDrift() {

        // Simulate a heart rate of 72 BPM
        let expectedBPM = 72.0
        let frequency = expectedBPM / 60.0

        let sampleRate = 30.0
        let duration = 15.0

        var samples: [PPGSample] = []

        for i in 0..<Int(duration * sampleRate) {

            let time = Double(i) / sampleRate

            // Simulated heartbeat
            let heartbeat = 5.0 * sin(
                2.0 * Double.pi * frequency * time
            )

            // Gradually increase brightness over time
            // to simulate changes in finger pressure or lighting
            let drift = 2.0 * time

            // Combine the heartbeat and brightness drift
            let red = 150.0 + heartbeat + drift

            samples.append(
                PPGSample(
                    timestamp: time,
                    red: red,
                    green: 10.0,
                    blue: 2.0
                )
            )
        }

        // Calculate heart rate using our existing processor
        let processor = PulseSignalProcessor()
        let result = processor.estimate(from: samples)

        XCTAssertNotNil(result)

        if let result = result {

            print("Expected BPM:", expectedBPM)
            print("Calculated BPM with drift:", result.bpm)
            print("Signal Score:", result.signalScore)

            // Check whether the estimate is within 2 BPM
            XCTAssertEqual(
                result.bpm,
                expectedBPM,
                accuracy: 2.0
            )
        }
    }
    
    
    // Track B: Test heart rate estimation with random noise
    func testWithNoise() {

        // Simulate a heart rate of 72 BPM
        let expectedBPM = 72.0
        let frequency = expectedBPM / 60.0

        let sampleRate = 30.0
        let duration = 15.0

        var samples: [PPGSample] = []

        for i in 0..<Int(duration * sampleRate) {

            let time = Double(i) / sampleRate

            // Generate the simulated heartbeat
            let heartbeat = 5.0 * sin(
                2.0 * Double.pi * frequency * time
            )

            // Add random noise to the camera measurements
            let noise = Double.random(in: -5.0...5.0)

            // Combine the heartbeat and noise
            let red = 190.0 + heartbeat + noise

            samples.append(
                PPGSample(
                    timestamp: time,
                    red: red,
                    green: 10.0,
                    blue: 2.0
                )
            )
        }

        // Calculate heart rate using our existing processor
        let processor = PulseSignalProcessor()
        let result = processor.estimate(from: samples)

        XCTAssertNotNil(result)

        if let result = result {

            print("Expected BPM:", expectedBPM)
            print("Calculated BPM with noise:", result.bpm)
            print("Signal Score:", result.signalScore)

            // Check whether the result is within 2 BPM
            XCTAssertEqual(
                result.bpm,
                expectedBPM,
                accuracy: 2.0
            )
        }
    }
    
    // Track B: Test heart rate estimation with Gaussian noise
    func testWithGaussianNoise() {

        // Simulate a heart rate of 72 BPM
        let expectedBPM = 72.0
        let frequency = expectedBPM / 60.0

        let sampleRate = 30.0
        let duration = 15.0
        let amplitude = 5.0

        var samples: [PPGSample] = []

        // Fixed seed makes our test reproducible
        var seed: UInt64 = 12345

        // Generate a repeatable random number between 0 and 1
        func randomNumber() -> Double {
            seed = 2862933555777941757 &* seed &+ 3037000493
            return Double(seed >> 11) / 9007199254740992.0
        }

        for i in 0..<Int(duration * sampleRate) {

            let time = Double(i) / sampleRate

            // Simulated heartbeat with amplitude 5
            let heartbeat = amplitude * sin(
                2.0 * Double.pi * frequency * time
            )

            // Box-Muller method generates Gaussian noise
            // with mean 0 and standard deviation 1
            let u1 = max(randomNumber(), 1e-12)
            let u2 = randomNumber()

            let standardNormal =
                sqrt(-2.0 * log(u1)) *
                cos(2.0 * Double.pi * u2)

            // Noise standard deviation equals pulse amplitude
            let noise = amplitude * standardNormal

            // Combine heartbeat and Gaussian noise
            let red = 190.0 + heartbeat + noise

            samples.append(
                PPGSample(
                    timestamp: time,
                    red: red,
                    green: 10.0,
                    blue: 2.0
                )
            )
        }

        // Run our existing signal-processing pipeline
        let processor = PulseSignalProcessor()
        let result = processor.estimate(from: samples)

        XCTAssertNotNil(result)

        if let result = result {

            print("Expected BPM:", expectedBPM)
            print("Calculated BPM with Gaussian noise:", result.bpm)
            print("Signal Score:", result.signalScore)

            // Check whether the calculated BPM is within 2 BPM
            XCTAssertEqual(
                result.bpm,
                expectedBPM,
                accuracy: 2.0
            )
        }
    }

    
    // Track B: Test BPM calculation using Dylan's real camera data
    func testRealCameraData() throws {

        // Find the CSV file in the test bundle.
        guard let fileURL = Bundle(for: type(of: self)).url(
            forResource: "PPG_Testing1RGB",
            withExtension: "csv"
        ) else {
            XCTFail("Could not find CSV file")
            return
        }

        // Read the CSV as text.
        let csv = try String(contentsOf: fileURL, encoding: .utf8)

        var samples: [PPGSample] = []

        // Read each row of the CSV.
        for line in csv.components(separatedBy: .newlines) {

            let columns = line.split(separator: ",")

            // Skip the filename/title and column headers.
            guard columns.count == 4,
                  let timestamp = Double(columns[0]),
                  let red = Double(columns[1]),
                  let green = Double(columns[2]),
                  let blue = Double(columns[3]) else {
                continue
            }

            // Store each real camera measurement.
            samples.append(
                PPGSample(
                    timestamp: timestamp,
                    red: red,
                    green: green,
                    blue: blue
                )
            )
        }

        // Make sure the CSV contained usable measurements.
        XCTAssertFalse(samples.isEmpty)

        guard let startTime = samples.first?.timestamp,
              let endTime = samples.last?.timestamp else {
            return
        }

        print("Total samples:", samples.count)
        print("Recording duration:", endTime - startTime)

        let processor = PulseSignalProcessor()

        // Analyze different parts of Dylan's recording.
        let windows: [(Double, Double)] = [
            (0, 30),
            (5, 30),
            (15, 30),
            (20, 35),
            (30, 45)
        ]

        for (start, end) in windows {

            // Select measurements within this time range.
            let windowSamples = samples.filter { sample in
                let relativeTime = sample.timestamp - startTime
                return relativeTime >= start && relativeTime < end
            }

            // Run our existing signal-processing algorithm.
            let result = processor.estimate(from: windowSamples)

            if let result = result {

                print("Window: \(start)-\(end) seconds")
                print("Calculated BPM:", result.bpm)
                print("Signal Score:", result.signalScore)

                // Check that BPM is in our allowed range.
                XCTAssertTrue(
                    result.bpm >= 42 && result.bpm <= 240
                )

            } else {
                XCTFail("No BPM result for window \(start)-\(end)")
            }
        }
    }




}
