//
//  Sound.swift
//  TrainControl
//
//  Created by David Giovannini on 9/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
#if os(iOS)
import SwiftyFog_iOS
#elseif os(watchOS)
import SwiftFog_watch
#endif

class Sound {
	private var piezo: FogFeedbackValue<TrainRational>
	
	public init() {
		self.piezo = FogFeedbackValue(TrainRational(num: TrainRational.ValueType(0), den: 100))
	}
	
    public var mqtt: MQTTBridge! {
		didSet {
		}
    }
	
	public func control(piezo: TrainRational) {
		self.piezo.control(piezo) { value in
			var data  = Data(capacity: value.fogSize)
			data.fogAppend(value)
			mqtt.publish(MQTTMessage(topic: "piezo/control", payload: data))
		}
	}
}
