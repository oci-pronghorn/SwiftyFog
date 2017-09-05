//
//  TrainViewController.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/26/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import SwiftyFog

public extension UIView {
	func setSyncronized(_ syncronized: Bool) {
		self.backgroundColor = syncronized ? UIColor.clear : UIColor.yellow.withAlphaComponent(0.15)
	}
}

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
	let train = Train()
	let engine = Engine()
	let lights = Lights()
	let billboard = Billboard()
	
	@IBOutlet weak var trainAlive: UIImageView!
	@IBOutlet weak var trainName: UILabel!
	@IBOutlet weak var connectMetrics: FSDAirportFlipLabel!
	@IBOutlet weak var connectedImage: UIImageView!
	@IBOutlet weak var stopStartButton: UIButton!
	
	@IBOutlet weak var billboardImage: UIImageView!
	
	@IBOutlet weak var lightOverride: UISegmentedControl!
	@IBOutlet weak var lightIndicatorImage: UIImageView!
	@IBOutlet weak var lightCalibration: UISlider!
	@IBOutlet weak var lightingGauge: WMGaugeView!
	
	@IBOutlet weak var enginePower: ScrubControl!
	@IBOutlet weak var engineCalibration: UISlider!
	@IBOutlet weak var engineGauge: WMGaugeView!
	
	let pulsator = Pulsator()
	
	var mqttControl: MQTTControl! {
		didSet {
			mqttControl.start()
		}
	}
	
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

	override func viewDidLoad() {
		super.viewDidLoad()
		self.codeUi()
		
		self.connectedImage.isHighlighted = mqttControl.connected
		self.stopStartButton.isSelected = mqttControl.started
		
		assertValues()
	}
	
	func codeUi() {
        connectedImage.layer.superlayer?.insertSublayer(pulsator, below: connectedImage.layer)
        pulsator.animationDuration = 1
		pulsator.backgroundColor = UIColor.blue.cgColor
		pulsator.repeatCount = 1
		
		engineGauge.rangeLabels = ["Reverse", "Idle", "Forward"]
		engineGauge.rangeColors = [UIColor.red, UIColor.yellow, UIColor.green]
		lightingGauge.rangeLabels = ["Dark", "Light"]
		lightingGauge.rangeColors = [UIColor.darkGray, UIColor.lightGray]
	}

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.layoutIfNeeded()
        pulsator.position = connectedImage.layer.position
        pulsator.radius = connectedImage.frame.width
    }
}

extension TrainViewController {
	func mqtt(connected: MQTTConnectedState) {
		switch connected {
			case .started:
				self.stopStartButton.isSelected = mqttControl.started
				break
			case .connected(let counter):
				feedbackCut()
				assertValues()
				pulsator.backgroundColor = UIColor.green.cgColor
				pulsator.start()
				self.connectedImage?.isHighlighted = true
				self.connectMetrics.text = "\(counter).-.-"
				break
			case .pinged(let status):
				switch status {
					case .notConnected:
						pulsator.backgroundColor = UIColor.black.cgColor
						pulsator.start()
						break
					case .sent:
						break
					case .skipped:
						pulsator.backgroundColor = UIColor.white.cgColor
						pulsator.start()
						break
					case .ack:
						pulsator.backgroundColor = UIColor.blue.cgColor
						pulsator.start()
						break
					case .serverDied:
						pulsator.backgroundColor = UIColor.red.cgColor
						pulsator.start()
						break
				}
				break
			case .retry(let counter, let rescus, let attempt, _):
				self.connectMetrics.text = "\(counter).\(rescus).\(attempt)"
				break
			case .retriesFailed(let counter, let rescus, _):
				self.connectMetrics.text = "\(counter).\(rescus).-"
				break
			case .discconnected(_, _):
				self.connectedImage?.isHighlighted = false
				self.stopStartButton.isSelected = mqttControl.started
				feedbackCut()
				break
		}
	}
}

extension TrainViewController {
	func feedbackCut() {
		engine.reset()
		lights.reset()
		billboard.reset()
	}

	func assertValues() {
		engine.assertValues()
		lights.assertValues()
		billboard.assertValues()
	}
	
	func isReady() {
/*		if engine.hasFeedback &&
			lights.hasFeedback &&
		billboard.hasFeedback {
			print("ready")
		}
		else {
			print("not yet")
		}*/
	}
	
	@IBAction func stopStartConnecting(sender: UIButton?) {
		if mqttControl.started {
			mqttControl.stop()
		}
		else {
			mqttControl.start()
		}
	}
	
	@IBAction
	func doEnginePower(sender: ScrubControl?) {
		engine.control(power: sender!.rational)
	}
	
	@IBAction
	func doEngineCalibration(sender: UISlider?) {
		engine.control(calibration: sender!.rational)
	}
	
	@IBAction
	func doLightOverride(sender: UISegmentedControl?) {
		let override = LightCommand(rawValue: Int32(sender!.selectedSegmentIndex))!
		lights.control(override: override)
	}
	
	@IBAction
	func doLightCalibration(sender: UISlider?) {
		lights.control(calibration: sender!.rational)
	}
	
	@IBAction
	func onPicture(sender: UIButton?) {
		let photos = PhotosAccess(title: nil, root: self);
		photos.selectImage(hasCamera: true, hasClear: false) { (image, access) in
			if access {
				if let image = image {
					DispatchQueue.main.async {
						self.billboard.control(image: image)
					}
				}
			}
		}
	}
}

extension TrainViewController:
		TrainDelegate,
		EngineDelegate,
		LightsDelegate,
		BillboardDelegate {
	
	func train(alive: Bool) {
		if alive == false {
			feedbackCut()
		}
	}
	
	func engine(power: FogRational<Int64>, _ asserted: Bool) {
		engineGauge?.setValue(Float(power.num), animated: true, duration: 0.5)
		if asserted {
			self.enginePower.rational = power
			isReady()
		}
	}
	
	func engine(calibration: FogRational<Int64>, _ asserted: Bool) {
		engineGauge?.rangeValues = [NSNumber(value: -calibration.num), NSNumber(value: calibration.num), 100]
		if asserted {
			self.engineCalibration.rational = calibration
			isReady()
		}
	}
	
	func lights(override: LightCommand, _ asserted: Bool) {
		if asserted {
			lightOverride.selectedSegmentIndex = Int(override.rawValue)
			isReady()
		}
	}
	
	func lights(power: Bool, _ asserted: Bool) {
		lightIndicatorImage?.isHighlighted = power
	}
	
	func lights(calibration: FogRational<Int64>, _ asserted: Bool) {
		lightingGauge?.rangeValues = [NSNumber(value: calibration.num), 256]
		if asserted {
			self.lightCalibration.rational = calibration
			isReady()
		}
	}
	
	func lights(ambient: FogRational<Int64>, _ asserted: Bool) {
		self.lightingGauge?.setValue(Float(ambient.num), animated: true, duration: 0.5)
		if asserted {
			isReady()
		}
	}

	func billboard(layout: FogBitmapLayout) {
		isReady()
	}
	
	func billboard(image: UIImage) {
		billboardImage?.image = image
	}
}
