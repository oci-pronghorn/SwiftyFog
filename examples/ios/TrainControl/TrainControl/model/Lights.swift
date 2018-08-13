//
//  Lights.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/29/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
#if os(iOS)
import SwiftyFog_iOS
#elseif os(watchOS)
import SwiftFog_watch
#endif

public enum LightCommand: Int32 {
    case off = 0
    case on = 1
    case auto = 2
	
	func next() -> LightCommand {
		if self == .auto {
			return .off
		}
		return LightCommand(rawValue: self.rawValue + 1)!
	}
}

public protocol LightsDelegate: class, SubscriptionLogging {
	func lights(override: LightCommand, _ asserted: Bool)
	func lights(power: Bool, _ asserted: Bool)
	func lights(calibration: TrainRational, _ asserted: Bool)
	func lights(ambient: TrainRational, _ asserted: Bool)
}

public class Lights: FogFeedbackModel {
	private var broadcaster: MQTTBroadcaster?
	private var override: FogFeedbackValue<LightCommand>
	private var power: FogFeedbackValue<Bool>
	private var calibration: FogFeedbackValue<TrainRational>
	private var ambient: FogFeedbackValue<TrainRational>
	
	public weak var delegate: LightsDelegate?
	
    public var mqtt: MQTTBridge? {
		didSet {
			broadcaster.assign(mqtt?.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("override/feedback", .atMostOnce, Lights.feedbackOverride),
				("power/feedback", .atMostOnce, Lights.feedbackPower),
				("calibration/feedback", .atMostOnce, Lights.feedbackCalibration),
				("ambient/feedback", .atMostOnce, Lights.feedbackAmbient),
			]) {[weak self] (_, status) in self?.delegate?.onSubscriptionAck(status: status)})
		}
    }
	
    public init() {
		self.override = FogFeedbackValue(.auto)
		self.power = FogFeedbackValue(false)
		self.calibration = FogFeedbackValue(TrainRational(num: TrainRational.ValueType(128), den: 255))
		self.ambient = self.calibration
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
	
	public func controlNextOverride() {
		self.control(override: override.value.next())
	}
	
	public func control(override: LightCommand) {
		var data  = Data(capacity: override.fogSize)
		data.fogAppend(override)
		mqtt?.publish(MQTTMessage(topic: "override/control", payload: data))
	}
	
	public func control(calibration: TrainRational) {
		self.calibration.control(calibration) { value in
			var data  = Data(capacity: value.fogSize)
			data.fogAppend(value)
			mqtt?.publish(MQTTMessage(topic: "calibration/control", payload: data))
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
