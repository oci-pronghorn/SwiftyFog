//
//  TrainViewController.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/26/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import SwiftyFog

class TrainViewController: UIViewController {	
	let engine = Engine()
	let lights = Lights()
	let billboard = Billboard()
	
    var mqtt: MQTTBridge! {
		didSet {
			engine.mqtt = mqtt.createBridge(subPath: "engine")
			lights.mqtt = mqtt.createBridge(subPath: "lights")
			billboard.mqtt = mqtt.createBridge(subPath: "billboard")
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}
	
	func connected() {
		engine.start()
		lights.start()
		billboard.start();
	}
	
	func disconnected() {
		engine.stop()
		lights.stop()
		billboard.stop();
	}
	
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
		let numerator = Int64(sender!.value)
		let denominator = Int64(sender!.maximumValue)
		let rational = FogRational(num: numerator, den: denominator)
		engine.newPower = rational
	}
	
	@IBAction
	func onDoEngineCalibration(sender: UISlider?) {
		let numerator = Int64(sender!.value)
		let denominator = Int64(sender!.maximumValue)
		let rational = FogRational(num: numerator, den: denominator)
		engine.calibration = rational
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
