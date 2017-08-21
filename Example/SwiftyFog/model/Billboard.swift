//
//  Billboard.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/9/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import SwiftyFog

protocol BillboardDelegate: class {
	func onImageSpecConfirmed(layout: FogBitmapLayout)
	func onPostImage(image: UIImage)
}

class Billboard {
	private var bitmap: FogBitMap?
	private var broadcaster: MQTTBroadcaster?
	
	weak var delegate: BillboardDelegate?
	
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
	
	private func receiveSpec(msg: MQTTMessage) {
		let layout: FogBitmapLayout = msg.payload.fogExtract()
		delegate?.onImageSpecConfirmed(layout: layout)
		bitmap = FogBitMap(layout: layout)
	}
	
	func display(image: UIImage) {
		if var bitmap = bitmap {
			let resized = bitmap.imbue(image)
			delegate?.onPostImage(image: resized!)
			var data  = Data(capacity: bitmap.fogSize)
			data.fogAppend(bitmap)
			mqtt.publish(MQTTPubMsg(topic: "image", payload: data))
		}
	}
}
