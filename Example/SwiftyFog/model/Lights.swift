//
//  Lights.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/29/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import SwiftyFog

public protocol LightsDelegate: class {
	func onLightsPowered(powered: Bool, _ asserted: Bool)
	func onLightsAmbient(power: FogRational<Int64>, _ asserted: Bool)
	func onLightsCalibrated(power: FogRational<Int64>, _ asserted: Bool)
}

public enum LightCommand: Int32 {
	case off
	case on
	case auto
}

public class Lights {
	private var broadcaster: MQTTBroadcaster?
	public private(set) var calibration: FogFeedbackValue<FogRational<Int64>>
	public private(set) var powered: FogFeedbackValue<Bool>
	public private(set) var ambient: FogFeedbackValue<FogRational<Int64>>
	
	public weak var delegate: LightsDelegate?
	
    public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("powered", .atLeastOnce, Lights.receivePowered),
				("ambient", .atLeastOnce, Lights.receiveAmbient),
				("calibrated", .atLeastOnce, Lights.receiveCalibration),
			])
		}
    }
	
    init() {
		self.calibration = FogFeedbackValue(FogRational(num: Int64(128), den: 255))
		self.powered = FogFeedbackValue(false)
		self.ambient = FogFeedbackValue(FogRational())
    }
	
	var isReady: Bool {
		return calibration.hasFeedback && powered.hasFeedback
	}
	
	public func calibrate(_ calibration: FogRational<Int64>) {
		self.calibration.controlled(calibration) { value in
			var data  = Data(capacity: value.fogSize)
			data.fogAppend(value)
			mqtt.publish(MQTTPubMsg(topic: "calibrate", payload: data))
		}
	}
	
	public var powerOverride: LightCommand = .auto {
		didSet {
			var data  = Data(capacity: powerOverride.fogSize)
			data.fogAppend(powerOverride)
			mqtt.publish(MQTTPubMsg(topic: "override", payload: data))
		}
	}
	
	private func receiveCalibration(msg: MQTTMessage) {
		self.calibration.received(msg.payload.fogExtract()) { value, asserted in
			delegate?.onLightsCalibrated(power: value, asserted)
		}
	}
	
	private func receivePowered(_ msg: MQTTMessage) {
		self.powered.received(msg.payload.fogExtract()) { value, asserted in
			delegate?.onLightsPowered(powered: value, asserted)
		}
	}
	
	private func receiveAmbient(_ msg: MQTTMessage) {
		self.ambient.received(msg.payload.fogExtract()) { value, asserted in
			delegate?.onLightsAmbient(power: value, asserted)
		}
	}
}
