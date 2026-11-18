//
//  CameraView.swift
//  ID PPG
//
//  Created by Dylan Gonzalez on 29/9/2026.
//
import SwiftUI
import AudioToolbox
import Combine

struct ReadingView: View {

    @Environment(\.dismiss) private var dismiss

    @StateObject private var camera = CameraManager()
    @StateObject private var ecgWave = ECGHeartbeatWave()

    @State private var showResults = false
    @State private var showWarning = true
    @State private var showIncomplete = false
    @State private var neverShowWarningA = false

    @State private var isReading = false
    @State private var readingComplete = false

    @State private var startTime: Date?
    @State private var secondsRemaining = 60
    @State private var lastFingerDetectedTime: Date?

    @State private var bpmValuesThisReading: [Double] = []
    @State private var finalPPGWaveform: [Double] = []

    @State private var showRGBValues = false
    @State private var rgbDisplayTask: DispatchWorkItem?
    @AppStorage("neverShowWarning")
    private var neverShowWarning = false

    private let minRVal = 110//140
    private let maxBVal = 70
    private let maxGVal = 130// G > 40 pushing to hard.

    private let readTime = 60
    private let readingDuration: TimeInterval = 60
    
    
    private var pressingTooHard: Bool {
        fingerDetected && camera.centerGreen > 40
    }

    // MARK: - Average BPM

    private var averageBPM: Double? {

        guard !bpmValuesThisReading.isEmpty else {
            return nil
        }

        return bpmValuesThisReading.reduce(0, +)
            / Double(bpmValuesThisReading.count)
    }
    private var validMeasurementPosition: Bool {
        fingerDetected && !pressingTooHard
    }

    // MARK: - Signal Quality

    private var signalQualityPercent: Double {

        min(
            max(camera.signalScore * 100.0, 0),
            100
        )
    }


    // MARK: - Finger Detection

    private var leftFinger: Bool {

        camera.topRed > minRVal &&
        camera.topBlue < maxBVal &&
        camera.topGreen < maxGVal
    }


    private var rightFinger: Bool {

        camera.bottomRed > minRVal &&
        camera.bottomBlue < maxBVal &&
        camera.bottomGreen < maxGVal
    }


    private var topFinger: Bool {

        camera.leftRed > minRVal &&
        camera.leftBlue < maxBVal &&
        camera.leftGreen < maxGVal
    }


    private var centerFinger: Bool {

        camera.centerRed > minRVal &&
        camera.centerBlue < maxBVal &&
        camera.centerGreen < maxGVal
    }


    private var bottomFinger: Bool {

        camera.rightRed + 10 > minRVal &&
        camera.rightBlue < maxBVal &&
        camera.rightGreen < maxGVal
    }


    private var fingerDetected: Bool {

        centerFinger &&
        bottomFinger &&
        topFinger &&
        rightFinger &&
        leftFinger
    }


    // MARK: - Progress

    private var readingProgress: Double {

        guard isReading else {
            return 0
        }

        return min(
            max(
                Double(readTime - secondsRemaining)
                    / Double(readTime),
                0
            ),
            1
        )
    }


    // MARK: - Guidance

    private var guidanceIcon: String {
        if pressingTooHard {
               return "hand.raised.fill"
           }
        
        if fingerDetected {
            return isReading
                ? "waveform.path.ecg"
                : "checkmark.circle.fill"
        }

        if centerFinger && topFinger && leftFinger && rightFinger {
            return "arrow.down"
        }

        if centerFinger && bottomFinger && leftFinger && rightFinger {
            return "arrow.up"
        }

        if topFinger && rightFinger {
            return "arrow.down.right"
        }

        if topFinger && leftFinger {
            return "arrow.down.left"
        }

        if bottomFinger && rightFinger {
            return "arrow.up.right"
        }

        if bottomFinger && leftFinger {
            return "arrow.up.left"
        }

        if centerFinger {
            return "record.circle"
        }

        if topFinger {
            return "arrow.down"
        }

        if bottomFinger {
            return "arrow.up"
        }

        if leftFinger {
            return "arrow.left"
        }

        if rightFinger {
            return "arrow.right"
        }

        return "hand.point.up.left.fill"
    }


    private var guidanceTitle: String {
        if pressingTooHard {
                return "Reduce Finger Pressure"
            }

        if fingerDetected {

            if isReading {
                return "Measuring Heart Rate"
            }

            return "Finger Detected"
        }

        if centerFinger {
            return "Adjust Your Finger"
        }

        return "Place Finger on Camera"
    }


    private var guidanceText: String {
        if pressingTooHard {
                return "Lighten the pressure on the camera while keeping it fully covered."
            }

        if fingerDetected {

            if isReading {
                return "Keep your finger still and maintain gentle pressure."
            }

            return "Your finger is positioned correctly."
        }

        if centerFinger && topFinger && leftFinger && rightFinger {
            return "Move your finger down slightly."
        }

        if centerFinger && bottomFinger && leftFinger && rightFinger {
            return "Move your finger up slightly."
        }

        if topFinger && rightFinger {
            return "Move your finger down and right."
        }

        if topFinger && leftFinger {
            return "Move your finger down and left."
        }

        if bottomFinger && rightFinger {
            return "Move your finger up and right."
        }

        if bottomFinger && leftFinger {
            return "Move your finger up and left."
        }

        if centerFinger {
            return "Move your finger closer to fully cover the camera."
        }

        if topFinger {
            return "Move your finger down."
        }

        if bottomFinger {
            return "Move your finger up."
        }

        if leftFinger {
            return "Move your finger left."
        }

        if rightFinger {
            return "Move your finger right."
        }

        return "Cover the rear camera and flash completely with your fingertip."
    }


    // MARK: - Body

    var body: some View {

        ScrollView {

            VStack(spacing: 22) {

                statusSection

                cameraSection

                guidanceSection

                if isReading {
                    measurementSection
                }

                Text(
                    "Stay still and keep your finger in place until the measurement finishes."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 36)
        }
        .background(
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
        )

        .navigationTitle("Heart Rate")
        .navigationBarTitleDisplayMode(.inline)

        .onAppear {

            showWarning = !neverShowWarning

            camera.turnFlashlightOn()
        }

        .onDisappear {

            camera.turnFlashlightOff()

            ecgWave.stop()
        }

        .onReceive(
            camera.$centerRed.dropFirst()
        ) { _ in

            handleFingerDetection()
        }

        .onReceive(
            camera.$estimatedBPM.dropFirst()
        ) { latestBPM in

            ecgWave.beatsPerMinute =
                latestBPM

            if isReading,
               let latestBPM,
               latestBPM.isFinite {

                bpmValuesThisReading.append(
                    latestBPM
                )
            }
        }

        .navigationDestination(
            isPresented: $showResults) {
            ResultsView(
                averageBPM: averageBPM,
                confidencePCT: camera.finalQualityPCT,
                signalQualityLabel: camera.finalQualityLabel,
                finalPPGWaveform: finalPPGWaveform
            )
        }

        .sheet(
            isPresented: Binding(
                get: {
                    showWarning &&
                    !neverShowWarning
                },
                set: {
                    showWarning = $0
                }
            )
        ) {

            preparationSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }

        .sheet(
            isPresented: $showIncomplete
        ) {

            incompleteSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }


    // MARK: - Status

    private var statusSection: some View {

        HStack(spacing: 8) {

            Circle()
                .fill(
                    fingerDetected
                    ? Color.red
                    : Color.secondary.opacity(0.45)
                )
                .frame(
                    width: 8,
                    height: 8
                )

            Text(
                fingerDetected
                ? isReading
                    ? "Measuring"
                    : "Ready to Measure"
                : "Waiting for Finger"
            )
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(
                    Color.secondary.opacity(0.12)
                )
        )
    }


    // MARK: - Camera

    private var cameraSection: some View {

        ZStack {

            Circle()
                .stroke(
                    Color.secondary.opacity(0.18),
                    lineWidth: 9
                )
                .frame(
                    width: 284,
                    height: 284
                )

            if isReading {

                Circle()
                    .trim(
                        from: 0,
                        to: readingProgress
                    )
                    .stroke(
                        Color.red,
                        style: StrokeStyle(
                            lineWidth: 9,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(
                        .degrees(-90)
                    )
                    .frame(
                        width: 284,
                        height: 284
                    )
                    .animation(
                        .linear(duration: 0.2),
                        value: readingProgress
                    )
            }

            CameraView(
                session: camera.session
            )
            .frame(
                width: 260,
                height: 260
            )
            .clipShape(Circle())

            Circle()
                .stroke(
                    fingerDetected
                    ? Color.red.opacity(0.65)
                    : Color.secondary.opacity(0.28),
                    lineWidth: 2
                )
                .frame(
                    width: 260,
                    height: 260
                )

            if showRGBValues {

                VStack(spacing: 5) {

                    Text("RGB")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            .white.opacity(0.8)
                        )

                    Text(
                        "R: \(Int(camera.centerRed))"
                    )
                    .foregroundStyle(.red)

                    Text(
                        "G: \(Int(camera.centerGreen))"
                    )
                    .foregroundStyle(.green)

                    Text(
                        "B: \(Int(camera.centerBlue))"
                    )
                    .foregroundStyle(.blue)
                }
                .font(
                    .system(
                        size: 22,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    Color.black.opacity(0.55)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                )

            } else if isReading {

                VStack(spacing: 2) {

                    Text(
                        camera.estimatedBPM.map {
                            String(
                                Int(
                                    $0.rounded()
                                )
                            )
                        } ?? "--"
                    )
                    .font(
                        .system(
                            size: 68,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .monospacedDigit()
                    .foregroundStyle(.white)

                    Text("BPM")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            .white.opacity(0.85)
                        )
                }
            }
        }
        .contentShape(Circle())
        .onTapGesture {
            showCurrentRGBValues()
        }
        .accessibilityElement(
            children: .combine
        )
        .accessibilityLabel(
            isReading
            ? "Current heart rate measurement"
            : "Camera preview"
        )
    }


    // MARK: - Guidance

    private var guidanceSection: some View {

        VStack(spacing: 8) {

            Image(
                systemName: guidanceIcon
            )
            .font(
                .system(
                    size: 26,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                fingerDetected
                ? Color.red
                : Color.secondary
            )


            Text(guidanceTitle)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)


            Text(guidanceText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
    }


    // MARK: - Measurement

    private var measurementSection: some View {

        VStack(spacing: 16) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text("Measurement")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(
                        "\(secondsRemaining) seconds remaining"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                }


                Spacer()


                Text(
                    "\(Int(readingProgress * 100))%"
                )
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(.primary)
            }


            ProgressView(
                value: readingProgress
            )
            .tint(.red)


            WaveformShape(
                points: ecgWave.points
            )
            .stroke(
                Color.red,
                style: StrokeStyle(
                    lineWidth: 2.5,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .frame(height: 70)


            HStack(spacing: 6) {

                Image(
                    systemName:
                        "waveform.path.ecg"
                )

                Text(
                    "Signal may stabilize as the measurement continues."
                )
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
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
                cornerRadius: 20,
                style: .continuous
            )
        )
    }


    // MARK: - Preparation Sheet

    private var preparationSheet: some View {

        VStack(spacing: 22) {

            Spacer()


            Image(
                systemName:
                    "heart.text.clipboard.fill"
            )
            .font(.system(size: 44))
            .foregroundStyle(.red)


            VStack(spacing: 6) {

                Text("Before Your Reading")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(
                    "For a more consistent measurement:"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }


            VStack(spacing: 14) {

                preparationRow(
                    icon:
                        "speaker.slash.fill",
                    text:
                        "Remain quiet"
                )

                preparationRow(
                    icon:
                        "figure.stand",
                    text:
                        "Remain still"
                )

                preparationRow(
                    icon:
                        "wind",
                    text:
                        "Relax and breathe normally"
                )
            }
            .padding(16)
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


            Toggle(
                "Don't show this again",
                isOn:
                    $neverShowWarningA
            )
            .tint(.red)


            Button {

                if neverShowWarningA {
                    neverShowWarning = true
                }

                showWarning = false

            } label: {

                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(height: 50)
            }
            .buttonStyle(
                .borderedProminent
            )
            .tint(.red)


            Spacer()
        }
        .padding(.horizontal, 24)
        .background(
            Color(
                uiColor:
                    .systemBackground
            )
        )
    }


    // MARK: - Preparation Row

    private func preparationRow(
        icon: String,
        text: String
    ) -> some View {

        HStack(spacing: 12) {

            Image(systemName: icon)
                .foregroundStyle(.red)
                .frame(width: 24)

            Text(text)
                .foregroundStyle(.primary)

            Spacer()
        }
    }


    // MARK: - Incomplete Sheet

    private var incompleteSheet: some View {

        VStack(spacing: 22) {

            Spacer()


            Image(
                systemName:
                    "heart.slash.fill"
            )
            .font(.system(size: 44))
            .foregroundStyle(.red)


            VStack(spacing: 8) {

                Text("Reading Incomplete")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(
                    "Your finger moved before the measurement finished. Retaking it may provide a more consistent result."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }


            Button {

                showIncomplete = false

                resetReading()

            } label: {

                Text("Retake Reading")
                    .fontWeight(.semibold)
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(height: 50)
            }
            .buttonStyle(
                .borderedProminent
            )
            .tint(.red)


            Button {

                showIncomplete = false

                finalPPGWaveform =
                    ecgWave.points

                camera.stopRecording()
                ecgWave.stop()

                isReading = false
                readingComplete = true
                secondsRemaining = 0
                startTime = nil

                showResults = true

            } label: {

                Text("View Current Result")
                    .fontWeight(.medium)
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)


            Spacer()
        }
        .padding(.horizontal, 24)
        .background(
            Color(
                uiColor:
                    .systemBackground
            )
        )
    }


    // MARK: - Finger Detection Handler

    private func handleFingerDetection() {

        if showWarning ||
            showIncomplete ||
            readingComplete {

            return
        }
        let detected = validMeasurementPosition
        //finger coverage info to signal quality
        camera.updateFingerCoverage(detected)
        


        if detected {

            lastFingerDetectedTime =
                Date()
        }


        let fingerStillPresent =

            detected ||

            (
                lastFingerDetectedTime.map {

                    Date()
                        .timeIntervalSince(
                            $0
                        ) < 0.5

                } ?? false
            )


        if fingerStillPresent {

            if !isReading {

                startMeasurement()
            }


            updateTimer()

        } else if isReading {

            stopMeasurementEarly()
        }
    }


    // MARK: - Start Measurement

    private func startMeasurement() {

        isReading = true

        startTime = Date()

        secondsRemaining =
            readTime

        bpmValuesThisReading = []

        finalPPGWaveform = []

        ecgWave.beatsPerMinute =
            camera.estimatedBPM

        ecgWave.start()

        camera.startRecording()
    }


    // MARK: - Update Timer

    private func updateTimer() {

        guard
            isReading,
            let start = startTime
        else {
            return
        }


        let elapsed =

            Date()
                .timeIntervalSince(start)


        secondsRemaining =

            max(
                0,
                Int(
                    ceil(
                        readingDuration
                            - elapsed
                    )
                )
            )


        if elapsed >=
            readingDuration {

            completeMeasurement()
        }
    }


    // MARK: - Complete Measurement

    private func completeMeasurement() {

        AudioServicesPlaySystemSound(
            kSystemSoundID_Vibrate
        )

        finalPPGWaveform =
            ecgWave.points

        ecgWave.stop()

        isReading = false
        readingComplete = true
        secondsRemaining = 0
        startTime = nil

        //calculate signal quality before opening Results
        camera.finishRecording {
            showResults = true
        }
    }


    // MARK: - Stop Early

    private func stopMeasurementEarly() {

        camera.stopRecording()

        ecgWave.stop()

        isReading = false

        startTime = nil


        if secondsRemaining
            <= readTime / 2 {

            finalPPGWaveform =
                ecgWave.points

            showIncomplete = true
        }


        secondsRemaining =
            readTime
    }


    // MARK: - Reset

    private func resetReading() {

        camera.stopRecording()

        ecgWave.stop()

        isReading = false

        readingComplete = false

        startTime = nil

        secondsRemaining =
            readTime

        bpmValuesThisReading = []

        finalPPGWaveform = []

        lastFingerDetectedTime = nil
    }
    private func showCurrentRGBValues() {

        rgbDisplayTask?.cancel()

        withAnimation(
            .easeInOut(duration: 0.15)
        ) {
            showRGBValues = true
        }

        let task = DispatchWorkItem {

            withAnimation(
                .easeInOut(duration: 0.2)
            ) {
                showRGBValues = false
            }
        }

        rgbDisplayTask = task

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 2.5,
            execute: task
        )
    }
}


// MARK: - Waveform

struct WaveformShape: Shape {

    let points: [Double]

    func path(
        in rect: CGRect
    ) -> Path {

        var path = Path()

        guard points.count > 1 else {
            return path
        }


        let xSpacing =
            rect.width
            / CGFloat(
                points.count - 1
            )

        let centerY =
            rect.midY

        let heightScale =
            rect.height * 0.35


        for (
            index,
            height
        ) in points.enumerated() {

            let x =
                CGFloat(index)
                * xSpacing

            let y =
                centerY
                - CGFloat(height)
                * heightScale


            if index == 0 {

                path.move(
                    to:
                        CGPoint(
                            x: x,
                            y: y
                        )
                )

            } else {

                path.addLine(
                    to:
                        CGPoint(
                            x: x,
                            y: y
                        )
                )
            }
        }


        return path
    }
}


// MARK: - ECG Heartbeat Wave

final class ECGHeartbeatWave:
    ObservableObject {

    @Published
    var points: [Double] =
        Array(
            repeating: 0,
            count: 150
        )

    var beatsPerMinute: Double?

    private var phase = 0.0
    private var timer: Timer?

    private let updatesPerSecond =
        30.0


    func start() {

        stop()

        phase = 0

        points =
            Array(
                repeating: 0,
                count: 150
            )


        timer =
            Timer.scheduledTimer(
                withTimeInterval:
                    1.0
                    / updatesPerSecond,
                repeats: true
            ) { [weak self] _ in

                self?.addNextPoint()
            }
    }


    func stop() {

        timer?.invalidate()

        timer = nil
    }


    private func addNextPoint() {

        var value = 0.0


        if let bpm =
            beatsPerMinute,
           bpm.isFinite,
           bpm > 0 {

            phase +=
                (bpm / 60.0)
                / updatesPerSecond

            phase.formTruncatingRemainder(
                dividingBy: 1.0
            )


            func peak(
                _ center: Double,
                _ width: Double,
                _ height: Double
            ) -> Double {

                let distance =
                    (phase - center)
                    / width

                return height
                    * exp(
                        -0.5
                        * distance
                        * distance
                    )
            }


            value =

                peak(
                    0.18,
                    0.035,
                    0.12
                )

                - peak(
                    0.39,
                    0.012,
                    0.18
                )

                + peak(
                    0.42,
                    0.008,
                    1.0
                )

                - peak(
                    0.45,
                    0.012,
                    0.30
                )

                + peak(
                    0.68,
                    0.075,
                    0.23
                )
        }


        points.append(value)

        points.removeFirst()
    }


    deinit {

        timer?.invalidate()
    }
}


// MARK: - Preview

struct ReadingView_Previews:
    PreviewProvider {

    static var previews:
        some View {

        NavigationStack {

            ReadingView()
        }
    }
}
