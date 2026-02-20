import SwiftUI
import AVFoundation

@Observable
class FaceSwapViewModel {
    var faceOverlayImage: UIImage?
    var selectedSourceImage: UIImage?
    var detectedFaceRect: CGRect = .zero
    var faceRoll: CGFloat = 0
    var sourceAspectRatio: CGFloat = 1.0
    var isSwapping: Bool = false
    var isProcessingFace: Bool = false
    var showFaceSelection: Bool = false
    var showGallery: Bool = false
    var showNoFaceAlert: Bool = false
    var showCaptureFlash: Bool = false
    var capturedImages: [UIImage] = []
    var viewSize: CGSize = .zero
    var isFrontCamera: Bool = true
    var showDebugOverlay: Bool = false
    var debugLandmarkScreenPoints: [CGPoint] = []

    nonisolated(unsafe) let cameraService = CameraService()
    nonisolated(unsafe) private let engine = FaceSwapEngine()
    nonisolated(unsafe) private var _isProcessing = false
    nonisolated(unsafe) private var _bufferSize: CGSize = .zero

    func startCamera() {
        let engine = self.engine

        cameraService.onFrame = { [weak self] buffer in
            guard let self, !self._isProcessing else { return }
            self._isProcessing = true

            guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else {
                self._isProcessing = false
                return
            }

            let isFront = self.cameraService.currentPosition == .front
            let faceResult = engine.detectFace(in: pixelBuffer, isFrontCamera: isFront)

            if let result = faceResult {
                self._bufferSize = CGSize(
                    width: CGFloat(result.bufferWidth),
                    height: CGFloat(result.bufferHeight)
                )
            }

            var capturedImage: UIImage?
            if engine.captureRequested {
                engine.captureRequested = false
                capturedImage = engine.compositeCapture(pixelBuffer: pixelBuffer)
            }

            Task { @MainActor [weak self] in
                guard let self else { return }
                if let result = faceResult {
                    self.detectedFaceRect = self.convertToScreen(
                        result.boundingBox,
                        bufferWidth: result.bufferWidth,
                        bufferHeight: result.bufferHeight
                    )
                    self.faceRoll = result.roll
                    self.debugLandmarkScreenPoints = result.landmarkPoints.map { point in
                        self.convertPointToScreen(point, bufferWidth: result.bufferWidth, bufferHeight: result.bufferHeight)
                    }
                } else {
                    self.detectedFaceRect = .zero
                    self.faceRoll = 0
                    self.debugLandmarkScreenPoints = []
                }
                if let captured = capturedImage {
                    self.capturedImages.insert(captured, at: 0)
                }
                self._isProcessing = false
            }
        }

        cameraService.start()
    }

    func stopCamera() {
        cameraService.stop()
    }

    func selectSourceImage(_ image: UIImage) {
        selectedSourceImage = image
        isProcessingFace = true
        let engine = self.engine

        Task.detached {
            let overlay = engine.processSourceFace(image)
            let aspectRatio = engine.sourceAspectRatio
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.isProcessingFace = false
                if let overlay {
                    self.faceOverlayImage = overlay
                    self.sourceAspectRatio = aspectRatio
                    self.isSwapping = true
                } else {
                    self.showNoFaceAlert = true
                    self.isSwapping = false
                }
                self.showFaceSelection = false
            }
        }
    }

    func clearFace() {
        faceOverlayImage = nil
        selectedSourceImage = nil
        isSwapping = false
        detectedFaceRect = .zero
    }

    func capture() {
        engine.captureOverlayImage = faceOverlayImage
        engine.captureOverlayRect = detectedFaceRect
        engine.captureViewSize = viewSize
        engine.captureBufferSize = _bufferSize
        engine.captureIsFrontCamera = isFrontCamera
        engine.captureRequested = true

        showCaptureFlash = true
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            showCaptureFlash = false
        }
    }

    func switchCamera() {
        isFrontCamera.toggle()
        cameraService.switchCamera()
    }

    private func convertToScreen(_ visionRect: CGRect, bufferWidth: Int, bufferHeight: Int) -> CGRect {
        guard viewSize.width > 0, viewSize.height > 0 else { return .zero }

        let bw = CGFloat(bufferWidth)
        let bh = CGFloat(bufferHeight)
        guard bw > 0, bh > 0 else { return .zero }

        let videoAspect = bw / bh
        let viewAspect = viewSize.width / viewSize.height

        let scale: CGFloat
        let offsetX: CGFloat
        let offsetY: CGFloat

        if videoAspect > viewAspect {
            scale = viewSize.height / bh
            offsetX = (bw * scale - viewSize.width) / 2
            offsetY = 0
        } else {
            scale = viewSize.width / bw
            offsetX = 0
            offsetY = (bh * scale - viewSize.height) / 2
        }

        let pixelX = visionRect.origin.x * bw
        let pixelY = (1 - visionRect.origin.y - visionRect.height) * bh
        let pixelW = visionRect.width * bw
        let pixelH = visionRect.height * bh

        return CGRect(
            x: pixelX * scale - offsetX,
            y: pixelY * scale - offsetY,
            width: pixelW * scale,
            height: pixelH * scale
        )
    }

    private func convertPointToScreen(_ point: CGPoint, bufferWidth: Int, bufferHeight: Int) -> CGPoint {
        guard viewSize.width > 0, viewSize.height > 0 else { return .zero }

        let bw = CGFloat(bufferWidth)
        let bh = CGFloat(bufferHeight)
        guard bw > 0, bh > 0 else { return .zero }

        let videoAspect = bw / bh
        let viewAspect = viewSize.width / viewSize.height

        let scale: CGFloat
        let offsetX: CGFloat
        let offsetY: CGFloat

        if videoAspect > viewAspect {
            scale = viewSize.height / bh
            offsetX = (bw * scale - viewSize.width) / 2
            offsetY = 0
        } else {
            scale = viewSize.width / bw
            offsetX = 0
            offsetY = (bh * scale - viewSize.height) / 2
        }

        let pixelX = point.x * bw
        let pixelY = (1 - point.y) * bh

        return CGPoint(
            x: pixelX * scale - offsetX,
            y: pixelY * scale - offsetY
        )
    }
}
