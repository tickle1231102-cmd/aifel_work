import AVFoundation
import CoreImage
import UIKit
import Photos
import Combine

/// 카메라 세션 관리, 실시간 프레임에 필터 적용, 사진 촬영/저장을 담당하는 클래스.
final class CameraManager: NSObject, ObservableObject {

    // MARK: - Published state (UI에서 관찰)

    @Published var currentFrame: CGImage?
    @Published var selectedStyle: FilmStyle = .original
    @Published var isAuthorized = false
    @Published var authorizationDenied = false
    @Published var capturedImage: UIImage?
    @Published var isUsingFrontCamera = false
    @Published var didSavePhoto = false

    // MARK: - AVFoundation

    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoInput: AVCaptureDeviceInput?

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    // 촬영 시 현재 선택된 스타일을 그대로 적용하기 위해 저장
    private var pendingStyle: FilmStyle = .original

    override init() {
        super.init()
    }

    // MARK: - 권한

    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    self?.authorizationDenied = !granted
                    if granted {
                        self?.configureSession()
                    }
                }
            }
        default:
            isAuthorized = false
            authorizationDenied = true
        }
    }

    // MARK: - 세션 구성

    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            self.addVideoInput(front: false)

            if self.session.canAddOutput(self.videoOutput) {
                self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.session.addOutput(self.videoOutput)
            }

            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }

            self.updateVideoOrientation()
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    private func addVideoInput(front: Bool) {
        if let existing = videoInput {
            session.removeInput(existing)
        }
        let position: AVCaptureDevice.Position = front ? .front : .back
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        if session.canAddInput(input) {
            session.addInput(input)
            videoInput = input
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    /// 전/후면 카메라 전환
    func flipCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            let goingFront = !self.isUsingFrontCamera
            self.addVideoInput(front: goingFront)
            self.updateVideoOrientation()
            self.session.commitConfiguration()
            DispatchQueue.main.async {
                self.isUsingFrontCamera = goingFront
            }
        }
    }

    private func updateVideoOrientation() {
        guard let connection = videoOutput.connection(with: .video) else { return }
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = isUsingFrontCamera
        }
    }

    // MARK: - 사진 촬영

    func capturePhoto() {
        pendingStyle = selectedStyle
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    /// 촬영한 사진을 사진 앱(Photos)에 저장
    func savePhotoToLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, _ in
                DispatchQueue.main.async {
                    self.didSavePhoto = success
                }
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                        didOutput sampleBuffer: CMSampleBuffer,
                        from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        // 실시간 프리뷰에서는 매 프레임 날짜 스탬프를 새로 그리는 비용을 피한다 (촬영본에만 적용).
        let filtered = FilmFilterEngine.apply(selectedStyle, to: ciImage, includeDateStamp: false)

        guard let cgImage = ciContext.createCGImage(filtered, from: filtered.extent) else { return }

        DispatchQueue.main.async { [weak self] in
            self?.currentFrame = cgImage
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                      didFinishProcessingPhoto photo: AVCapturePhoto,
                      error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let uiImage = UIImage(data: data),
              let ciImage = CIImage(image: uiImage) else { return }

        let filtered = FilmFilterEngine.apply(pendingStyle, to: ciImage, includeDateStamp: true)
        guard let cgImage = ciContext.createCGImage(filtered, from: filtered.extent) else { return }

        let finalImage = UIImage(cgImage: cgImage, scale: uiImage.scale, orientation: uiImage.imageOrientation)

        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = finalImage
            self?.savePhotoToLibrary(finalImage)
        }
    }
}
