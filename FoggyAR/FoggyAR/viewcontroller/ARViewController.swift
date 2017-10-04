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

class ARViewController: UIViewController, ARSCNViewDelegate {
	
	//The MQTT control element
	var mqttControl: MQTTControl! {
		didSet {
			mqttControl.start()
		}
	}
	
	//MQTT representation for the logo
	let logo = FoggyLogo()
	
	//The bridge, responsible for receiving train data
	var mqtt: MQTTBridge! {
		didSet {
			logo.delegate = self
			logo.mqtt = mqtt.createBridge(subPath: "")
		}
	}
	
	//TODO: fakeHeadingTimer is for testing and demo-purposes, don't actually use it prod
	private var fakeHeadingTimer: DispatchSourceTimer?
	private var fakeHeading : Int = 0
	
	@IBOutlet var sceneView: ARSCNView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Set the view's delegate
		sceneView.delegate = self
		
		// Create a new scene
		let scene = SCNScene(named: "art.scnassets/logo.scn")!
		
		createFakeTimer()
		
		// Set the scene to the view
		sceneView.scene = scene
	}
	
	//TODO: get rid of this eventually
	func createFakeTimer()
	{
		let interval = 3
		let leeway = 1
		
		let fakeHeadingTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
		fakeHeadingTimer.schedule(deadline: .now() + .seconds(interval), repeating: .seconds(interval), leeway: .seconds(leeway))
		fakeHeadingTimer.setEventHandler { [weak self] in
			
			self?.fakeHeading = self!.fakeHeading <= 360 ? self!.fakeHeading + 5 : 0
			self?.logo.control(heading: FogRational(num: Int64(self!.fakeHeading), den: Int64(360)))
		}
		self.fakeHeadingTimer = fakeHeadingTimer
		fakeHeadingTimer.resume()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		// Create a session configuration
		let configuration = ARWorldTrackingConfiguration()
		
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
	
	func session(_ session: ARSession, didFailWithError error: Error) {
		// Present an error message to the user
		print("Session error occured: \(error.localizedDescription)")
	}
	
	func sessionWasInterrupted(_ session: ARSession) {
		// Inform the user that the session has been interrupted, for example, by presenting an overlay
		print("Session was interrupted")
	}
	
	func sessionInterruptionEnded(_ session: ARSession) {
		// Reset tracking and/or remove existing anchors if consistent tracking is required
		print("Session interruption ended")
	}
}

extension ARViewController {
	
	func feedbackCut() {
		logo.reset()
	}
	
	func assertValues() {
		logo.assertValues()
	}
	
}

extension ARViewController : FoggyLogoDelegate {
	func foggyLogo(lightsPower: Bool, _ asserted: Bool) {
		print("Lights are on: \(lightsPower)")
	}
	
	func foggyLogo(accelerometerHeading: FogRational<Int64>, _ asserted: Bool) {
		print("Received acceloremeter heading: \(accelerometerHeading)")
	}
}
