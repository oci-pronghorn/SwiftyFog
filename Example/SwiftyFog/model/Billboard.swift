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
    var mqtt: MQTTBridge!
	var bitmap: FogBitMap?
	
	init() {
		var layout = FogBitmapLayout(colorSpace: .gray)
		layout.width = 96
		layout.height = 96
		layout.componentDepth = 4
		bitmap = FogBitMap(layout: layout)
	}
	
	func start() {
		//mqtt.subscribe(to: ["thejoveexpress/billboard/spec" : MQTTQoS.exactlyOnce])
	}
	
	func stop() {
	}
	
	func display(image: UIImage) {
		bitmap?.imbue(image: image)
		var data  = Data(capacity: bitmap!.fogSize)
		data.fogAppend(bitmap!)
		
		mqtt.publish(MQTTPubMsg(topic: "thejoveexpress/billboard/image", payload: data))
	}
}
