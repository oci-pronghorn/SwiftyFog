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
	func billboard(layout: FogBitmapLayout)
	func billboard(image: UIImage)
}

public class Billboard: FogFeedbackModel {
	private var bitmap: FogBitMap?
	private var broadcaster: MQTTBroadcaster?
	
	public weak var delegate: BillboardDelegate?
	
    public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("spec/feedback", .atLeastOnce, Billboard.feedbackSpec)
			])
		}
    }
	
	public init() {
	}
	
	public var hasFeedback: Bool {
		return bitmap != nil
	}
	
	public func reset() {
		bitmap = nil
	}
	
	public func assertValues() {
	}
	
	public var layout: FogBitmapLayout? {
		return bitmap?.layout
	}
	
	public func control(image: UIImage) {
		if var bitmap = bitmap {
			let resized = bitmap.imbue(image)
			delegate?.billboard(image: resized!)
			var data  = Data(capacity: bitmap.fogSize)
			data.fogAppend(bitmap)
			mqtt.publish(MQTTMessage(topic: "image/control", payload: data))
		}
		else {
			delegate?.billboard(image: image)
		}
	}
	
	private func feedbackSpec(msg: MQTTMessage) {
		let layout: FogBitmapLayout = msg.payload.fogExtract()
		delegate?.billboard(layout: layout)
		bitmap = FogBitMap(layout: layout)
	}
}
