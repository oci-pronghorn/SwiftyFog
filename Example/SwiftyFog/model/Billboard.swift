//
//  Billboard.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/9/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import SwiftyFog

class Billboard {
	var bitmap: FogBitMap?
	var registrations = [MQTTRegistration]()
	
    var mqtt: MQTTBridge! {
		didSet {
			registrations = mqtt.registerTopics([
				("billboard/spec", receiveSpec)
			])
		}
    }
	
	func start() {
	}
	
	func stop() {
	}
	
	func receiveSpec(msg: MQTTMessage) {
		let layout: FogBitmapLayout = msg.payload.fogExtract()
		bitmap = FogBitMap(layout: layout)
	}
	
	func display(image: UIImage) {
		bitmap?.imbue(image: image)
		var data  = Data(capacity: bitmap!.fogSize)
		data.fogAppend(bitmap!)
		
		mqtt.publish(MQTTPubMsg(topic: "billboard/image", payload: data))
	}
}
