//
//  Barcode.swift
//  FoggyAR
//
//  Created by Tobias Schweiger on 10/6/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import ARKit
import Vision

public protocol QRDetectionDelegate: class {
	func foundQRValue(stringValue : String)
	func updatingStatusChanged(status : Bool)
	func updatedAnchor()
	func detectRequestError(error : Error)
}

public class QRDetection : NSObject, ARSessionDelegate {
	public weak var delegate: QRDetectionDelegate?
	public private (set) var detectedDataAnchor: ARAnchor?
	
	public var qrValue: String = String()
	private var confidence: Float
	
	private var sceneView : ARSCNView
	
	private var isProcessing : Bool = false

	public var isUpdating : Bool = false {
		didSet {
			delegate?.updatingStatusChanged(status: isUpdating)
		}
	}
	
	public init(sceneView : ARSCNView, confidence : Float) {
		self.sceneView = sceneView
		self.confidence = confidence
		
		super.init()
		
		self.sceneView.session.delegate = self
	}
	
	private func getBarcodeRequest(_ frame : ARFrame) -> VNDetectBarcodesRequest {
		let request = VNDetectBarcodesRequest { (request, error) in
			
			if let results = request.results, let result = results.first as? VNBarcodeObservation {
				
				let newValue = result.payloadStringValue
				
				if(self.qrValue.isEmpty || newValue != self.qrValue) {
					self.delegate?.foundQRValue(stringValue: newValue!)
					self.qrValue = newValue!
				}
				
				if(result.confidence >= self.confidence) {
					var rect = result.boundingBox
					
					rect = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
					rect = rect.applying(CGAffineTransform(translationX: 0, y: 1))
					
					let center = CGPoint(x: rect.midX, y: rect.midY)
					
					DispatchQueue.main.async {
						
						let hitTestResults = frame.hitTest(center, types: [.featurePoint/*, .estimatedHorizontalPlane, .existingPlane, .existingPlaneUsingExtent*/] )
						
						if let hitTestResult = hitTestResults.first {
							
							//TODO: move this out of QRDetection, against S in SOLID
							if let detectedDataAnchor = self.detectedDataAnchor,
								let node = self.sceneView.node(for: detectedDataAnchor) {
								
								self.delegate?.updatedAnchor()
								node.transform = SCNMatrix4(hitTestResult.worldTransform)
								
							} else {
								self.isUpdating = true
								self.detectedDataAnchor = ARAnchor(transform: hitTestResult.worldTransform)
								self.sceneView.session.add(anchor: self.detectedDataAnchor!)
							}
							
						}
						
						self.isProcessing = false
					}
				}
				
			} else {
				self.isProcessing = false
			}
		}
		
		return request
	}
	
	public func session(_ session: ARSession, didUpdate frame: ARFrame) {
		if self.isProcessing {
			return
		}
		
		self.isProcessing = true
		self.isUpdating = false
		
		let detectRequest = getBarcodeRequest(frame)
		
		// Process the request in the background
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				// Set it to recognize QR code only
				detectRequest.symbologies = [.QR]
				
				// Create a request handler using the captured image from the ARFrame
				let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, options: [:])
				// Process the request
				try imageRequestHandler.perform([detectRequest])
			} catch let error {
				self.delegate?.detectRequestError(error: error)
			}
		}
	}
}
