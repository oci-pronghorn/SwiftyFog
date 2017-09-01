//
//  Engine.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/29/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import SwiftyFog

public protocol EngineDelegate: class {
	func engine(power: FogRational<Int64>, _ asserted: Bool)
	func engine(calibration: FogRational<Int64>, _ asserted: Bool)
}

public class Engine: FogFeedbackModel {
	private var broadcaster: MQTTBroadcaster?
	private var power: FogFeedbackValue<FogRational<Int64>>
	private var calibration: FogFeedbackValue<FogRational<Int64>>
	
	public weak var delegate: EngineDelegate?
	
	public init() {
		self.power = FogFeedbackValue(FogRational(num: Int64(0), den: 100))
		self.calibration = FogFeedbackValue(FogRational(num: Int64(15), den: 100))
	}
	
    public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("power/feedback", .atLeastOnce, Engine.feedbackPower),
				("calibration/feedback", .atLeastOnce, Engine.feedbackCalibration)
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
	
	public func control(power: FogRational<Int64>) {
		self.power.control(power) { value in
			var data  = Data(capacity: value.fogSize)
			data.fogAppend(value)
			mqtt.publish(MQTTPubMsg(topic: "power/control", payload: data))
		}
	}
	
	public func control(calibration: FogRational<Int64>) {
		self.calibration.control(calibration) { value in
			var data  = Data(capacity: calibration.fogSize)
			data.fogAppend(calibration)
			mqtt.publish(MQTTPubMsg(topic: "calibration/control", payload: data))
		}
	}
	
	private func feedbackPower(_ msg: MQTTMessage) {
		let value: FogRational<Int64> = msg.payload.fogExtract()
		self.power.receive(value) { value, asserted in
			delegate?.engine(power: value, asserted)
		}
	}
	
	private func feedbackCalibration(_ msg: MQTTMessage) {
		self.calibration.receive(msg.payload.fogExtract()) { value, asserted in
			delegate?.engine(calibration: value, asserted)
		}
	}
}
