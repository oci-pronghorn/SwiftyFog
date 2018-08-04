//
//  TrainInterfaceController.swift
//  TrainConductor Extension
//
//  Created by David Giovannini on 7/7/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

import WatchKit
import Foundation
import SwiftFog_watch

class TrainInterfaceController: WKInterfaceController {
	let discovery = TrainDiscovery()
	let train = Train()
	let engine = Engine()
	let lights = Lights()
	
	@IBOutlet weak var aliveIndicator: WKInterfaceImage!
	@IBOutlet weak var engineIndicator: WKInterfaceImage!
	@IBOutlet weak var lightIndicator: WKInterfaceImage!
	@IBOutlet weak var powerIndicator: WKInterfaceLabel!
	
	@IBOutlet weak var overrideOnIndicator: WKInterfaceLabel!
	@IBOutlet weak var overrideOffIndicator: WKInterfaceLabel!
	@IBOutlet weak var overrideAutoIndicator: WKInterfaceLabel!
	
	static var discoverBridge: MQTTBridge!
	static var mqttControl: MQTTControl!
	
	static func set(discoverBridge: MQTTBridge, mqttControl: MQTTControl!) {
		self.discoverBridge = discoverBridge
		self.mqttControl = mqttControl
	}

	var mqtt: MQTTBridge! {
		didSet {
			train.mqtt = mqtt
			engine.mqtt = mqtt.createBridge(subPath: "engine")
			lights.mqtt = mqtt.createBridge(subPath: "lights")
		}
	}
	
	private var discoverBridge: MQTTBridge! {
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
		}
	}
	
// MARK: Life Cycle
	
	override init() {
		super.init()
		discovery.delegate = self
		train.delegate = self
		engine.delegate = self
		lights.delegate = self
	}

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
		self.crownSequencer.delegate = self
    	self.discoverBridge = TrainInterfaceController.discoverBridge
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        self.assertConnectionState()
        self.assertValues()
		self.crownSequencer.focus()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
}

// MARK: UI Reactions

extension TrainInterfaceController: WKCrownDelegate {
	func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
		if (engine.control(powerIncrement: rotationalDelta)) {
			WKInterfaceDevice.current().play(WKHapticType.click)
		}
	}
	
	@IBAction func stopMotor(sender: WKTapGestureRecognizer?) {
		if sender?.state == WKGestureRecognizerState.ended {
			engine.controlStop()
		}
	}
	
	@IBAction func lights(sender: WKInterfaceButton?) {
		lights.controlNextOverride()
	}
	
	@IBAction
	func shutdownTrain(sender: WKLongPressGestureRecognizer) {
		train.controlShutdown()
	}
	
	@IBAction
	func requestFeedback(sender: WKTapGestureRecognizer) {
		train.askForFeedback()
	}
}

// MARK: Connection State

extension TrainInterfaceController {
	func mqtt(connected: MQTTConnectedState) {
		switch connected {
			case .started:
				aliveIndicator.setImage(#imageLiteral(resourceName: "Disconnected"))
				break
			case .connected(_, _, _, _):
				feedbackCut()
				assertValues()
				aliveIndicator.setImage(#imageLiteral(resourceName: "Dead"))
				break
			case .pinged(let status):
				switch status {
					case .notConnected:
						break
					case .sent:
						break
					case .skipped:
						break
					case .ack:
						break
					case .serverDied:
						break
				}
				break
			case .retry(_, _, _, _):
				break
			case .retriesFailed(_, _, _):
				break
			case .disconnected(_, _, _):
				feedbackCut()
				aliveIndicator.setImage(#imageLiteral(resourceName: "Disconnected"))
				break
		}
	}
	
	func assertConnectionState() {
	}

	func assertValues() {
		train.assertValues()
		engine.assertValues()
		lights.assertValues()
	}
	
	func feedbackCut() {
		train.reset()
		engine.reset()
		lights.reset()
	}
}

// MARK: Model Delegate

extension TrainInterfaceController: TrainDiscoveryDelegate {
	func train(_ train: DiscoveredTrain, discovered: Bool) {
		if discovered && self.discoveredTrain == nil {
			self.discoveredTrain = train
		}
		if discovered == false {
			if train.trainName == discoveredTrain?.trainName {
				self.discoveredTrain = self.discovery.firstTrain
			}
		}
	}
}

extension TrainInterfaceController:
		TrainDelegate,
		EngineDelegate,
		LightsDelegate {

	func onSubscriptionAck(status: MQTTSubscriptionStatus) {
	}
	
	func train(alive: Bool, named: String?) {
		if alive == false {
			feedbackCut()
		}
		if let name = named {
        	self.setTitle(name)
        }
		aliveIndicator.setImage(alive ? #imageLiteral(resourceName: "Alive") : #imageLiteral(resourceName: "Dead"))
	}
			
    func train(faults: MotionFaults, _ asserted: Bool) {
        if faults.hasFault {
        }
    }
	
	func train(webHost: String?) {
	}
	
	func engine(power: TrainRational, _ asserted: Bool) {
		powerIndicator.setText(power.num.description)
	}
			
    func engine(state: EngineState, _ asserted: Bool) {
    	let colorName: String
        switch state {
            case .idle:
            	colorName = "NoPower"
				WKInterfaceDevice.current().play(WKHapticType.stop)
            case .forward:
            	colorName = "Forward"
				WKInterfaceDevice.current().play(WKHapticType.directionUp)
            case .reverse:
            	colorName = "Reverse"
				WKInterfaceDevice.current().play(WKHapticType.directionDown)
        }
		engineIndicator.setImage(#imageLiteral(resourceName: "Motion").tinted(with: UIColor(named: colorName)!))
    }
	
	func engine(calibration: TrainRational, _ asserted: Bool) {
	}
	
	func lights(override: LightCommand, _ asserted: Bool) {
		switch override {
		case .off:
			overrideOnIndicator.setTextColor(UIColor.black)
			overrideOffIndicator.setTextColor(UIColor.white)
			overrideAutoIndicator.setTextColor(UIColor.black)
		case .on:
			overrideOnIndicator.setTextColor(UIColor.white)
			overrideOffIndicator.setTextColor(UIColor.black)
			overrideAutoIndicator.setTextColor(UIColor.black)
		case .auto:
			overrideOnIndicator.setTextColor(UIColor.black)
			overrideOffIndicator.setTextColor(UIColor.black)
			overrideAutoIndicator.setTextColor(UIColor.white)
		}
	}
	
	func lights(power: Bool, _ asserted: Bool) {
		lightIndicator.setImage(#imageLiteral(resourceName: "Torch").tinted(with: UIColor(named: power ? "LightsOn" : "NoPower")!))
	}
	
	func lights(calibration: TrainRational, _ asserted: Bool) {
	}
	
	func lights(ambient: TrainRational, _ asserted: Bool) {
	}
}
