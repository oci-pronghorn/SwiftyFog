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
	
	@IBOutlet weak var connectMetrics: FSDAirportFlipLabel!
	@IBOutlet weak var connectedImage: UIImageView!
	@IBOutlet weak var stopStartButton: UIButton!
	
	@IBOutlet weak var billboardImage: UIImageView!
	
	@IBOutlet weak var lightCalibration: UISlider!
	@IBOutlet weak var lightPower: UISegmentedControl!
	@IBOutlet weak var engineCalibration: UISlider!
	@IBOutlet weak var enginePower: ScrubControl!
	
	@IBOutlet weak var powerGauge: WMGaugeView!
	@IBOutlet weak var lightIndicatorImage: UIImageView!
	@IBOutlet weak var ambientGauge: WMGaugeView!
	
	let pulsator = Pulsator()
	
	var mqttControl: MQTTControl! {
		didSet {
			mqttControl.start()
		}
	}
	
    var mqtt: MQTTBridge! {
		didSet {
			train.delegate = self
			train.mqtt = mqtt
			
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
		
		powerGauge.rangeLabels = ["Reverse", "Idle", "Forward"]
		powerGauge.rangeColors = [UIColor.red, UIColor.yellow, UIColor.green]
		ambientGauge.rangeLabels = ["Dark", "Light"]
		ambientGauge.rangeColors = [UIColor.darkGray, UIColor.lightGray]
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
				pulsator.start()
				self.connectedImage?.isHighlighted = true
				self.connectMetrics.text = "\(counter).-.-"
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
	
	func pinged() {
		pulsator.start()
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
	
	@IBAction func stopStartConnecting(sender: UIButton?) {
		if mqttControl.started {
			mqttControl.stop()
		}
		else {
			mqttControl.start()
		}
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

extension TrainViewController:
		TrainDelegate,
		BillboardDelegate,
		LightsDelegate,
		EngineDelegate {
	
	func train(handshake: Bool) {
	}

	func billboard(layout: FogBitmapLayout) {
	}
	
	func billboard(image: UIImage) {
		billboardImage?.image = image
	}
	
	func lights(powered: Bool, _ asserted: Bool) {
		lightIndicatorImage?.isHighlighted = powered
	}
	
	func lights(ambient: FogRational<Int64>, _ asserted: Bool) {
		self.ambientGauge?.setValue(Float(ambient.num), animated: true, duration: 0.5)
	}
	
	func lights(calibration: FogRational<Int64>, _ asserted: Bool) {
		ambientGauge?.rangeValues = [NSNumber(value: calibration.num), 256]
		if asserted {
			self.lightCalibration.rational = calibration
		}
	}
	
	func engine(power: FogRational<Int64>, _ asserted: Bool) {
		self.powerGauge?.setValue(Float(power.num), animated: true, duration: 0.5)
		if asserted {
			self.enginePower.rational = power
		}
	}
	
	func engine(calibration: FogRational<Int64>, _ asserted: Bool) {
		powerGauge?.rangeValues = [NSNumber(value: -calibration.num), NSNumber(value: calibration.num), 100]
		if asserted {
			self.engineCalibration.rational = calibration
		}
	}
}
