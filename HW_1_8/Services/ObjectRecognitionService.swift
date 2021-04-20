//
//  ObjectRecognitionService.swift
//  HW_1_8
//
//  Created by Pavel Sakhanko on 20.04.21.
//

import AVFoundation
import Vision
import AudioToolbox

class ObjectRecognitionService {

    static var requests = [VNRequest]()
    static var visionModel: VNCoreMLModel?

    @discardableResult
    func setupVision() -> NSError? {
        let error: NSError! = nil

        guard let modelURL = Bundle.main.url(forResource: "TVFinder", withExtension: "mlmodelc") else {
            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }

        do {
            ObjectRecognitionService.visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let objectRecognition = VNCoreMLRequest(model: ObjectRecognitionService.visionModel!, completionHandler: { (request, error) in
                
                guard let results = request.results as? [VNClassificationObservation],
                    let _ = results.first else {
                        print("No results found")
                        return
                }
            })
            ObjectRecognitionService.requests = [objectRecognition]
        } catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }
        
        return error
    }

    static func detectVisionRequestResults(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        guard let model = ObjectRecognitionService.visionModel else { return }

        let request = VNCoreMLRequest(model: model) { (finishedReq, _) in
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            guard let firstObservation = results.first else { return }

            if firstObservation.identifier == "tv_images" && firstObservation.confidence * 100 > 99 {
                DispatchQueue.main.async {
                    AudioServicesPlaySystemSound(1518)
                }
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}
