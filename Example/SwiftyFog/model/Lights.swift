//
//  Lights.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/29/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import SwiftyFog

enum LightCommand: Int32 {
	case off
	case on
	case auto
}

class Lights {
	var broadcaster: MQTTBroadcaster?
	
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
	
	func powered(_ msg: MQTTMessage) {
		let powered: Bool = msg.payload.fogExtract()
		print("Lights Powered: \(powered)")
	}
	
	func ambient(_ msg: MQTTMessage) {
		let ambient: FogRational<Int64> = msg.payload.fogExtract()
		print("Light Ambient: \(ambient)")
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
