//
//  Billboard.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/9/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
#if os(iOS)
import SwiftyFog_iOS
#elseif os(watchOS)
import SwiftFog_watch
#endif

public protocol BillboardDelegate: class {
	func billboard(layout: FogBitmapLayout)
	func billboard(image: UIImage)
    func billboard(text: String, _ asserted: Bool)
}

public class Billboard: FogFeedbackModel {
    private var broadcaster: MQTTBroadcaster?
	private var bitmap: FogBitMap?
    private var text: FogFeedbackValue<String>
	
	public weak var delegate: BillboardDelegate?
	
    public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("spec/feedback", .atMostOnce, Billboard.feedbackSpec),
                ("text/feedback", .atMostOnce, Billboard.feedbackText)
			])
		}
    }
	
	public init() {
        self.text = FogFeedbackValue("")
	}
	
	public var hasFeedback: Bool {
		return /*bitmap != nil &&*/ text.hasFeedback
	}
	
	public func reset() {
		bitmap = nil
        text.reset()
	}
	
	public func assertValues() {
        delegate?.billboard(text: text.value, true)
	}
	
	public var layout: FogBitmapLayout? {
		return bitmap?.layout
	}
    
    public func control(text: String) {
        var payload = Data();
        payload.fogAppend(text);
        mqtt.publish(MQTTMessage(topic: "text/control", payload: payload))
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
		if let layout: FogBitmapLayout = msg.payload.fogExtract() {
			delegate?.billboard(layout: layout)
			bitmap = FogBitMap(layout: layout)
		}
	}
    
    private func feedbackText(msg: MQTTMessage) {
        self.text.receive(msg.payload.fogExtract()) { value, asserted in
            delegate?.billboard(text: value.trimmingCharacters(in: .whitespacesAndNewlines), asserted)
        }
    }
}
