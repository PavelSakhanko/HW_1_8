//
//  CameraService.swift
//  HW_1_8
//
//  Created by Pavel Sakhanko on 18.04.21.
//

import UIKit
import AVFoundation
import Vision

enum SessionSetupResult {
    case success
    case notAuthorized
    case configurationFailed
}

final class CameraService: NSObject {
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "camera session queue")
    private var setupResult: SessionSetupResult = .success
    var bufferSize: CGSize = .zero
    public let session = AVCaptureSession()
    private var isSessionRunning = false
    private var isConfigured = false

    override init() {
        super.init()
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] as [String: Any]
        ObjectRecognitionService().setupVision()
    }

    deinit {
        self.videoOutput.setSampleBufferDelegate(nil, queue: nil)
    }

    public func checkForPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            videoDataOutputQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.videoDataOutputQueue.resume()
            })
        default:
            setupResult = .notAuthorized
        }
    }

    public func configureSession() {
        guard setupResult == .success else { return }
        session.beginConfiguration()
        session.sessionPreset = .vga640x480

        do {
            guard let videoDevice = videoDevice() else { return }
            setVideoDeviceInput(videoDevice: videoDevice)
        }
        setVideoOutput()

        session.commitConfiguration()
        self.isConfigured = true
        self.start()
    }

    private func videoDevice() -> AVCaptureDevice? {
        guard let videoDevice = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        ).devices.first else {
            setupResult = .configurationFailed
            session.commitConfiguration()
            return nil
        }
        return videoDevice
    }

    private func start() {
        videoDataOutputQueue.async {
            if !self.isSessionRunning && self.isConfigured {
                switch self.setupResult {
                case .success:
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                default: break
                }
            }
        }
    }
    
    public func setVideoDeviceInput(videoDevice: AVCaptureDevice) {
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Could not create video device input: \(error)")
            return
        }
    }

    private func setVideoOutput() {
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            setupResult = .configurationFailed
            print("Could not add video data output to the session")
            return
        }
    }

    func captureMedia() {
        if self.setupResult != .configurationFailed {
            videoDataOutputQueue.async {
                let captureConnection = self.videoOutput.connection(with: .video)
                captureConnection?.videoOrientation = .portrait
                captureConnection?.isEnabled = true
                
                guard let videoDevice = self.videoDevice() else { return }

                do {
                    try  videoDevice.lockForConfiguration()
                    let dimensions = CMVideoFormatDescriptionGetDimensions(videoDevice.activeFormat.formatDescription)
                    self.bufferSize.width = CGFloat(dimensions.width)
                    self.bufferSize.height = CGFloat(dimensions.height)
                    videoDevice.unlockForConfiguration()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    private func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        switch UIDevice.current.orientation {
        case UIDeviceOrientation.portraitUpsideDown:
            return .left
        case UIDeviceOrientation.landscapeLeft:
            return .upMirrored
        case UIDeviceOrientation.landscapeRight:
            return .down
        case UIDeviceOrientation.portrait:
            return .up
        default:
            return .up
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        ObjectRecognitionService.detectVisionRequestResults(sampleBuffer: sampleBuffer)
    }
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {}
}
