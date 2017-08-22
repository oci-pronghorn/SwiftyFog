//
//  TrainViewController.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/26/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import SwiftyFog

public extension UISlider {
	public var rational: FogRational<Int64> {
		get {
			let numerator = Int64(self.value)
			let denominator = Int64(self.maximumValue)
			return FogRational(num: numerator, den: denominator)
		}
		set {
			self.value = self.maximumValue * Float(newValue.num) / Float(newValue.den)
		}
	}
}

class TrainViewController: UIViewController {	
	let engine = Engine()
	let lights = Lights()
	let billboard = Billboard()
	
	@IBOutlet weak var connectedImage: UIImageView!
	@IBOutlet weak var billboardImage: UIImageView!
	@IBOutlet weak var engineCalibration: UISlider!
	@IBOutlet weak var enginePower: UISlider!
	@IBOutlet weak var lightsImage: UIImageView!
	
    var mqtt: MQTTBridge! {
		didSet {
			engine.delegate = self
			engine.mqtt = mqtt.createBridge(subPath: "engine")
			
			lights.delegate = self
			lights.mqtt = mqtt.createBridge(subPath: "lights")
			
			billboard.delegate = self
			billboard.mqtt = mqtt.createBridge(subPath: "billboard")
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.engineCalibration.rational = engine.calibration
		self.enginePower.rational = engine.power
		self.lightsImage.image = lights.powered ?  #imageLiteral(resourceName: "TorchOn") : #imageLiteral(resourceName: "TorchOff")
		self.connectedImage.image = mqtt.connected ?  #imageLiteral(resourceName: "TorchOn") : #imageLiteral(resourceName: "TorchOff")
	}
}

extension TrainViewController {
	@IBAction
	func onPicture(sender: UIButton?) {
		let photos = PhotosAccess(title: nil, root: self);
		photos.selectImage(hasCamera: true, hasClear: false) { (image, access) in
			if access {
				if let image = image {
					DispatchQueue.main.async {
						self.billboard.display(image: image)
					}
				}
			}
		}
	}
	
	@IBAction
	func onPower(sender: UISlider?) {
		engine.power = sender!.rational
	}
	
	@IBAction
	func onDoEngineCalibration(sender: UISlider?) {
		engine.calibration = sender!.rational
	}
	
	@IBAction
	func onLight(sender: UISegmentedControl?) {
		let cmd = LightCommand(rawValue: Int32(sender!.selectedSegmentIndex))!
		lights.cmd = cmd
	}
	
	@IBAction
	func onLightCalibration(sender: UIButton?) {
		lights.calibrate();
	}
}

extension TrainViewController: BillboardDelegate, LightsDelegate, EngineDelegate {
	func connected() {
		self.connectedImage?.image =  #imageLiteral(resourceName: "TorchOn")
		engine.start()
	}
	
	func disconnected() {
		self.connectedImage?.image = #imageLiteral(resourceName: "TorchOff")
		engine.stop()
	}
	
	func onImageSpecConfirmed(layout: FogBitmapLayout) {
		print("Billboard Specified: \(layout)")
	}
	
	func onLightsPowered(powered: Bool) {
		lightsImage?.image = powered ?  #imageLiteral(resourceName: "TorchOn") : #imageLiteral(resourceName: "TorchOff")
	}
	
	func onLightsAmbient(power: FogRational<Int64>) {
		print("Light Ambient: \(power)")
	}
	
	func onPowerConfirm(power: FogRational<Int64>) {
		if self.enginePower?.isHighlighted ?? true == false {
			self.enginePower?.rational = power
		}
	}
	
	func onPowerCalibrated(power: FogRational<Int64>) {
		if self.engineCalibration?.isHighlighted ?? true == false {
			self.engineCalibration?.rational = power
		}
	}
	
	func onPostImage(image: UIImage) {
		billboardImage.image = image
	}
}
