//
//  QRDetection.swift
//  FoggyAR
//
//  Created by Tobias Schweiger on 10/6/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//
import Foundation
import ARKit
import Vision

public protocol QRDetectionDelegate: class {
	func findQRValue(observation : VNBarcodeObservation) -> Bool
	func detectRequestError(error : Error)
}

public class QRDetection {
	public weak var delegate: QRDetectionDelegate?
	public private (set) var qrValue: String = String()
	
	private let confidence: Float
	
	private lazy var request: VNDetectBarcodesRequest = {
		let detectRequest = VNDetectBarcodesRequest(completionHandler: barcodeRequestCompletion)
		detectRequest.symbologies = [.QR]
		return detectRequest
	}()
	
	public init(confidence : Float) {
		self.confidence = confidence
	}
	
	public func session(_ session: ARSession, inScene: ARSCNView, didUpdate frame: ARFrame, capturedImage: CVPixelBuffer) {
		do {
			let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: capturedImage, options: [:])
			try imageRequestHandler.perform([self.request])
		}
		catch let error {
			self.delegate?.detectRequestError(error: error)
		}
	}
	
	private func barcodeRequestCompletion(_ request: VNRequest, _ error : Error?) {
		if let result = request.results?.first as? VNBarcodeObservation, let newValue = result.payloadStringValue {
			if newValue.isEmpty == false && newValue != self.qrValue {
				if result.confidence >= self.confidence {
					if (self.delegate?.findQRValue(observation: result))! {
						self.qrValue = newValue
					}
				}
			}
		}
	}
}
