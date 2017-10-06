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

public protocol QRDetectionDelegate: class
{
	func foundQRValue(stringValue : String)
	func updatedAnchor()
}

public class QRDetection : NSObject, ARSessionDelegate
{
	public weak var delegate: QRDetectionDelegate?
	private var detectedDataAnchor: ARAnchor?
	
	var qrValue: String = String()
	var confidence: Float = 1.0
	
	var sceneView : ARSCNView?
	
	private var isProcessing : Bool = false
	
	override init() { super.init() }
	
	public init(sceneView : ARSCNView) {
		super.init()
		
		self.sceneView = sceneView
	}
	
	public func session(_ session: ARSession, didUpdate frame: ARFrame) {
		
		if self.isProcessing
		{
			return
		}
		
		self.isProcessing = true
		
		let request = VNDetectBarcodesRequest { (request, error) in

			if let results = request.results, let result = results.first as? VNBarcodeObservation {
				
				let newValue = result.payloadStringValue
				
				if(self.qrValue.isEmpty || newValue != self.qrValue)
				{
					print("QR value found!")
					
					self.delegate?.foundQRValue(stringValue: newValue!)
					self.qrValue = newValue!
				}
				
				if(result.confidence >= self.confidence)
				{
					var rect = result.boundingBox
					
					rect = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
					rect = rect.applying(CGAffineTransform(translationX: 0, y: 1))
					
					let center = CGPoint(x: rect.midX, y: rect.midY)
					
					DispatchQueue.main.async {
						
						let hitTestResults = frame.hitTest(center, types: [.featurePoint/*, .estimatedHorizontalPlane, .existingPlane, .existingPlaneUsingExtent*/] )
						
						if let hitTestResult = hitTestResults.first {
							
							if let detectedDataAnchor = self.detectedDataAnchor,
								let node = self.sceneView!.node(for: detectedDataAnchor) {
								
								self.delegate?.updatedAnchor()
								node.transform = SCNMatrix4(hitTestResult.worldTransform)
								
							} else {
								self.detectedDataAnchor = ARAnchor(transform: hitTestResult.worldTransform)
								self.sceneView!.session.add(anchor: self.detectedDataAnchor!)
							}
							
						}
						
						self.isProcessing = false
					}
				}
				
			} else {
				self.isProcessing = false
			}
		}
		
		// Process the request in the background
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				// Set it to recognize QR code only
				request.symbologies = [.QR]
				
				// Create a request handler using the captured image from the ARFrame
				let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage,
																												options: [:])
				// Process the request
				try imageRequestHandler.perform([request])
			} catch {
				
			}
		}
		
	}
	
}
