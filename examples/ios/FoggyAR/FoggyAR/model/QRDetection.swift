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
	func findQRValue(observation : VNBarcodeObservation, frame : ARFrame) -> Bool
	func detectRequestError(error : Error)
}

public class QRDetection {
	public weak var delegate: QRDetectionDelegate?
	public private (set) var qrValue: String = String()
	
	private let confidence: Float
	private var isProcessing : Bool = false
	
	public init(confidence : Float) {
		self.confidence = confidence
	}
	
	public func session(_ session: ARSession, inScene: ARSCNView, didUpdate frame: ARFrame, capturedImage: CVPixelBuffer) {
		// Process the request in the background
		do {
			if self.isProcessing {
				return
			}
			self.isProcessing = true
			let detectRequest = VNDetectBarcodesRequest(completionHandler: { (request, error) in
				self.qrCodeRequestCompletion(frame, capturedImage, inScene, request, error: error)
				self.isProcessing = false
			})
			// Set it to recognize QR code only
			detectRequest.symbologies = [.QR]
			
			// Create a request handler using the captured image from the ARFrame
			let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: capturedImage, options: [:])
			// Process the request
			try imageRequestHandler.perform([detectRequest])
		}
		catch let error {
			self.delegate?.detectRequestError(error: error)
		}
	}
	
	private func qrCodeRequestCompletion(_ frame: ARFrame, _ capturedImage: CVPixelBuffer, _ sceneView: ARSCNView, _ request: VNRequest, error: Error?) {
		if let result = request.results?.first as? VNBarcodeObservation, let newValue = result.payloadStringValue {
			if newValue.isEmpty == false && newValue != self.qrValue {
				if result.confidence >= self.confidence {
				
					if (self.delegate?.findQRValue(observation: result, frame: frame))! {
						self.qrValue = newValue
					}
					/*
					var rect = result.boundingBox
					
					rect = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
					rect = rect.applying(CGAffineTransform(translationX: 0, y: 1))

					let center = CGPoint(x: rect.midX, y: rect.midY)

					let hitTestResults = frame.hitTest(center, types: [.featurePoint, /*.existingPlane, .existingPlaneUsingExtent*/] )
				
					if let hitTestResult = hitTestResults.first {
						self.qrValue = newValue
						DispatchQueue.main.async {
							self.delegate?.foundQRValue(stringValue: newValue)
							
							if let detectedDataAnchor = self.detectedDataAnchor,
								let node = sceneView.node(for: detectedDataAnchor) {
							
								node.transform = SCNMatrix4(hitTestResult.worldTransform)
								
							} else {
								self.detectedDataAnchor = ARAnchor(transform: hitTestResult.worldTransform)
								
								sceneView.session.add(anchor: self.detectedDataAnchor!)
							}
						}
					}*/
				}
			}
		}
	}
}
