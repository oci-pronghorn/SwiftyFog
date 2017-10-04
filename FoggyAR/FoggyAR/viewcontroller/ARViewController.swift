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
	
	@IBOutlet var sceneView: ARSCNView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Set the view's delegate
		sceneView.delegate = self
		
		// Show statistics such as fps and timing information
		sceneView.showsStatistics = true
		
		// Create a new scene
		let scene = SCNScene(named: "art.scnassets/ship.scn")!
		
		// Set the scene to the view
		sceneView.scene = scene
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
		
	}
	
	func sessionWasInterrupted(_ session: ARSession) {
		// Inform the user that the session has been interrupted, for example, by presenting an overlay
		
	}
	
	func sessionInterruptionEnded(_ session: ARSession) {
		// Reset tracking and/or remove existing anchors if consistent tracking is required
		
	}
}

extension ARViewController : FoggyLogoDelegate {
	func foggyLogo(lightsPower: Bool, _ asserted: Bool) {
		print("Lights are on: \(lightsPower)")
	}
	
}
