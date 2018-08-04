//
//  TrainViewController.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/26/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import WebKit
import AVFoundation
import SwiftyFog_iOS

class TrainViewController: UIViewController {
	let impact = UIImpactFeedbackGenerator()
	let discovery = TrainDiscovery()
	let train = Train()
	let engine = Engine()
	let lights = Lights()
	let billboard = Billboard()
	
	@IBOutlet weak var trainAlive: UIImageView!
	@IBOutlet weak var connectMetrics: FlipLabel!
	@IBOutlet weak var connectedImage: UIImageView!
	@IBOutlet weak var stopStartButton: UIButton!
    @IBOutlet weak var billboardText: UITextField!
	
	@IBOutlet weak var billboardImage: UIImageView!
	@IBOutlet weak var compass: GaugeView!
	
	@IBOutlet weak var lightOverride: UISegmentedControl!
	@IBOutlet weak var lightCalibration: UISlider!
	@IBOutlet weak var lightingGauge: GaugeView!
	
	@IBOutlet weak var enginePower: ScrubControl!
	@IBOutlet weak var engineCalibration: UISlider!
	@IBOutlet weak var engineGauge: GaugeView!
	
	@IBOutlet weak var soundControl: UISlider!
	
	@IBOutlet var pulsator: Pulsator!
	
	@IBOutlet var webView: WKWebView!
	
	var mqttControl: MQTTControl!
	
	var trainName: String = ""
	var alive = false
	/*
	func setBridge(bridging: MQTTBridge, force: Bool) {
		if trainName != name || force {
			self.trainName = name
			let scoped = bridging.createBridge(subPath: trainName)
			self.mqtt = scoped
		}
	}
	*/
	
	var discoverBridge: MQTTBridge! {
		didSet {
			self.discoveredTrain = nil
			discovery.mqtt = discoverBridge
		}
	}
	
	private var discoveredTrain: DiscoveredTrain? {
		didSet {
			let trainBridge = discoveredTrain != nil ? discoverBridge.createBridge(subPath: discoveredTrain!.trainName) : nil
			train.mqtt = trainBridge
			engine.mqtt = trainBridge?.createBridge(subPath: "engine")
			lights.mqtt = trainBridge?.createBridge(subPath: "lights")
			billboard.mqtt = trainBridge?.createBridge(subPath: "billboard")
		}
	}
	
	private var bypassFeed: Bool {
		return !mqttControl.started // just so I can see stuff while debugging
	}
    private weak var crack: UIImageView?
    private var player: AVAudioPlayer?

// MARK: Life Cycle
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		commonInit()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}
	
	private func commonInit() {
		discovery.delegate = self
		engine.delegate = self
		lights.delegate = self
		billboard.delegate = self
		train.delegate = self
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		/*
		self.compass.scaleDescription = { (v, i) in
			if v == 0 {
				return "N".localized
			}
			else if v == 90 {
				return "E".localized
			}
			else if v == 180 {
				return "S".localized
			}
			return "W".localized
		}
		*/
		assertConnectionState()
		assertValues()
		billboardPresentConnectionStatus()
	}

	// Force iPads to respect landscape (horizontalSizeClass compact)
	override public var traitCollection: UITraitCollection {
		if UIDevice.current.userInterfaceIdiom == .pad && UIDevice.current.orientation.isPortrait {
			return UITraitCollection(traitsFrom:[
				UITraitCollection(horizontalSizeClass: .compact),
				UITraitCollection(verticalSizeClass: .regular)])
		}
		return super.traitCollection
	}
}

// MARK: Connection State

extension TrainViewController {

	func mqtt(connected: MQTTConnectedState) {
		switch connected {
			case .started:
				self.stopStartButton.isSelected = mqttControl.started
				billboardPresentConnectionStatus()
				break
			case .connected(_, _, _, let counter):
				feedbackCut()
				assertValues()
				pulsator.backgroundColor = UIColor.green.cgColor
				pulsator.start()
				self.connectedImage?.isHighlighted = true
				self.connectMetrics.text = "\(counter).-.-"
				billboardPresentConnectionStatus()
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
			case .disconnected(_, _, _):
				self.connectedImage?.isHighlighted = false
				self.stopStartButton.isSelected = mqttControl.started
				self.trainAlive.isHighlighted = false
				feedbackCut()
				billboardPresentConnectionStatus()
				break
		}
	}
	
	func assertConnectionState() {
		self.connectedImage.isHighlighted = mqttControl.connected
		self.stopStartButton.isSelected = mqttControl.started
	}

	func assertValues() {
		train.assertValues()
		engine.assertValues()
		lights.assertValues()
		billboard.assertValues()
	}
	
	func feedbackCut() {
		train.reset()
		engine.reset()
		lights.reset()
		billboard.reset()
	}
}

// MARK: UI Reactions

extension TrainViewController: UITextFieldDelegate {
    
    @IBAction func stopStartConnecting(sender: UIButton?) {
        if mqttControl.started {
            mqttControl.stop()
        }
        else {
            mqttControl.start()
        }
    }
	
	@IBAction func billboardTextChanged(sender: UIButton?) {
		billboard.control(text: billboardText.text ?? "")
	}
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
	
	@IBAction
	func shutdownTrain(sender: UILongPressGestureRecognizer) {
		train.controlShutdown()
	}
	
	@IBAction
	func requestFeedback(sender: UITapGestureRecognizer) {
		train.askForFeedback()
	}
    
    @IBAction
    func faultTrain(sender: UIButton?) {
        train.controlFault()
		if bypassFeed {
			self.train(faults: MotionFaults(withFault: crack == nil), false)
		}
    }
	
	@IBAction
	func doEnginePower(sender: ScrubControl?) {
		engine.control(power: sender!.rational)
		if bypassFeed {
			self.engine(power: sender!.rational, false)
		}
	}
	
	@IBAction
	func doEngineCalibration(sender: UISlider?) {
		engine.control(calibration: sender!.rational)
		if bypassFeed {
			self.engine(calibration: sender!.rational, false)
		}
	}
	
	@IBAction
	func doLightOverride(sender: UISegmentedControl?) {
		let override = LightCommand(rawValue: Int32(sender!.selectedSegmentIndex))!
		lights.control(override: override)
		if bypassFeed {
			self.lights(override: override, false)
		}
	}
	
	@IBAction
	func doLightCalibration(sender: UISlider?) {
		lights.control(calibration: sender!.rational)
		if bypassFeed {
			self.lights(calibration: sender!.rational, false)
		}
	}
	
	@IBAction
	func onPicture(sender: UIButton?) {
		let photos = PhotosAccess(title: nil, root: self);
		photos.selectImage(hasCamera: true, hasLibrary: false, hasClear: false) { (image, access) in
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

// MARK: Model Delegate

extension TrainViewController: TrainDiscoveryDelegate {
	func train(_ train: DiscoveredTrain, discovered: Bool, transitionary: Bool) {
		if self.discoveredTrain == nil && discovered {
			self.discoveredTrain = train
		}
		if discovered == false {
			if train.trainName == discoveredTrain?.trainName {
				self.discoveredTrain = self.discovery.firstTrain
			}
		}
	}
}

extension TrainViewController:
		TrainDelegate,
		EngineDelegate,
		LightsDelegate,
		BillboardDelegate {

	func onSubscriptionAck(status: MQTTSubscriptionStatus) {
		//print("***Subscription Status: \(status)")
	}
	
	func train(alive: Bool, named: String?) {
		if alive == false {
			feedbackCut()
		}
		self.alive = alive
		trainAlive.isHighlighted = alive
		self.billboardPresentConnectionStatus()
	}
    
    func train(faults: MotionFaults, _ asserted: Bool) {
        if faults.hasFault == false {
            crack?.removeFromSuperview()
        }
        else if (self.crack == nil) {
            self.player = AVAudioPlayer.playSound()
            impact.impactOccurred()
            let crack = UIImageView(image: #imageLiteral(resourceName: "brokenglass"))
            crack.translatesAutoresizingMaskIntoConstraints = false
            crack.alpha = 0.25
            view.addSubview(crack)
            crack.bindFrameToSuperviewBounds()
            self.crack = crack
        }
    }
	
	func train(webHost: String?) {
		if let webHost = webHost, let url = URL(string: webHost), !webHost.isEmpty {
			webView.isHidden = false
			let request = URLRequest(url: url)
			webView.load(request)
		}
		else {
			webView.isHidden = true
		}
	}
	
	func engine(power: TrainRational, _ asserted: Bool) {
		engineGauge?.setValue(CGFloat(power.num), animated: true, duration: 0.5)
		if asserted {
			self.enginePower.rational = power
		}
	}
    
    func engine(state: EngineState, _ asserted: Bool) {
    	let colorName: String
        switch state {
            case .idle:
                colorName = "NoPower"
            case .forward:
                colorName = "Forward"
            case .reverse:
                colorName = "Reverse"
        }
		engineGauge?.indicatorTint = UIColor(named: colorName)
    }
	
	func engine(calibration: TrainRational, _ asserted: Bool) {
		engineGauge?.ranges[0].value = CGFloat(-calibration.num)
		engineGauge?.ranges[1].value = CGFloat(calibration.num)
		if asserted {
			self.engineCalibration.rational = calibration
		}
	}
	
	func lights(override: LightCommand, _ asserted: Bool) {
		if asserted {
			lightOverride.selectedSegmentIndex = Int(override.rawValue)
		}
	}
	
	func lights(power: Bool, _ asserted: Bool) {
		lightingGauge?.indicatorTint = power ? UIColor(named: "LightsOn")! : UIColor(named: "NoPower")!
	}
	
	func lights(calibration: TrainRational, _ asserted: Bool) {
		lightingGauge?.ranges[0].value = CGFloat(calibration.num)
		if asserted {
			self.lightCalibration.rational = calibration
		}
	}
	
	func lights(ambient: TrainRational, _ asserted: Bool) {
		self.lightingGauge?.setValue(CGFloat(ambient.num), animated: true, duration: 0.15)
		if asserted {
		}
	}

	func billboard(layout: FogBitmapLayout) {
	}
	
	func billboard(image: UIImage) {
		billboardImage?.image = image
	}
    
    func billboard(text: String, _ asserted: Bool) {
        if asserted {
            billboardText.text = text
        }
    }
	
    func billboardPresentConnectionStatus() {
		if mqttControl.started {
			if mqttControl.connected {
				if self.alive {
					billboardText.isEnabled = true
					billboardText.text = ""
				}
				else {
					billboardText.text = "No Train"
					billboardText.isEnabled = false
				}
			}
			else {
				self.alive = false
				billboardText.text = "Connecting..."
				billboardText.isEnabled = false
			}
		}
		else {
			self.alive = false
			billboardText.text = "No Connection"
			billboardText.isEnabled = false
		}
		billboardText.backgroundColor = UIColor(named: billboardText.isEnabled ? "Background" : "Gold")!
	}
}
