//
//  TrainViewController.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/26/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftyFog_iOS

class TrainViewController: UIViewController {
	let train = Train()
	let engine = Engine()
	let lights = Lights()
	let sound = Sound()
	let billboard = Billboard()
	
	@IBOutlet weak var trainAlive: UIImageView!
	@IBOutlet weak var connectMetrics: FlipLabel!
	@IBOutlet weak var connectedImage: UIImageView!
	@IBOutlet weak var stopStartButton: UIButton!
    @IBOutlet weak var billboardText: UITextField!
	
	@IBOutlet weak var billboardImage: UIImageView!
	@IBOutlet weak var compass: WMGaugeView!
	
	@IBOutlet weak var lightOverride: UISegmentedControl!
	@IBOutlet weak var lightCalibration: UISlider!
	@IBOutlet weak var lightingGauge: WMGaugeView!
	
	@IBOutlet weak var enginePower: ScrubControl!
	@IBOutlet weak var engineCalibration: UISlider!
	@IBOutlet weak var engineGauge: WMGaugeView!
	
	@IBOutlet weak var soundControl: UISlider!
	
	@IBOutlet var pulsator: Pulsator!
	
    weak var crack: UIImageView?
    var player: AVAudioPlayer?
	
	var mqttControl: MQTTControl!
	
	var bypassFeed: Bool {
		return !mqttControl.started // just so I can see stuff while debugging
	}
	
	var mqtt: MQTTBridge! {
		didSet {
			engine.delegate = self
			engine.mqtt = mqtt.createBridge(subPath: "engine")
			
			lights.delegate = self
			lights.mqtt = mqtt.createBridge(subPath: "lights")
			
			billboard.delegate = self
			billboard.mqtt = mqtt.createBridge(subPath: "billboard")
			
			sound.mqtt = mqtt.createBridge(subPath: "sound")
			
			train.delegate = self
			train.mqtt = mqtt
		}
	}
}

// MARK: Life Cycle

extension TrainViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
		
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
		
		self.connectedImage.isHighlighted = mqttControl.connected
		self.stopStartButton.isSelected = mqttControl.started
		
		assertValues()
	}

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.layoutIfNeeded()
        // TODO get pulsator to do this automatically
        pulsator.position = connectedImage.layer.position
    }
}

// MARK: Connection State

extension TrainViewController {
	func mqtt(connected: MQTTConnectedState) {
		switch connected {
			case .started:
				self.stopStartButton.isSelected = mqttControl.started
				break
			case .connected(_, _, _, let counter):
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
			case .disconnected(_, _, _):
				self.connectedImage?.isHighlighted = false
				self.stopStartButton.isSelected = mqttControl.started
				self.trainAlive.isHighlighted = false
				feedbackCut()
				break
		}
	}
	
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
	func doSoundPiezo(sender: UISlider?) {
		sound.control(piezo: sender!.rational)
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

// MARK: Model Extensions

extension TrainViewController:
		TrainDelegate,
		EngineDelegate,
		LightsDelegate,
        BillboardDelegate {
	
	func train(alive: Bool) {
		if alive == false {
			feedbackCut()
		}
		trainAlive.isHighlighted = alive
	}
    
    func train(faults: MotionFaults, _ asserted: Bool) {
        if faults.hasFault == false {
            crack?.removeFromSuperview()
        }
        else if (self.crack == nil) {
            self.player = AVAudioPlayer.playSound()
            let crack = UIImageView(image: #imageLiteral(resourceName: "brokenglass"))
            crack.translatesAutoresizingMaskIntoConstraints = false
            crack.alpha = 0.25
            view.addSubview(crack)
            crack.bindFrameToSuperviewBounds()
            self.crack = crack
        }
    }
	
	func engine(power: TrainRational, _ asserted: Bool) {
		engineGauge?.setValue(Float(power.num), animated: true, duration: 0.5)
		if asserted {
			self.enginePower.rational = power
		}
	}
    
    func engine(state: EngineState, _ asserted: Bool) {
        switch state {
            case .idle:
                engineGauge?.indicatorImage = #imageLiteral(resourceName: "MotionIdle")
            case .forward:
                engineGauge?.indicatorImage = #imageLiteral(resourceName: "MotionForward")
            case .reverse:
                engineGauge?.indicatorImage = #imageLiteral(resourceName: "MotionReverse")
        }
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
		lightingGauge?.isIndicatorHighlighted = power
	}
	
	func lights(calibration: TrainRational, _ asserted: Bool) {
		lightingGauge?.ranges[0].value = CGFloat(calibration.num)
		if asserted {
			self.lightCalibration.rational = calibration
		}
	}
	
	func lights(ambient: TrainRational, _ asserted: Bool) {
		self.lightingGauge?.setValue(Float(ambient.num), animated: true, duration: 0.5)
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
}
