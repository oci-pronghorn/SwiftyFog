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
	func onPowerConfirm(power: FogRational<Int64>)
	func onPowerCalibrated(power: FogRational<Int64>)
}

public class Engine {
	private var broadcaster: MQTTBroadcaster?
	private let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
	private var oldPower = FogRational(num: Int64(0), den: 0)
	private var oldCalibration = FogRational(num: Int64(0), den: 0)
	
    var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("powered", .atMostOnce, Engine.powered),
				("calibrated", .atMostOnce, Engine.calibrated)
			])
		}
    }
	
	public weak var delegate: EngineDelegate?
	
	init() {
		timer.setEventHandler { [weak self] in
			self?.onTimer()
		}
	}
	
	func start() {
		timer.schedule(deadline: .now(), repeating: .milliseconds(250/*40*/), leeway: .milliseconds(10))
		timer.resume()
	}
	
	func stop() {
		timer.suspend()
	}
	
	deinit {
		timer.cancel()
	}
	
	public var calibration = FogRational(num: Int64(15), den: 100)
	public var power = FogRational(num: Int64(0), den: 1)
	
	private func onTimer() {
		if oldCalibration != calibration {
			oldCalibration = calibration
			var data  = Data(capacity: calibration.fogSize)
			data.fogAppend(calibration)
			mqtt.publish(MQTTPubMsg(topic: "calibrate", payload: data))
		}
		if oldPower != power {
			oldPower = power
			var data  = Data(capacity: power.fogSize)
			data.fogAppend(power)
			mqtt.publish(MQTTPubMsg(topic: "power", payload: data))
		}
	}
	
	private func calibrated(msg: MQTTMessage) {
		let newValue: FogRational<Int64> = msg.payload.fogExtract()
		if calibration != newValue {
			calibration = newValue
			delegate?.onPowerCalibrated(power: calibration)
		}
	}
	
	private func powered(msg: MQTTMessage) {
		let newValue: FogRational<Int64> = msg.payload.fogExtract()
		if power != newValue {
			power = newValue
			delegate?.onPowerConfirm(power: power)
		}
	}
}
