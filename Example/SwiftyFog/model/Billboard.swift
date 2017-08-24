//
//  Billboard.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/9/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import SwiftyFog

public protocol BillboardDelegate: class {
	func onImageSpecConfirmed(layout: FogBitmapLayout)
	func onPostImage(image: UIImage)
}

public class Billboard {
	private var broadcaster: MQTTBroadcaster?
	
    public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("spec", .atMostOnce, Billboard.receiveSpec)
			])
		}
    }
	
	private var bitmap: FogBitMap?
	
	public var layout: FogBitmapLayout? {
		return bitmap?.layout
	}
	
	public weak var delegate: BillboardDelegate?
	
	public func display(image: UIImage) {
		if var bitmap = bitmap {
			let resized = bitmap.imbue(image)
			delegate?.onPostImage(image: resized!)
			var data  = Data(capacity: bitmap.fogSize)
			data.fogAppend(bitmap)
			mqtt.publish(MQTTPubMsg(topic: "image", payload: data))
		}
		else {
			delegate?.onPostImage(image: image)
		}
	}
	
	private func receiveSpec(msg: MQTTMessage) {
		let layout: FogBitmapLayout = msg.payload.fogExtract()
		delegate?.onImageSpecConfirmed(layout: layout)
		bitmap = FogBitMap(layout: layout)
	}
}
