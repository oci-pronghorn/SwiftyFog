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
import Vision
#if APP
import SwiftyFog_iOS
#endif

public class FoggyViewController: UIViewController {
	let logo = FoggyLogo()
	
	public var mqtt: MQTTBridge! {
		didSet {
			logo.mqtt = mqtt
		}
	}
	
	var renderer : FoggyLogoRenderer!
	
	var qrValue : String = ""
	
	// The activity indicator to be shown whenever it's trying to determine the QR code
	@IBOutlet weak var centerActivityView: UIView!
	
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	// Outlet to the scene
	@IBOutlet weak var sceneView: ARSCNView!
    
    public func buildUI() {
        #if APP
            // IB
        #else
        let b = self.view.bounds
        let sceceView = ARSCNView(frame: b)
        let centerActivityView = UIView(frame: CGRect(x: 10, y: 10, width: 56, height: 56))
        centerActivityView.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        centerActivityView.isOpaque = false
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 18, y: 18, width: 20, height: 20))
            
        self.sceneView = sceceView
        self.centerActivityView = centerActivityView
        self.activityIndicator = activityIndicator
            
        self.view.addSubview(self.sceneView)
        self.view.addSubview(self.centerActivityView)
        self.centerActivityView.addSubview(self.activityIndicator)
            
        #endif
        
        // Set the scene to the view
        // Add anitaliasing
        sceneView.scene = SCNScene()
        sceneView.antialiasingMode = SCNAntialiasingMode.multisampling4X
        self.centerActivityView.layer.cornerRadius = 5;
    }
	
	override public func viewDidLoad() {
		super.viewDidLoad()
        
        buildUI()

		logo.delegate = self
        
		// Set the renderer's delegate
		self.renderer = FoggyLogoRenderer(sceneView: sceneView)
		self.renderer.delegate = self
		
		// Create tap gesture recognizer
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gestureRecognizer:)))
		self.sceneView.addGestureRecognizer(tapGesture)
	}

	func isShowingActivityIndicator(_ status: Bool) {
		DispatchQueue.main.async {
			self.centerActivityView.isHidden = !status
		}
	}
	
	override public var prefersStatusBarHidden: Bool {
		return true
	}

	override public func viewWillAppear(_ animated: Bool) {
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
			  #if APP
				if(renderer.hitQRCode(node: node) && UIApplication.shared.canOpenURL(url)) {
					UIApplication.shared.open(url)
				}
				#endif
			}
		}
	}

	override public func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		// Pause the view's session
		sceneView.session.pause()
	}
    
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
}

extension FoggyViewController : FoggyLogoDelegate {
	
	func trainIsAlive(_ alive: Bool) {
		renderer.train(alive: alive)
	}
	
	public func foggyLogo(lightsPower: Bool) {
		renderer.lights(on: lightsPower)
	}
	
	public func foggyLogo(alive: Bool) {
		trainIsAlive(alive)
	}
	
	public func foggyLogo(accelerometerHeading: FogRational<Int64>) {
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

