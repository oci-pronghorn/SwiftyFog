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
	@IBOutlet weak var trainName: UILabel!
	@IBOutlet weak var connectMetrics: FlipLabel!
	@IBOutlet weak var connectedImage: UIImageView!
	@IBOutlet weak var stopStartButton: UIButton!
    @IBOutlet weak var billboardText: UITextField!
	
	@IBOutlet weak var billboardImage: UIImageView!
	@IBOutlet weak var compass: WMGaugeView!
	
	@IBOutlet weak var lightOverride: UISegmentedControl!
	@IBOutlet weak var lightIndicatorImage: UIImageView!
	@IBOutlet weak var lightCalibration: UISlider!
	@IBOutlet weak var lightingGauge: WMGaugeView!
	
	@IBOutlet weak var enginePower: ScrubControl!
    @IBOutlet weak var motionIndicatorImage: UIImageView!
	@IBOutlet weak var engineCalibration: UISlider!
	@IBOutlet weak var engineGauge: WMGaugeView!
	
	@IBOutlet weak var soundControl: UISlider!
	
	let pulsator = Pulsator()
    weak var crack: UIImageView?
    var player: AVAudioPlayer?
	
	var mqttControl: MQTTControl!
	
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
		
		compass.rangeLabels = ["North", "North East", "East", "South East", "South", "SouthWest", "West", "North West"]
		compass.rangeValues = [22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5, 337.5]/*, 382.5]*/
		compass.rangeColors = [UIColor.white, UIColor.lightGray, UIColor.white, UIColor.lightGray, UIColor.white, UIColor.lightGray, UIColor.white, UIColor.lightGray]
		compass.rangeLabelsOffset = -22.5
		
		compass.scaleDescription = { (v, i) in
			if v == 0 {
				return "N"
			}
			else if v == 90 {
				return "E"
			}
			else if v == 180 {
				return "S"
			}
			return "W"
		}
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
}

extension TrainViewController: UITextFieldDelegate {
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
	
	@IBAction func billboardTextChanged(sender: UIButton?) {
		billboard.control(text: billboardText.text ?? "")
	}
	
	@IBAction
	func shutdownTrain(sender: UILongPressGestureRecognizer) {
		train.controlShutdown()
	}
    
    @IBAction
    func faultTrain(sender: UIButton?) {
        train.controlFault()
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

extension UIView {
    
    /// Adds constraints to this `UIView` instances `superview` object to make sure this always has the same size as the superview.
    /// Please note that this has no effect if its `superview` is `nil` – add this `UIView` instance as a subview before calling this.
    func bindFrameToSuperviewBounds() {
        guard let superview = self.superview else {
            print("Error! `superview` was nil – call `addSubview(view: UIView)` before calling `bindFrameToSuperviewBounds()` to fix this.")
            return
        }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": self]))
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": self]))
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
		trainAlive.isHighlighted = alive
	}
    
    func train(faults: MotionFaults, _ asserted: Bool) {
        if faults.hasFault == false {
            crack?.removeFromSuperview()
        }
        else if (self.crack == nil) {
            playSound()
            let crack = UIImageView(image: #imageLiteral(resourceName: "brokenglass"))
            crack.translatesAutoresizingMaskIntoConstraints = false
            crack.alpha = 0.25
            view.addSubview(crack)
            crack.bindFrameToSuperviewBounds()
            self.crack = crack
        }
    }
    
    func playSound() {
        guard let url = Bundle.main.url(forResource: "glass break", withExtension: "mp3") else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            guard let player = player else { return }
            
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
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
                motionIndicatorImage?.image = #imageLiteral(resourceName: "MotionIdle")
            case .forward:
                motionIndicatorImage?.image = #imageLiteral(resourceName: "MotionForward")
            case .reverse:
                motionIndicatorImage?.image = #imageLiteral(resourceName: "MotionReverse")
        }
    }
	
	func engine(calibration: TrainRational, _ asserted: Bool) {
		engineGauge?.rangeValues = [NSNumber(value: -calibration.num), NSNumber(value: calibration.num), 100]
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
		lightIndicatorImage?.isHighlighted = power
	}
	
	func lights(calibration: TrainRational, _ asserted: Bool) {
		lightingGauge?.rangeValues = [NSNumber(value: calibration.num), 256]
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
}
