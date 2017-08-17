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
	var registrations = [MQTTRegistration]()
	
    var mqtt: MQTTBridge! {
		didSet {
			registrations = mqtt.registerTopics([
				("thejoveexpress/lights/powered", powered),
				("thejoveexpress/lights/ambient", ambient)
			])
			
		}
    }
	
	init() {
	}
	
	func start() {
	}
	
	func stop() {
	}
	
	func powered(msg: MQTTMessage) {
		//let powered: LightCommand = msg.payload.fogExtract() ?? .off
	}
	
	func ambient(msg: MQTTMessage) {
		//let ambient: FogRational<Int64> = msg.payload.fogExtract()
	}
	
	func calibrate() {
		let data  = Data(capacity: 0)
		mqtt.publish(MQTTPubMsg(topic: "thejoveexpress/lights/calibrate", payload: data))
	}
	
	var cmd: LightCommand = .auto {
		didSet {
			var data  = Data(capacity: MemoryLayout.size(ofValue: cmd.rawValue))
			data.fogAppend(cmd.rawValue)
			mqtt.publish(MQTTPubMsg(topic: "thejoveexpress/lights/override", payload: data))
		}
	}
}
