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
	func onLightsPowered(powered: Bool)
	func onLightsAmbient(power: FogRational<Int64>)
	func onLightsCalibrated(power: FogRational<Int64>)
}

public enum LightCommand: Int32 {
	case off
	case on
	case auto
}

public class Lights {
	private var broadcaster: MQTTBroadcaster?
	public private(set) var calibration = FogRational(num: Int64(128), den: 255)
	public private(set) var powered: Bool = false
	public private(set) var ambient: FogRational<Int64> = FogRational()
	
    public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("powered", .atLeastOnce, Lights.powered),
				("ambient", .atLeastOnce, Lights.ambient),
				("calibrated", .atLeastOnce, Lights.calibrated),
			])
		}
    }
	
	public weak var delegate: LightsDelegate?
	
	public func calibrate(_ calibration: FogRational<Int64>) {
		var data  = Data(capacity: calibration.fogSize)
		data.fogAppend(calibration)
		mqtt.publish(MQTTPubMsg(topic: "calibrate", payload: data))
	}
	
	public var powerOverride: LightCommand = .auto {
		didSet {
			var data  = Data(capacity: powerOverride.fogSize)
			data.fogAppend(powerOverride)
			mqtt.publish(MQTTPubMsg(topic: "override", payload: data))
		}
	}
	
	private func calibrated(msg: MQTTMessage) {
		calibration = msg.payload.fogExtract()
		delegate?.onLightsCalibrated(power: calibration)
	}
	
	private func powered(_ msg: MQTTMessage) {
		powered = msg.payload.fogExtract()
		delegate?.onLightsPowered(powered: powered)
	}
	
	private func ambient(_ msg: MQTTMessage) {
		ambient = msg.payload.fogExtract()
		delegate?.onLightsAmbient(power: ambient)
	}
}
