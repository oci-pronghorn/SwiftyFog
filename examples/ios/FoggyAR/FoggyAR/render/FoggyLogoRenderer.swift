//
//  FoggyLogoRenderer.swift
//  FoggyAR
//
//  Created by Tobias Schweiger on 10/11/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import SwiftyFog_iOS
import Vision

protocol FoggyLogoRendererDelegate:class {
	func qrCodeDetected(code: String)
	func loading(_ state : Bool)
}

class FoggyLogoRenderer : NSObject {

	private let qrDetector : QRDetection
	private let trainDetector : TrainDetection
	
	// SceneNode for the 3D models
	private var logoNode : SCNNode!
	private var lightbulbNode : SCNNode!
	private var largeSpotLightNode : SCNNode!
	private var qrValueTextNode : SCNNode!
	
	public private (set) var detectedDataAnchor: ARAnchor?
	
	// Rotation variables
	private var hasAppliedHeading = false
	private var oldRotationY: CGFloat = 0.0

	private let sceneView : 	ARSCNView
	
	private var originalPosition = SCNVector3()
	
	public weak var delegate: FoggyLogoRendererDelegate?
	
	private let dispatchQueue = DispatchQueue(label: "com.hw.dispatchqueueml")
	
	public init(sceneView : ARSCNView) {
		self.sceneView = sceneView
		self.trainDetector = TrainDetection()
		self.qrDetector = QRDetection(confidence: 0.8)
		
		super.init()
		
		self.sceneView.session.delegate = self
		self.sceneView.session.delegateQueue = dispatchQueue
		self.sceneView.delegate = self
		self.qrDetector.delegate = self
		self.trainDetector.delegate = self
		
		self.delegate?.loading(true)
	}
	
	func hitQRCode(node: SCNNode) -> Bool {
		return node == qrValueTextNode
	}
	
	func train(alive: Bool) {
		if !alive {
			self.sceneView.scene.fogColor = UIColor.red
			self.sceneView.scene.fogEndDistance = 0.045
		} else {
			self.sceneView.scene.fogEndDistance = 0
		}
	}
	
	private var lastTime = Date().timeIntervalSince1970
	
	func heading(heading: FogRational<Int64>) {
		let newRotationY = CGFloat(heading.num) / 10.0 // in units of 0.1 degrees
		let normDelta = newRotationY - oldRotationY
		let crossDelta = oldRotationY < newRotationY ? newRotationY - 360 - oldRotationY : 360 - oldRotationY + newRotationY
		let rotateBy = abs(normDelta) < abs(crossDelta) ? normDelta : crossDelta
		oldRotationY = newRotationY
		
		let now = Date().timeIntervalSince1970
		print("Heading: \(heading) degrees: \(newRotationY) delta: \(rotateBy) in \(now - lastTime) secs.")
		lastTime = now
		
		if let logoNode = logoNode {
			//if hasAppliedHeading {
			//	logoNode.rotateAroundYAxis(by: -rotateBy.degreesToRadians, duration: 1)
			//} else {
				logoNode.rotateToYAxis(to: -oldRotationY.degreesToRadians)
				hasAppliedHeading = true
			//}
		}
	}
	
	public func lights(on : Bool) {
		if let lightbulbNode = lightbulbNode, let largeSpotLightNode = largeSpotLightNode {
			lightbulbNode.isHidden = !on
			largeSpotLightNode.isHidden = !on
		}
	}
}

extension FoggyLogoRenderer : ARSCNViewDelegate {
	
	func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
		
		// If this is our anchor, create a node
		if self.detectedDataAnchor?.identifier == anchor.identifier {
			
			//We rendered, so stop showing the activity indicator
			delegate?.loading(false)
			
			guard let virtualObjectScene = SCNScene(named: "art.scnassets/logo.scn") else {
				return nil
			}
			
			//Grab the required nodes
			logoNode = virtualObjectScene.rootNode.childNode(withName: "OCILogo", recursively: false)!
			let (minVec, maxVec) = logoNode.boundingBox
			logoNode.pivot = SCNMatrix4MakeTranslation((maxVec.x - minVec.x) / 2 + minVec.x, (maxVec.y - minVec.y) / 2 + minVec.y, 0)
			
			logoNode.position = SCNVector3(0, 0, 0)
			
			//Before render we have already received a rotation, set it to that
			//CULRPIT RIGHT HERE:
			logoNode.rotateToYAxis(to: -oldRotationY.degreesToRadians)
			
			lightbulbNode = virtualObjectScene.rootNode.childNode(withName: "lightbulb", recursively: false)
			largeSpotLightNode = virtualObjectScene.rootNode.childNode(withName: "largespot", recursively: false)
			
			//Hide the light bulb nodes initially
			lightbulbNode.isHidden = true
			largeSpotLightNode.isHidden = true
			
			//Get the text node for the QR code
			qrValueTextNode = virtualObjectScene.rootNode.childNode(withName: "QRCode", recursively: false)
			
			//Since we always receive the QR code before we render our nodes, assign the
			//existing scanned value to our geometry
			qrValueTextNode.setGeometryText(value: qrDetector.qrValue)
			
			//Wrapper node for adding nodes that we want to spawn on top of the QR code
			let wrapperNode = SCNNode()
			
			//Iterate over the child nodes to add them all to the wrapper node
			for child in virtualObjectScene.rootNode.childNodes {
				child.geometry?.firstMaterial?.lightingModel = .physicallyBased
				child.movabilityHint = .movable
				
				wrapperNode.addChildNode(child)
			}
			
			// Set its position based off the anchor
			wrapperNode.transform = SCNMatrix4(anchor.transform)
			
			return wrapperNode
		}
		
		return nil
	}
}

extension SCNNode {
	func setGeometryText(value : String) {
		if let textGeometry = self.geometry as? SCNText {
			textGeometry.string = value
			textGeometry.alignmentMode = kCAAlignmentCenter
		}
	}
	
	func rotateToYAxis(to: CGFloat) {
		self.eulerAngles.y = Float(to)
	}
	
	func rotateAroundYAxis(by: CGFloat, duration : TimeInterval) {
		let action = SCNAction.rotate(by: by, around: SCNVector3(0, 1, 0), duration: duration)
		
		self.runAction(action, forKey: "rotatingYAxis")
		
		self.position = SCNVector3(0,0,0)
	}
}


extension FoggyLogoRenderer: ARSessionDelegate {
	public func session(_ session: ARSession, didUpdate frame: ARFrame) {
		// Process the request in the background
		let capturedImage = frame.capturedImage
		self.qrDetector.session(session, inScene: self.sceneView, didUpdate: frame, capturedImage: capturedImage)
		//self.trainDetector.session(didUpdate: capturedImage)
	}
}

extension FoggyLogoRenderer: QRDetectionDelegate, TrainDetectionDelegate {
	
	func foundObject(observation: VNClassificationObservation) {
		/*
		// Get Classifications
		let classifications = observations[0...1] // top 2 results
			.flatMap({ $0 as? VNClassificationObservation })
			.map({ "\($0.identifier) \(String(format:"- %.2f", $0.confidence))" })
			.joined(separator: "\n")
		
			print(classifications)
			print("--")
		}*/
		print(observation.identifier)
	}
	
	func findQRValue(observation : VNBarcodeObservation, frame : ARFrame) -> Bool {
		var newValue : String = observation.payloadStringValue!
		
		// 3D Text
		if let qrValueTextNode = qrValueTextNode {
			qrValueTextNode.setGeometryText(value: newValue)
			delegate?.qrCodeDetected(code: newValue)
		}
		
		// Logo
		var rect = observation.boundingBox
		
		rect = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
		rect = rect.applying(CGAffineTransform(translationX: 0, y: 1))
		
		let center = CGPoint(x: rect.midX, y: rect.midY)
		
		let hitTestResults = frame.hitTest(center, types: [.featurePoint] )
		
		if let hitTestResult = hitTestResults.first {
			DispatchQueue.main.async {
				self.delegate?.qrCodeDetected(code: newValue)
				
				if let detectedDataAnchor = self.detectedDataAnchor,
					let node = self.sceneView.node(for: detectedDataAnchor) {
					
					node.transform = SCNMatrix4(hitTestResult.worldTransform)
					
				} else {
					self.detectedDataAnchor = ARAnchor(transform: hitTestResult.worldTransform)
					
					self.sceneView.session.add(anchor: self.detectedDataAnchor!)
				}
			}
			return true
		}
		
		return false
	}
	
	func detectRequestError(error: Error) {
		print("Error in detection: \(error.localizedDescription)")
	}
}

