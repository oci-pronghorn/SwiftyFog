//
//  Sound.swift
//  TrainControl
//
//  Created by David Giovannini on 9/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import SwiftyFog_iOS

class Sound {
	private var piezo: FogFeedbackValue<FogRational<Int64>>
	
	public init() {
		self.piezo = FogFeedbackValue(FogRational(num: Int64(0), den: 100))
	}
	
    public var mqtt: MQTTBridge! {
		didSet {
		}
    }
	
	public func control(piezo: FogRational<Int64>) {
		self.piezo.control(piezo) { value in
			var data  = Data(capacity: value.fogSize)
			data.fogAppend(value)
			mqtt.publish(MQTTMessage(topic: "piezo/control", payload: data))
		}
	}
}
