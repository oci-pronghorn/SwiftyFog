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
import Vision
#if APP
import SwiftyFog_iOS
#endif

extension FloatingPoint {
	var degreesToRadians: Self { return self * .pi / 180 }
	var radiansToDegrees: Self { return self * 180 / .pi }
}

protocol FoggyLogoRendererDelegate:class {
	func qrCodeDetected(code: String)
	func loading(_ state : Bool)
}

class FoggyLogoRenderer : NSObject {

	private let qrDetector : QRDetection
	
	#if APP
	private let trainDetector : TrainDetection
	#endif
	
	// SceneNode for the 3D models
	private var logoNode : SCNNode!
	private var lightbulbNode : SCNNode!
	private var largeSpotLightNode : SCNNode!
	private var qrValueTextNode : SCNNode!
	public private (set) var detectedDataAnchor: ARAnchor?
	
	// Rotation variables
	private var hasAppliedHeading = false
	private var oldRotationY: CGFloat = 0.0

	private let sceneView : ARSCNView
	
	private var originalPosition = SCNVector3()
	
	public weak var delegate: FoggyLogoRendererDelegate?
	
	private let dispatchQueue = DispatchQueue(label: "com.hw.dispatchqueueml")
	
	public init(sceneView : ARSCNView) {
		self.sceneView = sceneView
		#if APP
		self.trainDetector = TrainDetection()
		#endif
		self.qrDetector = QRDetection(confidence: 0.8)
		
		super.init()
		
		self.sceneView.session.delegate = self
		self.sceneView.session.delegateQueue = dispatchQueue
		self.sceneView.delegate = self
		self.qrDetector.delegate = self
		
		#if APP
		self.trainDetector.delegate = self
		#endif
		
		self.delegate?.loading(true)
		
		loopCoreMLUpdate()
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
	
	func heading(heading: TrainRational) {
		let newRotationY = CGFloat(heading.num) / 10.0 // in units of 0.1 degrees
		let normDelta = newRotationY - oldRotationY
		let crossDelta = oldRotationY < newRotationY ? newRotationY - 360 - oldRotationY : 360 - oldRotationY + newRotationY
		let rotateBy = abs(normDelta) < abs(crossDelta) ? normDelta : crossDelta
		oldRotationY = newRotationY
		
		let now = Date().timeIntervalSince1970
		print("Heading: \(heading) degrees: \(newRotationY) delta: \(rotateBy) in \(now - lastTime) secs.")
		lastTime = now
		
		if let logoNode = logoNode {
				logoNode.rotateToYAxis(to: -oldRotationY.degreesToRadians)
				hasAppliedHeading = true
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
			
            // TODO: this appears to not work in playgrounds...
            #if APP
			guard let virtualObjectScene = SCNScene(named: "art.scnassets/logo.scn") else {
				return nil
			}
            #else
                let virtualObjectScene = SCNScene(named: "logo.scn")!
            #endif
			
			//Grab the required nodes
			logoNode = virtualObjectScene.rootNode.childNode(withName: "OCILogo", recursively: false)!
			
			#if APP
			let (minVec, maxVec) = logoNode.boundingBox
			logoNode.pivot = SCNMatrix4MakeTranslation((maxVec.x - minVec.x) / 2 + minVec.x, (maxVec.y - minVec.y) / 2 + minVec.y, 0)
			
			logoNode.position = SCNVector3(0, 0, 0)
			
			//Before render we have already received a rotation, set it to that
			logoNode.rotateToYAxis(to: -oldRotationY.degreesToRadians)
				
			#endif
			
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
			
			print("Centering QR text!")
			//Attempt at centering QR text
			let (minVecL, maxVecL) = qrValueTextNode.boundingBox
			qrValueTextNode.pivot = SCNMatrix4MakeTranslation(
				minVecL.x + (maxVecL.x - minVecL.x)/2,
				minVecL.y + (maxVecL.y - minVecL.y)/2,
				minVecL.z + (maxVecL.z - minVecL.z)/2
			)
			
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
			textGeometry.alignmentMode = convertFromCATextLayerAlignmentMode(CATextLayerAlignmentMode.center)
		}
	}
	
	func rotateToYAxis(to: CGFloat) {
		#if APP
		self.eulerAngles.y = Float(to)
		#endif
	}
	
	func rotateAroundYAxis(by: CGFloat, duration : TimeInterval) {
		#if APP
		let action = SCNAction.rotate(by: by, around: SCNVector3(0, 1, 0), duration: duration)
		
		self.runAction(action, forKey: "rotatingYAxis")
		self.position = SCNVector3(0,0,0)
		#endif
	}
}

extension FoggyLogoRenderer: ARSessionDelegate {
	public func session(_ session: ARSession, didUpdate frame: ARFrame) {
	}

	func loopCoreMLUpdate() {
		// Having the background serial queue requeue the detection request
		// after each process instead of session delegate frame update is kinder
		// to the frame rate.
		// Since the rate of frame changes is higher than the processing time
		// of detection we are not queuing up detection requests on the serial
		// queue for old frames. Nor do we have to maintain "is processing"
		// flags to stop that queuing.
		// The detector's didUpdate methods are blocking. Strangely, if the
		// dectectors are dispatched async from the session delegate the AR
		// frame rate drops with the processing time of the detector.
		// The AR scene will eventually freeze if the detectors are executed
		// simultaniously.
		// There is some mutex shenanigans that could explain the AR freeze
		// and the AR drop in framerate.
		// Maybe file a bug report with ARKit?
		dispatchQueue.async { [weak self] in
			// Since this is a recursive dispatch, we must use weak self.
			if let me = self {
				// We appear to never receive the same frame consecutively - always detect.
				if let frame = me.sceneView.session.currentFrame {
					let capturedImage = frame.capturedImage
					// Blocking calls and must be executed serially.
					#if APP
					me.trainDetector.session(didUpdate: capturedImage)
					#endif
					me.qrDetector.session(me.sceneView.session, inScene: me.sceneView, didUpdate: frame, capturedImage: capturedImage)
				}
				else {
					// This happens during setup. Be kind and not queue up 1000 no-ops.
					// Alternative is to use a flag. This is simpler for a one time
					// startup performance consideration.
					sleep(1)
				}
				// Recurse
				me.loopCoreMLUpdate()
			}
		}
	}
}

#if APP
extension FoggyLogoRenderer: TrainDetectionDelegate {
    func foundObject(observation: VNClassificationObservation) {
        print(observation.identifier)
    }
}
#endif

extension FoggyLogoRenderer: QRDetectionDelegate  {
	
	func findQRValue(observation : VNBarcodeObservation/*, frame: ARFrame*/) -> Bool {
		let newValue : String = observation.payloadStringValue!
		
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
		
		let hitTestResults = self.sceneView.session.currentFrame?.hitTest(center, types: [.featurePoint] )
		
		if let hitTestResult = hitTestResults?.first {
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
		#if APP
		print("Error in detection: \(error.localizedDescription)")
		#endif
	}
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCATextLayerAlignmentMode(_ input: CATextLayerAlignmentMode) -> String {
	return input.rawValue
}
