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
	func onEnginePower(power: FogRational<Int64>)
	func onEngineCalibrated(power: FogRational<Int64>)
}

public class Engine {
	private var broadcaster: MQTTBroadcaster?
	public private(set) var calibration = FogRational(num: Int64(15), den: 100)
	public private(set) var power = FogRational(num: Int64(0), den: 1)
	
    var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("powered", .atLeastOnce, Engine.receivePower),
				("calibrated", .atLeastOnce, Engine.receiveCalibration)
			])
		}
    }
	
	public weak var delegate: EngineDelegate?
	
	public func calibrate(_ calibration: FogRational<Int64>) {
		var data  = Data(capacity: calibration.fogSize)
		data.fogAppend(calibration)
		mqtt.publish(MQTTPubMsg(topic: "calibrate", payload: data))
	}
	
	public func setPower(_ power: FogRational<Int64>) {
		self.power = power
		var data  = Data(capacity: power.fogSize)
		data.fogAppend(power)
		mqtt.publish(MQTTPubMsg(topic: "power", payload: data))
	}
	
	private func receivePower(msg: MQTTMessage) {
		power = msg.payload.fogExtract()
		delegate?.onEnginePower(power: power)
	}
	
	private func receiveCalibration(msg: MQTTMessage) {
		calibration = msg.payload.fogExtract()
		delegate?.onEngineCalibrated(power: calibration)
	}
}
