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

class FoggyViewController: UIViewController {
	
	let logo = FoggyLogo()
	
	var mqtt: MQTTBridge! {
		didSet {
			logo.delegate = self
			logo.mqtt = mqtt
		}
	}
	
	var renderer : FoggyLogoRenderer!
	
	var trainDetector : TrainDetection!
	
	var qrValue : String = ""
	
	// The activity indicator to be shown whenever it's trying to determine the QR code
	@IBOutlet weak var centerActivityView: UIView!
	
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	// Outlet to the scene
	@IBOutlet weak var sceneView: ARSCNView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Set the scene to the view
		sceneView.scene = SCNScene()
		
		// Set the view's delegate
		self.renderer = FoggyLogoRenderer(sceneView: sceneView)
		self.renderer.delegate = self
		
		// Set the ML's view
		self.trainDetector = TrainDetection(sceneView: sceneView)
		
		// Make the activity indicator prettier
		self.centerActivityView.layer.cornerRadius = 5;
		
		// Add anitaliasing
		sceneView.antialiasingMode = SCNAntialiasingMode.multisampling4X
		
		// Create tap gesture recognizer
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gestureRecognizer:)))
		self.sceneView.addGestureRecognizer(tapGesture)
	}
	
	func isShowingActivityIndicator(_ status: Bool) {
		DispatchQueue.main.async(execute: {
				self.centerActivityView.isHidden = !status
		})
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
	
	@objc func handleTap(gestureRecognizer: UITapGestureRecognizer) {
		let touchLocation = gestureRecognizer.location(in: self.sceneView)
		let hitResults = self.sceneView.hitTest(touchLocation, options: [:])
		
		if !hitResults.isEmpty {
			
			guard let hitResult = hitResults.first else {
				return
			}
			let node = hitResult.node
			
			if let url = URL(string: qrValue) {
				if(renderer.hitQRCode(node: node) && UIApplication.shared.canOpenURL(url)) {
					UIApplication.shared.open(url)
				}
			}
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		// Pause the view's session
		sceneView.session.pause()
	}
}

extension FoggyViewController : FoggyLogoDelegate {
	
	func mqtt(connected: MQTTConnectedState) {
		switch connected {
		case .started:
			trainIsAlive(false)
		case .connected:
			trainIsAlive(true)
		case .retry:
			break
		case .retriesFailed:
			break
		case .pinged:
			break
		case .disconnected:
			trainIsAlive(false)
		}
	}
	
	func trainIsAlive(_ alive: Bool) {
		renderer.train(alive: alive)
	}
	
	func foggyLogo(lightsPower: Bool) {
		renderer.lights(on: lightsPower)
	}
	
	func foggyLogo(alive: Bool) {
		trainIsAlive(alive)
	}
	
	func foggyLogo(accelerometerHeading: FogRational<Int64>) {
		renderer.heading(heading: accelerometerHeading)
	}
}

extension FoggyViewController : FoggyLogoRendererDelegate {
	func qrCodeDetected(code: String) {
		self.qrValue = code
		
		print("found qr value! \(self.qrValue)")
	}
	
	func loading(_ state : Bool) {
		self.isShowingActivityIndicator(state)
	}
}
