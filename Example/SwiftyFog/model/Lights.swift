//
//  Lights.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/29/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import SwiftyFog

protocol LightsDelegate: class {
	func onLightsPowered(powered: Bool)
	func onLightsAmbient(power: FogRational<Int64>)
}

enum LightCommand: Int32 {
	case off
	case on
	case auto
}

class Lights {
	var broadcaster: MQTTBroadcaster?
	
	weak var delegate: LightsDelegate?
	
    var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, topics: [
				("powered", .atMostOnce, Lights.powered),
				("ambient", .atMostOnce, Lights.ambient)
			])
		}
    }
	
	init() {
	}
	
	func start() {
	}
	
	func stop() {
	}
	
	private func powered(_ msg: MQTTMessage) {
		let powered: Bool = msg.payload.fogExtract()
		delegate?.onLightsPowered(powered: powered)
	}
	
	private func ambient(_ msg: MQTTMessage) {
		let ambient: FogRational<Int64> = msg.payload.fogExtract()
		delegate?.onLightsAmbient(power: ambient)
	}
	
	func calibrate() {
		let data  = Data(capacity: 0)
		mqtt.publish(MQTTPubMsg(topic: "calibrate", payload: data))
	}
	
	var cmd: LightCommand = .auto {
		didSet {
			var data  = Data(capacity: MemoryLayout.size(ofValue: cmd.rawValue))
			data.fogAppend(cmd.rawValue)
			mqtt.publish(MQTTPubMsg(topic: "override", payload: data))
		}
	}
}
