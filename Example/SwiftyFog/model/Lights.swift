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
    var mqtt: MQTTBridge!
	
	init() {
	}
	
	func start() {
	}
	
	func stop() {
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
