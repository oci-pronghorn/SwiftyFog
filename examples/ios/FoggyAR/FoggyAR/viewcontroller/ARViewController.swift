//
//  ViewController.swift
//  FoggyAR
//
//  Created by Tobias Schweiger on 10/4/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import SwiftyFog_iOS
import Vision

class ARViewController: UIViewController {
	
	// MQTT representation for the logo
	let logo = FoggyLogo()
	
	var qrDetector : QRDetection!
	
	var hasAppliedHeading = false
	
	// SceneNode for the 3D models
	var logoNode : SCNNode!
	var lightbulbNode : SCNNode!
	var qrValueTextNode : SCNNode!
	
	// The bridge, responsible for receiving train data
	var mqtt: MQTTBridge! {
		didSet {
			logo.delegate = self
			logo.mqtt = mqtt
		}
	}
	
	private var oldRotationY: CGFloat = 0.0
	
	// The activity indicator to be shown whenever it's trying to determine the QR code
	@IBOutlet weak var centerActivityView: UIView!
	
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	// Outlet to the scene
	@IBOutlet weak var sceneView: ARSCNView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Set the scene to the view
		sceneView.scene = SCNScene()
		
		qrDetector = QRDetection(sceneView: self.sceneView, confidence: 0.8)
		qrDetector.delegate = self
		
		// Set the view's delegate
		sceneView.delegate = self
		
		// Make the activity indicator prettier
		self.centerActivityView.layer.cornerRadius = 5;
		
		//Add tapping mechanism
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gestureRecognizer:)))
		view.addGestureRecognizer(tapGesture)
	}
	
	func isShowingActivityIndicator(_ status: Bool) {
		DispatchQueue.main.async(execute: {
				self.centerActivityView.isHidden = !status
		})
	}
	
	@objc func handleTap(gestureRecognizer: UITapGestureRecognizer) {
		let touchLocation = gestureRecognizer.location(in: self.sceneView)
		let hitResults = self.sceneView.hitTest(touchLocation, options: [:])
		
	  if !hitResults.isEmpty {
			
			guard let hitResult = hitResults.first else {
				return
			}
			let node = hitResult.node
			let url = URL(string: qrDetector.qrValue)!
			
			if(node == qrValueTextNode && UIApplication.shared.canOpenURL(url))
			{
				UIApplication.shared.open(url)
			}
		}
		
	}
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		// Create a session configuration
		let configuration = ARWorldTrackingConfiguration()
		
		// Enable horizontal plane detection
		configuration.planeDetection = .horizontal
		
		// Run the view's session
		sceneView.session.run(configuration)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		// Pause the view's session
		sceneView.session.pause()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Release any cached data, images, etc that aren't in use.
	}

}

extension SCNNode
{
	func setGeometryText(value : String) {
		if let textGeometry = self.geometry as? SCNText {
			textGeometry.string = value
		}
	}
	
	func rotateToYAxis(to: CGFloat) {
		self.eulerAngles.y = Float(to)
	}
	
	func rotateAroundYAxis(by: CGFloat, duration : TimeInterval) {
		let (minVec, maxVec) = self.boundingBox
		
		// Create pivot so it can spin around itself
		self.pivot = SCNMatrix4MakeTranslation((maxVec.x - minVec.x) / 2 + minVec.x, (maxVec.y - minVec.y) / 2 + minVec.y, 0)

		// Create the rotateTo action.
		let action = SCNAction.rotate(by: by, around: SCNVector3(0, 1, 0), duration: duration)
	
		self.runAction(action, forKey: "rotateLogo")
	}
}

extension ARViewController : QRDetectionDelegate {

	func foundQRValue(stringValue: String) {
		print("Code scanned: \(stringValue)")
		
		if let qrValueTextNode = qrValueTextNode {
			qrValueTextNode.setGeometryText(value: stringValue)
		}
	}
	
	func updatedAnchor() {
		print("Anchor changed")
	}
	
	func updatingStatusChanged(status: Bool) {
		isShowingActivityIndicator(status)
	}
	
	func detectRequestError(error: Error) {
		print("Error in QR: \(error.localizedDescription)")
	}
}

extension ARViewController : ARSCNViewDelegate {
	
	//Note: Renderer only executes ONCE
	func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
		
		// If this is our anchor, create a node
		if self.qrDetector.detectedDataAnchor?.identifier == anchor.identifier {
			
			guard let virtualObjectScene = SCNScene(named: "art.scnassets/logo.scn") else {
				return nil
			}
			
			//Grab the required nodes
			logoNode = virtualObjectScene.rootNode.childNode(withName: "OCILogo", recursively: false)!
			
			//Before render we have already received a rotation, set it to that
			logoNode.rotateToYAxis(to: oldRotationY.degreesToRadians)
			
		  lightbulbNode = virtualObjectScene.rootNode.childNode(withName: "lightbulb", recursively: false)
			
			//Hide the light bulb node initially
			lightbulbNode.isHidden = true
			
			//Get the text node for the QR code
			qrValueTextNode = virtualObjectScene.rootNode.childNode(withName: "QRCode", recursively: false)
			
			let (minBound, maxBound) = logoNode.boundingBox
			
			qrValueTextNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, 0.005)
			
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
	
	func sessionWasInterrupted(_ session: ARSession) {
	}
	
	func session(_ session: ARSession, didFailWithError error: Error) {
	}
	
	func sessionInterruptionEnded(_ session: ARSession) {
	}
	
}

extension ARViewController : FoggyLogoDelegate {
	func foggyLogo(lightsPower: Bool) {
		print("Lights are on: \(lightsPower)")
		lightbulbNode.isHidden = !lightsPower
	}
	
	func foggyLogo(accelerometerHeading: FogRational<Int64>) {
		let newRotationY = CGFloat(accelerometerHeading.num)
		let normDelta = newRotationY - oldRotationY
		let crossDelta = oldRotationY < newRotationY ? newRotationY - 360 - oldRotationY : 360 - oldRotationY + newRotationY
		let rotateBy = abs(normDelta) < abs(crossDelta) ? normDelta : crossDelta
		oldRotationY = newRotationY
		print("Received acceloremeter heading: \(accelerometerHeading) rotate by: \(rotateBy)")
		
		if let logoNode = logoNode {
			if hasAppliedHeading {
				logoNode.rotateAroundYAxis(by: -rotateBy.degreesToRadians, duration: 1)
			} else {
				logoNode.rotateToYAxis(to: -oldRotationY)
				hasAppliedHeading = true
			}
		}
	}
}
