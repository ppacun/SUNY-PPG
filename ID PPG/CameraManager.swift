import AVFoundation

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let CFPS = 30
    let session = AVCaptureSession()
    
    private var cameraDevice: AVCaptureDevice?
    private var isRecording = false
    private var csvURL: URL?
    @Published var lastCSVURL: URL?
    @Published var avgRed: Int = 0
    @Published var avgGreen: Int = 0
    @Published var avgBlue: Int = 0
    @Published var centerRed: Int = 0
    @Published var centerGreen: Int = 0
    @Published var centerBlue: Int = 0
    @Published var leftRed: Int = 0
    @Published var leftGreen: Int = 0
    @Published var leftBlue: Int = 0
    @Published var rightRed: Int = 0
    @Published var rightGreen: Int = 0
    @Published var rightBlue: Int = 0
    @Published var topRed: Int = 0
    @Published var topGreen: Int = 0
    @Published var topBlue: Int = 0
    @Published var bottomRed: Int = 0
    @Published var bottomGreen: Int = 0
    @Published var bottomBlue: Int = 0
    
    // for the integration from dylans camera code to mine (yaren's) pulse signal processor code
    // Track B: Pulse signal processing
    @Published var estimatedBPM: Double?
    @Published var signalScore: Double = 0

    private let pulseProcessor = PulseSignalProcessor()
    private var pulseSamples: [PPGSample] = []
    private var frameCounter = 0
    //end of the code i added for integration- yaren

    override init() {
        super.init()
        setupCamera()
    }
    //also for integration:
    
    // Track B: Receive RGB measurements from the camera
    private func processPulseSample(
        timestamp: TimeInterval,
        red: Int,
        green: Int,
        blue: Int
    ) {
        let sample = PPGSample(
            timestamp: timestamp,
            red: Double(red),
            green: Double(green),
            blue: Double(blue)
        )

        pulseSamples.append(sample)

        // Keep the most recent 12 seconds
        pulseSamples.removeAll {
            timestamp - $0.timestamp > 12.0
        }

        frameCounter += 1

        // Process approximately once every 30 frames
        guard frameCounter >= 30 else {
            return
        }

        frameCounter = 0

        // Wait until at least 10 seconds of data is available
        guard let first = pulseSamples.first,
              timestamp - first.timestamp >= 10.0 else {
            return
        }

        let result = pulseProcessor.estimate(
            from: pulseSamples
        )

        DispatchQueue.main.async {
            self.estimatedBPM = result?.bpm
            self.signalScore = result?.signalScore ?? 0
        }
    }
    //end of added code

    private func saveReading(
        avgRed: Int,
        avgGreen: Int,
        avgBlue: Int
    ) {
        guard isRecording,
              let url = csvURL else {
            return
        }

        let timestamp = Date().timeIntervalSince1970

        let row = "\(timestamp),\(avgRed),\(avgGreen),\(avgBlue)\n"

        guard let data = row.data(using: .utf8) else {
            return
        }

        do {
            let fileHandle = try FileHandle(forWritingTo: url)

            fileHandle.seekToEndOfFile()
            fileHandle.write(data)

            try fileHandle.close()

        } catch {
            print("Could not write CSV:", error)
        }
    }
    func startRecording() {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let fileName = "PPG_\(Int(Date().timeIntervalSince1970)).csv"
        let url = documents.appendingPathComponent(fileName)

        csvURL = url
        lastCSVURL = url

        let header = "timestamp,avgRed,avgGreen,avgBlue\n"

        do {
            try header.write(
                to: url,
                atomically: true,
                encoding: .utf8
            )

            isRecording = true

            print("Recording started:")
            print(url)

        } catch {
            print("Could not create CSV:", error)
        }
    }

    func stopRecording() {
        isRecording = false

        if let url = csvURL {
            print("Recording stopped:")
            print(url)
        }
    }
    private func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .low
        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            return
        }

        cameraDevice = camera

        do {
            let input = try AVCaptureDeviceInput(device: camera)

            if session.canAddInput(input) {
                session.addInput(input)
            }

        } catch {
            print("Camera input error:", error)
        }
        do{
            try camera.lockForConfiguration()
            camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(CFPS))
            camera.activeVideoMaxFrameDuration = CMTime(value: 1, timescale:  CMTimeScale(CFPS))
            camera.unlockForConfiguration()
        }catch{
            print("Could not set FPS to 30")
        }

        // Get raw video frames
        let videoOutput = AVCaptureVideoDataOutput()

        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String:
                kCVPixelFormatType_32BGRA
        ]

        videoOutput.alwaysDiscardsLateVideoFrames = true

        let queue = DispatchQueue(label: "cameraFrameQueue")

        videoOutput.setSampleBufferDelegate(
            self,
            queue: queue
        )

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {

        guard let pixelBuffer =
            CMSampleBufferGetImageBuffer(sampleBuffer)
        else {
            return
        }

        CVPixelBufferLockBaseAddress(
            pixelBuffer,
            .readOnly
        )

        guard let baseAddress =
            CVPixelBufferGetBaseAddress(pixelBuffer)
        else {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            return
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        // Center of camera frame
        let centerX = width / 2
        let centerY = height / 2

        let leftX = width / 4
        let rightX = (width * 3) / 4

        let topY = height / 4
        let bottomY = (height * 3) / 4

        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        func pixelIndex(x: Int, y: Int) -> Int {
            return y * bytesPerRow + x * 4
        }

        let centerPixelIndex = pixelIndex(
            x: centerX,
            y: centerY
        )

        let leftPixelIndex = pixelIndex(
            x: leftX,
            y: centerY
        )

        let rightPixelIndex = pixelIndex(
            x: rightX,
            y: centerY
        )

        let topPixelIndex = pixelIndex(
            x: centerX,
            y: topY
        )

        let bottomPixelIndex = pixelIndex(
            x: centerX,
            y: bottomY
        )

        // BGRA format
        let centerBlueValue = buffer[centerPixelIndex]
        let centerGreenValue = buffer[centerPixelIndex + 1]
        let centerRedValue = buffer[centerPixelIndex + 2]
        let leftBlueValue = buffer[leftPixelIndex]
        let leftGreenValue = buffer[leftPixelIndex + 1]
        let leftRedValue = buffer[leftPixelIndex + 2]
        let rightBlueValue = buffer[rightPixelIndex]
        let rightGreenValue = buffer[rightPixelIndex + 1]
        let rightRedValue = buffer[rightPixelIndex + 2]
        let topBlueValue = buffer[topPixelIndex]
        let topGreenValue = buffer[topPixelIndex + 1]
        let topRedValue = buffer[topPixelIndex + 2]
        let bottomBlueValue = buffer[bottomPixelIndex]
        let bottomGreenValue = buffer[bottomPixelIndex + 1]
        let bottomRedValue = buffer[bottomPixelIndex + 2]
        let avgR = (
            Int(centerRedValue) +
            Int(leftRedValue) +
            Int(rightRedValue) +
            Int(topRedValue) +
            Int(bottomRedValue)
        ) / 5

        let avgG = (
            Int(centerGreenValue) +
            Int(leftGreenValue) +
            Int(rightGreenValue) +
            Int(topGreenValue) +
            Int(bottomGreenValue)
        ) / 5

        let avgB = (
            Int(centerBlueValue) +
            Int(leftBlueValue) +
            Int(rightBlueValue) +
            Int(topBlueValue) +
            Int(bottomBlueValue)
        ) / 5

        CVPixelBufferUnlockBaseAddress(
            pixelBuffer,
            .readOnly
        )
        saveReading(
            avgRed: avgR,
            avgGreen: avgG,
            avgBlue: avgB
        )
        //adding here for the integration-yaren
        // Track B: Send live RGB measurements to BPM processor
        let timestamp = CMSampleBufferGetPresentationTimeStamp(
            sampleBuffer
        ).seconds

        if timestamp.isFinite {
            processPulseSample(
                timestamp: timestamp,
                red: avgR,
                green: avgG,
                blue: avgB
            )
        }
        //end of added code
        
        DispatchQueue.main.async {
            self.centerRed = Int(centerRedValue)
            self.centerGreen = Int(centerGreenValue)
            self.centerBlue = Int(centerBlueValue)
            self.rightRed = Int(rightRedValue)
            self.rightGreen = Int(rightGreenValue)
            self.rightBlue = Int(rightBlueValue)
            self.leftRed = Int(leftRedValue)
            self.leftGreen = Int(leftGreenValue)
            self.leftBlue = Int(leftBlueValue)
            self.bottomRed = Int(bottomRedValue)
            self.bottomGreen = Int(bottomGreenValue)
            self.bottomBlue = Int(bottomBlueValue)
            self.topRed = Int(topRedValue)
            self.topGreen = Int(topGreenValue)
            self.topBlue = Int(topBlueValue)
            self.avgRed = avgR
            self.avgGreen = avgG
            self.avgBlue = avgB
        }
    }

    func turnFlashlightOn() {
        guard let device = cameraDevice,
              device.hasTorch else {
            return
        }

        do {
            try device.lockForConfiguration()

            try device.setTorchModeOn(level: 0.25)

            device.unlockForConfiguration()

        } catch {
            print("Could not turn flashlight on:", error)
        }
    }

    func turnFlashlightOff() {
        guard let device = cameraDevice,
              device.hasTorch else {
            return
        }

        do {
            try device.lockForConfiguration()

            device.torchMode = .off

            device.unlockForConfiguration()

        } catch {
            print("Could not turn flashlight off:", error)
        }
    }
}
