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
	let train = Train()
	
	@IBOutlet weak var connectMetrics: FSDAirportFlipLabel!
	@IBOutlet weak var connectedImage: UIImageView!
	@IBOutlet weak var billboardImage: UIImageView!
	
	@IBOutlet weak var lightCalibration: UISlider!
	@IBOutlet weak var lightPower: UISegmentedControl!
	@IBOutlet weak var engineCalibration: UISlider!
	@IBOutlet weak var enginePower: ScrubControl!
	
	@IBOutlet weak var powerGauge: WMGaugeView!
	@IBOutlet weak var lightIndicatorImage: UIImageView!
	@IBOutlet weak var ambientGauge: WMGaugeView!
	
	let pulsator = Pulsator()
	
    var mqtt: MQTTBridge! {
		didSet {
			engine.delegate = self
			engine.mqtt = mqtt.createBridge(subPath: "engine")
			
			lights.delegate = self
			lights.mqtt = mqtt.createBridge(subPath: "lights")
			
			billboard.delegate = self
			billboard.mqtt = mqtt.createBridge(subPath: "billboard")
			
			train.delegate = self
			train.mqtt = mqtt
		}
	}

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.layoutIfNeeded()
        pulsator.position = connectedImage.layer.position
        pulsator.radius = connectedImage.frame.width
    }

	override func viewDidLoad() {
		super.viewDidLoad()
		
        connectedImage.layer.superlayer?.insertSublayer(pulsator, below: connectedImage.layer)
        pulsator.animationDuration = 1
		pulsator.backgroundColor = UIColor.blue.cgColor
		pulsator.repeatCount = 1
		
		powerGauge.rangeLabels = ["Reverse", "Idle", "Forward"]
		powerGauge.rangeColors = [UIColor.red, UIColor.yellow, UIColor.green]
		ambientGauge.rangeLabels = ["Dark", "Light"]
		ambientGauge.rangeColors = [UIColor.darkGray, UIColor.lightGray]
		
		updateGauges()
		updateControls()
		
		/*
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
		*/
	}
}

extension TrainViewController {

	func updateGauges() {
		//self.connectedImage.isHighlighted = mqtt.connected
		self.powerGauge.rangeValues = [NSNumber(value: -engine.calibration.resolved.num), NSNumber(value: engine.calibration.resolved.num), 100]
		self.ambientGauge.rangeValues = [NSNumber(value: lights.calibration.resolved.num), 256]
		self.lightIndicatorImage?.isHighlighted = lights.powered.resolved
	}
	
	func updateControls() {
		self.engineCalibration.rational = engine.calibration.resolved
		self.enginePower.rational = engine.power.resolved
		self.lightCalibration.rational = lights.calibration.resolved
		self.lightPower.selectedSegmentIndex = Int(lights.powerOverride.rawValue)
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

extension TrainViewController {
	func mqtt(connected: MQTTConnectedState) {
		switch connected {
			case .connected(let counter):
				pulsator.start()
				self.connectedImage?.isHighlighted = true
				break
			case .retry(let rescus, let attempt, _):
				break
			case .discconnected(let reason, let error):
				self.connectedImage?.isHighlighted = false
				break
		}
	}
	
	func pinged() {
		pulsator.start()
	}
}

extension TrainViewController: BillboardDelegate, LightsDelegate, EngineDelegate, TrainDelegate {

	func train(handshake: Bool) {
	}
	
	func onImageSpecConfirmed(layout: FogBitmapLayout) {
	}
	
	func onLightsPowered(powered: Bool, _ asserted: Bool) {
		lightIndicatorImage?.isHighlighted = powered
	}
	
	func onLightsAmbient(power: FogRational<Int64>, _ asserted: Bool) {
		self.ambientGauge?.setValue(Float(power.num), animated: true, duration: 0.5)
	}
	
	func onLightsCalibrated(power: FogRational<Int64>, _ asserted: Bool) {
		ambientGauge?.rangeValues = [NSNumber(value: power.num), 256]
		if asserted {
			self.lightCalibration.rational = power
		}
	}
	
	func onEnginePower(power: FogRational<Int64>, _ asserted: Bool) {
		self.powerGauge?.setValue(Float(power.num), animated: true, duration: 0.5)
		if asserted {
			self.enginePower.rational = power
		}
	}
	
	func onEngineCalibrated(power: FogRational<Int64>, _ asserted: Bool) {
		powerGauge?.rangeValues = [NSNumber(value: -power.num), NSNumber(value: power.num), 100]
		if asserted {
			self.engineCalibration.rational = power
		}
	}
	
	func onPostImage(image: UIImage) {
		billboardImage?.image = image
	}
}
