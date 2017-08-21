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
	var broadcaster: MQTTBroadcaster?
	
    var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, topics: [
				("spec", .atMostOnce, Billboard.receiveSpec)
			])
		}
    }
	
	func start() {
	}
	
	func stop() {
	}
	
	func receiveSpec(msg: MQTTMessage) {
		let layout: FogBitmapLayout = msg.payload.fogExtract()
		print("Billboard Specified: \(layout)")
		bitmap = FogBitMap(layout: layout)
	}
	
	func display(image: UIImage) {
		if var bitmap = bitmap {
			bitmap.imbue(image: image)
			var data  = Data(capacity: bitmap.fogSize)
			data.fogAppend(bitmap)
			mqtt.publish(MQTTPubMsg(topic: "image", payload: data))
		}
	}
}
