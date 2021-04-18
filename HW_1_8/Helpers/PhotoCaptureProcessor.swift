//
//  PhotoCaptureProcessor.swift
//  HW_1_8
//
//  Created by Pavel Sakhanko on 18.04.21.
//

import Photos

class PhotoCaptureProcessor: NSObject {
    private(set) var requestedPhotoSettings: AVCapturePhotoSettings
    private let willCapturePhotoAnimation: () -> Void
    private let completionHandler: (PhotoCaptureProcessor) -> Void
    var photoData: Data?

    init(
        with requestedPhotoSettings: AVCapturePhotoSettings,
        willCapturePhotoAnimation: @escaping () -> Void,
        completionHandler: @escaping (PhotoCaptureProcessor) -> Void
    ) {
        self.requestedPhotoSettings = requestedPhotoSettings
        self.willCapturePhotoAnimation = willCapturePhotoAnimation
        self.completionHandler = completionHandler
    }
}

extension PhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, resolvedSettings: AVCaptureResolvedPhotoSettings) {
        DispatchQueue.main.async {
            self.willCapturePhotoAnimation()
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, photo: AVCapturePhoto, error: Error?) {
        guard let error = error else {
            photoData = photo.fileDataRepresentation()
            return
        }
        print("Error capturing photo: \(error)")
    }

    func photoOutput(_ output: AVCapturePhotoOutput, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        self.completionHandler(self)
    }
}
