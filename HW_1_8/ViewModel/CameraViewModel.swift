//
//  CameraViewModel.swift
//  HW_1_8
//
//  Created by Pavel Sakhanko on 18.04.21.
//

import AVFoundation

final class CameraViewModel: ObservableObject {
    
    private let service = CameraService()
    var session: AVCaptureSession

    init() {
        self.session = service.session
    }

    func configure() {
        service.checkForPermissions()
        service.configureSession()
    }

    func capturePhoto() {
        service.capturePhoto()
    }
}
