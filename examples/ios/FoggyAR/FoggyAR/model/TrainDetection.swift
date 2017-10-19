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

public class TrainDetection : NSObject {
	private var visionRequests = [VNRequest]()
	private let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml")
	private let sceneView : ARSCNView
	
	public init(sceneView : ARSCNView) {
		self.sceneView = sceneView

		super.init()
		
		//self.sceneView.session.delegate = self
		
		guard let selectedModel = try? VNCoreMLModel(for: Inceptionv3().model) else {
			fatalError("Could not load model. Ensure model has been added to project.")
		}
		
		let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: classificationCompleteHandler)
		classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
		visionRequests = [classificationRequest]
		
		// Begin Loop to Update CoreML
		loopCoreMLUpdate()
	}
	
	func loopCoreMLUpdate() {
		// Continuously run CoreML whenever it's ready. (Preventing 'hiccups' in Frame Rate)
		
		dispatchQueueML.async {
			// 1. Run Update.
			self.updateCoreML()
			
			// 2. Loop this function.
			self.loopCoreMLUpdate()
		}
		
	}
	
	func classificationCompleteHandler(request: VNRequest, error: Error?) {
		// Catch Errors
		if error != nil {
			print("Error: " + (error?.localizedDescription)!)
			return
		}
		guard let observations = request.results else {
			print("No results")
			return
		}
		
		// Get Classifications
		let classifications = observations[0...1] // top 2 results
			.flatMap({ $0 as? VNClassificationObservation })
			.map({ "\($0.identifier) \(String(format:"- %.2f", $0.confidence))" })
			.joined(separator: "\n")
		
		DispatchQueue.main.async {
			// Print Classifications
			print(classifications)
			print("--")
			
			// Display Debug Text on screen
			/*var debugText:String = ""
			debugText += classifications
			self.debugTextView.text = debugText
			
			// Store the latest prediction
			var objectName:String = "…"
			objectName = classifications.components(separatedBy: "-")[0]
			objectName = objectName.components(separatedBy: ",")[0]
			self.latestPrediction = objectName*/
			
		}
	}
	
	func updateCoreML() {
		///////////////////////////
		// Get Camera Image as RGB
		let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
		if pixbuff == nil { return }
		let ciImage = CIImage(cvPixelBuffer: pixbuff!)
		// Note: Not entirely sure if the ciImage is being interpreted as RGB, but for now it works with the Inception model.
		// Note2: Also uncertain if the pixelBuffer should be rotated before handing off to Vision (VNImageRequestHandler) - regardless, for now, it still works well with the Inception model.
		
		///////////////////////////
		// Prepare CoreML/Vision Request
		let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
		// let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage!, orientation: myOrientation, options: [:]) // Alternatively; we can convert the above to an RGB CGImage and use that. Also UIInterfaceOrientation can inform orientation values.
		
		///////////////////////////
		// Run Image Request
		do {
			try imageRequestHandler.perform(self.visionRequests)
		} catch {
			print(error)
		}
		
	}
	
}
