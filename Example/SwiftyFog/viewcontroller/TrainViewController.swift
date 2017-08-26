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

public extension ScrubControl {
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
	
	@IBOutlet weak var connectMetrics: FSDAirportFlipLabel!
	@IBOutlet weak var connectedImage: UIImageView!
	@IBOutlet weak var billboardImage: UIImageView!
	
	@IBOutlet weak var lightCalibration: UISlider!
	@IBOutlet weak var engineCalibration: UISlider!
	@IBOutlet weak var enginePower: ScrubControl!
	
	@IBOutlet weak var powerGauge: WMGaugeView!
	@IBOutlet weak var lightIndicatorImage: UIImageView!
	@IBOutlet weak var ambientGauge: WMGaugeView!
	
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
		powerGauge.rangeLabels = ["Reverse", "Idle", "Forward"]
		powerGauge.rangeColors = [UIColor.red, UIColor.yellow, UIColor.green]
		ambientGauge.rangeLabels = ["Dark", "Light"]
		ambientGauge.rangeColors = [UIColor.darkGray, UIColor.lightGray]
		
		self.engineCalibration.rational = engine.calibration
		self.enginePower.rational = engine.power
		self.connectedImage.isHighlighted = mqtt.connected
		lightIndicatorImage?.isHighlighted = lights.powered
		
		powerGauge.rangeValues = [NSNumber(value: -engine.calibration.num), NSNumber(value: engine.calibration.num), 100]
		ambientGauge.rangeValues = [NSNumber(value: lights.calibration.num), 256]
		
		self.connectMetrics.textSize = 24
		self.connectMetrics.useSound = true
		self.connectMetrics.fixedLength = 15
		self.connectMetrics.flipDuration = 0.1
		self.connectMetrics.flipDurationRange = 1.0
		self.connectMetrics.numberOfFlips = 1
		self.connectMetrics.numberOfFlipsRange = 1.0
		self.connectMetrics.flipTextColor = UIColor.white
		self.connectMetrics.flipBackGroundColor = UIColor.black
		
		self.connectMetrics.startedFlippingLabelsBlock = { [weak self] in
			//self?.changeButton.enabled = NO
		}
		self.connectMetrics.finishedFlippingLabelsBlock = {  [weak self] in
			//self?.changeButton.enabled = YES
		}
		
		self.connectMetrics.text = "\(0)\(0).\(0)\(0).\(0)\(0)"
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
	func doEnginePower(sender: ScrubControl?) {
		engine.setPower(sender!.rational)
	}
	
	@IBAction
	func doEngineCalibration(sender: UISlider?) {
		engine.calibrate(sender!.rational)
	}
	
	@IBAction
	func doLightOverride(sender: UISegmentedControl?) {
		let powerOverride = LightCommand(rawValue: Int32(sender!.selectedSegmentIndex))!
		lights.powerOverride = powerOverride
	}
	
	@IBAction
	func doLightCalibration(sender: UISlider?) {
		lights.calibrate(sender!.rational)
	}
}

extension TrainViewController: BillboardDelegate, LightsDelegate, EngineDelegate {
	func connected() {
		self.connectedImage?.isHighlighted = true
	}
	
	func disconnected() {
		self.connectedImage?.isHighlighted = false
	}
	
	func onImageSpecConfirmed(layout: FogBitmapLayout) {
	}
	
	func onLightsPowered(powered: Bool) {
		lightIndicatorImage?.isHighlighted = powered
	}
	
	func onLightsAmbient(power: FogRational<Int64>) {
		self.ambientGauge?.setValue(Float(power.num), animated: true, duration: 0.5)
	}
	
	func onLightsCalibrated(power: FogRational<Int64>) {
		ambientGauge?.rangeValues = [NSNumber(value: lights.calibration.num), 256]
	}
	
	func onEnginePower(power: FogRational<Int64>) {
		self.powerGauge?.setValue(Float(power.num), animated: true, duration: 0.5)
	}
	
	func onEngineCalibrated(power: FogRational<Int64>) {
		powerGauge?.rangeValues = [NSNumber(value: -power.num), NSNumber(value: power.num), 100]
	}
	
	func onPostImage(image: UIImage) {
		billboardImage?.image = image
	}
}
