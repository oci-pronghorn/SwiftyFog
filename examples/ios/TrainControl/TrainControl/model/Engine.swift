//
//  Engine.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/29/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import SwiftyFog_iOS

public enum EngineState: Int32 {
    case reverse = -1
    case idle = 0
    case forward = 1
}

public protocol EngineDelegate: class {
	func engine(power: TrainRational, _ asserted: Bool)
	func engine(calibration: TrainRational, _ asserted: Bool)
    func engine(state: EngineState, _ asserted: Bool)
}

public class Engine: FogFeedbackModel {
	private var broadcaster: MQTTBroadcaster?
	private var power: FogFeedbackValue<TrainRational>
	private var calibration: FogFeedbackValue<TrainRational>
    private var state: FogFeedbackValue<EngineState>
	
	public weak var delegate: EngineDelegate?
	
	public init() {
		self.power = FogFeedbackValue(TrainRational(num: TrainRational.ValueType(0), den: 100))
		self.calibration = FogFeedbackValue(TrainRational(num: TrainRational.ValueType(30), den: 100))
        self.state = FogFeedbackValue(.idle)
	}
	
    public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
                ("power/feedback", .atMostOnce, Engine.feedbackPower),
                ("calibration/feedback", .atMostOnce, Engine.feedbackCalibration),
                ("state/feedback", .atMostOnce, Engine.feedbackState)
			])
		}
    }
	
	public var hasFeedback: Bool {
		return power.hasFeedback && calibration.hasFeedback
	}
	
	public func reset() {
		power.reset()
		calibration.reset()
	}
	
	public func assertValues() {
		delegate?.engine(power: power.value, true)
		delegate?.engine(calibration: calibration.value, true)
	}
	
	public func control(power: TrainRational) {
		self.power.control(power) { value in
			var data  = Data(capacity: value.fogSize)
			data.fogAppend(value)
			mqtt.publish(MQTTMessage(topic: "power/control", payload: data))
		}
	}
	
	public func control(calibration: TrainRational) {
		self.calibration.control(calibration) { value in
			var data  = Data(capacity: calibration.fogSize)
			data.fogAppend(calibration)
			mqtt.publish(MQTTMessage(topic: "calibration/control", payload: data))
		}
	}
	
	private func feedbackPower(_ msg: MQTTMessage) {
		self.power.receive(msg.payload.fogExtract()) { value, asserted in
			delegate?.engine(power: value, asserted)
		}
	}
	
	private func feedbackCalibration(_ msg: MQTTMessage) {
		self.calibration.receive(msg.payload.fogExtract()) { value, asserted in
			delegate?.engine(calibration: value, asserted)
		}
	}
    
    private func feedbackState(_ msg: MQTTMessage) {
        self.state.receive(msg.payload.fogExtract()) { value, asserted in
            delegate?.engine(state: value, asserted)
        }
    }
}
