import AVFoundation

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let CFPS = 30
    let session = AVCaptureSession()

    private var cameraDevice: AVCaptureDevice?

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

    override init() {
        super.init()
        setupCamera()
    }

    private func setupCamera() {
        session.beginConfiguration()

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

        CVPixelBufferUnlockBaseAddress(
            pixelBuffer,
            .readOnly
        )

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
        }
    }

    func turnFlashlightOn() {
        guard let device = cameraDevice,
              device.hasTorch else {
            return
        }

        do {
            try device.lockForConfiguration()

            try device.setTorchModeOn(level: 1.0)

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
