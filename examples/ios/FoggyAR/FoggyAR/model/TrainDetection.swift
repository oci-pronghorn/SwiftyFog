//
//  TrainDetection.swift
//  FoggyAR
//
//  Created by Tobias Schweiger on 10/18/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision

#if APP
public protocol TrainDetectionDelegate: class {
	func foundObject(observation : VNClassificationObservation)
	func detectRequestError(error : Error)
}

public class TrainDetection {
	public weak var delegate: TrainDetectionDelegate?
	private let selectedModel: VNCoreMLModel
	private var identifier = ""
	
	private lazy var request: VNCoreMLRequest = {
		let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: classificationCompleteHandler)
		classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop
		return classificationRequest
	}()
	
	public init() {
		guard let selectedModel = try? VNCoreMLModel(for: Inceptionv3().model) else {
			fatalError("Could not load model. Ensure model has been added to project.")
		}
		self.selectedModel = selectedModel
	}
	
	public func session(didUpdate capturedImage: CVPixelBuffer) {
		let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: capturedImage, options: [:])
		do {
			try imageRequestHandler.perform([self.request])
		} catch {
			delegate?.detectRequestError(error: error)
		}
	}
	
	func classificationCompleteHandler(request: VNRequest, error: Error?) {
		if let error = error {
			delegate?.detectRequestError(error: error)
		}
		else if let observation = request.results?.first as? VNClassificationObservation {
			if identifier != observation.identifier {
				identifier = observation.identifier
				delegate?.foundObject(observation: observation)
			}
		}
	}
}
#endif
