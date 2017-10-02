//
//  Lights.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/29/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import SwiftyFog_iOS

public protocol LightsDelegate: class {
	func lights(override: LightCommand, _ asserted: Bool)
	func lights(power: Bool, _ asserted: Bool)
	func lights(calibration: FogRational<Int64>, _ asserted: Bool)
	func lights(ambient: FogRational<Int64>, _ asserted: Bool)
}

public enum LightCommand: Int32 {
	case off
	case on
	case auto
}

public class Lights: FogFeedbackModel {
	private var broadcaster: MQTTBroadcaster?
	private var override: FogFeedbackValue<LightCommand>
	private var power: FogFeedbackValue<Bool>
	private var calibration: FogFeedbackValue<FogRational<Int64>>
	private var ambient: FogFeedbackValue<FogRational<Int64>>
	
	public weak var delegate: LightsDelegate?
	
    public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("override/feedback", .atMostOnce, Lights.feedbackOverride),
				("power/feedback", .atMostOnce, Lights.feedbackPower),
				("calibration/feedback", .atMostOnce, Lights.feedbackCalibration),
				("ambient/feedback", .atMostOnce, Lights.feedbackAmbient),
			])
		}
    }
	
    public init() {
		self.override = FogFeedbackValue(.auto)
		self.power = FogFeedbackValue(false)
		self.calibration = FogFeedbackValue(FogRational(num: Int64(128), den: 255))
		self.ambient = FogFeedbackValue(FogRational())
    }
	
	public var hasFeedback: Bool {
		return override.hasFeedback && power.hasFeedback && calibration.hasFeedback && ambient.hasFeedback
	}
	
	public func reset() {
		override.reset()
		power.reset()
		calibration.reset()
		ambient.reset()
	}
	
	public func assertValues() {
		delegate?.lights(override: override.value, true)
		delegate?.lights(power: power.value, true)
		delegate?.lights(calibration: calibration.value, true)
		delegate?.lights(ambient: ambient.value, true)
	}
	
	public func control(override: LightCommand) {
		var data  = Data(capacity: override.fogSize)
		data.fogAppend(override)
		mqtt.publish(MQTTMessage(topic: "override/control", payload: data))
	}
	
	public func control(calibration: FogRational<Int64>) {
		self.calibration.control(calibration) { value in
			var data  = Data(capacity: value.fogSize)
			data.fogAppend(value)
			mqtt.publish(MQTTMessage(topic: "calibration/control", payload: data))
		}
	}
	
	private func feedbackOverride(_ msg: MQTTMessage) {
		self.override.receive(msg.payload.fogExtract()) { value, asserted in
			delegate?.lights(override: value, asserted)
		}
	}
	
	private func feedbackPower(_ msg: MQTTMessage) {
		self.power.receive(msg.payload.fogExtract()) { value, asserted in
			delegate?.lights(power: value, asserted)
		}
	}
	
	private func feedbackCalibration(msg: MQTTMessage) {
		self.calibration.receive(msg.payload.fogExtract()) { value, asserted in
			delegate?.lights(calibration: value, asserted)
		}
	}
	
	private func feedbackAmbient(_ msg: MQTTMessage) {
		self.ambient.receive(msg.payload.fogExtract()) { value, asserted in
			delegate?.lights(ambient: value, asserted)
		}
	}
}
