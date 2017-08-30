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
	public private(set) var calibration: FogFeedbackValue<FogRational<Int64>>
	public private(set) var power: FogFeedbackValue<FogRational<Int64>>
	
	public weak var delegate: EngineDelegate?
	
	public init() {
		self.calibration = FogFeedbackValue(FogRational(num: Int64(15), den: 100))
		self.power = FogFeedbackValue(FogRational(num: Int64(0), den: 1))
	}
	
    public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("powered", .atLeastOnce, Engine.receivePower),
				("calibrated", .atLeastOnce, Engine.receiveCalibration)
			])
		}
    }
	
	public var hasFeedback: Bool {
		return calibration.hasFeedback && power.hasFeedback
	}
	
	public func reset() {
		calibration.reset()
		power.reset()
	}
	
	public func assertValues() {
		delegate?.engine(power: power.value, true)
		delegate?.engine(calibration: calibration.value, true)
	}
	
	public func calibrate(_ calibration: FogRational<Int64>) {
		self.calibration.control(calibration) { value in
			var data  = Data(capacity: calibration.fogSize)
			data.fogAppend(calibration)
			mqtt.publish(MQTTPubMsg(topic: "calibrate", payload: data))
		}
	}
	
	public func setPower(_ power: FogRational<Int64>) {
		self.power.control(power) { value in
			var data  = Data(capacity: value.fogSize)
			data.fogAppend(value)
			mqtt.publish(MQTTPubMsg(topic: "power", payload: data))
		}
	}
	
	private func receivePower(msg: MQTTMessage) {
		self.power.receive(msg.payload.fogExtract()) { value, asserted in
			delegate?.engine(power: value, asserted)
		}
	}
	
	private func receiveCalibration(msg: MQTTMessage) {
		self.calibration.receive(msg.payload.fogExtract()) { value, asserted in
			delegate?.engine(calibration: value, asserted)
		}
	}
}
