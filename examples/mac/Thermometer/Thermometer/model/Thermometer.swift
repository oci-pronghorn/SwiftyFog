//
//  Thermometer.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/29/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import SwiftyFog_mac

public protocol ThermometerDelegate: class {
	func thermometer(temperature: Int32)
}

public class Thermometer {
	private var broadcaster: MQTTBroadcaster?
	private var temperature: Int32
	
	public weak var delegate: ThermometerDelegate?
	
	public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("temperature/feedback", .atMostOnce, Thermometer.feedbackTemperature)])
		}
	}
	
	public init() {
		self.temperature = 0
	}
	
	private func feedbackTemperature(_ msg: MQTTMessage) {
		self.temperature = msg.payload.fogExtract()
		delegate?.thermometer(temperature: temperature)
	}
}

