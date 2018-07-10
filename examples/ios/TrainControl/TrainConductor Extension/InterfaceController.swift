//
//  InterfaceController.swift
//  TrainConductor Extension
//
//  Created by David Giovannini on 7/7/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

import WatchKit
import Foundation
import SwiftFog_watch

class InterfaceController: WKInterfaceController {
	let train = Train()
	let engine = Engine()
	let lights = Lights()
	let billboard = Billboard()
	
	var mqttControl: MQTTControl!
	
	@IBOutlet weak var aliveIndicator: WKInterfaceImage!
	@IBOutlet weak var engineIndicator: WKInterfaceImage!
	@IBOutlet weak var lightIndicator: WKInterfaceImage!
	@IBOutlet weak var powerIndicator: WKInterfaceLabel!
	
// MARK: Life Cycle

	static var mqtt: MQTTBridge!

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

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
		self.crownSequencer.delegate = self
    	self.mqtt = InterfaceController.mqtt
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

extension InterfaceController: WKCrownDelegate {
	func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
		engine.control(powerIncrement: rotationalDelta)
	}
	
	@IBAction func lights(sender: WKInterfaceButton?) {
		lights.controlNextOverride()
	}
}

// MARK: Connection State

extension InterfaceController {
	func mqtt(connected: MQTTConnectedState) {
		switch connected {
			case .started:
				break
			case .connected(_, _, _, _):
				feedbackCut()
				assertValues()
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
				break
		}
	}
	
	func assertConnectionState() {
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

// MARK: Model Delegate

extension InterfaceController:
		TrainDelegate,
		EngineDelegate,
		LightsDelegate,
        BillboardDelegate {
	
	func train(alive: Bool) {
		if alive == false {
			feedbackCut()
		}
		aliveIndicator.setImage(alive ? #imageLiteral(resourceName: "Alive") : #imageLiteral(resourceName: "Dead"))
	}
			
    func train(faults: MotionFaults, _ asserted: Bool) {
        if faults.hasFault {
        }
    }
	
	func engine(power: TrainRational, _ asserted: Bool) {
		powerIndicator.setText(power.num.description)
	}
			
    func engine(state: EngineState, _ asserted: Bool) {
        switch state {
            case .idle:
                engineIndicator.setImage(#imageLiteral(resourceName: "MotionIdle"))
            case .forward:
                engineIndicator.setImage(#imageLiteral(resourceName: "MotionForward"))
            case .reverse:
                engineIndicator.setImage(#imageLiteral(resourceName: "MotionReverse"))
        }
    }
	
	func engine(calibration: TrainRational, _ asserted: Bool) {
	}
	
	func lights(override: LightCommand, _ asserted: Bool) {
	}
	
	func lights(power: Bool, _ asserted: Bool) {
		lightIndicator.setImage(power ? #imageLiteral(resourceName: "TorchOn") : #imageLiteral(resourceName: "TorchOff"))
	}
	
	func lights(calibration: TrainRational, _ asserted: Bool) {
	}
	
	func lights(ambient: TrainRational, _ asserted: Bool) {
	}

	func billboard(layout: FogBitmapLayout) {
	}
	
	func billboard(image: UIImage) {
	}
	
    func billboard(text: String, _ asserted: Bool) {
        self.setTitle(text)
    }
}
