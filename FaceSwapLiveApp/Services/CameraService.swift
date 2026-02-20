import AVFoundation

nonisolated final class CameraService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.faceswap.session")
    private let videoQueue = DispatchQueue(label: "com.faceswap.video")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let positionLock = NSLock()
    private var _currentPosition: AVCaptureDevice.Position = .front

    var currentPosition: AVCaptureDevice.Position {
        positionLock.lock()
        defer { positionLock.unlock() }
        return _currentPosition
    }

    var onFrame: ((CMSampleBuffer) -> Void)?

    func start() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    func switchCamera() {
        positionLock.lock()
        _currentPosition = (_currentPosition == .front) ? .back : .front
        positionLock.unlock()
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }

    private func configureSession() {
        session.beginConfiguration()

        for input in session.inputs {
            session.removeInput(input)
        }

        if session.outputs.isEmpty {
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
        }

        session.sessionPreset = .high

        let position = currentPosition
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        session.commitConfiguration()

        if !session.isRunning {
            session.startRunning()
        }
    }

    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        onFrame?(sampleBuffer)
    }
}
