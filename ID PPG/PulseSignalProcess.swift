//
//  PulseSignalProcess.swift
//  ID PPG
//
//  Created by Elif Yaren Celebi on 9/10/26.
//

import Foundation
import Accelerate

//camera measurement
//stores one measurement from the camera
//each measurement contains the time and RGB values
struct PPGSample {
    let timestamp: TimeInterval
    let red: Double
    let green: Double
    let blue: Double
}

//pulse result
//has the calculated heart rate and signal information

struct PulseResult {
    let bpm: Double
    let signalScore: Double
    let windowSeconds: Double
}


//signal processor
//Track B: Converts camera measurements into BPM here
//
//steps to take:
//1-resample camera measurements
//2-remove brightness drift
//3-apply a 0.7-4 Hz bandpass filter
//4-sse Apple's Accelerate FFT
//5-convert frequency to BPM
//6-calculate a preliminary signal score

struct PulseSignalProcessor {
    let sampleRate = 30.0
    let minBPM = 42.0
    let maxBPM = 240.0
    let minimumSeconds = 10.0

    //function will connect all the processing steps above
    //will return nil when there is not enough or usable data

    func estimate(from samples: [PPGSample]) -> PulseResult? {
        //keep valid measurements and then sort by timestamps
        let data = samples
            .filter {
                $0.timestamp.isFinite &&
                $0.red.isFinite
            }
            .sorted { $0.timestamp < $1.timestamp }
        guard let first = data.first,
              let last = data.last else {
            return nil
        }
        let duration = last.timestamp - first.timestamp
        //at least 10 seconds of measurement required
        guard duration >= minimumSeconds else {
            return nil
        }

        //we should reject recordings with missing frames
        guard Double(data.count) >= duration * sampleRate * 0.65 else {
            return nil
        }

        //1-convert measurements to a uniform 30 Hz
        guard let signal = resample(data) else {
            return nil
        }

        //2-remove changes in brightness
        let cleanSignal = detrend(signal)

        //3-keep frequencies between 0.7 and 4 Hz
        let filteredSignal = bandpassFilter(cleanSignal)

        //4-estimate heart rate using Accelerate FFT
        guard let result = estimateBPM(filteredSignal) else {
            return nil
        }

        //return the result to the rest of the app
        return PulseResult(
            bpm: result.bpm,
            signalScore: result.score,
            windowSeconds: duration
        )
    }

    //resampling
    //the iPhone camera targets 30 fps for now, may change to 60 depending on our testing
    //linear interpolation to estimate measurements at equally spaced time intervals.... (checked with ai for this information and most of the algorithm logic)

    func resample(_ samples: [PPGSample]) -> [Double]? {
        guard let first = samples.first,
              let last = samples.last,
              samples.count >= 2 else {
            return nil
        }
        let startTime = first.timestamp
        let duration = last.timestamp - startTime

        let count = Int(duration * sampleRate) + 1

        var result = [Double]()
        result.reserveCapacity(count)

        var index = 0

        for i in 0..<count {
            //time at we want a red measurement
            let time = startTime + Double(i) / sampleRate

            //to findthe surrounding original measurements
            while index + 1 < samples.count - 1 &&
                  samples[index + 1].timestamp < time {
                index += 1
            }
            let a = samples[index]
            let b = samples[index + 1]
            let timeDifference = b.timestamp - a.timestamp

            //repeated timestamps cannot be interpolated??
            //but large gaps also make interpolation unreliable
            guard timeDifference > 0,
                  timeDifference <= 0.2 else {
                return nil
            }
            //clculate the position between the two samples
            let fraction = min(
                1.0,
                max(0.0, (time - a.timestamp) / timeDifference)
            )
            //interpolate the red value here
            let redValue = a.red + (b.red - a.red) * fraction

            result.append(redValue)
        }

        return result
    }

    //detrending
    //red intensity can slowly increase or decrease because of finger movement pressure or lighting changes
    //these gradual changes are called drift (also ai help a lot here)
    //fit a straight line to the measurements and subtract that line from the signal
    //which is linear polynomial detrending
    func detrend(_ signal: [Double]) -> [Double] {

        guard signal.count >= 2 else {
            return signal
        }
        let count = Double(signal.count)

        let meanX = (count - 1.0) / 2.0
        let meanY = signal.reduce(0.0, +) / count

        var numerator = 0.0
        var denominator = 0.0

        for i in signal.indices {
            let x = Double(i) - meanX
            numerator += x * (signal[i] - meanY)
            denominator += x * x
        }

        //calculate the slope of the best-fitting line here
        let slope = denominator > 0
            ? numerator / denominator
            : 0.0

        //now subtract the fitted line from each value
        return signal.indices.map { i in

            let trend = meanY +
                slope * (Double(i) - meanX)

            return signal[i] - trend
        }
    }
    //bandpass filter
    //project wants a bandpass filter
    //that passes frequencies from 0.7 Hz to 4.0 Hz
    //0.7 Hz * 60 = 42 BPM, 4.0 Hz * 60 = 240 BPM
    //
    //we use a windowed-sinc FIR filter
    //
    //so frequencies below 0.7 Hz and above 4 Hz are reduced rather than deleted

    func bandpassFilter(_ signal: [Double]) -> [Double] {

        guard !signal.isEmpty else {
            return []
        }
        let lowCutoff = minBPM / 60.0
        let highCutoff = maxBPM / 60.0

        //odd number of coefficients gives a centered filter. (logic from internet and ai help here at this section as well)
        let tapCount = 151
        let middle = tapCount / 2
        var coefficients = [Double]()
        for i in 0..<tapCount {

            let n = i - middle
            let coefficient: Double
            if n == 0 {

                coefficient =
                    2.0 * (highCutoff - lowCutoff) / sampleRate
            } else {
                let x = Double(n)
                let highPart =
                    sin(2.0 * Double.pi * highCutoff *
                        x / sampleRate)

                let lowPart =
                    sin(2.0 * Double.pi * lowCutoff *
                        x / sampleRate)
                coefficient =
                    (highPart - lowPart) /
                    (Double.pi * x)
            }

            //different from applying a Hann window here to the signal before the FFT
            let hamming = 0.54 - 0.46 *
                cos(2.0 * Double.pi * Double(i) /
                    Double(tapCount - 1))

            coefficients.append(coefficient * hamming)
        }

        //apply the FIR filter to the signal
        //and eflect the signal at the boundaries to reduce

        var filtered = [Double](
            repeating: 0.0,
            count: signal.count
        )
        for i in signal.indices {

            var sum = 0.0

            for j in 0..<tapCount {

                let offset = j - middle
                var index = i + offset

                // Reflection at the signal boundaries.
                while index < 0 || index >= signal.count {

                    if index < 0 {
                        index = -index - 1
                    } else {
                        index = 2 * signal.count - index - 1
                    }
                }

                sum += signal[index] * coefficients[j]
            }

            filtered[i] = sum
        }

        return filtered
    }

    //acc fft

    //the Fast Fourier Transform (fft) shows the frequencies present in the filtered signal
    //so we find the strongest frequency within the heart-rate range and convert it to a BPM
    //it uses Apple's Accelerate framework
    func estimateBPM(
        _ signal: [Double]
    ) -> (bpm: Double, score: Double)? {

        guard signal.count >= 2 else {
            return nil
        }

        //remove the remaining average here
        let mean = signal.reduce(0.0, +) /
            Double(signal.count)

        let centered = signal.map {
            Float($0 - mean)
        }
        //help with the logic and the overall structure here with ai
        //the radix-2 FFT requires a power-of-two size
        //zero-padding also provides more closely spaced frequency samples but does not add new data
        var fftSize = 1
        while fftSize < centered.count * 4 {
            fftSize *= 2
        }
        let log2N = Int(log2(Double(fftSize)))

        //put the signal into a zero-padded array here
        var padded = [Float](
            repeating: 0,
            count: fftSize
        )
        for i in centered.indices {
            padded[i] = centered[i]
        }
        //accelerate's real fft uses split-complex storage
        //real and imaginary arrays contain diff input values before the forward transform

        var real = [Float](
            repeating: 0,
            count: fftSize / 2
        )
        var imaginary = [Float](
            repeating: 0,
            count: fftSize / 2
        )
        for i in 0..<(fftSize / 2) {
            real[i] = padded[2 * i]
            imaginary[i] = padded[2 * i + 1]
        }
        //fft setup here using Apple's Accelerate
        guard let setup = vDSP_create_fftsetup(
            vDSP_Length(log2N),
            FFTRadix(kFFTRadix2)
        ) else {
            return nil
        }
        defer {
            vDSP_destroy_fftsetup(setup)
        }
        //perform the forward real FFT.
        real.withUnsafeMutableBufferPointer { realBuffer in

            imaginary.withUnsafeMutableBufferPointer {
                imaginaryBuffer in

                var splitComplex = DSPSplitComplex(
                    realp: realBuffer.baseAddress!,
                    imagp: imaginaryBuffer.baseAddress!
                )
                vDSP_fft_zrip(
                    setup,
                    &splitComplex,
                    1,
                    vDSP_Length(log2N),
                    FFTDirection(FFT_FORWARD)
                )
            }
        }
        //calculate the power at each frequency.are we ignorign bin0? what is it exaclty not so sure. help with ai here especially for the structure.
        var powers = [Double](
            repeating: 0.0,
            count: fftSize / 2
        )
        for i in 1..<(fftSize / 2) {
            let re = Double(real[i])
            let im = Double(imaginary[i])
            powers[i] = re * re + im * im
        }

        //each fft represents a specific frequency
        let frequencyResolution =
            sampleRate / Double(fftSize)

        let minimumFrequency = minBPM / 60.0
        let maximumFrequency = maxBPM / 60.0

        var bestIndex = 0
        var bestPower = 0.0
        var totalPower = 0.0

        for i in 1..<(fftSize / 2) {

            let frequency =
                Double(i) * frequencyResolution

            //lookat the physiological BPM range
            if frequency < minimumFrequency ||
               frequency > maximumFrequency {
                continue
            }
            let power = powers[i]
            totalPower += power

            if power > bestPower {
                bestPower = power
                bestIndex = i
            }
        }
        guard bestIndex > 0,
              bestPower > 1e-12,
              totalPower > 0 else {
            return nil
        }
        //peak position by fitting a parabola through the strongest bin and its neighbors
        //helps reduce fft bin-rounding error

        var peakIndex = Double(bestIndex)

        if bestIndex > 1 &&
           bestIndex + 1 < powers.count {
            let left = powers[bestIndex - 1]
            let center = powers[bestIndex]
            let right = powers[bestIndex + 1]

            let denominator =
                left - 2.0 * center + right

            if abs(denominator) > 1e-12 {
                let offset = 0.5 * (left - right) /
                    denominator

                peakIndex += min(0.5, max(-0.5, offset))
            }
        }
        //convert the detected frequency into BPM
        let dominantFrequency =
            peakIndex * frequencyResolution

        let bpm = dominantFrequency * 60.0

        // fraction of searched spectral power concentrated
        // in a small neighborhood around the strongest peak.
        //not an accuracy confidence

        let lower = max(1, bestIndex - 2)
        let upper = min(powers.count - 1, bestIndex + 2)
        let peakRegionPower =
            powers[lower...upper].reduce(0.0, +)
        let score = min(
            1.0,
            max(0.0, peakRegionPower / totalPower)
        )
        return (bpm: bpm, score: score)
    }
}
