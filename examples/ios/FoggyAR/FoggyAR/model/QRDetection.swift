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
	func updatedAnchor()
	func detectRequestError(error : Error)
}

public class QRDetection : NSObject {
	public weak var delegate: QRDetectionDelegate?
	public private (set) var detectedDataAnchor: ARAnchor?
	
	public private (set) var qrValue: String = String()
	private let confidence: Float
	
	private let sceneView : ARSCNView
	
	private var isProcessing : Bool = false
	
	public init(sceneView : ARSCNView, confidence : Float) {
		self.sceneView = sceneView
		self.confidence = confidence
		
		super.init()
		
		self.sceneView.session.delegate = self
	}
	
	private func qrCodeRequestCompletion(_ frame: ARFrame, _ request: VNRequest, error: Error?) {
		if let result = request.results?.first as? VNBarcodeObservation, let newValue = result.payloadStringValue {
			if newValue.isEmpty == false && newValue != self.qrValue {
				if result.confidence >= self.confidence {
				
					var rect = result.boundingBox
					
					rect = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
					rect = rect.applying(CGAffineTransform(translationX: 0, y: 1))
					
					//print("qr code width: \(rect.size.width) height: \(rect.size.height)")
					
					let center = CGPoint(x: rect.midX, y: rect.midY)
					
					let hitTestResults = frame.hitTest(center, types: [.estimatedHorizontalPlane, .existingPlane, .existingPlaneUsingExtent] )
				
					if let hitTestResult = hitTestResults.first {
					
						DispatchQueue.main.async {
							self.qrValue = newValue
							self.delegate?.foundQRValue(stringValue: newValue)
							
							self.delegate?.updatedAnchor()
							
							if let detectedDataAnchor = self.detectedDataAnchor,
								let node = self.sceneView.node(for: detectedDataAnchor) {
							
								node.transform = SCNMatrix4(hitTestResult.worldTransform)
								
							} else {
								self.detectedDataAnchor = ARAnchor(transform: hitTestResult.worldTransform)
								
								self.sceneView.session.add(anchor: self.detectedDataAnchor!)
							}
						}
					}
				}
			}
		}
	}
}

extension QRDetection: ARSessionDelegate {
	public func session(_ session: ARSession, didUpdate frame: ARFrame) {
		
		// Process the request in the background
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				if self.isProcessing {
					return
				}
				self.isProcessing = true
				let detectRequest = VNDetectBarcodesRequest(completionHandler: { (request, error) in
					self.qrCodeRequestCompletion(frame, request, error: error)
					self.isProcessing = false
				})
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
