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

class ARViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, QRDetectionDelegate {
	
	// MQTT representation for the logo
	let logo = FoggyLogo()
	
	var scene : SCNScene = SCNScene()
	
	var qrDetector : QRDetection = QRDetection()
	
	// SceneNode for the 3D models
	var logoNode = SCNNode()
	var lightbeamNode = SCNNode()
	var qrValueTextNode = SCNNode()
	
	var oldRotationY = CGFloat(360.0)
	
	// The bridge, responsible for receiving train data
	var mqtt: MQTTBridge! {
		didSet {
			logo.delegate = self
			logo.mqtt = mqtt
		}
	}
	
	// TODO: fakeHeadingTimer is for testing and demo-purposes, don't actually use it prod
	private var fakeHeadingTimer: DispatchSourceTimer?
	private var fakeHeading : Int = 0
	
	// The activity indicator to be shown whenever it's trying to determine the QR code
	@IBOutlet weak var centerActivityView: UIView!
	
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	// Outlet to the scene
	@IBOutlet var sceneView: ARSCNView!
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Set the scene to the view
		sceneView.scene = self.scene
		
		qrDetector = QRDetection(sceneView: self.sceneView)
		
		qrDetector.delegate = self
		
		// Set the view's delegate
		sceneView.delegate = self
		
		self.centerActivityView.layer.cornerRadius = 5;
		
		// Create the fake timer (get rid of this)
		createFakeTimer()
	}
	
	func foundQRValue(stringValue: String) {
		print("found qr value! \(stringValue)")
	}
	
	//Called when anchor changed
	func updatedAnchor() {
		
	}
	
	//Called when processing status changed
	func updatingStatusChanged(status: Bool) {
		DispatchQueue.main.async(execute: {
				self.centerActivityView.isHidden = !status
		})
	}
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
	
	// TODO: get rid of this eventually
	func createFakeTimer()
	{
		let interval = 1
		let leeway = 1
		
		// Fake timer
		let fakeHeadingTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
		
		fakeHeadingTimer.schedule(deadline: .now() + .seconds(interval), repeating: .seconds(interval), leeway: .seconds(leeway))
		fakeHeadingTimer.setEventHandler { [weak self] in
			if let m = self {
				m.fakeHeading += 20;
				if m.fakeHeading >= 360 {
					m.fakeHeading -= 360
				}
				m.logo.control(heading: FogRational(num: Int64(self!.fakeHeading), den: Int64(360)))
			}
		}
		
		self.fakeHeadingTimer = fakeHeadingTimer
		fakeHeadingTimer.resume()
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
{ // rational : FogRational<Int64>
	func rotateAroundYAxis(by: CGFloat, duration : Int)
	{
		let (minVec, maxVec) = self.boundingBox
		
		// Create pivot so it can spin around itself
		self.pivot = SCNMatrix4MakeTranslation((maxVec.x - minVec.x) / 2 + minVec.x, (maxVec.y - minVec.y) / 2 + minVec.y, 0)

		// Create the rotateTo action.
		let action = SCNAction.rotate(by: by, around: SCNVector3(0, 1, 0), duration: TimeInterval(duration))
	
		self.runAction(action, forKey: "rotateLogo")
	}
}

extension ARViewController {
	
	func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
		// If this is our anchor, create a node
		if self.qrDetector.detectedDataAnchor?.identifier == anchor.identifier {
			
			//Move line 163-to 173 maybe outside so we dont repeatedely keep grabbing it
			// Get our scene
			guard let virtualObjectScene = SCNScene(named: "art.scnassets/logo.scn") else {
				return nil
			}
			
			//Grab the required nodes
			logoNode = virtualObjectScene.rootNode.childNode(withName: "OCILogo", recursively: false)!
			lightbeamNode = virtualObjectScene.rootNode.childNode(withName: "lightbeam", recursively: false)!
			
			//Wrapper node for adding nodes that we want to spawn on top of the QR code
			let wrapperNode = SCNNode()
			
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
	func foggyLogo(lightsPower: Bool, _ asserted: Bool) {
		print("Lights are on: \(lightsPower)")
		lightbeamNode.isHidden = !lightsPower
	}
	
	func foggyLogo(accelerometerHeading: FogRational<Int64>, _ asserted: Bool) {
		print("Received acceloremeter heading: \(accelerometerHeading)")
	
		let newRotationY = CGFloat(accelerometerHeading.num) + 360
		let distance = abs(newRotationY - oldRotationY)
		let rotateBy = distance < 180 ? newRotationY - oldRotationY : 360.0 - distance
		oldRotationY = newRotationY
		
		logoNode.rotateAroundYAxis(by: rotateBy.degreesToRadians, duration: 1)
	}
}
