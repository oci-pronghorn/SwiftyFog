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

class FoggyLogoRenderer : NSObject, ARSCNViewDelegate {
	
	let logo = FoggyLogo()
	
	var qrDetector : QRDetection!
	
	var hasAppliedHeading = false
	
	// SceneNode for the 3D models
	var logoNode : SCNNode!
	var lightbulbNode : SCNNode!
	var largeSpotLightNode : SCNNode!
	var qrValueTextNode : SCNNode!
	
	let spotlightColorBulb = UIColor.yellow
	let spotlightColorDead = UIColor.red
	
	var sceneView : 	ARSCNView!
	
	private var oldRotationY: CGFloat = 0.0
	
	public init(sceneView : ARSCNView) {
		qrDetector = QRDetection(sceneView: self.sceneView, confidence: 0.8)
		
		super.init()
		qrDetector.delegate = self
		
		self.sceneView = sceneView;
	}
	
	func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
		
		// If this is our anchor, create a node
		if self.qrDetector.detectedDataAnchor?.identifier == anchor.identifier {
			
			//We rendered, so stop showing the activity indicator
			//isShowingActivityIndicator(false)
			
			guard let virtualObjectScene = SCNScene(named: "art.scnassets/logo.scn") else {
				return nil
			}
			
			//Grab the required nodes
			logoNode = virtualObjectScene.rootNode.childNode(withName: "OCILogo", recursively: false)!
			
			//Before render we have already received a rotation, set it to that
			logoNode.rotateToYAxis(to: oldRotationY.degreesToRadians)
			
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
			
			let (minBound, maxBound) = logoNode.boundingBox
			qrValueTextNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, 0.5)
			qrValueTextNode.position = SCNVector3(0,0,0)
			
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

extension FoggyLogoRenderer: QRDetectionDelegate {
		
		func foundQRValue(stringValue: String) {
			if let qrValueTextNode = qrValueTextNode {
				qrValueTextNode.setGeometryText(value: stringValue)
			}
		}
		
		func updatedAnchor() {
			//print("Anchor changed")
		}
		
		func detectRequestError(error: Error) {
			print("Error in QR: \(error.localizedDescription)")
		}
}

